import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart'; // Import your notification service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated cross-platform keys
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service for lifecycle alerts (Submitted, Verified, Assigned, Resolved)
  await NotificationService.init();

  runApp(const RoadWatchApp());
}

class RoadWatchApp extends StatelessWidget {
  const RoadWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadWatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    ); // MaterialApp
  }
}