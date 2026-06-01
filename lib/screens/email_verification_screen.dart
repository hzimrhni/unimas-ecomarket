import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import 'auth_gate.dart';
import 'student_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isChecking = false;
  bool isSending = false;

  Future<void> refreshVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() {
      isChecking = true;
    });

    try {
      await currentUser.getIdToken(true);
      await currentUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (!mounted) {
        return;
      }

      if (refreshedUser != null && refreshedUser.emailVerified) {
        await FirebaseFirestore.instance.collection('User').doc(refreshedUser.uid).set({
          'user_status': 'verified',
          'profile_completed': false,
        }, SetOptions(merge: true));

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(
          content: Text("Your email is still not verified yet."),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      showError(error.message ?? "Couldn't refresh verification status.");
    } catch (error) {
      if (!mounted) {
        return;
      }
      showError("Couldn't refresh verification status: $error");
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        isChecking = false;
      });
    }
  }

  Future<void> resendVerificationEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await currentUser.sendEmailVerification();

      if (!mounted) {
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        SnackBar(
          content: Text(
            "Verification email sent to ${widget.email}. Check your inbox and spam folder.",
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      showError(error.message ?? "Couldn't resend verification email.");
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpacing = (constraints.maxHeight * 0.08).clamp(20.0, 72.0);
            final logoHeight = (constraints.maxWidth * 0.22).clamp(110.0, 170.0);
            final logoWidth = (constraints.maxWidth * 0.5).clamp(220.0, 420.0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, topSpacing, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                      Image.asset(
                        'assets/ecomarket_wordlogo.png',
                        height: logoHeight,
                        width: logoWidth,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        "Verify Your UNIMAS Email",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your account has been created successfully. Before you can start using the app, please verify your email.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: colors.primaryText,
                        ),
                      ),
                      Text(
                        "Check your inbox and spam/junk folder.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isChecking ? null : refreshVerificationStatus,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: const Color.fromRGBO(37, 99, 235, 1),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            isChecking
                                ? "Checking..."
                                : "I've Verified My Email",
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isSending ? null : resendVerificationEmail,
                        child: Text(
                          isSending
                              ? "Sending..."
                              : "Resend Verification Email",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: signOut,
                        child: const Text("Back to Login"),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

