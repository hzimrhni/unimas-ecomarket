import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/price_formatter.dart';
import 'my_item_detail_page.dart';
import 'student_theme.dart';
import 'seller_activity_history_page.dart';
import 'my_item_page.dart';
import 'seller_booking_page.dart';

class SellerDashboardPage extends StatelessWidget {
  final String userId;

  const SellerDashboardPage({
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
            final totalItems = listings.where((doc) {
              final data = doc.data();
              final listingStatus =
                  data['listing_status']?.toString().toLowerCase() ?? '';
              final saleStatus =
                  data['sale_status']?.toString().toLowerCase() ?? '';

              final isApproved = listingStatus == 'approved';
              final isAvailableOrBooked =
                  saleStatus == 'available' || saleStatus == 'booked';

              return isApproved && isAvailableOrBooked;
            }).length;

            final bookedItems = listings.where((doc) {
              final saleStatus =
                  doc.data()['sale_status']?.toString().toLowerCase() ?? '';
              return saleStatus == 'booked';
            }).length;

            final totalSales = listings.fold<double>(0, (sum, doc) {
              final data = doc.data();
              final saleStatus =
                  data['sale_status']?.toString().toLowerCase() ?? '';
              if (saleStatus != 'completed') {
                return sum;
              }
              final rawPrice = data['price'];
              final parsedPrice = rawPrice is num
                  ? rawPrice.toDouble()
                  : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
              return sum + parsedPrice;
            });

            final recentActivities = listings
                .map((doc) => _SellerActivity.fromDoc(doc))
                .where((activity) => activity != null)
                .cast<_SellerActivity>()
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seller Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your store',
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
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _SellerStatCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Items',
                          value: '$totalItems',
                          gradient: const [
                            Color(0xFF2F6BFF),
                            Color(0xFF3C85FF),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SellerStatCard(
                          icon: Icons.attach_money,
                          title: 'Sales',
                          value: formatRmPrice(totalSales),
                          gradient: const [
                            Color(0xFF0AC64F),
                            Color(0xFF05B83D),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SellerStatCard(
                          icon: Icons.calendar_today_outlined,
                          title: 'Booked',
                          value: '$bookedItems',
                          gradient: const [
                            Color(0xFF8A2BE2),
                            Color(0xFFC23DFF),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF8A2BE2),
                          iconBackground: const Color(0xFFF0E4FF),
                          title: 'Manage\nBookings',
                          subtitle: 'View and manage all\nbookings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellerBookingPage(userId: userId),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.inventory_2_outlined,
                          iconColor: const Color(0xFFFF5A00),
                          iconBackground: const Color(0xFFFFEED8),
                          title: 'My Items\nInventory',
                          subtitle: 'Manage your listings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyItemPage(userId: userId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                      if (recentActivities.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellerActivityHistoryPage(
                                  userId: userId,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See more',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    decoration: BoxDecoration(
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
                    ),
                    child: recentActivities.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No recent activity yet.',
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.secondaryText,
                              ),
                            ),
                          )
                        : Column(
                            children: recentActivities
                                .take(5)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final activity = entry.value;
                              return Column(
                                children: [
                                  _RecentActivityRow(
                                    activity: activity,
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
                                  ),
                                  if (index != recentActivities.take(5).length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: colors.divider,
                                    ),
                                ],
                              );
                            }).toList(),
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          size: 24,
          color: colors.icon,
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

class _RecentActivityRow extends StatelessWidget {
  final _SellerActivity activity;
  final VoidCallback onTap;

  const _RecentActivityRow({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              _RecentActivityImage(
                imagePath: activity.imagePath,
                fallbackIcon: activity.icon,
                fallbackIconColor: activity.iconColor,
                fallbackBackground: activity.iconBackground,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
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

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
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
    );
  }
}

class _SellerStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<Color> gradient;

  const _SellerStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
    final colors = StudentThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 280,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
