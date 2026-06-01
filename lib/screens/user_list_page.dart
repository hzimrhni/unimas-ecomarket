import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  static const double _tableWidth = 600;
  static const int _rowsPerPage = 10;
  bool showFilters = false;
  String selectedFilter = 'all';
  int currentPage = 1;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users',
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
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFC9FDFF),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('User')
                            .where('role', isEqualTo: 'student')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFFD9E1EC)),
                              ),
                              child: Text(
                                "Couldn't load users: ${snapshot.error}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            );
                          }

                          final query = searchController.text.trim().toLowerCase();
                          final docs = snapshot.data?.docs ?? [];
                          final users = docs.map((doc) {
                            final data = doc.data();
                            final createdAt = data['createdAt'] as Timestamp?;
                            final createdDate = createdAt?.toDate();
                            final joinedCompact = createdDate == null
                                ? '-'
                                : '${createdDate.year}-\n${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}';

                            return <String, String>{
                              'id': doc.id,
                              'email': data['unimas_email']?.toString() ?? '',
                              'fullName': data['name']?.toString().trim().isNotEmpty == true
                                  ? data['name'].toString()
                                  : 'Not completed',
                              'name': data['name']?.toString().trim().isNotEmpty == true
                                  ? data['name'].toString()
                                  : 'Not completed',
                              'phone': data['phone']?.toString() ?? '-',
                              'college': data['college']?.toString() ?? '-',
                              'faculty': data['faculty']?.toString() ?? '-',
                              'year': _formatYear(data['year_of_study']),
                              'createdAt': createdDate == null
                                  ? '-'
                                  : '${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}',
                              'joined': joinedCompact,
                              'status': data['user_status']?.toString() ?? 'unknown',
                              'profileCompleted':
                                  (data['profile_completed'] == true).toString(),
                            };
                          }).toList();

                          final filteredUsers = users.where((user) {
                            final status = user['status']?.toLowerCase() ?? '';
                            final matchesFilter = selectedFilter == 'all' ||
                                (selectedFilter == 'active' && status == 'active') ||
                                (selectedFilter == 'suspended' && status == 'suspended') ||
                                (selectedFilter == 'not verified' &&
                                    status == 'not verified');
                            final matchesSearch = query.isEmpty ||
                                (user['name'] ?? '').toLowerCase().contains(query) ||
                                (user['email'] ?? '').toLowerCase().contains(query);
                            return matchesFilter && matchesSearch;
                          }).toList();
                          final totalPages = filteredUsers.isEmpty
                              ? 1
                              : ((filteredUsers.length - 1) ~/ _rowsPerPage) + 1;
                          final safePage = currentPage.clamp(1, totalPages);
                          final startIndex =
                              filteredUsers.isEmpty ? 0 : (safePage - 1) * _rowsPerPage;
                          final endIndex = filteredUsers.isEmpty
                              ? 0
                              : ((startIndex + _rowsPerPage) > filteredUsers.length
                                  ? filteredUsers.length
                                  : (startIndex + _rowsPerPage));
                          final pagedUsers = filteredUsers.sublist(startIndex, endIndex);

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 58,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFD9E1EC),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.search,
                                            color: Color(0xFF8A94A6),
                                            size: 26,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: searchController,
                                              onChanged: (_) {
                                                setState(() {
                                                  currentPage = 1;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                hintText: 'Search by name or email...',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFF8A94A6),
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        showFilters = !showFilters;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFD9E1EC),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.filter_list_rounded,
                                        color: Color(0xFF4A5C78),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (showFilters) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFFD9E1EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF233B5E),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 12,
                                        children: [
                                          _FilterChip(
                                            label: 'All',
                                            selected: selectedFilter == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedFilter = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'Active',
                                            selected: selectedFilter == 'active',
                                            onTap: () {
                                              setState(() {
                                                selectedFilter = 'active';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'Suspended',
                                            selected:
                                                selectedFilter == 'suspended',
                                            onTap: () {
                                              setState(() {
                                                selectedFilter = 'suspended';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'Not Verified',
                                            selected:
                                                selectedFilter == 'not verified',
                                            onTap: () {
                                              setState(() {
                                                selectedFilter = 'not verified';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              const SizedBox(height: 18),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: const Color(0xFFD9E1EC)),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: SizedBox(
                                    width: _tableWidth,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                                          child: Row(
                                            children: const [
                                              SizedBox(
                                                width: 250,
                                                child: _HeaderText('User', alignLeft: true),
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: _HeaderText('Joined'),
                                              ),
                                              SizedBox(
                                                width: 102,
                                                child: _HeaderText('Status'),
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: _HeaderText('Actions'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFE7ECF3),
                                        ),
                                        ...pagedUsers.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final user = entry.value;
                                          return Column(
                                            children: [
                                              _UserRow(
                                                user: user,
                                                onView: () => _openUserDetail(user),
                                              ),
                                              if (index != pagedUsers.length - 1)
                                                const Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: Color(0xFFE7ECF3),
                                                ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Showing ${filteredUsers.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredUsers.length} users',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF31506E),
                                      ),
                                    ),
                                  ),
                                  _PagerButton(
                                    label: 'Previous',
                                    enabled: safePage > 1,
                                    onTap: safePage > 1
                                        ? () {
                                            setState(() {
                                              currentPage = safePage - 1;
                                            });
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  _PageNumberButton(
                                    label: '$safePage',
                                    selected: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _PagerButton(
                                    label: 'Next',
                                    enabled: safePage < totalPages,
                                    onTap: safePage < totalPages
                                        ? () {
                                            setState(() {
                                              currentPage = safePage + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
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
                    routeToDashboard: true,
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

  void _openUserDetail(Map<String, String> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(user: user),
      ),
    );
  }

  String _formatYear(dynamic value) {
    if (value == null) {
      return '-';
    }
    final text = value.toString();
    if (text.isEmpty || text == 'null') {
      return '-';
    }
    return text.startsWith('Year') || text == 'Post Graduate'
        ? text
        : 'Year $text';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F6BFF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFD9E1EC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF233B5E),
          ),
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignLeft;

  const _HeaderText(this.text, {this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF233B5E),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, String> user;
  final VoidCallback onView;

  const _UserRow({
    required this.user,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final status = (user['status'] ?? 'unknown').toLowerCase();
    final isSuspended = status == 'suspended';
    final isActive = status == 'active';
    final isVerified = status == 'verified';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'User Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? 'user@example.com',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E76B9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                user['joined'] ?? '2024-\n01-15',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  color: Color(0xFF233B5E),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 102,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSuspended
                        ? const Color(0xFFFFE3E3)
                        : isActive
                            ? const Color(0xFFD9F9E5)
                            : isVerified
                                ? const Color(0xFFEAF1FF)
                                : const Color(0xFFFFF3BF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user['status'] ?? 'unknown',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSuspended
                          ? const Color(0xFFB42318)
                          : isActive
                              ? const Color(0xFF067647)
                              : isVerified
                                  ? const Color(0xFF2F6BFF)
                                  : const Color(0xFFB67D00),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 36,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF1FF),
                    foregroundColor: const Color(0xFF2F6BFF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _PagerButton({
    required this.label,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9E1EC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? const Color(0xFF31506E) : const Color(0xFF98A5B8),
          ),
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _PageNumberButton({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2F6BFF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFD9E1EC),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF233B5E),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToItems;
  final bool routeToCategories;
  final bool routeToReports;
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
    this.routeToCategories = false,
    this.routeToReports = false,
    this.routeToImpact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7A90);
    final VoidCallback? onTap = routeToDashboard
        ? () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardPage(),
              ),
              (route) => false,
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
            : routeToCategories
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoryPage(),
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
                                builder: (_) => const SustainabilityAdminPage(),
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
