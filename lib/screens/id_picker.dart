import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'common_widgets.dart';
import 'ui_helpers.dart';

// Lets the user choose camera or gallery and returns the photo as base64 text
// (so it can be saved in LocalDb). Returns null if the user cancels,
// so nothing is marked as "uploaded" unless a real photo was picked.
Future<String?> pickImageBase64(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined, color: appTeal),
          title: const Text('Take a photo'),
          onTap: () => Navigator.pop(sheet, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: appTeal),
          title: const Text('Choose from gallery'),
          onTap: () => Navigator.pop(sheet, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (source == null) return null; // user closed the sheet

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 900,
      imageQuality: 65,
    );
    if (picked == null) return null; // user cancelled the picker
    final bytes = await picked.readAsBytes();
    return base64Encode(bytes);
  } catch (e) {
    if (context.mounted) snack(context, 'Could not open the photo: $e');
    return null;
  }
}

// Shows a saved photo (base64) – used for IDs
Widget photoFromBase64(String data, {double? height, BoxFit fit = BoxFit.cover}) {
  try {
    return Image.memory(
      base64Decode(data),
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined, size: 40),
    );
  } catch (_) {
    return const Icon(Icons.broken_image_outlined, size: 40);
  }
}

void showPhotoDialog(BuildContext context, String title, String data) => showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: photoFromBase64(data, fit: BoxFit.contain)),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
      ),
    );

// Upload box: tap to pick a photo, shows a preview once chosen.
class IdUploadBox extends StatelessWidget {
  final String label;
  final String? imageBase64;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  const IdUploadBox({
    super.key,
    required this.label,
    required this.imageBase64,
    required this.onChanged,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    final data = await pickImageBase64(context);
    if (data != null) onChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    final has = imageBase64 != null && imageBase64!.isNotEmpty;
    if (!has) {
      return DashedBox(
        fill: appTealLight,
        pad: const EdgeInsets.all(14),
        onTap: enabled ? () => _pick(context) : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.upload, color: appTeal, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: const TextStyle(color: appTeal, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }
    return Panel(
      pad: const EdgeInsets.all(8),
      child: Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: photoFromBase64(imageBase64!, height: 150)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.check_circle, color: appOk, size: 18),
          const SizedBox(width: 6),
          const Expanded(child: Text('Photo selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          TextButton(onPressed: enabled ? () => _pick(context) : null, child: const Text('Change')),
          TextButton(onPressed: enabled ? () => onChanged(null) : null, child: const Text('Remove')),
        ]),
      ]),
    );
  }
}