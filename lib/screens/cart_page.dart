import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import '../utils/price_formatter.dart';
import 'item_detail_page.dart';
import 'student_theme.dart';

class CartPage extends StatelessWidget {
  final String userId;

  const CartPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBackButton(context),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      'Your Cart',
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
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('User')
                      .doc(userId)
                      .collection('Cart')
                      .orderBy('added_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Couldn't load cart: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cartDocs = snapshot.data?.docs ?? [];
                    if (cartDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'Your cart is empty.',
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.secondaryText,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: cartDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final cartDoc = cartDocs[index];
                        final listingId =
                            cartDoc.data()['listing_id']?.toString() ?? cartDoc.id;
                        return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('Listing')
                              .doc(listingId)
                              .get(),
                          builder: (context, listingSnapshot) {
                            if (listingSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingCard(context);
                            }

                            final listingData = listingSnapshot.data?.data();
                            if (listingData == null) {
                              return _buildMissingCard(
                                context: context,
                                cartDocId: cartDoc.id,
                              );
                            }

                            return _buildCartCard(
                              context: context,
                              cartDocId: cartDoc.id,
                              item: _CartListing.fromData(
                                id: listingId,
                                data: listingData,
                              ),
                              name: listingData['title']?.toString() ??
                                  listingData['name']?.toString() ??
                                  'Item Name',
                              price: _formatPrice(
                                listingData['listing_type']?.toString() ?? '',
                                listingData['price'],
                              ),
                              imagePath:
                                  listingData['image_path']?.toString() ?? '',
                            );
                          },
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

  Widget _buildCartCard({
    required BuildContext context,
    required String cartDocId,
    required _CartListing item,
    required String name,
    required String price,
    required String imagePath,
  }) {
    final colors = StudentThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailPage(item: item.toDetailMap()),
            ),
          );
        },
        child: Ink(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colors.softBackground,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _CartImage(imagePath: imagePath),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 92,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => _removeCartItem(context, cartDocId),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFFFF1414),
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shadowColor: const Color(0x33FF1414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.saleStatus.toLowerCase() == 'booked' ||
                  item.saleStatus.toLowerCase() == 'completed' ||
                  item.saleStatus.toLowerCase() == 'removed')
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  right: 122,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      item.saleStatus.toLowerCase() == 'removed'
                          ? 'This item has been removed'
                          : item.saleStatus.toLowerCase() == 'completed'
                              ? 'This item is no longer available'
                              : 'This item is being booked by other user',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x99000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
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

  Widget _buildLoadingCard(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      height: 136,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildMissingCard({
    required BuildContext context,
    required String cartDocId,
  }) {
    final colors = StudentThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'This item is no longer available.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _removeCartItem(context, cartDocId),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFFFF1414),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCartItem(BuildContext context, String cartDocId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove from Cart'),
          content: const Text(
            'Are you sure you want to remove this item from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1414),
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('Cart')
          .doc(cartDocId)
          .delete();

      if (!context.mounted) {
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Item removed from cart.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Failed to remove item from cart.')),
      );
    }
  }

  String _formatPrice(String listingType, Object? rawPrice) {
    final normalizedType = listingType.toLowerCase();
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    if (normalizedType == 'donation' || parsedPrice <= 0) {
      return 'Free';
    }
    return formatRmPrice(parsedPrice);
  }
}

class _CartImage extends StatelessWidget {
  final String imagePath;

  const _CartImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return Image.network(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _placeholder(context),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _placeholder(context);
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: StudentThemeColors.of(context).tertiaryText,
        ),
      ),
    );
  }
}

class _CartListing {
  final String id;
  final String name;
  final String description;
  final String priceLabel;
  final String imagePath;
  final String sellerName;
  final String sellerEmail;
  final String sellerId;
  final String listingStatus;
  final String saleStatus;
  final String subcategoryId;
  final String subcategoryName;
  final String categoryId;

  const _CartListing({
    required this.id,
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.imagePath,
    required this.sellerName,
    required this.sellerEmail,
    required this.sellerId,
    required this.listingStatus,
    required this.saleStatus,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryId,
  });

  factory _CartListing.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final listingType = data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    String formattedPrice;
    if (listingType == 'donation' || parsedPrice <= 0) {
      formattedPrice = 'Free';
    } else {
      formattedPrice = formatRmPrice(parsedPrice);
    }

    return _CartListing(
      id: id,
      name: data['title']?.toString() ?? data['name']?.toString() ?? 'Item Name',
      description: data['description']?.toString() ?? 'Description',
      priceLabel: formattedPrice,
      imagePath: data['image_path']?.toString() ?? '',
      sellerName:
          data['seller_name']?.toString() ?? data['sellerName']?.toString() ?? 'Seller Name',
      sellerEmail: data['seller_email']?.toString() ??
          data['sellerEmail']?.toString() ??
          'seller@siswa.unimas.my',
      sellerId: data['seller_id']?.toString() ?? '',
      listingStatus: data['listing_status']?.toString() ?? '',
      saleStatus: data['sale_status']?.toString() ?? '',
      subcategoryId: data['subcategory_id']?.toString() ?? '',
      subcategoryName: data['subcategory_name']?.toString() ?? '',
      categoryId: data['category_id']?.toString() ?? '',
    );
  }

  Map<String, String> toDetailMap() {
    return {
      'id': id,
      'name': name,
      'price': priceLabel,
      'description': description,
      'imagePath': imagePath,
      'sellerName': sellerName,
      'sellerEmail': sellerEmail,
      'sellerId': sellerId,
      'listingStatus': listingStatus,
      'saleStatus': saleStatus,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'categoryId': categoryId,
    };
  }
}

