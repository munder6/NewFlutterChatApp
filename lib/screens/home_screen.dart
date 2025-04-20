import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import '../app_theme.dart';
import '../controller/homescreeen_controller.dart';
import '../widgets/conversation_list.dart';
import '../widgets/search_box.dart';
import 'new_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController homeController = Get.put(HomeController());
  final TextEditingController searchControllerText = TextEditingController();

  String searchQuery = "";
  String? userId;
  bool isLoading = true;

  static bool _alreadyLoaded = false; // ✅ متغير يتحكم إذا الصفحة اشتغلت أول مرة

  @override
  void initState() {
    super.initState();

    if (_alreadyLoaded) {
      // ✅ لو الصفحة اشتغلت مرة قبل هيك، ما بنعيد تحميل
      userId = GetStorage().read('user_id');
      isLoading = false;
    } else {
      _loadUserId(); // أول مرة بس
    }
  }

  Future<void> _loadUserId() async {
    await Future.delayed(Duration(milliseconds: 500)); // يعطي شعور التحميل
    userId = GetStorage().read('user_id');
    _alreadyLoaded = true;
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
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      body: Column(
        children: [
          // 🔹 AppBar مخصص
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white12,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Get.to(() => NewChatScreen());
                        },
                      ),
                      Text(
                        "Chats",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: Colors.blueAccent),
                        onPressed: () {
                          Get.toNamed('/settings');
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                  child: SearchBox(
                    searchControllerText: searchControllerText,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Conversation List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor(isDarkMode),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ConversationList(
                homeController: homeController,
                userId: userId!,

                searchQuery: searchQuery,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
