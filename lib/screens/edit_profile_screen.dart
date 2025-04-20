import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileScreen extends StatelessWidget {
  final EditProfileController controller = Get.put(EditProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // صورة المستخدم مع إمكانية تغييرها
            GestureDetector(
              onTap: () => controller.updateProfileImage(), // عند الضغط على الصورة لتغييرها
              child: Obx(() => Stack(
                children: [
                  CircleAvatar(
                    radius: 70, // تكبير الأفاتار
                    backgroundImage: NetworkImage(
                      controller.profileImageUrl.value.isEmpty
                          ? "https://i.pravatar.cc/150"
                          : controller.profileImageUrl.value,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 20,
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              )),
            ),
            SizedBox(height: 20),

            // تغيير الاسم الكامل
            TextField(
              controller: TextEditingController(text: controller.fullName.value),
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.fullName.value = value;
              },
            ),
            SizedBox(height: 20),

            // زر تحديث الاسم الكامل
            ElevatedButton(
              onPressed: () {
                controller.updateFullName(controller.fullName.value);
              },
              child: Text("Update Full Name"),
            ),
            SizedBox(height: 20),

            // تغيير اسم المستخدم
            TextField(
              controller: TextEditingController(text: controller.username.value),
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.username.value = value;
              },
            ),
            SizedBox(height: 20),

            // زر تحديث اسم المستخدم
            ElevatedButton(
              onPressed: () {
                controller.updateUsername(controller.username.value);
              },
              child: Text("Update Username"),
            ),
          ],
        ),
      ),
    );
  }
}
