import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';

class ItemDetailAdminPage extends StatefulWidget {
  final Map<String, String> item;

  const ItemDetailAdminPage({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailAdminPage> createState() => _ItemDetailAdminPageState();
}

class _ItemDetailAdminPageState extends State<ItemDetailAdminPage> {
  late Map<String, String> item;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    item = Map<String, String>.from(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? 'approved').toLowerCase();
    final saleStatus = (item['saleStatus'] ?? 'available').toLowerCase();
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final isRemoved = saleStatus == 'removed' || status == 'removed';
    final isDonation = (item['type'] ?? '').toLowerCase() == 'donation';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
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
                              'Item Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _AdminItemImage(
                            imagePath: item['imagePath'] ?? '',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldBlock(
                                label: 'Title',
                                value: item['title'] ??
                                    (item['name'] ?? 'Item Name').replaceAll('\n', ' '),
                              ),
                              const SizedBox(height: 22),
                              _FieldBlock(
                                label: 'Description',
                                value: item['description'] ?? 'Item description',
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Category',
                                      value: item['category'] ?? 'Category',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Listing Type',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _TypeChip(
                                          text: isDonation ? 'For Donation' : 'For Sale',
                                          donation: isDonation,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Price',
                                      value: item['price'] ?? '\$0',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Seller',
                                      value: item['seller'] ?? 'Seller Name',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Created At',
                                      value: item['createdDate'] ??
                                          (item['createdAt'] ?? '').replaceAll('\n', ''),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sale Status',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _SoftStatusChip(
                                          text: item['saleStatus'] ?? 'Available',
                                          backgroundColor: _saleStatusBackground(saleStatus),
                                          textColor: _saleStatusTextColor(saleStatus),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    backgroundColor: isApproved
                                        ? const Color(0xFFD9F9E5)
                                        : isPending
                                            ? const Color(0xFFFFF3BF)
                                            : const Color(0xFFFFE3E3),
                                    textColor: isApproved
                                        ? const Color(0xFF067647)
                                        : isPending
                                            ? const Color(0xFFB67D00)
                                            : const Color(0xFFB42318),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (isApproved && !isRemoved) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: isProcessing ? null : _removeApprovedItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF1010),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text(
                                'Remove Item',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ] else if (isPending) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: isProcessing ? null : _approveItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0AAA41),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text(
                                'Approve Item',
                                style: TextStyle(
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
                              onPressed: isProcessing ? null : _rejectItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF1010),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text(
                                'Reject Item',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ] else if (isRejected || isRemoved) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No actions available for this item',
                                style: TextStyle(
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
                    selected: true,
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
                    label: 'Reports',
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

  Future<void> _approveItem() async {
    final listingId = item['id'];
    if (listingId == null || listingId.isEmpty) {
      _showError('Couldn\'t approve this item.');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Listing').doc(listingId).update({
        'listing_status': 'approved',
        'admin_action_reason': FieldValue.delete(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'admin',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        item['status'] = 'approved';
        isProcessing = false;
      });

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Item approved successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        isProcessing = false;
      });
      _showError('Couldn\'t approve item: $error');
    }
  }

  Future<void> _rejectItem() async {
    final listingId = item['id'];
    if (listingId == null || listingId.isEmpty) {
      _showError('Couldn\'t reject this item.');
      return;
    }

    final reason = await _promptAdminReason(
      title: 'Reject item?',
      description:
          'Enter the reason for rejecting the item to be released into the system.',
      hintText: 'Enter reason',
      confirmLabel: 'Reject',
    );

    if (reason == null) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Listing').doc(listingId).update({
        'listing_status': 'rejected',
        'sale_status': 'removed',
        'admin_action_reason': reason,
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'admin',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        item['status'] = 'rejected';
        item['saleStatus'] = 'removed';
        item['adminActionReason'] = reason;
        isProcessing = false;
      });

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Item rejected successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        isProcessing = false;
      });
      _showError('Couldn\'t reject item: $error');
    }
  }

  Future<void> _removeApprovedItem() async {
    final reason = await _promptAdminReason(
      title: 'Remove item?',
      description:
          'Enter the reason for removing the item from the system listing.',
      hintText: 'Enter reason',
      confirmLabel: 'Remove',
    );

    if (reason == null) {
      return;
    }

    await _markItemRemoved(
      reason: reason,
      successMessage: 'Item removed successfully.',
    );
  }

  Future<void> _markItemRemoved({
    required String reason,
    required String successMessage,
  }) async {
    final listingId = item['id'];

    if (listingId == null || listingId.isEmpty) {
      _showError('Couldn\'t remove this item.');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance.collection('Listing').doc(listingId).update({
        'sale_status': 'removed',
        'admin_action_reason': reason,
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'admin',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        item['saleStatus'] = 'removed';
        item['adminActionReason'] = reason;
        isProcessing = false;
      });

      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        isProcessing = false;
      });
      _showError('Couldn\'t remove item: $error');
    }
  }

  void _showError(String message) {
    showTopSnackBarFromSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<String?> _promptAdminReason({
    required String title,
    required String description,
    required String hintText,
    required String confirmLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return _AdminReasonDialog(
          title: title,
          description: description,
          hintText: hintText,
          confirmLabel: confirmLabel,
        );
      },
    );
  }

  Color _saleStatusBackground(String status) {
    if (status.contains('removed')) {
      return const Color(0xFFF2F4F7);
    }
    if (status.contains('book')) {
      return const Color(0xFFFFF3BF);
    }
    if (status.contains('complete')) {
      return const Color(0xFFE0F2FE);
    }
    if (status.contains('cancel')) {
      return const Color(0xFFFEE2E2);
    }
    return const Color(0xFFD9F9E5);
  }

  Color _saleStatusTextColor(String status) {
    if (status.contains('removed')) {
      return const Color(0xFF475467);
    }
    if (status.contains('book')) {
      return const Color(0xFFB67D00);
    }
    if (status.contains('complete')) {
      return const Color(0xFF0369A1);
    }
    if (status.contains('cancel')) {
      return const Color(0xFFB91C1C);
    }
    return const Color(0xFF067647);
  }
}

class _AdminItemImage extends StatelessWidget {
  final String imagePath;

  const _AdminItemImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder();
    }

    return Container(
      width: double.infinity,
      height: 320,
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _placeholder();
          },
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 320,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Color(0xFF98A2B3),
          ),
        ),
      ),
    );
  }
}

class _AdminReasonDialog extends StatefulWidget {
  final String title;
  final String description;
  final String hintText;
  final String confirmLabel;

  const _AdminReasonDialog({
    required this.title,
    required this.description,
    required this.hintText,
    required this.confirmLabel,
  });

  @override
  State<_AdminReasonDialog> createState() => _AdminReasonDialogState();
}

class _AdminReasonDialogState extends State<_AdminReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Reason',
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
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
  final bool donation;

  const _TypeChip({
    required this.text,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: donation ? const Color(0xFFF1E5FF) : const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: donation ? const Color(0xFF9B4DDB) : const Color(0xFF2F6BFF),
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
  final bool routeToCategories;
  final bool routeToReports;
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
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

