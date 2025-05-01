import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/homescreeen_controller.dart';
import '../models/user_model.dart';
import '../app_theme.dart';

class StoryViewersBottomSheet extends StatelessWidget {
  final List<String> viewerIds;
  final HomeController homeController = Get.find();

  StoryViewersBottomSheet({required this.viewerIds});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 400,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Viewers",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: viewerIds.length,
                  itemBuilder: (context, index) {
                    final userId = viewerIds[index];
                    return FutureBuilder<UserModel>(
                      future: homeController.getUserById(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();
                        final user = snapshot.data!;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user.profileImage),
                          ),
                          title: Text(
                            user.fullName,
                            style: TextStyle(
                              color: AppTheme.getTextColor(isDarkMode),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "@${user.username}",
                            style: TextStyle(
                              color: AppTheme.getTextColor(isDarkMode)
                                  .withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
