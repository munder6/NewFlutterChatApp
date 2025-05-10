import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../controller/edit_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final EditProfileController controller = Get.put(EditProfileController());
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  late bool isDarkMode;
  final box = GetStorage();
  DateTime? selectedBirthDate;

  @override
  void initState() {
    super.initState();
    nameController.text = box.read('fullName') ?? '';
    bioController.text = box.read('bio') ?? '';
    final storedDate = box.read('birthDate');
    if (storedDate != null) {
      selectedBirthDate = DateTime.tryParse(storedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.backgroundColor(isDarkMode);
    final textColor = AppTheme.getTextColor(isDarkMode);
    final dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final cardColor = isDarkMode ? const Color(0xFF131313) : const Color(0xFFF2F2F7);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
    ));

    final profileImageUrl = box.read('profileImageUrl') ?? 'https://i.pravatar.cc/150';
    final username = box.read('username') ?? '';
    final email = box.read('email') ?? 'example@email.com';
    final phoneNumber = box.read('phone') ?? '+972 59 998 7676';
    final formattedBirthDate = selectedBirthDate != null ? DateFormat.yMMMd().format(selectedBirthDate!) : "Not set";

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: controller.updateProfileImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 75,
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: Obx(() => CachedNetworkImage(
                              imageUrl: controller.profileImageUrl.value,
                              fit: BoxFit.cover,
                              width: 150,
                              height: 150,
                              placeholder: (context, url) => CircularProgressIndicator(color: Colors.white),
                              errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
                            )),
                          ),
                        ),
                        if (controller.isUploadingImage.value)
                          CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Set New Photo", style: TextStyle(color: Colors.blue)),
                  const SizedBox(height: 20),
                ],
              ),
              _buildTextField("Name", controller: nameController),
              const SizedBox(height: 12),
              _buildTextField("Bio", controller: bioController),
              const SizedBox(height: 12),
              _buildDatePicker(context),
              const SizedBox(height: 12),
              _buildSection(cardColor, [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildLabelTile("Change Number", phoneNumber),
                      Divider(height: 1, thickness: 0.4, color: dividerColor),
                      _buildLabelTile("Username", "@$username", onTap: () => _editUsernameModal(context)),
                      Divider(height: 1, thickness: 0.4, color: dividerColor),
                      _buildLabelTile("Email", email),
                    ],
                  ),
                )
              ]),
              const SizedBox(height: 30),
              // Center(
              //   child: TextButton(
              //     onPressed: () {
              //       Get.snackbar("Logout", "You have been logged out.");
              //     },
              //     child: Text("Log Out", style: TextStyle(color: Colors.red)),
              //   ),
              // )
            ],
          ),
          _buildBlurAppBar(textColor),
        ],
      ),
    );
  }

  Widget _buildBlurAppBar(Color textColor) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80,
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
          color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text("Cancel", style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              TextButton(
                onPressed: () async {
                  await controller.updateFullName(nameController.text.trim());
                  await controller.updateBio(bioController.text.trim());
                  if (selectedBirthDate != null) {
                    final formatted = DateFormat("d MMM yyyy").format(selectedBirthDate!);
                    await controller.updateBirthDate(formatted);
                  }

                  // 🔁 تحديث البيانات المعروضة بعد الحفظ
                  setState(() {
                    nameController.text = box.read('fullName') ?? '';
                    bioController.text = box.read('bio') ?? '';
                    final storedDate = box.read('birthDate');
                    if (storedDate != null && storedDate is String) {
                      try {
                        selectedBirthDate = DateFormat("d MMM yyyy").parse(storedDate);
                      } catch (e) {
                        selectedBirthDate = null;
                      }
                    }                    controller.profileImageUrl.value = box.read('profileImageUrl') ?? '';
                    controller.username.value = box.read('username') ?? '';
                  });
                  Navigator.pop(context);
                  },
                child: Text("Done", style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppTheme.getTextColor(isDarkMode)),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Enter your $label",
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Date of Birth"),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedBirthDate ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => selectedBirthDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedBirthDate != null ? DateFormat.yMMMd().format(selectedBirthDate!) : "Not set",
              style: TextStyle(fontSize: 16, color: AppTheme.getTextColor(isDarkMode)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildLabelTile(String label, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: TextStyle(fontSize: 16, color: AppTheme.getTextColor(isDarkMode))),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildSection(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  void _editUsernameModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String current = controller.username.value;
    TextEditingController usernameController = TextEditingController(text: current);
    RxBool isAvailable = true.obs;
    RxBool checking = false.obs;

    // ✅ التحقق من توفر اليوزرنيم
    Future<void> checkUsername(String username) async {
      if (username.trim().length < 5 || !RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
        isAvailable.value = false;
        return;
      }
      checking.value = true;
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      checking.value = false;
      isAvailable.value =
          snapshot.docs.isEmpty || snapshot.docs.first.id == GetStorage().read('user_id');
    }

    // ✅ عرض المودال
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final textColor = AppTheme.getTextColor(isDarkMode);
            final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black87;
            final greyText = TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[800], fontSize: 13);

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.4),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Obx(() {
                      final username = usernameController.text.trim();
                      final valid = username.length >= 5 &&
                          RegExp(r'^[a-z0-9_]+$').hasMatch(username);

                      return ListView(
                        controller: scrollController,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text("Cancel", style: TextStyle(color: Colors.blue)),
                              ),
                              Text("Username",
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              TextButton(
                                onPressed: isAvailable.value && valid
                                    ? () {
                                  controller.updateUsername(username);
                                  Get.back();
                                }
                                    : null,
                                child: Text("Done",
                                    style: TextStyle(
                                        color: isAvailable.value && valid
                                            ? Colors.blue
                                            : Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("USERNAME",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black)),
                          const SizedBox(height: 5),

                          // ✅ TextField بتصميم شفاف جميل
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800.withOpacity(0.5)
                                  : Colors.blue[700]?.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: usernameController,
                              onChanged: (val) => checkUsername(val.trim()),
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.alternate_email,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.black.withOpacity(0.5)),
                                suffixIcon: checking.value
                                    ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CupertinoActivityIndicator(radius: 8)),
                                )
                                    : Icon(
                                  isAvailable.value
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: isAvailable.value
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                hintText: "Enter username",
                                hintStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "You can use a–z, 0–9 and underscores. Minimum length is 5 characters.",
                            style: greyText,
                          ),
                          const SizedBox(height: 12),

                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
