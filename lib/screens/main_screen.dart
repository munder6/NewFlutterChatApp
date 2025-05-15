import 'dart:ui';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:meassagesapp/screens/home_screen.dart';
import 'package:meassagesapp/screens/settings_screen.dart';
import 'package:meassagesapp/screens/stories_screen.dart';
import '../app_theme.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? userId;
  bool isLoading = true;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    userId = GetStorage().read('user_id');
    if (userId != null) {
      _screens = [HomeScreen(), StoriesGridScreen(), SettingsScreen()];
      isLoading = false;
    } else {
      _loadUserId();
    }
  }

  Future<void> _loadUserId() async {
    await Future.delayed(Duration(milliseconds: 500));
    userId = GetStorage().read('user_id');
    _screens = [HomeScreen(), StoriesGridScreen(), SettingsScreen()];
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(isDarkMode),
        body: Center(
          child: Lottie.asset("assets/lottie/splash.json", height: 60),
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(isDarkMode),
        body: Center(
          child: Text(
            "User not found",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.backgroundColor(isDarkMode),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          color: isDarkMode ? Colors.grey[900]!.withOpacity(0.1) : Colors.grey[500]!.withOpacity(0.1),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
              child: Container(
                height: 65,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: EvaIcons.messageCircle,
                      label: 'Chats',
                      index: 0,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: EvaIcons.bookOpenOutline,
                      label: 'Stories',
                      index: 1,
                      isDarkMode: isDarkMode,
                    ),
                    _buildNavItem(
                      icon: EvaIcons.settings2Outline,
                      label: 'Settings',
                      index: 2,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDarkMode,
  }) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : (isDarkMode ? Colors.white : Colors.black54),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.blue
                  : (isDarkMode ? Colors.white70 : Colors.black45),
            ),
          ),
          SizedBox(height: 20,)
        ],
      ),
    );
  }
}
