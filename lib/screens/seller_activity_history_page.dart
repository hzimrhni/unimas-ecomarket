import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/price_formatter.dart';
import 'my_item_detail_page.dart';
import 'student_theme.dart';

class SellerActivityHistoryPage extends StatelessWidget {
  final String userId;

  const SellerActivityHistoryPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Listing')
              .where('seller_id', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            final listings = snapshot.data?.docs ?? [];
            final activities = listings
                .map((doc) => _SellerActivity.fromDoc(doc))
                .where((activity) => activity != null)
                .cast<_SellerActivity>()
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Row(
                    children: [
                      Container(
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
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: colors.icon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity History',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'All seller notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: activities.isEmpty
                      ? Center(
                          child: Text(
                            'No activity yet.',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.secondaryText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: colors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.shadow,
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MyItemDetailPage(
                                          item: activity.itemDetailMap,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          _RecentActivityImage(
                                            imagePath: activity.imagePath,
                                            fallbackIcon: activity.icon,
                                            fallbackIconColor: activity.iconColor,
                                            fallbackBackground:
                                                activity.iconBackground,
                                          ),
                                         const SizedBox(width: 14),
                                         Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                               Text(
                                                 activity.title,
                                                 style: TextStyle(
                                                   fontSize: 16,
                                                   fontWeight: FontWeight.w700,
                                                   color: colors.primaryText,
                                                 ),
                                               ),
                                              const SizedBox(height: 4),
                                               Text(
                                                 activity.subtitle,
                                                 style: TextStyle(
                                                   fontSize: 14,
                                                   color: colors.secondaryText,
                                                 ),
                                               ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colors.tertiaryText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecentActivityImage extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final Color fallbackIconColor;
  final Color fallbackBackground;

  const _RecentActivityImage({
    required this.imagePath,
    required this.fallbackIcon,
    required this.fallbackIconColor,
    required this.fallbackBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fallbackBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          fallbackIcon,
          color: fallbackIconColor,
          size: 24,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colors.softBackground,
          border: Border.all(color: colors.border),
        ),
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: fallbackBackground,
              child: Icon(
                fallbackIcon,
                color: fallbackIconColor,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SellerActivity {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String imagePath;
  final DateTime timestamp;
  final Map<String, String> itemDetailMap;

  const _SellerActivity({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.imagePath,
    required this.timestamp,
    required this.itemDetailMap,
  });

  static _SellerActivity? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final listingStatus = data['listing_status']?.toString().toLowerCase() ?? '';
    final saleStatus = data['sale_status']?.toString().toLowerCase() ?? '';
    final title = data['title']?.toString() ?? 'Item';
    final sellerId = data['seller_id']?.toString() ?? '';
    final updatedBy = data['updated_by']?.toString() ?? '';
    final updatedByRole = data['updated_by_role']?.toString().toLowerCase() ?? '';
    final updatedAt = data['updated_at'];
    final createdAt = data['created_at'];
    final timestamp = updatedAt is Timestamp
        ? updatedAt.toDate()
        : createdAt is Timestamp
            ? createdAt.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

    if (listingStatus == 'rejected') {
      final message = updatedByRole == 'admin'
          ? 'Admin rejected your item'
          : 'Your item was rejected';
      return _SellerActivity(
        title: message,
        subtitle: '$title - ${_timeAgo(timestamp)}',
        icon: Icons.close_rounded,
        iconColor: const Color(0xFFB42318),
        iconBackground: const Color(0xFFFFE3E3),
        imagePath: data['image_path']?.toString() ?? '',
        timestamp: timestamp,
        itemDetailMap: _buildItemDetailMap(doc),
      );
    }

    if (saleStatus == 'removed') {
      final removedBySeller = updatedByRole == 'seller' || updatedBy == sellerId;
      final message = removedBySeller
          ? 'You removed an item'
          : 'Admin removed your item';
      return _SellerActivity(
        title: message,
        subtitle: '$title - ${_timeAgo(timestamp)}',
        icon: Icons.delete_outline,
        iconColor: const Color(0xFF667085),
        iconBackground: const Color(0xFFF2F4F7),
        imagePath: data['image_path']?.toString() ?? '',
        timestamp: timestamp,
        itemDetailMap: _buildItemDetailMap(doc),
      );
    }

    if (listingStatus == 'approved') {
      final message = updatedByRole == 'admin'
          ? 'Admin approved your item'
          : 'Item approved';
      return _SellerActivity(
        title: message,
        subtitle: '$title - ${_timeAgo(timestamp)}',
        icon: Icons.check_box_outlined,
        iconColor: const Color(0xFF12B76A),
        iconBackground: const Color(0xFFD9F9E5),
        imagePath: data['image_path']?.toString() ?? '',
        timestamp: timestamp,
        itemDetailMap: _buildItemDetailMap(doc),
      );
    }

    return null;
  }

  static String _timeAgo(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  static Map<String, String> _buildItemDetailMap(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final listingType = data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final isDonation = listingType == 'donate' || listingType == 'donation';
    final formattedPrice = isDonation || parsedPrice <= 0
        ? 'Free'
        : formatRmPrice(parsedPrice);

    return {
      'id': doc.id,
      'sellerId': data['seller_id']?.toString() ?? '',
      'name': data['title']?.toString() ?? 'Item Name',
      'title': data['title']?.toString() ?? 'Item Name',
      'price': formattedPrice,
      'priceValue': parsedPrice.toString(),
      'imagePath': data['image_path']?.toString() ?? '',
      'description': data['description']?.toString() ?? 'Description',
      'category': data['category_name']?.toString() ??
          data['category']?.toString() ??
          '-',
      'categoryId': data['category_id']?.toString() ?? '',
      'subcategory': data['subcategory_name']?.toString() ?? '-',
      'subcategoryId': data['subcategory_id']?.toString() ?? '',
      'listingType': isDonation ? 'Donation' : 'Sale',
      'listingTypeRaw': listingType,
      'saleStatus': data['sale_status']?.toString() ?? 'Available',
      'listingStatus': data['listing_status']?.toString() ?? 'pending',
      'updatedByRole': data['updated_by_role']?.toString() ?? '',
      'adminActionReason': data['admin_action_reason']?.toString() ?? '',
    };
  }
}
