import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_detail_admin_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';
import 'user_detail_page.dart';

class ReportDetailAdminPage extends StatefulWidget {
  final String reportId;

  const ReportDetailAdminPage({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailAdminPage> createState() => _ReportDetailAdminPageState();
}

class _ReportDetailAdminPageState extends State<ReportDetailAdminPage> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Report')
              .doc(widget.reportId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorScaffold(
                message: "Couldn't load report: ${snapshot.error}",
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final doc = snapshot.data!;
            if (!doc.exists) {
              return const _ErrorScaffold(message: 'This report no longer exists.');
            }

            final report = doc.data()!;
            final reportType =
                (report['report_type']?.toString().toLowerCase() ?? 'item');
            final status =
                (report['report_status']?.toString().toLowerCase() ?? 'pending');
            final isPending = status == 'pending';
            final isResolved = status == 'resolved';
            final isUserReport = reportType == 'user';
            final statusBackground = isPending
                ? const Color(0xFFFFF3BF)
                : isResolved
                    ? const Color(0xFFD9F9E5)
                    : const Color(0xFFF1F3F7);
            final statusColor = isPending
                ? const Color(0xFFB67D00)
                : isResolved
                    ? const Color(0xFF067647)
                    : const Color(0xFF475467);

            return Column(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFC9FDFF),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF233B5E),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Complaint Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0A2342),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _DetailCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldBlock(
                                    label: 'Complaint ID',
                                    value:
                                        report['report_id']?.toString() ?? doc.id,
                                  ),
                                  const SizedBox(height: 22),
                                  _FieldBlock(
                                    label: 'Reporter',
                                    value:
                                        report['reporter_name']?.toString() ??
                                        report['reporter_email']?.toString() ??
                                        'Unknown reporter',
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Complaint Type',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF667085),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _TypeChip(
                                              text: isUserReport
                                                  ? 'User Report'
                                                  : 'Item Report',
                                              userReport: isUserReport,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Status',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF667085),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _SoftStatusChip(
                                              text: status,
                                              backgroundColor:
                                                  statusBackground,
                                              textColor: statusColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    isUserReport
                                        ? 'Reported User'
                                        : 'Reported Item',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFD),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isUserReport
                                                ? (report['reported_user_name']
                                                          ?.toString() ??
                                                      report['reported_user_email']
                                                          ?.toString() ??
                                                      'Unknown user')
                                                : (report['reported_listing_name']
                                                          ?.toString() ??
                                                      'Unknown item'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0A2342),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          height: 40,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _openReportedDetails(report),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFEAF1FF),
                                              foregroundColor:
                                                  const Color(0xFF2F6BFF),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'View Details',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _FieldBlock(
                                    label: 'Reason',
                                    value:
                                        report['reason']?.toString() ??
                                        'No reason provided',
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _FieldBlock(
                                          label: 'Created Date',
                                          value: _formatDate(
                                            report['created_at'] as Timestamp?,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _FieldBlock(
                                          label: 'Resolved Date',
                                          value: _formatDate(
                                            report['resolved_at'] as Timestamp?,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isPending) ...[
                                    const SizedBox(height: 22),
                                    _FieldBlock(
                                      label: 'Resolved By',
                                      value:
                                          report['handled_by_name']
                                              ?.toString() ??
                                          report['handled_by']?.toString() ??
                                          '-',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            if (isPending) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _updateReportStatus('resolved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0AAA41),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    isProcessing
                                        ? 'Updating...'
                                        : 'Resolve Complaint',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _updateReportStatus('dismissed'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5C6C82),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: Text(
                                    isProcessing
                                        ? 'Updating...'
                                        : 'Dismiss Complaint',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    isResolved
                                        ? 'This complaint has been resolved'
                                        : 'This complaint has been dismissed',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B7A90),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(String nextStatus) async {
    setState(() {
      isProcessing = true;
    });

    try {
      final handledBy = FirebaseAuth.instance.currentUser?.uid ?? '';
      String? handledByName;
      if (handledBy.isNotEmpty) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('User')
            .doc(handledBy)
            .get();
        final name = adminDoc.data()?['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          handledByName = name;
        }
      }

      await FirebaseFirestore.instance
          .collection('Report')
          .doc(widget.reportId)
          .update({
            'report_status': nextStatus,
            'resolved_at': FieldValue.serverTimestamp(),
            'handled_by': handledBy,
            'handled_by_name': handledByName,
          });

      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(
          content: Text(
            nextStatus == 'resolved'
              ? 'Complaint resolved successfully.'
              : 'Complaint dismissed successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text('Couldn\'t update report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _openReportedDetails(Map<String, dynamic> report) async {
    final reportType =
        (report['report_type']?.toString().toLowerCase() ?? 'item');

    if (reportType == 'user') {
      final userId = report['reported_user_id']?.toString() ?? '';
      if (userId.isEmpty) {
        _showError('This report has no linked user record.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        _showError('The reported user could not be found.');
        return;
      }

      final data = userDoc.data()!;
      final createdAt = data['createdAt'] as Timestamp?;
      final createdDate = createdAt?.toDate();
      final userMap = <String, String>{
        'id': userDoc.id,
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
        'status': data['user_status']?.toString() ?? 'unknown',
        'purchases': '0',
        'sales': '0',
      };

      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserDetailPage(user: userMap)),
      );
      return;
    }

    final listingId = report['reported_listing_id']?.toString() ?? '';
    if (listingId.isEmpty) {
      _showError('This report has no linked item record.');
      return;
    }

    final listingDoc = await FirebaseFirestore.instance
        .collection('Listing')
        .doc(listingId)
        .get();
    if (!listingDoc.exists) {
      _showError('The reported item could not be found.');
      return;
    }

    final data = listingDoc.data()!;
    final createdAt = data['created_at'] as Timestamp?;
    final createdDate = createdAt?.toDate();
    final typeRaw = data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final itemMap = <String, String>{
      'id': listingDoc.id,
      'imagePath': data['image_path']?.toString() ?? '',
      'title': data['title']?.toString() ?? 'Item Name',
      'name': data['title']?.toString() ?? 'Item Name',
      'description': data['description']?.toString() ?? '',
      'category':
          data['subcategory_name']?.toString() ??
          data['category_name']?.toString() ??
          'Category',
      'type': typeRaw == 'donation' || typeRaw == 'donate'
          ? 'Donation'
          : 'Sale',
      'price': typeRaw == 'donation' || typeRaw == 'donate'
          ? 'Free'
          : 'RM${_formatPrice(data['price'])}',
      'seller':
          report['seller_name']?.toString() ??
          data['seller_name']?.toString() ??
          'Seller Name',
      'createdDate': createdDate == null
          ? '-'
          : '${createdDate.year}-${createdDate.month.toString().padLeft(2, '0')}-${createdDate.day.toString().padLeft(2, '0')}',
      'saleStatus': data['sale_status']?.toString() ?? 'available',
      'status': data['listing_status']?.toString() ?? 'pending',
    };

    if (!mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailAdminPage(item: itemMap)),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    final date = timestamp?.toDate();
    if (date == null) {
      return '-';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  String _formatPrice(dynamic value) {
    if (value == null) {
      return '0.00';
    }
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    return parsed.toStringAsFixed(2);
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    showTopSnackBarFromSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;

  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFFB42318),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: child,
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final String value;

  const _FieldBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A2342),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String text;
  final bool userReport;

  const _TypeChip({
    required this.text,
    required this.userReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: userReport ? const Color(0xFFF1E5FF) : const Color(0xFFFFEFD9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: userReport ? const Color(0xFF9B4DDB) : const Color(0xFFDA7B00),
        ),
      ),
    );
  }
}

class _SoftStatusChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _SoftStatusChip({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
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

