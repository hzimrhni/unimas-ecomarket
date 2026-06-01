import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import 'chat_detail_page.dart';
import 'report_item_page.dart';
import 'seller_profile_page.dart';
import 'student_theme.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, String> item;

  const ItemDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool showReportAction = false;
  bool isAddingToCart = false;
  bool isOpeningChat = false;

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final item = widget.item;
    final currentUser = FirebaseAuth.instance.currentUser;
    final listingId = item['id'] ?? '';
    final initialSaleStatus = (item['saleStatus'] ?? '').toLowerCase();

    return Scaffold(
      backgroundColor: colors.pageBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: listingId.isEmpty
              ? null
              : FirebaseFirestore.instance
                  .collection('Listing')
                  .doc(listingId)
                  .snapshots(),
          builder: (context, listingSnapshot) {
            final liveSaleStatus =
                listingSnapshot.data?.data()?['sale_status']?.toString().toLowerCase() ??
                    initialSaleStatus;
            final isUnavailable =
                liveSaleStatus == 'completed' || liveSaleStatus == 'removed';

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border: Border(
                  top: BorderSide(color: colors.divider),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: isUnavailable
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.softBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        liveSaleStatus == 'removed'
                            ? 'This item has been removed'
                            : 'This item is not available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.secondaryText,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: isOpeningChat ? null : _openOrCreateChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F6BFF),
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: const Color(0x332F6BFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: isOpeningChat
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.chat_bubble_outline, size: 22),
                              label: Text(
                                isOpeningChat ? 'Opening...' : 'Chat Seller',
                                style: const TextStyle(
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
                            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: currentUser == null || listingId.isEmpty
                                  ? null
                                  : FirebaseFirestore.instance
                                      .collection('User')
                                      .doc(currentUser.uid)
                                      .collection('Cart')
                                      .doc(listingId)
                                      .snapshots(),
                              builder: (context, snapshot) {
                                final isInCart = snapshot.data?.exists ?? false;

                                if (isInCart) {
                                  return ElevatedButton.icon(
                                    onPressed: isAddingToCart ? null : _removeFromCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF1414),
                                      foregroundColor: Colors.white,
                                      elevation: 10,
                                      shadowColor: const Color(0x33FF1414),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      size: 24,
                                    ),
                                    label: const Text(
                                      'Remove from Cart',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }

                                return OutlinedButton.icon(
                                  onPressed: isAddingToCart ? null : _addToCart,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primaryText,
                                    side: BorderSide(
                                      color: colors.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 24,
                                  ),
                                  label: const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (showReportAction) {
                          setState(() {
                            showReportAction = false;
                          });
                        }
                      },
                      child: _ItemPreviewImage(
                        imagePath: item['imagePath'] ?? '',
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 8,
                      child: _circleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 8,
                      child: _circleIconButton(
                        icon: Icons.more_vert,
                        onTap: () {
                          setState(() {
                            showReportAction = !showReportAction;
                          });
                        },
                      ),
                    ),
                    if (showReportAction)
                      Positioned(
                        top: 60,
                        right: 8,
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              setState(() {
                                showReportAction = false;
                              });
                              final submitted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportItemPage(item: widget.item),
                                ),
                              );
                              if (submitted == true && mounted) {
                                showTopSnackBarFromSnackBar(context, 
                                  const SnackBar(
                                    content: Text(
                                      'Your report has been submitted successfully.',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1414),
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: const Color(0x33FF1414),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(
                              Icons.warning_amber_rounded,
                              size: 22,
                            ),
                            label: const Text(
                              'Report Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Item Name',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryText,
                    ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['price'] ?? 'RM0.00',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F6BFF),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      item['description'] ?? 'Description',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: colors.primaryText,
                    ),
                  ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Sell by:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primaryText,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => openSellerProfile(context),
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2F6BFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['sellerName'] ?? 'Seller Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => openSellerProfile(context),
                            child: Text(
                              item['sellerEmail'] ?? 'xxxxx@siswa.unimas.my',
                              style: TextStyle(
                                fontSize: 15,
                                color: colors.secondaryText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SellerReviewSummary(
                            sellerId: item['sellerId'] ?? '',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: colors.icon),
        onPressed: onTap,
      ),
    );
  }

  Future<void> openSellerProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfilePage(seller: widget.item),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    final listingId = widget.item['id'] ?? '';

    if (user == null || listingId.isEmpty) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Unable to add this item to cart.')),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final listingDoc = await FirebaseFirestore.instance
          .collection('Listing')
          .doc(listingId)
          .get();
      final saleStatus =
          listingDoc.data()?['sale_status']?.toString().toLowerCase() ?? '';

      if (!mounted) {
        return;
      }

      if (saleStatus == 'booked' || saleStatus == 'completed') {
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Item Unavailable'),
              content: Text(
                saleStatus == 'removed'
                    ? 'This item has been removed.'
                    : saleStatus == 'completed'
                        ? 'This item is not available.'
                        : 'This item is being booked by another user.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('Cart')
          .doc(listingId)
          .set({
        'user_id': user.uid,
        'listing_id': listingId,
        'added_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Item added to cart.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Failed to add item to cart.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _openOrCreateChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final listingId = widget.item['id'] ?? '';
    final sellerId = widget.item['sellerId'] ?? '';

    if (currentUser == null || listingId.isEmpty || sellerId.isEmpty) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Unable to open chat for this item.')),
      );
      return;
    }

    if (currentUser.uid == sellerId) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text("You can't chat about your own item.")),
      );
      return;
    }

    setState(() {
      isOpeningChat = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final buyerName = userData['name']?.toString().trim().isNotEmpty == true
          ? userData['name'].toString().trim()
          : 'Buyer Name';
      final buyerEmail =
          userData['unimas_email']?.toString() ?? currentUser.email ?? '';

      final sellerName = widget.item['sellerName'] ?? 'Seller Name';
      final sellerEmail =
          widget.item['sellerEmail'] ?? 'seller@siswa.unimas.my';

      final chatId = '${listingId}_${currentUser.uid}_$sellerId';
      final chatRef = FirebaseFirestore.instance.collection('Chat').doc(chatId);
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'chat_id': chatId,
        'listing_id': listingId,
        'buyer_id': currentUser.uid,
        'buyer_name': buyerName,
        'buyer_email': buyerEmail,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'seller_email': sellerEmail,
        'item_name': widget.item['name'] ?? 'Item Name',
        'item_price': widget.item['price'] ?? 'RM0.00',
        'item_image_path': widget.item['imagePath'] ?? '',
        'item_description': widget.item['description'] ?? 'Description',
        'updated_at': now,
      };

      await chatRef.set(payload, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            chat: {
              'chatId': chatId,
              'chatRole': 'buying',
              'currentUserId': currentUser.uid,
              'buyerId': currentUser.uid,
              'sellerId': sellerId,
              'buyerName': buyerName,
              'buyerEmail': buyerEmail,
              'sellerName': sellerName,
              'sellerEmail': sellerEmail,
              'displayName': sellerName,
              'itemId': listingId,
              'itemName': widget.item['name'] ?? 'Item Name',
                'itemPrice': widget.item['price'] ?? 'RM0.00',
              'itemImagePath': widget.item['imagePath'] ?? '',
              'itemDescription': widget.item['description'] ?? 'Description',
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't open chat: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningChat = false;
        });
      }
    }
  }

  Future<void> _removeFromCart() async {
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

    final user = FirebaseAuth.instance.currentUser;
    final listingId = widget.item['id'] ?? '';

    if (user == null || listingId.isEmpty) {
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Unable to remove this item from cart.')),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('Cart')
          .doc(listingId)
          .delete();

      if (!mounted) {
        return;
      }

      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Item removed from cart.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('Failed to remove item from cart.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

}

class _SellerReviewSummary extends StatelessWidget {
  final String sellerId;

  const _SellerReviewSummary({
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (sellerId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Review')
          .where('seller_id', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var totalReviews = 0;
        var totalRating = 0;

        for (final doc in docs) {
          final raw = doc.data()['rating'];
          final rating = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
          if (rating >= 1 && rating <= 5) {
            totalReviews += 1;
            totalRating += rating;
          }
        }

        final average = totalReviews == 0 ? 0.0 : totalRating / totalReviews;

        return Row(
          children: [
            Wrap(
              spacing: 1,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                IconData icon;
                if (average >= starNumber) {
                  icon = Icons.star_rounded;
                } else if (average >= starNumber - 0.5) {
                  icon = Icons.star_half_rounded;
                } else {
                  icon = Icons.star_border_rounded;
                }

                return Icon(
                  icon,
                  size: 22,
                  color: const Color(0xFFFFC107),
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              average.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.primaryText,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($totalReviews review${totalReviews == 1 ? '' : 's'})',
              style: TextStyle(
                fontSize: 15,
                color: colors.secondaryText,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ItemPreviewImage extends StatelessWidget {
  final String imagePath;

  const _ItemPreviewImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(24),
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
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(24),
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

