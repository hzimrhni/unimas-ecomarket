import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sales_report_admin_page.dart';
import 'sustainability_admin_page.dart';
import 'user_list_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC9FDFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dashboard',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0A2342),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7A90),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Log Out'),
                                      content: const Text(
                                        'Are you sure you want to log out?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Log Out'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldLogout == true) {
                                  await FirebaseAuth.instance.signOut();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthGate(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF6B7A90),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC9FDFF),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE3E8EF)),
                          bottom: BorderSide(color: Color(0xFFE3E8EF)),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('User')
                            .where('role', isEqualTo: 'student')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final studentDocs = snapshot.data?.docs ?? [];
                          final totalStudents = studentDocs.length;
                          final activeStudents = studentDocs.where((doc) {
                            final status =
                                doc.data()['user_status']?.toString().toLowerCase();
                            return status == 'active';
                          }).length;
                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('Listing')
                                .where('listing_status', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, listingSnapshot) {
                              final pendingItemCount =
                                  listingSnapshot.data?.docs.length ?? 0;

                              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('Report')
                                    .where('report_status', isEqualTo: 'pending')
                                    .snapshots(),
                                builder: (context, reportSnapshot) {
                                  final pendingReportCount =
                                      reportSnapshot.data?.docs.length ?? 0;

                                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('Listing')
                                        .where('sale_status', isEqualTo: 'completed')
                                        .snapshots(),
                                    builder: (context, completedSnapshot) {
                                      final completedDocs =
                                          completedSnapshot.data?.docs ?? [];
                                      final carbonSaved = completedDocs.fold<double>(
                                        0,
                                        (sum, doc) {
                                          final data = doc.data();
                                          final carbonReduction =
                                              _asDouble(data['carbon_reduction']);
                                          final efUsed = _asDouble(data['ef_used']);
                                          return sum +
                                              (carbonReduction > 0
                                                  ? carbonReduction
                                                  : efUsed);
                                        },
                                      );

                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _StatCard(
                                                  icon: Icons.groups_outlined,
                                                  iconColor: const Color(0xFF2F6BFF),
                                                  iconBackground:
                                                      const Color(0xFFEAF1FF),
                                                  title: 'Active Users',
                                                  value: '$activeStudents',
                                                  suffix: '/$totalStudents',
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const UserListPage(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: _StatCard(
                                                  icon: Icons.inventory_2_outlined,
                                                  iconColor:
                                                      const Color(0xFFDA9B00),
                                                  iconBackground:
                                                      const Color(0xFFFFF6DA),
                                                  title: 'Pending Items',
                                                  value: '$pendingItemCount',
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const ItemListPage(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _StatCard(
                                                  icon: Icons.error_outline,
                                                  iconColor:
                                                      const Color(0xFFFF2A2A),
                                                  iconBackground:
                                                      const Color(0xFFFFEFEF),
                                                  title: 'Pending Complaints',
                                                  value: '$pendingReportCount',
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const ReportListAdminPage(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: _StatCard(
                                                  icon: Icons.eco_outlined,
                                                  iconColor:
                                                      const Color(0xFF0BA84A),
                                                  iconBackground:
                                                      const Color(0xFFE8F8EE),
                                                  title: 'Carbon Saved',
                                                  value:
                                                      '${_formatKg(carbonSaved)} kg CO2e',
                                                  isCompactValue: true,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const SustainabilityAdminPage(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                     const Padding(
                       padding: EdgeInsets.fromLTRB(24, 26, 24, 14),
                       child: Text(
                         'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A2342),
                        ),
                       ),
                     ),
                     Padding(
                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                       child: _QuickActionCard(
                         icon: Icons.description_outlined,
                         iconColor: const Color(0xFF2F6BFF),
                         iconBackground: const Color(0xFFEAF1FF),
                         title: 'Sales Report',
                         subtitle: 'View monthly sales data',
                         onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => const SalesReportAdminPage(),
                             ),
                           );
                         },
                       ),
                     ),
                     Padding(
                       padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                       child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('Listing')
                            .where('listing_status', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final pendingItemCount =
                              snapshot.data?.docs.length ?? 0;

                          return _QuickActionCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFFDA9B00),
                            iconBackground: const Color(0xFFFFF6DA),
                            title: 'Review Items',
                            subtitle: '$pendingItemCount pending approval',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ItemListPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('Report')
                            .where('report_status', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final pendingReportCount =
                              snapshot.data?.docs.length ?? 0;

                          return _QuickActionCard(
                            icon: Icons.error_outline,
                            iconColor: const Color(0xFFFF2A2A),
                            iconBackground: const Color(0xFFFFEFEF),
                            title: 'Handle Complaints',
                            subtitle: '$pendingReportCount pending review',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportListAdminPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE3E8EF)),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AdminNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Items',
                    routeToItems: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    routeToCategories: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Home',
                    selected: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.error_outline,
                    label: 'Complaints',
                    routeToReports: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.eco_outlined,
                    label: 'Impact',
                    routeToImpact: true,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String? suffix;
  final bool isCompactValue;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    this.suffix,
    this.isCompactValue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 156,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E1EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF39506F),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF0A2342),
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: isCompactValue ? 15 : 18,
                    ),
                  ),
                  if (suffix != null)
                    TextSpan(
                      text: suffix,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B7A90),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E1EC)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A2342),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7A90),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF98A5B8),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String _formatKg(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToCategories;
  final bool routeToItems;
  final bool routeToReports;
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToCategories = false,
    this.routeToItems = false,
    this.routeToReports = false,
    this.routeToImpact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7A90);
    final VoidCallback? onTap = routeToCategories
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryPage(),
              ),
            );
          }
        : routeToItems
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemListPage(),
                  ),
                );
              }
            : routeToReports
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportListAdminPage(),
                      ),
                    );
                  }
                : routeToImpact
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SustainabilityAdminPage(),
                          ),
                        );
                      }
            : null;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
