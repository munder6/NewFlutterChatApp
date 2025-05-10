import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controller/auth_controller.dart';
import '../app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.asset("assets/lottie/loginanimation.json", height: 180, repeat: false),
              SizedBox(height: 20),
              Text(
                "Getting Started",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Let's login for explore continues",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextColor(isDarkMode).withOpacity(0.6),
                ),
              ),
              SizedBox(height: 30),
              _buildTextField(emailController, "Email or Phone Number", EvaIcons.emailOutline, isDarkMode),
              SizedBox(height: 15),
              _buildPasswordField(isDarkMode),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Forgot password?", style: TextStyle(color: AppTheme.primaryColor(isDarkMode))),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(isDarkMode),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  authController.signInWithEmailOrUsername(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                },
                child: Text("Sign in", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor(isDarkMode),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  authController.signInWithGoogle();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/icons/google_icon.png", height: 24),
                    SizedBox(width: 8),
                    Text("Sign in with Google", style: TextStyle(color: AppTheme.getTextColor(isDarkMode), fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor(isDarkMode),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // authController.signInWithPhoneNumber();
                  Get.toNamed('/phone');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(EvaIcons.phone, color: AppTheme.getTextColor(isDarkMode), size: 24),
                    SizedBox(width: 8),
                    Text("Sign in with Phone Number", style: TextStyle(color: AppTheme.getTextColor(isDarkMode), fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Get.toNamed('/signup');
                },
                child: Text("Don’t have an account? Sign up", style: TextStyle(color: AppTheme.primaryColor(isDarkMode))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, bool isDarkMode) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: Icon(EvaIcons.lockOutline),
        hintText: "Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? EvaIcons.eyeOff2Outline : EvaIcons.eye),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }
}