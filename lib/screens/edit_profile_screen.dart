import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            GestureDetector(
              onTap: () => controller.updateProfileImage(),
              child: Obx(() => Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    child: controller.isUploadingImage.value
                        ? CircularProgressIndicator()
                        : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: controller.profileImageUrl.value.isEmpty
                            ? "https://i.pravatar.cc/150"
                            : controller.profileImageUrl.value,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 20,
                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              )),
            ),
            SizedBox(height: 20),
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
            ElevatedButton(
              onPressed: () {
                controller.updateFullName(controller.fullName.value);
              },
              child: Text("Update Full Name"),
            ),
            SizedBox(height: 20),
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
