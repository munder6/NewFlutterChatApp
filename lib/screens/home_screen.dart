import 'dart:ui';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import '../app_theme.dart';
import '../controller/homescreeen_controller.dart';
import '../controller/new_chat_controller.dart';
import '../widgets/conversation_list.dart';
import '../widgets/search_box.dart';
import '../widgets/user_list.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: AppBar(
              elevation: 0,
              backgroundColor: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              automaticallyImplyLeading: false,
              centerTitle: false,
              titleSpacing: 18,
              title: Text(
                "messenger",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.blue[700],
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Ionicons.create_outline,
                    color: isDarkMode ? Colors.white : Colors.blue[700],
                    size: 26,
                  ),
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
      body: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(isDarkMode),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ConversationList(
          homeController: homeController,
          userId: userId!,
        ),
      ),
    );
  }
}

Widget _buildBlurredBottomSheet(BuildContext context, bool isDarkMode) {
  final screenHeight = MediaQuery.of(context).size.height;
  final NewChatController newChatController = Get.put(NewChatController());
  final TextEditingController searchControllerText = TextEditingController();
  final RxString searchQuery = ''.obs;

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Center(
                child: Text(
                  "Start New Chat",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SearchBox(
                searchControllerText: searchControllerText,
                onChanged: (value) {
                  searchQuery.value = value.trim();
                  newChatController.searchUsers(searchQuery.value);
                },
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                return searchQuery.value.isEmpty
                    ? Center(
                  child: Text(
                    "Start typing to search users...",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                )
                    : UserList(newChatController: newChatController);
              }),
            ),
          ],
        ),
      ),
    ),
  );
}


