import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'auth_gate.dart';
import 'my_booking_page.dart';
import 'sellerDashboard_page.dart';
import 'sustainability_record_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('User')
        .doc(widget.userId)
        .get();

    if (!mounted) {
      return;
    }

    setState(() {
      userData = doc.data();
      isLoading = false;
    });
  }

  Future<void> signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
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
  }

  void toggleTheme(BuildContext context) {
    final themeMode = ThemeController.of(context);
    themeMode.value =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101114) : Colors.white;
    final sectionCardColor = isDark ? const Color(0xFF17191F) : Colors.white;
    final cardBorderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF0A2342);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF667085);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = userData?['name']?.toString() ?? 'User Name';
    final email =
        userData?['unimas_email']?.toString() ?? 'xxxxx@siswa.unimas.my';
    final phone = userData?['phone']?.toString() ?? 'Phone Number';
    final college = userData?['college']?.toString() ?? 'College Name';
    final faculty = userData?['faculty']?.toString() ?? 'Faculty Name';
    final yearLabel =
        userData?['year_of_study']?.toString() ?? 'Not completed';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 15,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _buildCircleButton(
                    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    onTap: () => toggleTheme(context),
                    backgroundColor: sectionCardColor,
                    iconColor: textColor,
                    borderColor: cardBorderColor,
                    shadowColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(width: 10),
                  _buildCircleButton(
                    icon: Icons.logout,
                    onTap: signOut,
                    backgroundColor: sectionCardColor,
                    iconColor: textColor,
                    borderColor: cardBorderColor,
                    shadowColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.08),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: sectionCardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorderColor),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      label: 'Phone Number',
                      value: phone,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _divider(isDark),
                    _infoRow(
                      label: 'College',
                      value: college,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _divider(isDark),
                    _infoRow(
                      label: 'Faculty',
                      value: faculty,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _divider(isDark),
                    _infoRow(
                      label: 'Year of Study',
                      value: yearLabel,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'My Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),
              _activityCard(
                context: context,
                icon: Icons.calendar_today_outlined,
                iconBackground: const LinearGradient(
                  colors: [Color(0xFF2F6BFF), Color(0xFF2563EB)],
                ),
                title: 'My Booking',
                subtitle: 'View your active bookings',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                cardColor: sectionCardColor,
                cardBorderColor: cardBorderColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyBookingPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _activityCard(
                context: context,
                icon: Icons.eco_outlined,
                iconBackground: const LinearGradient(
                  colors: [Color(0xFF0AC64F), Color(0xFF05B83D)],
                ),
                title: 'Sustainability Record',
                subtitle: 'Track your eco impact',
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                cardColor: sectionCardColor,
                cardBorderColor: cardBorderColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SustainabilityRecordPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Seller Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerDashboardPage(userId: widget.userId),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFA020F0),
                        Color(0xFF2F6BFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.26),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 22),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller Dashboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Manage your store and listings',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white12 : const Color(0xFFEAECEF),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    bool showDivider = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: shadowColor == Colors.transparent
            ? null
            : [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _activityCard({
    required BuildContext context,
    required IconData icon,
    required Gradient iconBackground,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color secondaryTextColor,
    required Color cardColor,
    required Color cardBorderColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: iconBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0x332F6BFF),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
