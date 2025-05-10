import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FrostedCupertinoAppBar extends StatelessWidget {
  final bool isDarkMode;

  const FrostedCupertinoAppBar({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.extraLightBackgroundGray)
            .withOpacity(0.3),
        border: null, // لإزالة الخط السفلي
        middle: Text(
          'messenger',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : CupertinoColors.activeBlue,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (_) => _buildCupertinoBottomSheet(context, isDarkMode),
            );
          },
          child: Icon(
            CupertinoIcons.pencil_outline,
            size: 26,
            color: isDarkMode ? Colors.white : CupertinoColors.activeBlue,
          ),
        ),
      ),
      child: Container(
        color: isDarkMode ? Colors.black : Colors.white,
        child: const Center(
          child: Text(
            'محتوى الصفحة هنا',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoBottomSheet(BuildContext context, bool isDarkMode) {
    return CupertinoPopupSurface(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode
              ? CupertinoColors.black.withOpacity(0.4)
              : CupertinoColors.systemGrey6.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("هنا المحتوى السفلي 🌙", style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
