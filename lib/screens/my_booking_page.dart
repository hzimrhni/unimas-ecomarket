import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import '../utils/price_formatter.dart';
import 'seller_profile_page.dart';
import 'student_theme.dart';

class MyBookingPage extends StatefulWidget {
  final String userId;

  const MyBookingPage({super.key, required this.userId});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class BuyerBookingDetailPage extends StatelessWidget {
  final String listingId;
  final String userId;

  const BuyerBookingDetailPage({
    super.key,
    required this.listingId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('Listing').doc(listingId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: Center(
              child: Text(
                "Couldn't load booking: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: Center(
              child: Text(
                'Booking not found.',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
          );
        }

        if ((data['booked_by_id']?.toString() ?? '') != userId) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: Center(
              child: Text(
                'This booking is not available.',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
          );
        }

        final saleStatus = data['sale_status']?.toString().toLowerCase() ?? 'booked';
        final item = _BuyerBookingItem.fromData(
          data,
          id: listingId,
          showBooked: saleStatus != 'completed',
        );

        return _BuyerBookingDetailPage(
          item: item,
          userId: userId,
        );
      },
    );
  }
}

class _MyBookingPageState extends State<MyBookingPage> {
  bool showBooked = true;

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final saleStatus = showBooked ? 'booked' : 'completed';

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          'My Booking',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.softBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(
                            label: 'Booked',
                            isSelected: showBooked,
                            onTap: () {
                              setState(() {
                                showBooked = true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildTab(
                            label: 'Completed',
                            isSelected: !showBooked,
                            onTap: () {
                              setState(() {
                                showBooked = false;
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Listing')
                    .where('booked_by_id', isEqualTo: widget.userId)
                    .where('sale_status', isEqualTo: saleStatus)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Couldn't load bookings: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs.toList() ?? [];
                  docs.sort((a, b) {
                    final aDate = _extractTimestamp(
                      showBooked ? a.data()['booked_at'] : a.data()['completed_at'],
                    );
                    final bDate = _extractTimestamp(
                      showBooked ? b.data()['booked_at'] : b.data()['completed_at'],
                    );
                    return bDate.compareTo(aDate);
                  });

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        showBooked
                            ? 'No booked items yet.'
                            : 'No completed bookings yet.',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.secondaryText,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _BuyerBookingItem.fromDoc(
                        docs[index],
                        showBooked: showBooked,
                      );
                      return _buildBookingCard(item);
                    },
                  );
                },
              ),
            ),
          ],
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          size: 24,
          color: colors.icon,
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
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
        alignment: Alignment.center,
        child: Text(
          label,
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

  Widget _buildBookingCard(_BuyerBookingItem item) {
    final colors = StudentThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _BuyerBookingDetailPage(
              item: item,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _BookingImage(imagePath: item.imagePath),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2F6BFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.dateLabel,
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
    );
  }
}

class _BuyerBookingItem {
  final String id;
  final String name;
  final String priceLabel;
  final String imagePath;
  final String dateLabel;
  final String detailDateLabel;
  final String appointmentDate;
  final String appointmentTime;
  final String description;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final bool isCompleted;

  const _BuyerBookingItem({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.imagePath,
    required this.dateLabel,
    required this.detailDateLabel,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.description,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.isCompleted,
  });

  factory _BuyerBookingItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool showBooked,
  }) {
    return _BuyerBookingItem.fromData(
      doc.data(),
      id: doc.id,
      showBooked: showBooked,
    );
  }

  factory _BuyerBookingItem.fromData(
    Map<String, dynamic> data, {
    required String id,
    required bool showBooked,
  }) {
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final listingType = data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final isDonation = listingType == 'donation' || listingType == 'donate';
    final priceLabel = isDonation || parsedPrice <= 0
        ? 'Free'
        : formatRmPrice(parsedPrice);
    final date = _extractTimestamp(
      showBooked ? data['booked_at'] : data['completed_at'],
    );
    final appointmentDate = data['appointment_date']?.toString() ?? '';
    final appointmentTime = data['appointment_time']?.toString() ?? '';
    final appointmentLabel =
        appointmentDate.isNotEmpty && appointmentTime.isNotEmpty
            ? '$appointmentDate at $appointmentTime'
            : appointmentDate.isNotEmpty
                ? appointmentDate
                : appointmentTime.isNotEmpty
                    ? appointmentTime
                    : 'DD/MM/YYYY at --:--';

    return _BuyerBookingItem(
      id: id,
      name: data['title']?.toString() ?? 'Item Name',
      priceLabel: priceLabel,
      imagePath: data['image_path']?.toString() ?? '',
      dateLabel: showBooked
          ? 'Date and Time for Appointment: $appointmentLabel'
          : 'Completed at: ${_formatDate(date)}',
      detailDateLabel:
          showBooked ? 'Date and Time for Appointment:' : 'Completed at:',
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      description: data['description']?.toString() ?? 'Item description goes here',
      sellerId: data['seller_id']?.toString() ?? '',
      sellerName: data['seller_name']?.toString() ?? 'Seller Name',
      sellerEmail: data['seller_email']?.toString() ?? 'xxxxx@siswa.unimas.my',
      isCompleted: !showBooked,
    );
  }
}

class _BuyerBookingDetailPage extends StatelessWidget {
  final _BuyerBookingItem item;
  final String userId;

  const _BuyerBookingDetailPage({
    required this.item,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: colors.cardBackground,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: colors.icon),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.softBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imagePath.isEmpty
                          ? Center(
                              child: Text(
                                'Picture',
                                style: TextStyle(
                                  color: colors.tertiaryText,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : Image.network(
                              item.imagePath,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: colors.tertiaryText,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  'Picture',
                                  style: TextStyle(
                                    color: colors.tertiaryText,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.priceLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F6BFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _BuyerDetailBlock(
                            label: 'Description:',
                            child: Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: colors.primaryText,
                              ),
                            ),
                          ),
                          Divider(height: 34, color: colors.divider),
                          _BuyerDetailBlock(
                            label: item.detailDateLabel,
                            child: Text(
                              item.detailDateLabel == 'Date and Time for Appointment:'
                                  ? item.dateLabel.replaceFirst(
                                      'Date and Time for Appointment: ', '',
                                    )
                                  : item.dateLabel.replaceFirst(
                                      'Completed at: ',
                                      '',
                                    ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.primaryText,
                              ),
                            ),
                          ),
                          Divider(height: 34, color: colors.divider),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Seller details:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.secondaryText,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SellerProfilePage(
                                        seller: {
                                          'sellerId': item.sellerId,
                                          'sellerName': item.sellerName,
                                          'sellerEmail': item.sellerEmail,
                                        },
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFEAF1FF),
                                  foregroundColor: const Color(0xFF2F6BFF),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.sellerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.sellerEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.secondaryText,
                            ),
                          ),
                          if (item.isCompleted) ...[
                            Divider(height: 34, color: colors.divider),
                            _BuyerReviewSection(
                              listingId: item.id,
                              sellerId: item.sellerId,
                              sellerName: item.sellerName,
                              reviewerId: userId,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerDetailBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _BuyerDetailBlock({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: colors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _BuyerReviewSection extends StatefulWidget {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String reviewerId;

  const _BuyerReviewSection({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.reviewerId,
  });

  @override
  State<_BuyerReviewSection> createState() => _BuyerReviewSectionState();
}

class _BuyerReviewSectionState extends State<_BuyerReviewSection> {
  int? _draftRating;
  bool _isSaving = false;

  String get reviewId => '${widget.listingId}_${widget.reviewerId}';

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewId)
          .snapshots(),
      builder: (context, snapshot) {
        final existing = snapshot.data?.data();
        final rating = existing?['rating'] is num
            ? (existing!['rating'] as num).toInt()
            : int.tryParse('${existing?['rating'] ?? ''}') ?? 0;
        final selectedRating = _draftRating ?? rating;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(24),
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
                  Text(
                    'Rate the Seller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Wrap(
                        spacing: 6,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _draftRating = star;
                              });
                            },
                            child: Icon(
                              selectedRating >= star
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 40,
                              color: const Color(0xFFFFC107),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving || selectedRating == 0
                    ? null
                    : () async {
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          final reviewerDoc = await FirebaseFirestore.instance
                              .collection('User')
                              .doc(widget.reviewerId)
                              .get();
                          final reviewerName =
                              reviewerDoc.data()?['name']?.toString() ?? 'Buyer';

                          await FirebaseFirestore.instance
                              .collection('Review')
                              .doc(reviewId)
                              .set({
                            'review_id': reviewId,
                            'listing_id': widget.listingId,
                            'seller_id': widget.sellerId,
                            'seller_name': widget.sellerName,
                            'reviewer_id': widget.reviewerId,
                            'reviewer_name': reviewerName,
                            'rating': selectedRating,
                            'created_at': existing == null
                                ? FieldValue.serverTimestamp()
                                : existing['created_at'] ??
                                    FieldValue.serverTimestamp(),
                            'updated_at': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (mounted) {
                            showTopSnackBarFromSnackBar(context, 
                              SnackBar(
                                content: Text(
                                  existing == null
                                      ? 'Review submitted successfully.'
                                      : 'Review updated successfully.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6BFF),
                  disabledBackgroundColor: colors.softBackground,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: colors.secondaryText,
                  elevation: 12,
                  shadowColor: const Color(0x332F6BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : existing == null
                          ? 'Submit Review'
                          : 'Update Review',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingImage extends StatelessWidget {
  final String imagePath;

  const _BookingImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: 102,
      height: 102,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? Center(
              child: Text(
                'Picture',
                style: TextStyle(
                  color: colors.tertiaryText,
                  fontSize: 16,
                ),
              ),
            )
          : Image.network(
              imagePath,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.tertiaryText,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  'Picture',
                  style: TextStyle(
                    color: colors.tertiaryText,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
    );
  }
}

DateTime _extractTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatDate(DateTime date) {
  if (date == DateTime.fromMillisecondsSinceEpoch(0)) {
    return 'DD/MM/YYYY';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

