import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controller/signup_controller.dart';
import '../app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final SignupController controller = Get.put(SignupController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Join us and explore",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.getTextColor(isDarkMode).withOpacity(0.6),
                ),
              ),
              SizedBox(height: 30),
              _buildTextField(displayNameController, "Full Name", EvaIcons.personOutline, isDarkMode),
              SizedBox(height: 15),
              _buildTextField(usernameController, "Username", EvaIcons.person, isDarkMode),
              SizedBox(height: 15),
              _buildTextField(emailController, "Email", EvaIcons.emailOutline, isDarkMode),
              SizedBox(height: 15),
              _buildPasswordField(passwordController, "Password", isDarkMode, true),
              SizedBox(height: 15),
              _buildPasswordField(confirmPasswordController, "Confirm Password", isDarkMode, false),
              SizedBox(height: 20),
              Obx(() => controller.isLoading.value
                  ? Center(child: CircularProgressIndicator())
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16)),
              )),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: controller.signUpWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor(isDarkMode),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/icons/google_icon.png", height: 24),
                    SizedBox(width: 8),
                    Text("Sign up with Google", style: TextStyle(color: AppTheme.getTextColor(isDarkMode), fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.toNamed('/login'),
                child: Text(
                  "Already have an account? Sign in",
                  style: TextStyle(color: AppTheme.primaryColor(isDarkMode)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, bool isDarkMode) {
    return TextField(
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black
      ),
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

  Widget _buildPasswordField(TextEditingController controller, String hintText, bool isDarkMode, bool isMainPassword) {
    return TextField(
      style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black
      ),
      controller: controller,
      obscureText: isMainPassword ? _obscurePassword : _obscureConfirmPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(EvaIcons.lockOutline),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        suffixIcon: IconButton(
          icon: Icon((isMainPassword ? _obscurePassword : _obscureConfirmPassword)
              ? EvaIcons.eyeOff2Outline
              : EvaIcons.eye),
          onPressed: () {
            setState(() {
              if (isMainPassword) {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }
            });
          },
        ),
      ),
    );
  }
}
