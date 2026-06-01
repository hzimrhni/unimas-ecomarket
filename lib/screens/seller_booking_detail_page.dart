import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import '../utils/price_formatter.dart';
import 'seller_profile_page.dart';
import 'student_theme.dart';

class SellerBookingDetailPage extends StatelessWidget {
  final String listingId;

  const SellerBookingDetailPage({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Listing')
          .doc(listingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: Center(
              child: Text(
                "Couldn't load booking: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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

        final data = snapshot.data!.data();
        if (data == null) {
          return Scaffold(
            backgroundColor: colors.pageBackground,
            body: Center(
              child: Text(
                'This booking is no longer available.',
                style: TextStyle(color: colors.primaryText),
              ),
            ),
          );
        }

        final item = _SellerBookingDetail.fromMap(snapshot.data!.id, data);

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
                                border: Border.all(color: colors.border),
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
                                    return const Center(
                                      child: CircularProgressIndicator(),
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
                            border: Border.all(color: colors.border),
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
                                item.title,
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
                              _DetailBlock(
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
                              _DetailBlock(
                                label: item.saleStatus == 'completed'
                                    ? (item.isDonation
                                          ? 'Donated at:'
                                          : 'Sold at:')
                                    : 'Date and Time for Appointment:',
                                child: Text(
                                  item.statusDateLabel,
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
                                      item.saleStatus == 'completed'
                                          ? 'Received by:'
                                          : 'Booked by:',
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
                                              'sellerId': item.counterpartyId,
                                              'sellerName': item.counterpartyName,
                                              'sellerEmail': item.counterpartyEmail,
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
                                item.counterpartyName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.counterpartyEmail,
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
                if (item.saleStatus == 'booked')
                  Container(
                    color: colors.cardBackground,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 62,
                          child: ElevatedButton(
                            onPressed: () => _completeBooking(context, item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Complete Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 62,
                          child: ElevatedButton(
                            onPressed: () => _cancelBooking(context, item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1717),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelBooking(
    BuildContext context,
    _SellerBookingDetail item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _appendChatBookingStatusSnapshot(
        item: item,
        status: 'cancelled',
        lastMessageText: 'Booking cancelled',
      );
      await FirebaseFirestore.instance.collection('Listing').doc(item.id).update({
        'sale_status': 'available',
        'booked_by_id': null,
        'booked_by_name': null,
        'booked_by_email': null,
        'booked_at': null,
        'receiver_id': null,
        'receiver_name': null,
        'receiver_email': null,
        'completed_at': null,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'seller',
      });

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't cancel booking: $error")),
      );
    }
  }

  Future<void> _completeBooking(
    BuildContext context,
    _SellerBookingDetail item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Booking'),
          content: const Text('Are you sure you want to mark this booking as completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      double? efUsed;
      final categoryId = item.categoryId;
      final subcategoryId = item.subcategoryId;
      if (categoryId.isNotEmpty && subcategoryId.isNotEmpty) {
        final subcategoryDoc = await FirebaseFirestore.instance
            .collection('Category')
            .doc(categoryId)
            .collection('SubCategory')
            .doc(subcategoryId)
            .get();
        final rawEf = subcategoryDoc.data()?['ef_value'];
        efUsed = rawEf is num
            ? rawEf.toDouble()
            : double.tryParse(rawEf?.toString() ?? '');
      }

      await _appendChatBookingStatusSnapshot(
        item: item,
        status: 'completed',
        lastMessageText: 'Booking completed',
      );
      await FirebaseFirestore.instance.collection('Listing').doc(item.id).update({
        'sale_status': 'completed',
        'receiver_id': item.counterpartyId,
        'receiver_name': item.counterpartyName,
        'receiver_email': item.counterpartyEmail,
        'completed_at': FieldValue.serverTimestamp(),
        'ef_used': efUsed,
        'carbon_reduction': efUsed,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid ?? '',
        'updated_by_role': 'seller',
      });

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't complete booking: $error")),
      );
    }
  }

  Future<void> _appendChatBookingStatusSnapshot({
    required _SellerBookingDetail item,
    required String status,
    required String lastMessageText,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty || item.counterpartyId.isEmpty) {
      return;
    }

    final chatSnapshot = await FirebaseFirestore.instance
        .collection('Chat')
        .where('listing_id', isEqualTo: item.id)
        .where('seller_id', isEqualTo: currentUserId)
        .where('buyer_id', isEqualTo: item.counterpartyId)
        .limit(1)
        .get();

    if (chatSnapshot.docs.isEmpty) {
      return;
    }

    final chatDoc = chatSnapshot.docs.first;
    final chatRef = chatDoc.reference;
    final now = FieldValue.serverTimestamp();
    final messageRef = chatRef.collection('ChatMessage').doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(messageRef, {
      'message_id': messageRef.id,
      'chat_id': chatDoc.id,
      'sender_id': currentUserId,
      'sender_role': 'seller',
      'message_type': 'booking_request',
      'booking_request_status': status,
      'buyer_id': item.counterpartyId,
      'seller_id': currentUserId,
      'listing_id': item.id,
      'item_name': item.title,
      'item_price': item.priceLabel,
      'item_image_path': item.imagePath,
      if (item.appointmentDate.isNotEmpty) 'appointment_date': item.appointmentDate,
      if (item.appointmentTime.isNotEmpty) 'appointment_time': item.appointmentTime,
      'created_at': now,
    });
    batch.update(chatRef, {
      'last_message_text': lastMessageText,
      'last_message_sender_id': currentUserId,
      'last_message_at': now,
      'updated_at': now,
      'buyer_unread_count': FieldValue.increment(1),
    });
    await batch.commit();
  }
}

class _DetailBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailBlock({
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

class _SellerBookingDetail {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final String priceLabel;
  final String saleStatus;
  final bool isDonation;
  final String statusDateLabel;
  final String appointmentDate;
  final String appointmentTime;
  final String counterpartyId;
  final String counterpartyName;
  final String counterpartyEmail;
  final String categoryId;
  final String subcategoryId;

  const _SellerBookingDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.priceLabel,
    required this.saleStatus,
    required this.isDonation,
    required this.statusDateLabel,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.counterpartyId,
    required this.counterpartyName,
    required this.counterpartyEmail,
    required this.categoryId,
    required this.subcategoryId,
  });

  factory _SellerBookingDetail.fromMap(String id, Map<String, dynamic> data) {
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final listingType = data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final isDonation = listingType == 'donation' || listingType == 'donate';
    final saleStatus = data['sale_status']?.toString().toLowerCase() ?? 'available';
    final bookedAt = data['booked_at'] is Timestamp
        ? (data['booked_at'] as Timestamp).toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final completedAt = data['completed_at'] is Timestamp
        ? (data['completed_at'] as Timestamp).toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final isCompleted = saleStatus == 'completed';
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

    return _SellerBookingDetail(
      id: id,
      title: data['title']?.toString() ?? 'Item Name',
      description: data['description']?.toString() ?? 'Description',
      imagePath: data['image_path']?.toString() ?? '',
      priceLabel: isDonation || parsedPrice <= 0
          ? 'Free'
          : formatRmPrice(parsedPrice),
      saleStatus: saleStatus,
      isDonation: isDonation,
      statusDateLabel: isCompleted
          ? _formatDate(completedAt)
          : appointmentLabel,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      counterpartyId: isCompleted
          ? data['receiver_id']?.toString() ?? ''
          : data['booked_by_id']?.toString() ?? '',
      counterpartyName: isCompleted
          ? data['receiver_name']?.toString() ?? 'Buyer Name'
          : data['booked_by_name']?.toString() ?? 'Buyer Name',
      counterpartyEmail: isCompleted
          ? data['receiver_email']?.toString() ?? 'xxxxx@siswa.unimas.my'
          : data['booked_by_email']?.toString() ?? 'xxxxx@siswa.unimas.my',
      categoryId: data['category_id']?.toString() ?? '',
      subcategoryId: data['subcategory_id']?.toString() ?? '',
    );
  }
}

String _formatDate(DateTime date) {
  if (date == DateTime.fromMillisecondsSinceEpoch(0)) {
    return 'DD/MM/YYYY';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

