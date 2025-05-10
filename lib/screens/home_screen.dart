import 'dart:ui';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import '../app_theme.dart';
import '../controller/homescreeen_controller.dart';
import '../widgets/conversation_list.dart';
import 'new_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController homeController = Get.put(HomeController());
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (GetStorage().read('isUserLoaded') == true) {
      userId = GetStorage().read('user_id');
      isLoading = false;
    } else {
      _loadUserId();
    }
  }

  Future<void> _loadUserId() async {
    await Future.delayed(Duration(milliseconds: 500));
    userId = GetStorage().read('user_id');
    GetStorage().write('isUserLoaded', true);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppTheme.backgroundColor(isDarkMode);

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Lottie.asset("assets/lottie/splash.json", height: 60),
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
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
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: Container(
              height: 110,
              padding: const EdgeInsets.only(top: 50, left: 20, right: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'messenger',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.blue[700],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Ionicons.pencil, size: 24, color: isDarkMode ? Colors.white : Colors.blue),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _buildBlurredBottomSheet(context, isDarkMode),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ConversationList(
            homeController: homeController,
            userId: userId!,
          ),
        ),
      ),
    );
  }

  Widget _buildBlurredBottomSheet(BuildContext context, bool isDarkMode) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: screenHeight * 0.89,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade800.withOpacity(0.4)
                : Colors.white.withOpacity(0.65),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: NewChatScreen(),
        ),
      ),
    );
  }
}
