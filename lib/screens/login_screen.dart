import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controller/auth_controller.dart';
import '../app_theme.dart'; // تأكد من أنك تستخدم AppTheme هنا للوصول للألوان

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
      backgroundColor: AppTheme.backgroundColor(isDarkMode), // استخدام اللون الخلفي المتغير
      body: Stack(
        children: [
          Container(
            height: 900,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor(isDarkMode),
                  AppTheme.primaryColor(isDarkMode).withOpacity(0.7),
                ],
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
              height: 900,
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor(isDarkMode), // الخلفية البيضاء أو السوداء
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
                children: [
                  Lottie.asset("assets/lottie/loginanimation.json", height: 180, repeat: false),

                  SizedBox(height: 20),
                  Text(
                    "Getting Started",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(isDarkMode), // نص العنوان
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Let's login for explore continues",
                    style: TextStyle(fontSize: 16, color: AppTheme.getTextColor(isDarkMode).withOpacity(0.6)),
                  ),
                  SizedBox(height: 30),
                  _buildTextField(emailController, "Email or Phone Number", Icons.email_outlined, isDarkMode),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size(double.infinity, 50),
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
                      minimumSize: Size(double.infinity, 50),
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
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Get.toNamed('/signup');
                          },
                          child: Text("Don’t have an account? Sign up", style: TextStyle(color: AppTheme.primaryColor(isDarkMode))),
                        ),
                      ],
                    ),
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
        prefixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100], // لون الخلفية في TextField حسب الوضع
      ),
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline),
        hintText: "Password",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100], // لون الخلفية في TextField حسب الوضع
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }
}
