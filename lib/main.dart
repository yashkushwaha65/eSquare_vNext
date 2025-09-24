import 'dart:io';

import 'package:esquare/core/theme/app_theme.dart';
import 'package:esquare/providers/authPdr.dart';
import 'package:esquare/providers/post_gate_in_summaryPdr.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/providers/pre_gate_in_summarayPdr.dart';
import 'package:esquare/screens/login_screens.dart';
import 'package:esquare/screens/post_survey/post_gate_in_summary_screen.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_screen.dart';
import 'package:esquare/screens/pre_survey/pre_gate_in_summary/pre_gate_in_summary_screen.dart';
import 'package:esquare/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => PreGateInSummaryProvider()),
        ChangeNotifierProvider(create: (_) => PostRepairSummaryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PreGateInProvider>(
          // `create` builds the initial instance of PreGateInProvider.
          create: (context) => PreGateInProvider(),

          // `update` is the magic part. It re-runs whenever AuthProvider changes.
          // `auth` is the AuthProvider instance.
          // `previousProvider` is the existing PreGateInProvider instance.
          // This line passes the user from `auth` into your provider's `updateUser` method.
          update: (context, auth, previousProvider) =>
              previousProvider!..updateUser(auth.user),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'eSquare vNext',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/pre-gate-in': (_) => const PreGateInScreen(),
          '/post-gate-in': (_) => const PreGateInScreen(),
          '/pre-gate-summary': (_) => const PreGateInSummaryPage(),
          '/post-gate-summary': (_) => const PostRepairSummaryPage(),
        },
      ),
    );
  }
}
