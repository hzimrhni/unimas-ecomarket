import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'student_theme.dart';

class ReportItemPage extends StatefulWidget {
  final Map<String, String> item;

  const ReportItemPage({
    super.key,
    required this.item,
  });

  @override
  State<ReportItemPage> createState() => _ReportItemPageState();
}

class _ReportItemPageState extends State<ReportItemPage> {
  final reasonController = TextEditingController();
  String reporterName = 'Reporter Name';
  String reporterEmail = 'xxxxx@siswa.unimas.my';
  bool isSubmitting = false;

  bool get canSubmit => reasonController.text.trim().isNotEmpty;

  void confirmSubmit() {
    if (!canSubmit || isSubmitting) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Report'),
          content: const Text('Are you sure you want to submit this report?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitReport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6BFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    reasonController.addListener(_onReasonChanged);
    _loadReporter();
  }

  Future<void> _loadReporter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    var nextName = widget.item['reporterName'] ?? 'Reporter Name';
    final nextEmail = user.email ?? widget.item['reporterEmail'] ?? reporterEmail;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final firestoreName = data?['name']?.toString().trim();
      if (firestoreName != null && firestoreName.isNotEmpty) {
        nextName = firestoreName;
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      reporterName = nextName;
      reporterEmail = nextEmail;
    });
  }

  Future<void> _submitReport() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('You need to sign in first.')),
      );
      return;
    }

    final reportRef = FirebaseFirestore.instance.collection('Report').doc();
    final sellerName = widget.item['sellerName'] ?? 'Seller Name';
    final sellerEmail = widget.item['sellerEmail'] ?? '';

    setState(() {
      isSubmitting = true;
    });

    try {
      await reportRef.set({
        'report_id': reportRef.id,
        'reporter_id': authUser.uid,
        'reporter_name': reporterName,
        'reporter_email': reporterEmail,
        'report_type': 'item',
        'reported_listing_id': widget.item['id'] ?? '',
        'reported_listing_name': widget.item['name'] ?? 'Item Name',
        'reported_user_id': widget.item['sellerId'] ?? '',
        'reported_user_name': sellerName,
        'reported_user_email': sellerEmail,
        'seller_id': widget.item['sellerId'] ?? '',
        'seller_name': sellerName,
        'seller_email': sellerEmail,
        'reason': reasonController.text.trim(),
        'report_status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'resolved_at': null,
        'handled_by': null,
        'handled_by_name': null,
      });

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text('Couldn\'t submit item report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _onReasonChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    reasonController.removeListener(_onReasonChanged);
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBackButton(context),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Report Item',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _infoSection(
                      label: 'Reporter:',
                      value: reporterName,
                      secondaryValue: reporterEmail,
                    ),
                    _divider(),
                    _infoSection(
                      label: 'Seller:',
                      value: widget.item['sellerName'] ?? 'Seller Name',
                      secondaryValue:
                          widget.item['sellerEmail'] ??
                          'xxxxx@siswa.unimas.my',
                    ),
                    _divider(),
                    _infoSection(
                      label: 'Reported Item:',
                      value: widget.item['name'] ?? 'Item Name',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Reason:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: reasonController,
                      maxLines: 7,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Please describe the reason for reporting this item...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: colors.tertiaryText,
                        ),
                        contentPadding: const EdgeInsets.all(18),
                        filled: true,
                        fillColor: colors.cardBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF2F6BFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: canSubmit && !isSubmitting ? confirmSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit && !isSubmitting
                        ? const Color(0xFF2F6BFF)
                        : const Color(0xFFD0D5DD),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD0D5DD),
                    disabledForegroundColor: Colors.white,
                    elevation: canSubmit && !isSubmitting ? 10 : 0,
                    shadowColor: const Color(0x332F6BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isSubmitting ? 'Submitting...' : 'Submit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.arrow_back, color: colors.icon),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final colors = StudentThemeColors.of(context);
    return BoxDecoration(
      color: colors.cardBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _divider() {
    final colors = StudentThemeColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colors.divider,
      ),
    );
  }

  Widget _infoSection({
    required String label,
    required String value,
    String? secondaryValue,
    bool showDivider = true,
  }) {
    final colors = StudentThemeColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
          if (secondaryValue != null) ...[
            const SizedBox(height: 8),
            Text(
              secondaryValue,
              style: TextStyle(
                fontSize: 15,
                color: colors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

