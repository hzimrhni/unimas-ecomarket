import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'student_theme.dart';

class LoginScreen extends StatefulWidget {
  final String? errorMessage;

  const LoginScreen({super.key, this.errorMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isAdmin = false;
  int logoTapCount = 0;
  bool isSubmitting = false;
  bool isRegisterMode = false;
  String? statusMessage;
  bool isStatusError = false;

  @override
  void initState() {
    super.initState();
    statusMessage = widget.errorMessage;
    isStatusError = widget.errorMessage != null;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage) {
      statusMessage = widget.errorMessage;
      isStatusError = widget.errorMessage != null;
    }
  }

  void toggleAdminMode() {
    setState(() {
      isAdmin = !isAdmin;
      isRegisterMode = false;
      statusMessage = null;
      isStatusError = false;
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    });

    showTopSnackBarFromSnackBar(context, 
      SnackBar(
        content: Text(
          isAdmin ? "Admin Mode Activated" : "Student Mode Activated",
        ),
      ),
    );
  }

  void handleLogoTap() {
    logoTapCount++;

    if (logoTapCount == 3) {
      logoTapCount = 0;
      toggleAdminMode();
    }
  }

  Future<void> submitAuth() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty) {
      showError("Please enter your email.");
      return;
    }

    if (!isAdmin && !email.endsWith("@siswa.unimas.my")) {
      showError("Please use your UNIMAS student email.");
      return;
    }

    if (password.isEmpty) {
      showError("Please enter your password.");
      return;
    }

    if (isRegisterMode && password.length < 6) {
      showError("Password must be at least 6 characters.");
      return;
    }

    if (isRegisterMode && password != confirmPassword) {
      showError("Passwords do not match.");
      return;
    }

    setState(() {
      isSubmitting = true;
      statusMessage = null;
      isStatusError = false;
    });

    try {
      if (isRegisterMode) {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.sendEmailVerification();

        final createdUser = userCredential.user;
        if (createdUser != null) {
          await FirebaseFirestore.instance.collection('User').doc(createdUser.uid).set({
            'role': 'student',
            'unimas_email': email,
            'name': null,
            'phone': null,
            'faculty': null,
            'college': null,
            'year_of_study': null,
            'user_status': 'not verified',
            'profile_completed': false,
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));
        }

        if (!mounted) {
          return;
        }

        setState(() {
          statusMessage =
              "Account created. A verification email has been sent to $email. Please check your inbox and spam folder.";
          isStatusError = false;
        });
      } else {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user;
        if (user == null) {
          showError("Authentication failed.");
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .get();
        final role = userDoc.data()?['role']?.toString().toLowerCase() ?? '';
        final userStatus =
            userDoc.data()?['user_status']?.toString().toLowerCase() ?? '';

        if (userStatus == 'suspended') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) {
            return;
          }

          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Account Suspended'),
                content: const Text(
                  'Your account is suspended. Please meet the admin to clarify and reactivate your account.',
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
          return;
        }

        if (isAdmin && role != 'admin') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) {
            return;
          }

          showError("Wrong admin credentials.");
          return;
        }

        if (!isAdmin && role == 'admin') {
          await FirebaseAuth.instance.signOut();

          if (!mounted) {
            return;
          }

          showError("This account must sign in from admin login.");
          return;
        }

        if (!user.emailVerified) {
          await user.sendEmailVerification();

          if (!mounted) {
            return;
          }

          setState(() {
            statusMessage =
                "Your email is not verified yet. We sent another verification email to $email.";
            isStatusError = false;
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      String message;
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          message = isAdmin
              ? "Wrong admin credentials."
              : "Wrong email or password.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        default:
          message = error.message ?? "Authentication failed.";
      }

      showError(message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showError("Authentication failed: $error");
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void showError(String message) {
    setState(() {
      statusMessage = message;
      isStatusError = true;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final Color backgroundColor = isAdmin
        ? const Color.fromRGBO(201, 253, 255, 1)
        : colors.pageBackground;
    final textColor = isAdmin ? const Color(0xFF0A2342) : colors.primaryText;
    final hintColor = isAdmin ? const Color(0xFF6B7A90) : colors.tertiaryText;
    final inputFillColor = isAdmin
        ? Colors.white
        : colors.cardBackground;
    final inputBorderColor = isAdmin
        ? const Color(0xFFD0D5DD)
        : colors.border;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final topSpacing = (constraints.maxHeight * 0.08).clamp(20.0, 72.0);
            final logoHeight = (constraints.maxWidth * 0.22).clamp(110.0, 170.0);
            final logoWidth = (constraints.maxWidth * 0.5).clamp(220.0, 420.0);
            final titleText = isAdmin
                ? "Sign in using your admin email"
                : isRegisterMode
                    ? "Create your UNIMAS student account"
                    : "Sign in using your UNIMAS email";

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, topSpacing, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: handleLogoTap,
                          child: Image.asset(
                            "assets/unimas_logo.png",
                            height: 55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: handleLogoTap,
                        child: Image.asset(
                          'assets/ecomarket_wordlogo.png',
                          height: logoHeight,
                          width: logoWidth,
                        ),
                      ),
                      SizedBox(height: isAdmin ? 72 : 60),
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: isAdmin ? 34 : 25),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: isAdmin
                                ? "example@unimas.my"
                                : isRegisterMode
                                    ? "example@siswa.unimas.my"
                                    : "example@siswa.unimas.my",
                            hintStyle: TextStyle(color: hintColor),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            hintText: "Password",
                            hintStyle: TextStyle(color: hintColor),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
                            ),
                          ),
                        ),
                      ),
                      if (isRegisterMode && !isAdmin) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                           child: TextField(
                             controller: confirmPasswordController,
                             obscureText: true,
                             textAlign: TextAlign.center,
                             style: TextStyle(color: textColor),
                             decoration: InputDecoration(
                               filled: true,
                               fillColor: inputFillColor,
                               hintText: "Confirm Password",
                               hintStyle: TextStyle(color: hintColor),
                               contentPadding: EdgeInsets.symmetric(
                                 horizontal: 14,
                                 vertical: 10,
                               ),
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: inputBorderColor),
                               ),
                               enabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: inputBorderColor),
                               ),
                               focusedBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(12),
                                 borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
                               ),
                             ),
                           ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitAuth,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor:
                                const Color.fromRGBO(37, 99, 235, 1),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isSubmitting
                                ? "Please wait..."
                                : isRegisterMode
                                    ? "Create Account"
                                    : isAdmin
                                        ? "Continue"
                                        : "Sign In",
                          ),
                        ),
                      ),
                      if (!isAdmin) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    isRegisterMode = !isRegisterMode;
                                    statusMessage = null;
                                    isStatusError = false;
                                  });
                                },
                          child: Text(
                            isRegisterMode
                                ? "Already have an account? Sign In"
                                : "New student? Create Account",
                          ),
                        ),
                      ],
                      if (statusMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          statusMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isStatusError ? Colors.red : textColor,
                          ),
                        ),
                      ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

