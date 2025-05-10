import 'package:flutter/material.dart';
import '../app_theme.dart'; // تأكد من استيراد ملف AppTheme

class SearchBox extends StatelessWidget {
  final TextEditingController searchControllerText;
  final Function(String) onChanged;
  final Function(String)? onSubmitted; // أضف هذا

  SearchBox({
    required this.searchControllerText,
    required this.onChanged,
    this.onSubmitted, // أضف هذا
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.blue[700]?.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchControllerText,
        textInputAction: TextInputAction.done,
        style: TextStyle(
          color: AppTheme.getTextColor(isDarkMode),
        ),
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
          if (onSubmitted != null) {
            onSubmitted!(value);
          } else {
            onChanged(value); // fallback: تعامل كأنها onChanged
          }
        },
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search",
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode
                ? Colors.white.withOpacity(0.5)
                : Colors.black.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

