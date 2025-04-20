import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controller/signup_controller.dart';
import '../app_theme.dart'; // تأكد من استيراد AppTheme

class SignupScreen extends StatelessWidget {
  final SignupController controller = Get.put(SignupController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على الوضع الحالي
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(isDarkMode), // استخدم اللون من AppTheme
      body: Stack(
        children: [
          Container(
            height: 1000,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              height: 850,
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor(isDarkMode), // استخدام الثيم المناسب
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/lottie/loginanimation.json", height: 100, repeat: false),
                  Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(isDarkMode), // استخدم النص المناسب
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildTextField(displayNameController, "Full Name", Icons.person, isDarkMode),
                  SizedBox(height: 15),
                  _buildTextField(usernameController, "Username", Icons.person, isDarkMode),
                  SizedBox(height: 15),
                  _buildTextField(emailController, "Email", Icons.email, isDarkMode),
                  SizedBox(height: 15),
                  _buildPasswordField(passwordController, "Password", isDarkMode),
                  SizedBox(height: 15),
                  _buildPasswordField(confirmPasswordController, "Confirm Password", isDarkMode),
                  SizedBox(height: 20),
                  Obx(() => controller.isLoading.value
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () {
                      controller.signUpWithEmail(
                        emailController.text.trim(),
                        displayNameController.text.trim(),
                        usernameController.text.trim(),
                        passwordController.text.trim(),
                        confirmPasswordController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(isDarkMode),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      controller.signUpWithGoogle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/icons/google_icon.png", height: 24),
                        SizedBox(width: 8),
                        Text("Sign up with Google", style: TextStyle(color: Colors.black, fontSize: 16)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Get.toNamed('/login');
                    },
                    child: Text("Already have an account? Sign in", style: TextStyle(color: AppTheme.primaryColor(isDarkMode))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, bool isDarkMode) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.getTextColor(isDarkMode)), // اللون يعتمد على الوضع
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100], // تغيير اللون بناءً على الوضع
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hintText, bool isDarkMode) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.getTextColor(isDarkMode)),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100],
      ),
    );
  }
}
