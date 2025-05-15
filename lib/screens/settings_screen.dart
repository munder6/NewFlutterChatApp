import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';
import '../controller/auth_controller.dart';
import '../controller/edit_profile_controller.dart';
import '../controller/user_controller.dart';
import '../app_theme.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final box = GetStorage();
  final AuthController authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final EditProfileController editProfileController = Get.put(EditProfileController());


  late bool isDarkMode;
  late Color bgColor;
  late Color cardColor;

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bgColor = AppTheme.backgroundColor(isDarkMode);
    cardColor = isDarkMode ? const Color(0xFF131313) : const Color(0xFFF2F2F7);

    final fullName = box.read('fullName') ?? 'John Doe';
    final email = box.read('email') ?? 'example@gmail.com';
    final username = box.read('username') ?? '@username';
    final profilePhoto = box.read('profileImageUrl') ?? 'https://i.pravatar.cc/150';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 115)),
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isExpanded ? MediaQuery.of(context).size.width : 110,
                        height: isExpanded ? MediaQuery.of(context).size.width : 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isExpanded ? 0 : 100),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(profilePhoto),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(fullName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(isDarkMode),
                          )),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(email, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 5),
                          const Text("•", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 5),
                          Text("@$username", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildCard([
                _settingTile(Icons.camera_alt_rounded, "Change Profile Photo", onTap: () {
                  editProfileController.updateProfileImage(); // ✅ فتح الاستوديو وتحديث الصورة

                }),
              ])),
              SliverToBoxAdapter(child: _buildAccountsSection()),
              _sectionTitle("General"),
              SliverToBoxAdapter(child: _buildCard([
                _settingTile(CupertinoIcons.person_crop_circle, "My Profile", onTap: () {}),
                _settingTile(CupertinoIcons.bookmark, "Saved Messages", onTap: () {}),
                _settingTile(CupertinoIcons.phone, "Recent Calls", onTap: () {}),
                _settingTile(CupertinoIcons.device_phone_portrait, "Devices", onTap: () {}),
              ])),
              _sectionTitle("Security"),
              SliverToBoxAdapter(child: _buildCard([
                _settingTile(CupertinoIcons.bell, "Notifications and Sounds", onTap: () {}),
                _settingTile(CupertinoIcons.lock, "Privacy and Security", onTap: () {}),
                _settingTile(CupertinoIcons.archivebox, "Data and Storage", onTap: () {}),
              ])),
              _sectionTitle("Manage"),
              SliverToBoxAdapter(child: _buildCard([
                _settingTile(CupertinoIcons.square_arrow_right, "Log Out", isDestructive: true, onTap: () async {
                  await authController.signOut();
                  Get.offAllNamed('/onboarding');
                }),
              ])),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              const SliverToBoxAdapter(child: SizedBox(height: 115)),

            ],
          ),
          _blurAppBar(),
        ],
      ),
    );
  }

  Widget _blurAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 90,
          padding: const EdgeInsets.only(top: 35, left: 20, right: 20),
          color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SvgPicture.asset("assets/icons/qrcode.svg", width: 22, color: Colors.blue),
              Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.getTextColor(isDarkMode))),
              GestureDetector(
                onTap: () => Get.to(() => EditProfileScreen()),
                child: Text("Edit", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(
          tiles.length,
              (index) => Column(
            children: [
              tiles[index],
              if (index < tiles.length - 1)
                Divider(height: 1, thickness: 0.3, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300, indent: 71),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, {VoidCallback? onTap, bool isDestructive = false}) {
    return SizedBox(
      height: 48,
      child: ListTile(
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _iconBg(icon),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : AppTheme.getTextColor(isDarkMode),
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildAccountsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.add, color: Colors.blue),
        title: Text("Add Account", style: TextStyle(fontSize: 14, color: Colors.blue)),
        onTap: () {},
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  SliverToBoxAdapter _sectionTitle(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
      ),
    );
  }

  Color _iconBg(IconData icon) {
    switch (icon) {
      case CupertinoIcons.bookmark:
        return Colors.blueAccent;
      case CupertinoIcons.phone:
        return Colors.green;
      case CupertinoIcons.device_phone_portrait:
        return Colors.orange;
      case CupertinoIcons.folder:
        return Colors.lightBlue;
      case CupertinoIcons.bell:
        return Colors.redAccent;
      case CupertinoIcons.lock:
        return Colors.grey;
      case CupertinoIcons.archivebox:
        return Colors.green.shade700;
      case CupertinoIcons.square_arrow_right:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
