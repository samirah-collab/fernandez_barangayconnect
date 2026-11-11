
import 'package:flutter/material.dart';

const Color appTeal = Color(0xFF117477);
const Color appYellow = Color(0xFFFFB000);

Widget pageTitle(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(
    title,
    style: const TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.bold,
      color: Color(0xFF172B2F),
    ),
  ),
);

Widget formLabel(String text) => Padding(
  padding: const EdgeInsets.only(top: 14, bottom: 7),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey,
    ),
  ),
);

Widget menuCard(
  IconData icon,
  String title,
  String subtitle,
  VoidCallback onTap, {
  Color color = appTeal,
}) {
  return Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(
        color: Color(0xFFDDE8E6),
      ),
    ),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.blueGrey,
      ),
    ),
  );
}
