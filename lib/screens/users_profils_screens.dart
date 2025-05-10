import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controller/chat_controller.dart';
import '../models/message_model.dart';

class UserProfileScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverUsername;
  final String receiverImage;
  final String bio;
  final String birthdate;

  final String userId = GetStorage().read('user_id') ?? '';

  UserProfileScreen({
    required this.receiverId,
    required this.receiverName,
    required this.receiverUsername,
    required this.receiverImage,
    super.key,
    required this.bio,
    required this.birthdate,
  });

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isImageExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "User Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? '';
          final bio = userData['bio'] ?? '';
          final birthdate = userData['birthDate'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isImageExpanded = !_isImageExpanded),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: _isImageExpanded ? MediaQuery.of(context).size.width : 130,
                              height: _isImageExpanded ? MediaQuery.of(context).size.width : 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: _isImageExpanded ? BorderRadius.circular(2) : BorderRadius.circular(100),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(widget.receiverImage),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildProfileActionButton(EvaIcons.phoneCallOutline, "Call"),
                              _buildProfileActionButton(EvaIcons.bellOutline, "Mute"),
                              _buildProfileActionButton(EvaIcons.searchOutline, "Search"),
                              _buildProfileActionButton(EvaIcons.moreHorizontalOutline, "More"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.all(16),
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: "@$username"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Username copied!")),
                            );
                          },
                          child: _buildUserInfoRow("username", "@$username", showQR: true),
                        ),                        Divider(thickness: 0.5),
                        _buildUserInfoRow("bio", bio, showQR: false),
                        Divider(thickness: 0.5),
                        if (birthdate.trim().isNotEmpty && birthdate.trim().toLowerCase() != "not set")
                          ...[
                            _buildUserInfoRow("Birthdate", birthdate, showQR: false),
                            Divider(thickness: 0.5),
                          ],
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: GestureDetector(
                            onTap: () => print("Block User tapped"),
                            child: Row(
                              children: [
                                Text("Block User", style: TextStyle(fontSize: 18, color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildMediaTabs(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileActionButton(IconData icon, String label) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 28.2),
        child: Column(
          children: [
            Icon(icon),
            SizedBox(height: 5),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String title, String value, {bool showQR = false}) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700])),
          ],
        ),
        Spacer(),
        if (showQR)
          SvgPicture.asset("assets/icons/qrcode.svg", color: Colors.blue[700], width: 28),
      ],
    );
  }

  Widget _buildMediaTabs(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: "Images"),
              Tab(text: "Videos"),
              Tab(text: "Audio"),
            ],
            indicatorColor: Colors.blue[700],
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            child: TabBarView(
              children: [
                _buildMediaSection("Images", widget.receiverId, "image"),
                _buildMediaSection("Videos", widget.receiverId, "video"),
                _buildMediaSection("Audio", widget.receiverId, "audio"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(String title, String receiverId, String contentType) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<List<MessageModel>>(
        stream: ChatController().getMessages(receiverId, widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No $title found."));
          }

          var messages = snapshot.data!.where((msg) => msg.contentType == contentType).toList();

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
            ),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var msg = messages[index];
              return Padding(
                padding: const EdgeInsets.all(1.0),
                child: contentType == "image"
                    ? GestureDetector(
                  onTap: () {
                    // عندما يتم الضغط على الصورة، يتم فتحها في نافذة منبثقة
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Dialog(
                            backgroundColor: Colors.transparent, // لجعل الخلفية شفافة
                            child: Stack(
                              children: [
                                // تأثير التمويه على الخلفية
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // تأثير التمويه
                                    child: Container(),
                                  ),
                                ),
                                // عرض الصورة المكبرة مع دعم التمرير
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: (){
                                              Navigator.pop(context);
                                            },
                                            child: Icon(EvaIcons.close, size: 28),
                                          ),
                                          Text("Save Photo", style: TextStyle(fontSize: 18)),
                                        ],
                                      ),
                                      SizedBox(height: 25),
                                      Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: CachedNetworkImage(
                                            imageUrl: msg.content,
                                            fit: BoxFit.cover,
                                            width: MediaQuery.of(context).size.width,
                                            height: MediaQuery.of(context).size.height / 1.5, // ارتفاع نافذة البوب أب
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade900,
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  hintText: "Type Your Reply", // النص المساعد داخل الحقل
                                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // لون النص المساعد
                                                  border: InputBorder.none, // إزالة الحدود
                                                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20), // المسافات داخل TextField
                                                ),
                                                style: TextStyle(color: Colors.white), // لون النص داخل الـ TextField
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                // ضع هنا الكود الذي سيتم تنفيذه عند الضغط على زر "Send"
                                                print("Send tapped");
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                                child: Text(
                                                  "Send", // نص زر "Send"
                                                  style: TextStyle(
                                                    color: Colors.blue, // لون النص في زر "Send"
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: CachedNetworkImage(imageUrl: msg.content, fit: BoxFit.cover),
                )
                    : contentType == "video"
                    ? CachedNetworkImage(imageUrl: msg.content, fit: BoxFit.cover)
                    : Icon(Icons.audiotrack, size: 50, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}

