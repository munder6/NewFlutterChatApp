import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/edit_profile_controller.dart';
import '../app_theme.dart';

class EditFullNameScreen extends StatelessWidget {
  final EditProfileController controller = Get.find<EditProfileController>();
  final TextEditingController fullNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    fullNameController.text = controller.fullName.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppTheme.getTextColor(isDarkMode)),
        title: Text(
          "Edit Full Name",
          style: TextStyle(color: AppTheme.getTextColor(isDarkMode)),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.blue[700]?.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: fullNameController,
                style: TextStyle(color: AppTheme.getTextColor(isDarkMode)),
                decoration: InputDecoration(
                  hintText: "Enter Full Name",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                controller.updateFullName(fullNameController.text);
                Get.back();
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
