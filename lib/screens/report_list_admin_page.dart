import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_detail_admin_page.dart';
import 'sustainability_admin_page.dart';

class ReportListAdminPage extends StatefulWidget {
  const ReportListAdminPage({super.key});

  @override
  State<ReportListAdminPage> createState() => _ReportListAdminPageState();
}

class _ReportListAdminPageState extends State<ReportListAdminPage> {
  static const double _tableWidth = 640;
  static const int _rowsPerPage = 10;
  bool showFilters = false;
  String selectedStatus = 'all';
  String selectedType = 'all';
  int currentPage = 1;

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
                    'Complaints',
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
                            .collection('Report')
                            .orderBy('created_at', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFD9E1EC),
                                ),
                              ),
                              child: Text(
                                "Couldn't load reports: ${snapshot.error}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFB42318),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final reports = docs.map(_mapReport).toList();
                          final pendingCount = reports
                              .where((report) => report['status'] == 'pending')
                              .length;
                          final resolvedCount = reports
                              .where((report) => report['status'] == 'resolved')
                              .length;
                          final dismissedCount = reports
                              .where((report) => report['status'] == 'dismissed')
                              .length;
                          final itemCount = reports
                              .where((report) => report['type'] == 'item')
                              .length;
                          final userCount = reports
                              .where((report) => report['type'] == 'user')
                              .length;

                          final filteredReports = reports.where((report) {
                            final matchesStatus = selectedStatus == 'all' ||
                                report['status'] == selectedStatus;
                            final matchesType = selectedType == 'all' ||
                                report['type'] == selectedType;
                            return matchesStatus && matchesType;
                          }).toList();
                          final totalPages = filteredReports.isEmpty
                              ? 1
                              : ((filteredReports.length - 1) ~/ _rowsPerPage) + 1;
                          final safePage = currentPage.clamp(1, totalPages);
                          final startIndex = filteredReports.isEmpty
                              ? 0
                              : (safePage - 1) * _rowsPerPage;
                          final endIndex = filteredReports.isEmpty
                              ? 0
                              : ((startIndex + _rowsPerPage) > filteredReports.length
                                  ? filteredReports.length
                                  : (startIndex + _rowsPerPage));
                          final pagedReports =
                              filteredReports.sublist(startIndex, endIndex);

                          return Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      showFilters = !showFilters;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFD9E1EC),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.filter_list_rounded,
                                          color: Color(0xFF4A5C78),
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF233B5E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (showFilters) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    20,
                                    20,
                                    18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFFD9E1EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            selected: selectedStatus == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'Pending ($pendingCount)',
                                            selected:
                                                selectedStatus == 'pending',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'pending';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label:
                                                'Resolved ($resolvedCount)',
                                            selected:
                                                selectedStatus == 'resolved',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'resolved';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label:
                                                'Dismissed ($dismissedCount)',
                                            selected:
                                                selectedStatus == 'dismissed',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'dismissed';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Complaint Type',
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
                                            selected: selectedType == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'Item ($itemCount)',
                                            selected: selectedType == 'item',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'item';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterChip(
                                            label: 'User ($userCount)',
                                            selected: selectedType == 'user',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'user';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFD9E1EC),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: SizedBox(
                                    width: _tableWidth,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            16,
                                            18,
                                            12,
                                          ),
                                          child: Row(
                                            children: const [
                                              SizedBox(
                                                width: 250,
                                                child: _HeaderText(
                                                  'Reporter',
                                                  alignLeft: true,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 78,
                                                child: _HeaderText('Type'),
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: _HeaderText('Date'),
                                              ),
                                              SizedBox(
                                                width: 92,
                                                child: _HeaderText('Status'),
                                              ),
                                              SizedBox(
                                                width: 92,
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
                                        if (filteredReports.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 28,
                                            ),
                                            child: Text(
                                              'No complaints found.',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF6B7A90),
                                              ),
                                            ),
                                          )
                                        else
                                          ...pagedReports.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;
                                            final report = entry.value;
                                            return Column(
                                              children: [
                                                _ReportRow(
                                                  report: report,
                                                  onView: () {
                                                    _openReportDetail(
                                                      report['id']!,
                                                    );
                                                  },
                                                ),
                                                if (index !=
                                                    pagedReports.length - 1)
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
                                      'Showing ${filteredReports.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredReports.length} complaints',
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
                    selected: true,
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

  Map<String, String> _mapReport(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAt = data['created_at'] as Timestamp?;
    final createdDate = createdAt?.toDate();
    final reporterName = (data['reporter_name']?.toString().trim().isNotEmpty == true)
        ? data['reporter_name'].toString()
        : (data['reporter_email']?.toString() ?? 'Unknown');
    final reportedLabel = (data['report_type']?.toString().toLowerCase() == 'user')
        ? (data['reported_user_name']?.toString().trim().isNotEmpty == true
            ? data['reported_user_name'].toString()
            : (data['reported_user_email']?.toString() ?? 'Unknown user'))
        : (data['reported_listing_name']?.toString().trim().isNotEmpty == true
            ? data['reported_listing_name'].toString()
            : 'Unknown item');

    return {
      'id': doc.id,
      'reportId': data['report_id']?.toString() ?? doc.id,
      'reporter': reporterName,
      'type': data['report_type']?.toString().toLowerCase() ?? 'item',
      'reported': reportedLabel,
      'date': _formatCompactDate(createdDate),
      'createdDate': _formatFullDate(createdDate),
      'status': data['report_status']?.toString().toLowerCase() ?? 'pending',
    };
  }

  String _formatCompactDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return '${date.year}-\n${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _openReportDetail(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailAdminPage(reportId: reportId),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F6BFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFD9E1EC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF4A5C78),
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

class _ReportRow extends StatelessWidget {
  final Map<String, String> report;
  final VoidCallback onView;

  const _ReportRow({
    required this.report,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final status = report['status'] ?? 'pending';
    final type = report['type'] ?? 'item';
    final isUser = type == 'user';
    final isPending = status == 'pending';
    final isResolved = status == 'resolved';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: Text(
              report['reporter'] ?? 'Reporter',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A2342),
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFFF1E5FF)
                        : const Color(0xFFFFEFD9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isUser ? 'User' : 'Item',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUser
                          ? const Color(0xFF9B4DDB)
                          : const Color(0xFFDA7B00),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                report['date'] ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  color: Color(0xFF233B5E),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFFFFF3BF)
                        : isResolved
                            ? const Color(0xFFD9F9E5)
                            : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPending
                          ? const Color(0xFFB67D00)
                          : isResolved
                              ? const Color(0xFF067647)
                              : const Color(0xFF475467),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
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
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
    this.routeToCategories = false,
    this.routeToImpact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7A90);
    final VoidCallback? onTap = routeToDashboard
        ? () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
              (route) => false,
            );
          }
        : routeToItems
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ItemListPage()),
            );
          }
        : routeToCategories
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
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
