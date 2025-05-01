import 'package:flutter/material.dart';

class AppTheme {
    static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.blue,

    hintColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.black, fontFamily: 'SFProDisplay'), // Text color for Light Mode
    ),
    buttonTheme: ButtonThemeData(buttonColor: Colors.blue),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'SFProDisplay'),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.black,
    hintColor: Colors.blueAccent,
    scaffoldBackgroundColor: Colors.black,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'SFProDisplay'), // Text color for Dark Mode
    ),
    buttonTheme: ButtonThemeData(buttonColor: Colors.black),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
  );

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }

  static Color primaryColor(bool isDarkMode) {
    return isDarkMode ? Colors.blueAccent : Colors.blue;
  }

  static Color backgroundColor(bool isDarkMode) {
    return isDarkMode ? Colors.black : Colors.white;
  }
}
