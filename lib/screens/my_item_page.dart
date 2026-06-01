import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import '../utils/price_formatter.dart';
import 'add_item_page.dart';
import 'my_item_detail_page.dart';
import 'student_theme.dart';

class MyItemPage extends StatefulWidget {
  final String userId;

  const MyItemPage({super.key, required this.userId});

  @override
  State<MyItemPage> createState() => _MyItemPageState();
}

class _MyItemPageState extends State<MyItemPage> {
  bool isForSaleSelected = true;

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: colors.pageBackground,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
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
                            icon: Icon(Icons.arrow_back, color: colors.icon),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            'My Item',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddItemPage(userId: widget.userId),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: const Color(0x332F6BFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '+  Add Item',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.softBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(
                            title: 'For Sale',
                            isSelected: isForSaleSelected,
                            onTap: () {
                              setState(() {
                                isForSaleSelected = true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildTab(
                            title: 'For Donation',
                            isSelected: !isForSaleSelected,
                            onTap: () {
                              setState(() {
                                isForSaleSelected = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: colors.pageBackground,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Listing')
                      .where('seller_id', isEqualTo: widget.userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            "Couldn't load your items: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allItems = snapshot.data?.docs
                            .map((doc) => _SellerListingItem.fromDoc(doc))
                            .toList() ??
                        [];

                    final visibleItems = allItems.where((item) {
                      final type = item.listingType.toLowerCase();
                      final listingStatus = item.listingStatus.toLowerCase();
                      final saleStatus = item.saleStatus.toLowerCase();
                      final isVisibleStatus =
                          listingStatus != 'rejected' &&
                          listingStatus != 'removed' &&
                          saleStatus != 'removed' &&
                          saleStatus != 'completed';

                      if (!isVisibleStatus) {
                        return false;
                      }

                      return isForSaleSelected
                          ? type == 'sell' || type == 'sale'
                          : type == 'donate' || type == 'donation';
                    }).toList();

                    if (visibleItems.isEmpty) {
                      return Center(
                        child: Text(
                          isForSaleSelected
                              ? 'No sale items yet.'
                              : 'No donation items yet.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7A90),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(
                          context,
                          visibleItems[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = StudentThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? colors.primaryText
                : colors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, _SellerListingItem item) {
    final colors = StudentThemeColors.of(context);
    final isPendingReview = item.listingStatus.toLowerCase() == 'pending';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyItemDetailPage(item: item.toDetailMap()),
          ),
        );
        if (result == true && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            showTopSnackBarFromSnackBar(this.context, 
              const SnackBar(content: Text('Item removed successfully.')),
            );
          });
        }
      },
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SellerListingImage(imagePath: item.imagePath),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isPendingReview)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xCCEEF1F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Pending for admin review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF344054),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellerListingItem {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String listingType;
  final String rawListingType;
  final String categoryName;
  final String categoryId;
  final String subcategoryName;
  final String subcategoryId;
  final String saleStatus;
  final String listingStatus;
  final String updatedByRole;
  final String adminActionReason;

  const _SellerListingItem({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.listingType,
    required this.rawListingType,
    required this.categoryName,
    required this.categoryId,
    required this.subcategoryName,
    required this.subcategoryId,
    required this.saleStatus,
    required this.listingStatus,
    required this.updatedByRole,
    required this.adminActionReason,
  });

  factory _SellerListingItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final listingType =
        data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return _SellerListingItem(
      id: doc.id,
      sellerId: data['seller_id']?.toString() ?? '',
      name: data['title']?.toString() ??
          data['name']?.toString() ??
          'Item Name',
      description: data['description']?.toString() ?? 'Description',
      price: parsedPrice,
      imagePath: data['image_path']?.toString() ?? '',
      listingType: listingType,
      rawListingType: listingType,
      categoryName: data['category_name']?.toString() ??
          data['category']?.toString() ??
          '-',
      categoryId: data['category_id']?.toString() ?? '',
      subcategoryName: data['subcategory_name']?.toString() ?? '-',
      subcategoryId: data['subcategory_id']?.toString() ?? '',
      saleStatus: data['sale_status']?.toString() ?? 'Available',
      listingStatus: data['listing_status']?.toString() ?? 'pending',
      updatedByRole: data['updated_by_role']?.toString() ?? '',
      adminActionReason: data['admin_action_reason']?.toString() ?? '',
    );
  }

  String get formattedPrice {
    if (listingType == 'donate' || listingType == 'donation' || price <= 0) {
      return 'Free';
    }
    return formatRmPrice(price);
  }

  String get listingTypeLabel {
    return listingType == 'donate' || listingType == 'donation'
        ? 'Donation'
        : 'Sale';
  }

  Map<String, String> toDetailMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'title': name,
      'price': formattedPrice,
      'priceValue': price.toString(),
      'imagePath': imagePath,
      'description': description,
      'category': categoryName,
      'categoryId': categoryId,
      'subcategory': subcategoryName,
      'subcategoryId': subcategoryId,
      'listingType': listingTypeLabel,
      'listingTypeRaw': rawListingType,
      'saleStatus': saleStatus,
      'listingStatus': listingStatus,
      'updatedByRole': updatedByRole,
      'adminActionReason': adminActionReason,
    };
  }
}

class _SellerListingImage extends StatelessWidget {
  final String imagePath;

  const _SellerListingImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        color: colors.softBackground,
        child: Image.network(
          imagePath,
          width: double.infinity,
          fit: BoxFit.cover,
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: colors.tertiaryText,
          ),
        ),
      ),
    );
  }
}

