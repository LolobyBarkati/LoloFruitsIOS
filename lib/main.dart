import 'package:barkati_frits/resources/auth_methods.dart';
import 'package:barkati_frits/screens/fruit_screen.dart';
import 'package:barkati_frits/screens/offer2edit.dart';
import 'package:barkati_frits/screens/phoneotp_screen.dart';
import 'package:barkati_frits/screens/profile.dart';
import 'package:barkati_frits/widgets/loading_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:barkati_frits/providers/user_provider.dart';
import 'package:barkati_frits/screens/home_screen.dart';
import 'package:barkati_frits/screens/login_screen.dart';
import 'package:barkati_frits/screens/signup_screen.dart';
import 'package:barkati_frits/onboarding_screen.dart';
import 'package:barkati_frits/utils/colors.dart';
import 'package:barkati_frits/screens/agents_screen.dart';
import 'package:barkati_frits/screens/storage_screen.dart';
import 'package:barkati_frits/screens/transport_screen.dart';
import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:barkati_frits/screens/fingerprintauth_screen.dart';
import 'package:barkati_frits/screens/faq_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'models/user.dart' as model;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize default Firebase app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, 
    // Use debug for dev
  );
  print("✅ Firebase App Check activated with debug mode.");

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("9f8342c0-ae62-4dc2-b578-a8049ae2101d");
  OneSignal.Notifications.requestPermission(true);

  await Supabase.initialize(
    url:
        'https://ufzfcpcdxdlisrhxetoq.supabase.co', // Replace with your Supabase project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmemZjcGNkeGRsaXNyaHhldG9xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NDY5NTEsImV4cCI6MjA2NTMyMjk1MX0.nr5IhO_NQzs6DhoX08Opk3H-ya_H9G_7HYYb1sZNZQs', // Replace with your Supabase anon key
  );


  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message: ${message.notification?.title}');
  });

  runApp(const RootApp());
}

// Helper to get correct secondary options for current platform

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barkati Fruits',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: secondarybcakgroundColor,
        appBarTheme: AppBarTheme.of(context).copyWith(
          backgroundColor: backgroundColor,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
          iconTheme: const IconThemeData(color: primaryColor),
        ),
      ),
      routes: {
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        FruitsScreen.routeName: (context) => const FruitsScreen(),
        TransportScreen.routeName: (context) => const TransportScreen(),
        AgentsScreen.routeName: (context) => const AgentsScreen(),
        StorageScreen.routeName: (context) => const StorageScreen(),
        Offer2edit.routeName: (context) => const Offer2edit(),
        SubscriptionScreen.routeName: (context) => const SubscriptionScreen(),
        FingerprintAuthScreen.routeName: (context) => FingerprintAuthScreen(),
        PhoneVerificationPage.routeName: (context) => PhoneVerificationPage(),
        FAQScreen.routeName: (context) => FAQScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
      },
      home: FutureBuilder(
        future: AuthMethods()
            .getCurrentUser(FirebaseAuth.instance.currentUser?.uid)
            .then((value) {
          if (value != null) {
            Provider.of<UserProvider>(context, listen: false).setUser(
              model.User.fromMap(value),
            );
          }
          return value;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasData) {
            // User is logged in → require fingerprint auth
            return FingerprintAuthScreen();
          }

          // Not logged in → show onboarding
          return const OnboardingScreen();
        },
      ),
    );
  }
}
