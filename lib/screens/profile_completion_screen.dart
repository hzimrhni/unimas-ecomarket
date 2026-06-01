import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_gate.dart';
import 'main_page.dart';
import 'student_theme.dart';
import '../widgets/floating_dropdown_field.dart';

class ProfileCompletionScreen extends StatefulWidget {

  final String email;

  const ProfileCompletionScreen({super.key, required this.email});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {

  final nameController = TextEditingController();
  //final matricController = TextEditingController();
  final phoneController = TextEditingController();
  final facultyController = TextEditingController();
  final collegeController = TextEditingController();
  final yearController = TextEditingController();

  String? selectedFaculty;
  String? selectedCollege;
  String? selectedYear;

  final List<String> facultyList = [
    "Faculty of Science Computer and Technology",
    "Faculty of Economics and Business",
    "Faculty of Engineering",
    "Faculty of Applied and Creative Arts",
    "Faculty of Cognitive Sciences and Human Development",
    "Faculty of Medicine and Health Sciences",
    "Faculty of Social Sciences and Humanities",
    "Faculty of Resource Science and Technology",
    "Faculty of Language and Communication",
    "Faculty of Built Environment"
  ];

  final List<String> collegeList = [
    "Cempaka",
    "Kenanga",
    "Allamanda",
    "Bunga Raya",
    "Sakura",
    "Seroja",
    "Dahlia",
    "Tun Ahmad Zaidi",
    "Rafflesia",
    "Not in any college"
  ];

  final List<String> yearList = [
    "Year 1",
    "Year 2",
    "Year 3",
    "Year 4",
    "Post Graduate"
  ];

  void saveProfile() async {

    if (nameController.text.isEmpty ||
        //matricController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedFaculty == null ||
        selectedCollege == null ||
        selectedYear == null) {

      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Error"),
          content: Text("Please fill in all fields."),
        ),
      );

      return;
    }

    if (phoneController.text.length < 10 || phoneController.text.length > 11) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Error"),
          content: Text("Phone number must be 10-11 digits."),
        ),
      );
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Error"),
          content: Text("You are not signed in. Please try again."),
        ),
      );
      return;
    }

    final userId = currentUser.uid;
    await FirebaseFirestore.instance
    .collection('User')
    .doc(userId)
    .set({
      'role': 'student',
      'name': nameController.text.trim(),
      'unimas_email': widget.email,
      'phone': phoneController.text.trim(),
      'faculty': selectedFaculty,
      'college': selectedCollege,
      'year_of_study': selectedYear,
      'user_status': 'active',
      'profile_completed': true,
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));

    showTopSnackBarFromSnackBar(context, 
      const SnackBar(content: Text("Profile Completed!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(userId: userId),
      ),
    );
  }

  //general input box
  Widget buildInput(String label, TextEditingController controller) {
    final colors = StudentThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        height: 56,
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 15,
            color: colors.primaryText,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: colors.secondaryText),
            filled: true,
            fillColor: colors.cardBackground,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
            ),
          ),
        ),
      ),
    );
  }

  //Phone number input format and box
  Widget buildPhoneInput() {
    final colors = StudentThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        height: 56,
        child: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          style: TextStyle(
            fontSize: 15,
            color: colors.primaryText,
          ),
          decoration: InputDecoration(
            labelText: "Phone Number",
            hintText: "eg: 0123456789",
            labelStyle: TextStyle(color: colors.secondaryText),
            hintStyle: TextStyle(color: colors.tertiaryText),
            filled: true,
            fillColor: colors.cardBackground,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
            ),
          ),
        ),
      ),
    );
  }

  //Dropdown type input box
  Widget buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final colors = StudentThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          FloatingDropdownField<String>(
            value: value,
            items: items,
            hint: label,
            onChanged: onChanged,
            borderColor: colors.border,
            focusedBorderColor: const Color(0xFF2F6BFF),
            borderRadius: 4,
            height: 56,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: TextStyle(
              fontSize: 15,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> backToLogin() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
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
            final topSpacing = (constraints.maxHeight * 0.06).clamp(16.0, 48.0);
            final logoHeight = (constraints.maxWidth * 0.22).clamp(110.0, 170.0);
            final logoWidth = (constraints.maxWidth * 0.5).clamp(220.0, 420.0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, topSpacing, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: backToLogin,
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Image.asset(
                          'assets/ecomarket_wordlogo.png',
                          height: logoHeight,
                          width: logoWidth,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Please complete your profile before using the system.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 40),
                      buildInput("Full Name", nameController),
                      const SizedBox(height: 20),
                      buildPhoneInput(),
                      const SizedBox(height: 20),
                      buildDropdown(
                        "Faculty",
                        selectedFaculty,
                        facultyList,
                        (value) {
                          setState(() {
                            selectedFaculty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      buildDropdown(
                        "College",
                        selectedCollege,
                        collegeList,
                        (value) {
                          setState(() {
                            selectedCollege = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      buildDropdown(
                        "Year of Study",
                        selectedYear,
                        yearList,
                        (value) {
                          setState(() {
                            selectedYear = value;
                          });
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saveProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: const Color.fromRGBO(37, 99, 235, 1),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Next"),
                        ),
                      ),
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
    nameController.dispose();
    //matricController.dispose();
    phoneController.dispose();
    facultyController.dispose();
    collegeController.dispose();
    super.dispose();
  }
}

