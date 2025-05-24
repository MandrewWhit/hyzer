import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF40454B);
    final Color primaryLightColor = const Color(0xFF40454B).withOpacity(0.3);
    final Color backgroundColor = const Color(0xFF7BD6B6);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Hyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: backgroundColor,
          primarySwatch: MaterialColor(0xFF40454B, {
            50: primaryColor.withOpacity(0.1),
            100: primaryColor.withOpacity(0.2),
            200: primaryColor.withOpacity(0.3),
            300: primaryColor.withOpacity(0.4),
            400: primaryColor.withOpacity(0.5),
            500: primaryColor.withOpacity(0.6),
            600: primaryColor.withOpacity(0.7),
            700: primaryColor.withOpacity(0.8),
            800: primaryColor.withOpacity(0.9),
            900: primaryColor,
          }),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryLightColor, width: 2.0),
            ),
            labelStyle: TextStyle(color: primaryColor),
            focusColor: primaryColor,
            fillColor: backgroundColor,
            filled: true,
          ),
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
