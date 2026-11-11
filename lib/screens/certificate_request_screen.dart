import 'package:flutter/material.dart';
import '../services/local_db.dart';
import 'common_widgets.dart';
import 'id_picker.dart';
import 'request_status_screen.dart';
import 'ui_helpers.dart';

class CertificateRequestScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CertificateRequestScreen({super.key, required this.user});

  @override
  State<CertificateRequestScreen> createState() => _CertificateRequestScreenState();
}

class _CertificateRequestScreenState extends State<CertificateRequestScreen> {
  final TextEditingController purpose = TextEditingController();
  CertType selected = certTypes.first;
  String method = 'Pick up at hall';
  String? idImage; // the real photo (base64) – null until the resident picks one
  String payment = paymentMethods.first;
  final TextEditingController paymentRef = TextEditingController();
  bool busy = false;

  bool get needsPayment => selected.fee > 0;
  bool get isEWallet => needsPayment && payment != paymentMethods.first;

  @override
  void dispose() {
    purpose.dispose();
    paymentRef.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (purpose.text.trim().isEmpty) {
      snack(context, 'Please enter the purpose of your request.');
      return;
    }
    if (idImage == null) {
      snack(context, 'Please upload a photo of your valid ID.');
      return;
    }
    if (isEWallet && paymentRef.text.trim().isEmpty) {
      snack(context, 'Please enter the $payment reference number of your payment.');
      return;
    }
    setState(() => busy = true);
    try {
      final request = <String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'type': selected.name,
        'purpose': purpose.text.trim(),
        'method': method,
        'fee': selected.fee,
        'idUploaded': true,
        'idImage': idImage,
        'paymentMethod': needsPayment ? payment : 'No payment needed',
        if (isEWallet) 'paymentRef': paymentRef.text.trim(),
        'owner': widget.user['email'],
        'status': 'Submitted',
        'created': DateTime.now().toIso8601String(),
      };
      await LocalDb.addRequest(request);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RequestStatusScreen(item: request, user: widget.user)),
      );
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Failed to submit request: $e');
      setState(() => busy = false);
    }
  }

  Widget methodButton(String value, String label) => Expanded(
        child: GestureDetector(
          onTap: busy ? null : () => setState(() => method = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            margin: EdgeInsets.only(right: value == 'Deliver' ? 0 : 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: method == value ? appTeal : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: method == value ? appTeal : appLine),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: method == value ? Colors.white : Colors.black)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: stdBar('Request a certificate', dashed: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Choose a certificate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        for (final t in certTypes)
          Panel(
            onTap: busy ? null : () => setState(() => selected = t),
            color: selected == t ? appTealLight : Colors.white,
            border: selected == t ? appTeal : appLine,
            borderWidth: selected == t ? 1.5 : 1,
            pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(selected == t ? Icons.radio_button_checked : Icons.radio_button_off, color: selected == t ? appTeal : Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${peso(t.fee)} · Ready in ${t.ready}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ]),
              ),
            ]),
          ),
        formLabel('Purpose'),
        TextField(
          controller: purpose,
          enabled: !busy,
          decoration: const InputDecoration(hintText: 'Employment requirement'),
        ),
        formLabel('How will you claim it?'),
        Row(children: [methodButton('Pick up at hall', 'Pick up at hall'), methodButton('Deliver', 'Deliver')]),
        const SizedBox(height: 16),
        IdUploadBox(
          label: 'Upload a valid ID (front)',
          imageBase64: idImage,
          enabled: !busy,
          onChanged: (v) => setState(() => idImage = v),
        ),
        const SizedBox(height: 6),
        formLabel('Payment method'),
        if (!needsPayment)
          const Panel(
            child: Row(children: [
              Icon(Icons.check_circle, color: appOk, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('No payment needed for this certificate.', style: TextStyle(fontSize: 13))),
            ]),
          )
        else ...[
          for (final m in paymentMethods)
            Panel(
              onTap: busy ? null : () => setState(() => payment = m),
              color: payment == m ? appTealLight : Colors.white,
              border: payment == m ? appTeal : appLine,
              borderWidth: payment == m ? 1.5 : 1,
              pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Icon(payment == m ? Icons.radio_button_checked : Icons.radio_button_off, color: payment == m ? appTeal : Colors.grey),
                const SizedBox(width: 10),
                Icon(m == paymentMethods.first ? Icons.payments_outlined : Icons.account_balance_wallet_outlined, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              ]),
            ),
          if (isEWallet) ...[
            Text('Send ${peso(selected.fee)} to Brgy. Abongan $payment: $eWalletNumber, then enter the reference number below.',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            TextField(
              controller: paymentRef,
              enabled: !busy,
              decoration: InputDecoration(hintText: '$payment reference number'),
            ),
          ],
        ],
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(needsPayment ? 'Total to pay' : 'Fee', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
          Text(peso(selected.fee), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 10),
        BigButton(busy ? 'Submitting...' : 'Submit request', busy ? null : submit),
      ]),
    );
  }
}