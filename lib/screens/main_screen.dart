import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import '../app_theme.dart';
import 'home_screen.dart';
import 'new_chat_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? userId;
  bool isLoading = true;

  final List<Widget> _screens = [
    HomeScreen(),
    NewChatScreen(),
    SettingsScreen(),

    // ممكن تضيف Tab ثالث: ContactsScreen() مثلاً
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    await Future.delayed(Duration(milliseconds: 500));
    userId = GetStorage().read('user_id');
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'New Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),


          // جاهز تضيف تاب ثالث لو بدك
        ],
      ),
    );
  }
}
