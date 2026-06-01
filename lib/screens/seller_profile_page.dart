import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/price_formatter.dart';
import 'item_detail_page.dart';
import 'report_user_page.dart';
import 'student_theme.dart';

class SellerProfilePage extends StatefulWidget {
  final Map<String, String> seller;

  const SellerProfilePage({
    super.key,
    required this.seller,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  Map<String, dynamic>? sellerData;
  bool isLoading = true;

  String get sellerId => widget.seller['sellerId'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    if (sellerId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        sellerData = null;
        isLoading = false;
      });
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('User').doc(sellerId).get();

      if (!mounted) {
        return;
      }

      setState(() {
        sellerData = doc.data();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        sellerData = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final sellerName = sellerData?['name']?.toString() ??
        widget.seller['sellerName'] ??
        'Seller Name';
    final sellerEmail = sellerData?['unimas_email']?.toString() ??
        widget.seller['sellerEmail'] ??
        'xxxxx@siswa.unimas.my';
    final phone = sellerData?['phone']?.toString() ?? '+60 12-345 6789';
    final college = sellerData?['college']?.toString() ?? 'College Name';
    final faculty = sellerData?['faculty']?.toString() ?? 'Faculty Name';
    final yearLabel =
        sellerData?['year_of_study']?.toString() ?? 'Not completed';

    return Scaffold(
      backgroundColor: colors.pageBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
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
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                final submitted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportUserPage(
                      seller: {
                        ...widget.seller,
                        'sellerName': sellerName,
                        'sellerEmail': sellerEmail,
                        'sellerId': sellerId,
                      },
                    ),
                  ),
                );
                if (submitted == true && context.mounted) {
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
                backgroundColor: const Color(0xFFFF1010),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: const Color(0x33FF1010),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.report_gmailerrorred_outlined, size: 24),
              label: const Text(
                'Report User',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
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
                        'User Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                             sellerName,
                            style: TextStyle(
                               fontSize: 22,
                               fontWeight: FontWeight.w800,
                               color: colors.primaryText,
                             ),
                           ),
                          const SizedBox(height: 18),
                          _infoRow('Email', sellerEmail),
                          _divider(),
                          _infoRow(
                            'Phone Number',
                            phone,
                            onTap: () => _showPhoneActions(phone),
                            valueColor: const Color(0xFF2F6BFF),
                          ),
                          _divider(),
                          _infoRow('College', college),
                          _divider(),
                          _infoRow('Faculty', faculty),
                          _divider(),
                          _infoRow('Year of Study', yearLabel, showDivider: false),
                        ],
                      ),
              ),
              const SizedBox(height: 28),
              Text(
                'User Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 18),
              _buildUserActivitySection(),
              const SizedBox(height: 28),
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 18),
              _buildReviewSection(),
              const SizedBox(height: 28),
              Text(
                'User Item List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 260,
                child: sellerId.isEmpty
                    ? Center(
                        child: Text(
                          'No item available.',
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.secondaryText,
                          ),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('Listing')
                            .where('seller_id', isEqualTo: sellerId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Couldn't load seller items.",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final items = snapshot.data?.docs
                                  .map((doc) => _SellerProfileItem.fromDoc(doc))
                                  .where((item) {
                                final listingStatus =
                                    item.listingStatus.toLowerCase();
                                final saleStatus =
                                    item.saleStatus.toLowerCase();
                                final sellerStatus =
                                    item.sellerStatus.toLowerCase();
                                return listingStatus == 'approved' &&
                                    saleStatus != 'removed' &&
                                    saleStatus != 'booked' &&
                                    saleStatus != 'completed' &&
                                    sellerStatus != 'suspended';
                              }).toList() ??
                              [];

                          if (items.isEmpty) {
                            return Center(
                              child: Text(
                                'No item available.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colors.secondaryText,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildSellerItemCard(context, item);
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

  Widget _buildUserActivitySection() {
    if (sellerId.isEmpty) {
      return _buildActivityCard(
        purchases: '0',
        sales: '0',
        donations: '0',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Listing')
          .where('seller_id', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, sellerListingSnapshot) {
        final sellerListings = sellerListingSnapshot.data?.docs ?? [];
        final completedSellerListings = sellerListings.where((doc) {
          final status = doc.data()['sale_status']?.toString().toLowerCase() ?? '';
          return status == 'completed';
        }).toList();

        final salesCount = completedSellerListings.where((doc) {
          final type = doc.data()['listing_type']?.toString().toLowerCase() ?? '';
          return type == 'sell' || type == 'sale';
        }).length;

        final donationCount = completedSellerListings.where((doc) {
          final type = doc.data()['listing_type']?.toString().toLowerCase() ?? '';
          return type == 'donation' || type == 'donate';
        }).length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Listing')
              .where('booked_by_id', isEqualTo: sellerId)
              .where('sale_status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, purchaseSnapshot) {
            final purchasesCount = purchaseSnapshot.data?.docs.length ?? 0;

            return _buildActivityCard(
              purchases: '$purchasesCount',
              sales: '$salesCount',
              donations: '$donationCount',
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String purchases,
    required String sales,
    required String donations,
  }) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
          Row(
            children: [
              Expanded(
                child: _ActivityStatBox(
                  label: 'Total Purchases',
                  value: purchases,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActivityStatBox(
                  label: 'Total Sales',
                  value: sales,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActivityStatBox(
                  label: 'Total Donations',
                  value: donations,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    final colors = StudentThemeColors.of(context);
    if (sellerId.isEmpty) {
      return _buildReviewCard(
        average: 0,
        totalReviews: 0,
        counts: const {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Review')
          .where('seller_id', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
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
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        var total = 0;
        for (final doc in docs) {
          final raw = doc.data()['rating'];
          final rating = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
          if (counts.containsKey(rating)) {
            counts[rating] = counts[rating]! + 1;
            total += rating;
          }
        }
        final totalReviews = counts.values.fold<int>(0, (sum, count) => sum + count);
        final average = totalReviews == 0 ? 0.0 : total / totalReviews;

        return _buildReviewCard(
          average: average,
          totalReviews: totalReviews,
          counts: counts,
        );
      },
    );
  }

  Widget _buildReviewCard({
    required double average,
    required int totalReviews,
    required Map<int, int> counts,
  }) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StaticStarRow(rating: average),
                    const SizedBox(height: 6),
                    Text(
                      totalReviews == 0
                          ? 'Based on 0 reviews'
                          : 'Based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final star in [5, 4, 3, 2, 1])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewBarRow(
                star: star,
                count: counts[star] ?? 0,
                totalReviews: totalReviews,
              ),
            ),
        ],
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

  Future<void> _showPhoneActions(String phone) async {
    final colors = StudentThemeColors.of(context);
    final callPhone = _normalizePhoneForCall(phone);
    final whatsappPhone = _normalizePhoneForWhatsApp(phone);

    if (callPhone.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                _phoneActionTile(
                  context,
                  icon: Icons.call_outlined,
                  title: 'Phone Call',
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri(scheme: 'tel', path: callPhone);
                    if (!await launchUrl(uri)) {
                      _showLaunchError('Unable to open phone app.');
                    }
                  },
                ),
                const SizedBox(height: 10),
                _phoneActionTile(
                  context,
                  iconWidget: Image.asset(
                    'assets/whatsapp_icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  title: 'WhatsApp Call',
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse('https://wa.me/$whatsappPhone');
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      _showLaunchError('Unable to open WhatsApp.');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _phoneActionTile(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = StudentThemeColors.of(context);
    return Material(
      color: colors.softBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              iconWidget ?? Icon(icon, color: colors.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizePhoneForCall(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) {
      return digits;
    }
    if (digits.startsWith('60')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+6$digits';
    }
    return digits;
  }

  String _normalizePhoneForWhatsApp(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('60')) {
      return digits;
    }
    if (digits.startsWith('0')) {
      return '6$digits';
    }
    return digits;
  }

  void _showLaunchError(String message) {
    if (!mounted) {
      return;
    }
    showTopSnackBarFromSnackBar(context, 
      SnackBar(content: Text(message)),
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

  Widget _infoRow(
    String label,
    String value, {
    bool showDivider = true,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final colors = StudentThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: colors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? colors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerItemCard(BuildContext context, _SellerProfileItem item) {
    final colors = StudentThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailPage(item: item.toItemDetailMap(widget.seller)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
      child: Container(
      width: 170,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: _SellerItemImage(imagePath: item.imagePath),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
      ),
    );
  }
}

class _StaticStarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StaticStarRow({
    required this.rating,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        IconData icon;
        if (rating >= starNumber) {
          icon = Icons.star_rounded;
        } else if (rating >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(
          icon,
          size: size,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }
}

class _ReviewBarRow extends StatelessWidget {
  final int star;
  final int count;
  final int totalReviews;

  const _ReviewBarRow({
    required this.star,
    required this.count,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final ratio = totalReviews == 0 ? 0.0 : count / totalReviews;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$star★',
            style: TextStyle(
              fontSize: 14,
              color: colors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: colors.softBackground,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC107)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 18,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: colors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _SellerProfileItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String listingType;
  final String listingStatus;
  final String saleStatus;
  final String sellerStatus;
  final String categoryId;
  final String subcategoryId;
  final String subcategoryName;

  const _SellerProfileItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.listingType,
    required this.listingStatus,
    required this.saleStatus,
    required this.sellerStatus,
    required this.categoryId,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  factory _SellerProfileItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return _SellerProfileItem(
      id: doc.id,
      name: data['title']?.toString() ??
          data['name']?.toString() ??
          'Item Name',
      description: data['description']?.toString() ?? 'Description',
      price: parsedPrice,
      imagePath: data['image_path']?.toString() ?? '',
      listingType: data['listing_type']?.toString().toLowerCase() ?? 'sell',
      listingStatus: data['listing_status']?.toString() ?? 'pending',
      saleStatus: data['sale_status']?.toString() ?? 'available',
      sellerStatus: data['seller_status']?.toString() ?? 'active',
      categoryId: data['category_id']?.toString() ?? '',
      subcategoryId: data['subcategory_id']?.toString() ?? '',
      subcategoryName: data['subcategory_name']?.toString() ?? '',
    );
  }

  String get formattedPrice {
    if (listingType == 'donate' || listingType == 'donation' || price <= 0) {
      return 'Free';
    }
    return formatRmPrice(price);
  }

  Map<String, String> toItemDetailMap(Map<String, String> seller) {
    return {
      'id': id,
      'name': name,
      'price': formattedPrice,
      'description': description,
      'imagePath': imagePath,
      'sellerName': seller['sellerName'] ?? 'Seller Name',
      'sellerEmail': seller['sellerEmail'] ?? 'xxxxx@siswa.unimas.my',
      'sellerId': seller['sellerId'] ?? '',
      'listingStatus': listingStatus,
      'saleStatus': saleStatus,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
    };
  }
}

class _SellerItemImage extends StatelessWidget {
  final String imagePath;

  const _SellerItemImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return Container(
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
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      color: colors.softBackground,
      alignment: Alignment.center,
      child: Text(
        'Picture',
        style: TextStyle(
          fontSize: 16,
          color: colors.tertiaryText,
        ),
      ),
    );
  }
}

class _ActivityStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _ActivityStatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

