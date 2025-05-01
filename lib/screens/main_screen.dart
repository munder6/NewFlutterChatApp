import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:meassagesapp/screens/home_screen.dart';
import 'package:meassagesapp/screens/new_chat_screen.dart';
import 'package:meassagesapp/screens/settings_screen.dart';
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
      _screens = [
        HomeScreen(),
        NewChatScreen(),
        SettingsScreen(),
      ];
      isLoading = false;
    } else {
      _loadUserId();
    }
  }

  Future<void> _loadUserId() async {
    await Future.delayed(Duration(milliseconds: 500));
    userId = GetStorage().read('user_id');

    _screens = [
      HomeScreen(),
      NewChatScreen(),
      SettingsScreen(),
    ];

    setState(() {
      isLoading = false;
    });
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 92,
        child: BottomNavigationBar(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/convs.svg',
                color: _selectedIndex == 0 ? Colors.blue[700] : Colors.white, // تغيير اللون عند التحديد
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(EvaIcons.editOutline),
              label: 'New Chat',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 25,
                color: _selectedIndex == 2 ? Colors.blue[700] : Colors.white, // تغيير اللون عند التحديد
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
