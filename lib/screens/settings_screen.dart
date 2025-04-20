import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controller/auth_controller.dart';
import '../controller/user_controller.dart';
import '../widgets/search_box.dart';
import 'edit_profile_screen.dart';
import '../app_theme.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final box = GetStorage();
  final AuthController authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  late bool isDarkMode;
  late Color bgColor;
  late Color cardColor;

  final List<Map<String, dynamic>> settingsItems = [
    {
      "section": "General",
      "items": [
        {"title": "Avatar", "icon": Icons.person_outline, "onTap": () {}},
        {"title": "Lists", "icon": Icons.list_alt, "onTap": () {}},
        {"title": "Broadcast messages", "icon": Icons.campaign_outlined, "onTap": () {}},
        {"title": "Starred messages", "icon": Icons.star_border, "onTap": () {}},
        {"title": "Linked devices", "icon": Icons.devices_other_outlined, "onTap": () {}},
      ]
    },
    {
      "section": "Security",
      "items": [
        {"title": "Account", "icon": Icons.verified_user_outlined, "onTap": () {}},
        {"title": "Privacy", "icon": Icons.lock_outline, "onTap": () {}},
        {"title": "Chats", "icon": Icons.chat_bubble_outline, "onTap": () {}},
        {"title": "Notifications", "icon": Icons.notifications_none_outlined, "onTap": () {}},
        {"title": "Storage and data", "icon": Icons.storage_rounded, "onTap": () {}},
      ]
    },
    {
      "section": "Actions",
      "items": [
        {
          "title": "Log Out",
          "icon": Icons.exit_to_app,
          "onTap": () async {
            await Get.find<AuthController>().signOut();
            Get.offAllNamed('/onboarding');
          }
        },
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bgColor = isDarkMode ? Color(0xFF121212) : Colors.grey[200]!;
    cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;

    String fullName = box.read('fullName') ?? 'John Doe';
    String email = box.read('email') ?? 'example@gmail.com';
    String profilePhoto = box.read('profileImageUrl') ?? 'https://i.pravatar.cc/150';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text("Settings", style: TextStyle(color: AppTheme.getTextColor(isDarkMode), fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: SearchBox(
              searchControllerText: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),

          // 🧑‍💼 User Profile
          if (searchQuery.isEmpty)
            InkWell(
              onTap: () => Get.to(() => EditProfileScreen()),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: CachedNetworkImageProvider(box.read("profileImageUrl") ?? ''),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.getTextColor(isDarkMode))),
                          SizedBox(height: 4),
                          Text(email, style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Icon(Icons.qr_code, color: Colors.grey),
                  ],
                ),
              ),
            ),

          SizedBox(height: 10),

          // 🧠 Filtered Settings
          ..._buildFilteredSections(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredSections() {
    List<Widget> sections = [];

    for (var section in settingsItems) {
      List<Widget> filteredItems = [];

      for (var item in section['items']) {
        if (searchQuery.isEmpty || item['title'].toLowerCase().contains(searchQuery.toLowerCase())) {
          filteredItems.add(_iconItem(item['icon'], item['title'], item['onTap']));
        }
      }

      if (filteredItems.isNotEmpty) {
        sections.add(_sectionCard(filteredItems));
        sections.add(SizedBox(height: 10));
      }
    }

    if (sections.isEmpty && searchQuery.isNotEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text("No results found", style: TextStyle(color: Colors.grey)),
          ),
        )
      ];
    }

    return sections;
  }

  Widget _iconItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: TextStyle(color: Colors.grey[300])),
      onTap: onTap,
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}
