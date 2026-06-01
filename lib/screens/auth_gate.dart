import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_light_theme.dart';
import 'admin_dashboard_page.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';
import 'main_page.dart';
import 'profile_completion_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String uid) {
    return FirebaseFirestore.instance
        .collection('User')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _getUserDoc(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "Couldn't load your profile state: ${profileSnapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final userDoc = profileSnapshot.data;
            final userData = userDoc?.data();
            final userDocExists = userDoc?.exists == true;
            final role = userData?['role']?.toString().toLowerCase();
            final isAdmin = role == 'admin';
            final userStatus =
                userData?['user_status']?.toString().toLowerCase() ?? '';
            final profileCompleted = userData?['profile_completed'] == true;

            if (userStatus == 'suspended') {
              return const _SuspendedAccountScreen();
            }

            if (!isAdmin &&
                (!user.emailVerified ||
                    !userDocExists ||
                    userStatus == 'not verified')) {
              return EmailVerificationScreen(
                email: user.email ?? '',
              );
            }

            if (isAdmin) {
              return Theme(
                data: buildAdminLightTheme(context),
                child: const AdminDashboardPage(),
              );
            }

            if (userDocExists && profileCompleted) {
              return MainPage(userId: user.uid);
            }

            return ProfileCompletionScreen(
              email: user.email ?? '',
            );
          },
        );
      },
    );
  }
}

class _SuspendedAccountScreen extends StatefulWidget {
  const _SuspendedAccountScreen();

  @override
  State<_SuspendedAccountScreen> createState() => _SuspendedAccountScreenState();
}

class _SuspendedAccountScreenState extends State<_SuspendedAccountScreen> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dialogShown) {
      return;
    }
    _dialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Account Suspended'),
            content: const Text(
              'Your account has been suspended. Please meet the admin to clarify and reactivate your account.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      await FirebaseAuth.instance.signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
