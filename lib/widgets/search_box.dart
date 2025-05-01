import 'package:flutter/material.dart';
import '../app_theme.dart'; // تأكد من استيراد ملف AppTheme

class SearchBox extends StatelessWidget {
  final TextEditingController searchControllerText;
  final Function(String) onChanged;

  SearchBox({required this.searchControllerText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.blue[700]?.withOpacity(0.08), // تغيير اللون بناءً على الوضع
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: TextStyle(
          color: AppTheme.getTextColor(isDarkMode), // ✅ لون النص المكتوب من المستخدم
        ),
        controller: searchControllerText,
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54, // لون النص حسب الوضع
          ),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)), // لون الأيقونة
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
