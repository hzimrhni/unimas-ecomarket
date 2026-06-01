import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chats_page.dart';
import 'home_page.dart';
import 'my_booking_page.dart';
import 'profile_page.dart';
import 'student_theme.dart';

class MainPage extends StatefulWidget {
  final String userId;

  const MainPage({super.key, required this.userId});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const String _seenBookingAlertsPrefsKey = 'seen_booking_alert_keys';
  int currentIndex = 1;
  late List<Widget> pages;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _acceptedBookingAlertSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _bookingStatusAlertSubscription;
  final Set<String> _seenBookingAlerts = <String>{};
  final List<_BookingAlertData> _bookingAlertQueue = <_BookingAlertData>[];
  bool _bookingAlertsInitialized = false;
  bool _showingBookingAlert = false;

  @override
  void initState() {
    super.initState();
    pages = [
      const ChatsPage(),
      HomePage(userId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];
    _initializeBookingAlerts();
  }

  @override
  void dispose() {
    _acceptedBookingAlertSubscription?.cancel();
    _bookingStatusAlertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeBookingAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    _seenBookingAlerts.addAll(
      prefs.getStringList(_seenBookingAlertsPrefsKey) ?? const <String>[],
    );

    if (!mounted) {
      return;
    }

    _bookingAlertsInitialized = true;
    _listenForBookingAlerts();
  }

  void _listenForBookingAlerts() {
    _listenForAcceptedBookingAlerts();
    _listenForBookingStatusAlerts();
  }

  void _listenForAcceptedBookingAlerts() {
    _acceptedBookingAlertSubscription = FirebaseFirestore.instance
        .collection('Listing')
        .where('booked_by_id', isEqualTo: widget.userId)
        .where('sale_status', isEqualTo: 'booked')
        .snapshots()
        .listen((snapshot) {
          if (!_bookingAlertsInitialized) {
            return;
          }
          final alerts = snapshot.docs
              .map((doc) => _BookingAlertData.fromDoc(doc))
              .where((alert) => alert.alertKey.isNotEmpty)
              .toList();

          for (final alert in alerts) {
            if (!_seenBookingAlerts.contains(alert.alertKey) &&
                !_bookingAlertQueue.any(
                  (queued) => queued.alertKey == alert.alertKey,
                )) {
              _bookingAlertQueue.add(alert);
            }
          }

          _showNextBookingAlertIfNeeded();
        });
  }

  void _listenForBookingStatusAlerts() {
    _bookingStatusAlertSubscription = FirebaseFirestore.instance
        .collection('Chat')
        .where('buyer_id', isEqualTo: widget.userId)
        .snapshots()
        .listen((snapshot) {
          if (!_bookingAlertsInitialized) {
            return;
          }
          final alerts = snapshot.docs
              .map((doc) => _BookingAlertData.fromChatDoc(doc))
              .where(
                (alert) =>
                    alert.alertKey.isNotEmpty &&
                    (alert.status == 'completed' || alert.status == 'cancelled'),
              )
              .toList();

          for (final alert in alerts) {
            if (!_seenBookingAlerts.contains(alert.alertKey) &&
                !_bookingAlertQueue.any(
                  (queued) => queued.alertKey == alert.alertKey,
                )) {
              _bookingAlertQueue.add(alert);
            }
          }

          _showNextBookingAlertIfNeeded();
        });
  }

  void _showNextBookingAlertIfNeeded() {
    if (!mounted || _showingBookingAlert || _bookingAlertQueue.isEmpty) {
      return;
    }

    _showingBookingAlert = true;
    final alert = _bookingAlertQueue.removeAt(0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _showingBookingAlert = false;
        return;
      }

      await _markBookingAlertSeen(alert.alertKey);

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final colors = StudentThemeColors.of(dialogContext);
          return AlertDialog(
            backgroundColor: colors.cardBackground,
            title: Text(
              alert.dialogTitle,
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              alert.dialogBody,
              style: TextStyle(
                color: colors.primaryText,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'later'),
                child: Text(alert.secondaryButtonLabel),
              ),
              if (alert.canViewDetails)
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'view'),
                  child: const Text('View Booking Details'),
                ),
            ],
          );
        },
      );

      _showingBookingAlert = false;

      if (!mounted) {
        return;
      }

      if (result == 'view') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerBookingDetailPage(
              listingId: alert.listingId,
              userId: widget.userId,
            ),
          ),
        );
      }

      _showNextBookingAlertIfNeeded();
    });
  }

  Future<void> _markBookingAlertSeen(String alertKey) async {
    if (alertKey.isEmpty || _seenBookingAlerts.contains(alertKey)) {
      return;
    }

    _seenBookingAlerts.add(alertKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _seenBookingAlertsPrefsKey,
      _seenBookingAlerts.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('Chat')
            .where('buyer_id', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, buyingSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('Chat')
                .where('seller_id', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, sellingSnapshot) {
              final hasBuyingUnread = buyingSnapshot.data?.docs.any(
                    (doc) =>
                        ((doc.data()['buyer_unread_count'] as num?)?.toInt() ??
                            0) >
                        0,
                  ) ??
                  false;
              final hasSellingUnread = sellingSnapshot.data?.docs.any(
                    (doc) =>
                        ((doc.data()['seller_unread_count'] as num?)?.toInt() ??
                            0) >
                        0,
                  ) ??
                  false;

              return BottomNavigationBar(
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: colors.navBackground,
                selectedItemColor: const Color(0xFF2F6BFF),
                unselectedItemColor: colors.tertiaryText,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_bubble_outline),
                        if (hasBuyingUnread || hasSellingUnread)
                          const Positioned(
                            right: -1,
                            top: -1,
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF2F6BFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Chat',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingAlertData {
  final String listingId;
  final String itemName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String alertKey;

  const _BookingAlertData({
    required this.listingId,
    required this.itemName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.alertKey,
  });

  factory _BookingAlertData.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final listingId = doc.id;
    final appointmentDate = data['appointment_date']?.toString() ?? '';
    final appointmentTime = data['appointment_time']?.toString() ?? '';
    final bookedAtValue = data['booked_at'];
    final bookedAtKey = bookedAtValue is Timestamp
        ? bookedAtValue.toDate().millisecondsSinceEpoch.toString()
        : bookedAtValue?.toString() ?? '';

    return _BookingAlertData(
      listingId: listingId,
      itemName: data['title']?.toString() ?? 'Item Name',
      appointmentDate: appointmentDate.isEmpty ? '-' : appointmentDate,
      appointmentTime: appointmentTime.isEmpty ? '-' : appointmentTime,
      status: 'accepted',
      alertKey: '$listingId|$bookedAtKey',
    );
  }

  factory _BookingAlertData.fromChatDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final listingId = data['listing_id']?.toString() ?? '';
    final lastMessageText = data['last_message_text']?.toString().toLowerCase() ?? '';
    final status = lastMessageText.contains('completed')
        ? 'completed'
        : lastMessageText.contains('cancelled')
            ? 'cancelled'
            : '';
    final appointmentDate = '';
    final appointmentTime = '';
    final updatedAtValue = data['updated_at'] ?? data['last_message_at'];
    final updatedAtKey = updatedAtValue is Timestamp
        ? updatedAtValue.toDate().millisecondsSinceEpoch.toString()
        : doc.id;

    return _BookingAlertData(
      listingId: listingId,
      itemName: data['item_name']?.toString() ?? 'Item Name',
      appointmentDate: appointmentDate.isEmpty ? '-' : appointmentDate,
      appointmentTime: appointmentTime.isEmpty ? '-' : appointmentTime,
      status: status,
      alertKey: status.isEmpty ? '' : '$listingId|$status|$updatedAtKey',
    );
  }

  bool get canViewDetails => status == 'accepted' || status == 'completed';

  String get secondaryButtonLabel => canViewDetails ? 'Later' : 'OK';

  String get dialogTitle {
    switch (status) {
      case 'completed':
        return 'Booking Completed';
      case 'cancelled':
        return 'Booking Cancelled';
      case 'accepted':
      default:
        return 'Booking Confirmed';
    }
  }

  String get dialogBody {
    switch (status) {
      case 'completed':
        return 'Your booking for $itemName has been completed.';
      case 'cancelled':
        return 'Your booking for $itemName has been cancelled.';
      case 'accepted':
      default:
        return 'Your booking for $itemName has been accepted.\n\n'
            'Date: $appointmentDate\n'
            'Time: $appointmentTime';
    }
  }
}
