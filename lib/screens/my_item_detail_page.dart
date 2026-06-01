import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_item_page.dart';
import 'student_theme.dart';

class MyItemDetailPage extends StatefulWidget {
  final Map<String, String> item;

  const MyItemDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<MyItemDetailPage> createState() => _MyItemDetailPageState();
}

class _MyItemDetailPageState extends State<MyItemDetailPage> {
  late Map<String, String> item;
  bool isRemoving = false;

  @override
  void initState() {
    super.initState();
    item = Map<String, String>.from(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final listingStatus = (item['listingStatus'] ?? '').toLowerCase();
    final saleStatus = (item['saleStatus'] ?? '').toLowerCase();
    final isPendingReview = listingStatus == 'pending';
    final isRejected = listingStatus == 'rejected';
    final isRemoved = saleStatus == 'removed' || listingStatus == 'removed';
    final isCompleted = saleStatus == 'completed';
    final updatedByRole = (item['updatedByRole'] ?? '').toLowerCase();
    final adminActionReason = (item['adminActionReason'] ?? '').trim();
    final showAdminReason = updatedByRole == 'admin' &&
        adminActionReason.isNotEmpty &&
        (isRejected || isRemoved);
    final adminReasonLabel = isRejected
        ? 'Reason for rejected item'
        : 'Reason for item removal';
    final canManageItem =
        !isPendingReview && !isRejected && !isRemoved && !isCompleted;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _DetailImage(imagePath: item['imagePath'] ?? ''),
                  Positioned(
                    top: 12,
                    left: 8,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back, color: colors.icon),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                item['name'] ?? "Item Name",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item['price'] ?? 'RM0.00',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F6BFF),
                ),
              ),
              const SizedBox(height: 26),
              _DetailSection(
                label: 'Description',
                value: item['description'] ?? 'Description',
              ),
              _DetailSection(
                label: 'Category',
                value: item['category'] ?? 'Category',
              ),
              _DetailSection(
                label: 'Subcategory',
                value: item['subcategory'] ?? 'Subcategory',
              ),
              _DetailSection(
                label: 'Listing Type',
                valueWidget: _typeChip(item['listingType'] ?? 'Sale'),
              ),
              _DetailSection(
                label: 'Sale Status',
                valueWidget: _statusChip(item['saleStatus'] ?? 'Available'),
                showDivider: !showAdminReason,
              ),
              if (showAdminReason)
                _DetailSection(
                  label: adminReasonLabel,
                  value: adminActionReason,
                  showDivider: false,
                ),
              if (isPendingReview) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isRemoving ? null : _cancelPendingItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1C12),
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: const Color(0x33FF1C12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isRemoving ? 'Removing...' : 'Remove Item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (canManageItem) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final userId = item['sellerId'] ?? item['userId'];
                            if (userId == null || userId.isEmpty) {
                              showTopSnackBarFromSnackBar(context, 
                                const SnackBar(
                                  content: Text('Couldn\'t open update form.'),
                                ),
                              );
                              return;
                            }

                            final updatedItem =
                                await Navigator.push<Map<String, String>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddItemPage(
                                  userId: userId,
                                  listingId: item['id'],
                                  initialItem: item,
                                ),
                              ),
                            );

                            if (updatedItem != null && mounted) {
                              setState(() {
                                item = updatedItem;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6BFF),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: const Color(0x332F6BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Update",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isRemoving ? null : _removeItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF1C12),
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: const Color(0x33FF1C12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isRemoving ? "Removing..." : "Remove",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeItem() async {
    final listingId = item['id'];
    final imagePath = item['imagePath'] ?? '';

    if (listingId == null || listingId.isEmpty) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Couldn\'t remove this item.')),
      );
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove item?'),
          content: const Text(
            'This will remove item from the system listing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    setState(() {
      isRemoving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Listing')
          .doc(listingId)
          .update({
        'sale_status': 'removed',
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'seller',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      item['saleStatus'] = 'removed';

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(
          content: Text('Couldn\'t remove item: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isRemoving = false;
      });
    }
  }

  Future<void> _cancelPendingItem() async {
    final listingId = item['id'];

    if (listingId == null || listingId.isEmpty) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Couldn\'t cancel this item.')),
      );
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove pending item?'),
          content: const Text(
            'This will remove pending request for the item to be in the system listing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    setState(() {
      isRemoving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Listing')
          .doc(listingId)
          .delete();

      if (!mounted) {
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Pending item removed successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(
          content: Text('Couldn\'t remove pending item: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isRemoving = false;
      });
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool showDivider;

  const _DetailSection({
    required this.label,
    this.value,
    this.valueWidget,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          valueWidget ??
              Text(
                value ?? '-',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: colors.primaryText,
                ),
              ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String value;

  const _TypeChip(this.value);

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final normalized = value.toLowerCase();
    final isDonation =
        normalized.contains('donation') || normalized.contains('donate');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDonation ? const Color(0xFFF2E7FF) : const Color(0xFFE3EEFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        color: isDonation ? const Color(0xFF8A2BE2) : Theme.of(context).colorScheme.primary,
      ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String value;

  const _StatusChip(this.value);

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final normalized = value.toLowerCase();
    Color bgColor = colors.softBackground;
    Color textColor = colors.secondaryText;

    if (normalized.contains('book')) {
      bgColor = const Color(0xFFFFF2CC);
      textColor = const Color(0xFFB7791F);
    } else if (normalized.contains('complete')) {
      bgColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0369A1);
    } else if (normalized.contains('cancel')) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

Widget _typeChip(String value) => _TypeChip(value);

Widget _statusChip(String value) => _StatusChip(value);

class _DetailImage extends StatelessWidget {
  final String imagePath;

  const _DetailImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return Container(
      height: 330,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(context),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _placeholder(context);
          },
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      height: 330,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: colors.tertiaryText,
          ),
        ),
      ),
    );
  }
}

