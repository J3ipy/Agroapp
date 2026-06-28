import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme.dart';
import 'models/user_profile.dart';
import 'services/auth_service.dart';
import 'services/hort_firestore.dart';
import 'screens/auth/login_screen.dart';
import 'screens/seller/seller_main.dart';
import 'screens/consumer/consumer_main.dart';

class HortApp extends StatelessWidget {
  const HortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: kPrimaryColor, colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor), useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snap.data == null) return const LoginScreen();

          return FutureBuilder<AppUserProfile>(
            future: HortFirestoreService.instance.getPerfilOnce(),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
              final role = profileSnap.data?.role ?? 'vendedor';
              return role == 'consumidor' ? const ConsumerMainContainer() : const SellerMainContainer();
            },
          );
        },
      ),
    );
  }
}