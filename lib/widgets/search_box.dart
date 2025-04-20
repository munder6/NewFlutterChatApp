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
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, // تغيير اللون بناءً على الوضع
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: searchControllerText,
        decoration: InputDecoration(
          hintText: "Search for chats",
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54, // لون النص حسب الوضع
          ),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black), // لون الأيقونة
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
