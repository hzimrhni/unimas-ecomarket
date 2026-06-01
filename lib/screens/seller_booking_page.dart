import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/price_formatter.dart';
import 'seller_booking_detail_page.dart';
import 'student_theme.dart';

class SellerBookingPage extends StatefulWidget {
  final String userId;

  const SellerBookingPage({super.key, required this.userId});

  @override
  State<SellerBookingPage> createState() => _SellerBookingPageState();
}

class _SellerBookingPageState extends State<SellerBookingPage> {
  bool isBookedSelected = true;

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final saleStatus = isBookedSelected ? 'booked' : 'completed';

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
                          'Manage Booking',
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
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(
                            label: 'Booked',
                            isSelected: isBookedSelected,
                            onTap: () {
                              setState(() {
                                isBookedSelected = true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildTab(
                            label: 'Completed',
                            isSelected: !isBookedSelected,
                            onTap: () {
                              setState(() {
                                isBookedSelected = false;
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
                    .where('seller_id', isEqualTo: widget.userId)
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
                      isBookedSelected
                          ? a.data()['booked_at']
                          : a.data()['completed_at'],
                    );
                    final bDate = _extractTimestamp(
                      isBookedSelected
                          ? b.data()['booked_at']
                          : b.data()['completed_at'],
                    );
                    return bDate.compareTo(aDate);
                  });

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        isBookedSelected
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
                      final item = _SellerBookingItem.fromDoc(
                        docs[index],
                        isBookedSelected: isBookedSelected,
                      );
                      return _buildBookingCard(context, item);
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

  Widget _buildBookingCard(BuildContext context, _SellerBookingItem item) {
    final colors = StudentThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerBookingDetailPage(
                listingId: item.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
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
                    const SizedBox(height: 4),
                    Text(
                      item.buyerLabel,
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

class _SellerBookingItem {
  final String id;
  final String name;
  final String priceLabel;
  final String imagePath;
  final String dateLabel;
  final String buyerLabel;

  const _SellerBookingItem({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.imagePath,
    required this.dateLabel,
    required this.buyerLabel,
  });

  factory _SellerBookingItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool isBookedSelected,
  }) {
    final data = doc.data();
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
      isBookedSelected ? data['booked_at'] : data['completed_at'],
    );
    final buyerEmail = (isBookedSelected
                ? data['booked_by_email']
                : data['receiver_email'])?.toString() ??
            data['booked_by_email']?.toString() ??
        'xxxxx@siswa.unimas.my';

    return _SellerBookingItem(
      id: doc.id,
      name: data['title']?.toString() ?? 'Item Name',
      priceLabel: priceLabel,
      imagePath: data['image_path']?.toString() ?? '',
      dateLabel:
          '${isBookedSelected ? 'Booked' : 'Completed'} at: ${_formatDate(date)}',
      buyerLabel:
          '${isBookedSelected ? 'Booked by' : 'Received by'}: $buyerEmail',
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
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
