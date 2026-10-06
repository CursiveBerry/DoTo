import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_app/services/auth_wrapper.dart';
import 'package:todo_app/widgets/app_colors.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.urbanist(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: kTextDark,
          ),
          bodyMedium: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: kTextDark,
          ),
          bodySmall: GoogleFonts.urbanist(fontSize: 24, color: kTextDark),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Color(0xFF1F2937),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
