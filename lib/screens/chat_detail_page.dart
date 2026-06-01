import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'my_booking_page.dart';
import 'seller_profile_page.dart';
import 'seller_booking_detail_page.dart';
import 'student_theme.dart';

class ChatDetailPage extends StatefulWidget {
  final Map<String, String> chat;

  const ChatDetailPage({
    super.key,
    required this.chat,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSending = false;
  int _initialUnreadCount = 0;
  String? _firstUnreadMessageId;

  String get _chatId => widget.chat['chatId'] ?? '';
  String get _currentUserId =>
      widget.chat['currentUserId'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isSellingChat => widget.chat['chatRole'] == 'selling';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUnreadState();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markCurrentSideRead() async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    final field = _isSellingChat ? 'seller_unread_count' : 'buyer_unread_count';
    try {
      await FirebaseFirestore.instance
          .collection('Chat')
          .doc(_chatId)
          .update({
            field: 0,
            (_isSellingChat ? 'seller_last_read_at' : 'buyer_last_read_at'):
                FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Ignore silent read-reset failures to avoid interrupting chat UI.
    }
  }

  Future<void> _initializeUnreadState() async {
    await _captureInitialUnreadMarker();
    if (!mounted) {
      return;
    }
    await _markCurrentSideRead();
  }

  Future<void> _captureInitialUnreadMarker() async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    final unreadField = _isSellingChat ? 'seller_unread_count' : 'buyer_unread_count';
    try {
      final doc = await FirebaseFirestore.instance.collection('Chat').doc(_chatId).get();
      final data = doc.data();
      if (data == null) {
        return;
      }

      final unreadCount = (data[unreadField] as num?)?.toInt() ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _initialUnreadCount = unreadCount;
        _firstUnreadMessageId = null;
      });
    } catch (_) {
      // Ignore marker capture failures so chat can still open normally.
    }
  }

  void _openCounterpartyProfile() {
    final profileId = _isSellingChat
        ? (widget.chat['buyerId'] ?? '')
        : (widget.chat['sellerId'] ?? '');
    final profileName = _isSellingChat
        ? (widget.chat['buyerName'] ?? 'User Name')
        : (widget.chat['sellerName'] ?? 'User Name');
    final profileEmail = _isSellingChat
        ? (widget.chat['buyerEmail'] ?? 'xxxxx@siswa.unimas.my')
        : (widget.chat['sellerEmail'] ?? 'xxxxx@siswa.unimas.my');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfilePage(
          seller: {
            'sellerId': profileId,
            'sellerName': profileName,
            'sellerEmail': profileEmail,
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final chatRef = FirebaseFirestore.instance.collection('Chat').doc(_chatId);
      final now = FieldValue.serverTimestamp();
      final isSellerSender = widget.chat['sellerId'] == _currentUserId;
      final messageRef = chatRef.collection('ChatMessage').doc();

      await messageRef.set({
        'message_id': messageRef.id,
        'chat_id': _chatId,
        'sender_id': _currentUserId,
        'sender_role': isSellerSender ? 'seller' : 'buyer',
        'message_type': 'text',
        'message_text': text,
        'created_at': now,
      });

      await chatRef.update({
        'last_message_text': text,
        'last_message_sender_id': _currentUserId,
        'last_message_at': now,
        'updated_at': now,
        if (isSellerSender)
          'buyer_unread_count': FieldValue.increment(1)
        else
          'seller_unread_count': FieldValue.increment(1),
      });

      _messageController.clear();
      if (mounted) {
        setState(() {
          _initialUnreadCount = 0;
          _firstUnreadMessageId = null;
        });
      }
      _markCurrentSideRead();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't send message: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final chat = widget.chat;
    final displayName =
        chat['displayName'] ?? chat['sellerName'] ?? 'Seller Name';
    final counterpartyEmail =
        _isSellingChat ? chat['buyerEmail'] : chat['sellerEmail'];
    final itemName = chat['itemName'] ?? 'Item Name';
    final itemPrice = chat['itemPrice'] ?? 'RM0.00';
    final itemImagePath = chat['itemImagePath'] ?? '';

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _openCounterpartyProfile,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    counterpartyEmail ?? 'xxxxx@siswa.unimas.my',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showItemDetailSheet(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: colors.divider),
                            bottom: BorderSide(color: colors.divider),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _ChatItemImage(imagePath: itemImagePath),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        itemPrice,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2F6BFF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (!_isSellingChat)
                                  _BuyerRequestButton(
                                    chatId: _chatId,
                                    listingId: widget.chat['itemId'] ?? '',
                                    onRequest: () => _showRequestBookingSheet(context),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.info_rounded,
                                  size: 18,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSellingChat
                                      ? 'You are the seller in this chat'
                                      : 'You are the buyer in this chat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: (widget.chat['itemId'] ?? '').isEmpty
                            ? null
                            : FirebaseFirestore.instance
                                .collection('Listing')
                                .doc(widget.chat['itemId'] ?? '')
                                .snapshots(),
                        builder: (context, listingSnapshot) {
                          final liveSaleStatus = listingSnapshot.data
                                  ?.data()?['sale_status']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';

                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _chatId.isEmpty
                                ? null
                                : FirebaseFirestore.instance
                                    .collection('Chat')
                                    .doc(_chatId)
                                    .collection('ChatMessage')
                                    .orderBy('created_at')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    "Couldn't load chat: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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

                              final messages = snapshot.data?.docs ?? [];
                              _scrollToBottom();
                              _markCurrentSideRead();

                              if (_initialUnreadCount > 0 &&
                                  _firstUnreadMessageId == null &&
                                  messages.isNotEmpty) {
                                final startIndex =
                                    (messages.length - _initialUnreadCount)
                                        .clamp(0, messages.length - 1);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted || _firstUnreadMessageId != null) {
                                    return;
                                  }
                                  setState(() {
                                    _firstUnreadMessageId = messages[startIndex].id;
                                  });
                                });
                              }

                              final children = <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.bubbleSurface,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                        'Today',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: colors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ];
                              var unreadDividerInserted = false;

                              for (final doc in messages) {
                                final data = doc.data();
                                final senderId = data['sender_id']?.toString() ?? '';
                                final createdAt = data['created_at'];
                                final isMine = senderId == _currentUserId;
                                final messageType =
                                    data['message_type']?.toString() ?? 'text';

                                if (!unreadDividerInserted &&
                                    _firstUnreadMessageId != null &&
                                    doc.id == _firstUnreadMessageId &&
                                    !isMine) {
                                  children.add(const Padding(
                                    padding: EdgeInsets.fromLTRB(0, 6, 0, 22),
                                    child: _UnreadMessagesDivider(),
                                  ));
                                  unreadDividerInserted = true;
                                }

                                if (messageType == 'booking_request') {
                                  final status = data['booking_request_status']
                                          ?.toString() ??
                                      'pending';
                                  final requestItemName =
                                      data['item_name']?.toString() ?? itemName;
                                  final requestItemPrice =
                                      data['item_price']?.toString() ?? itemPrice;
                                  final requestImagePath =
                                      data['item_image_path']?.toString() ?? '';
                                  final requestListingId =
                                      data['listing_id']?.toString() ??
                                      (widget.chat['itemId'] ?? '');
                                  final appointmentDate =
                                      data['appointment_date']?.toString() ?? '';
                                  final appointmentTime =
                                      data['appointment_time']?.toString() ?? '';

                                  children.add(
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 18),
                                      child: Align(
                                        alignment: isMine
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Column(
                                          crossAxisAlignment: isMine
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (_isSellingChat)
                                              _SellingBookingRequestCard(
                                                itemName: requestItemName,
                                                itemPrice: requestItemPrice,
                                                imagePath: requestImagePath,
                                                listingId: requestListingId,
                                                status: status,
                                                appointmentDate: appointmentDate,
                                                appointmentTime: appointmentTime,
                                                canAccept: status != 'pending' ||
                                                    liveSaleStatus == 'available',
                                                onAccept: () async {
                                                  final appointment =
                                                      await _showAcceptBookingDialog();
                                                  if (appointment == null) {
                                                    return;
                                                  }
                                                  await _updateBookingRequestStatus(
                                                    messageId: doc.id,
                                                    status: 'accepted',
                                                    appointmentDate:
                                                        appointment['appointment_date'],
                                                    appointmentTime:
                                                        appointment['appointment_time'],
                                                  );
                                                },
                                                onDecline: () =>
                                                    _updateBookingRequestStatus(
                                                  messageId: doc.id,
                                                  status: 'declined',
                                                ),
                                              )
                                            else
                                              _BookingRequestCard(
                                                itemName: requestItemName,
                                                itemPrice: requestItemPrice,
                                                imagePath: requestImagePath,
                                                listingId: requestListingId,
                                                status: status,
                                                appointmentDate: appointmentDate,
                                                appointmentTime: appointmentTime,
                                                onViewDetails: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => BuyerBookingDetailPage(
                                                        listingId: requestListingId,
                                                        userId: _currentUserId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _formatMessageTime(createdAt),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.secondaryText,
                                      ),
                                    ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  continue;
                                }

                                children.add(
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: _MessageBubble(
                                      text: data['message_text']?.toString() ??
                                          data['text']?.toString() ??
                                          '',
                                      time: _formatMessageTime(createdAt),
                                      isMine: isMine,
                                    ),
                                  ),
                                );
                              }

                              return ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 20),
                                children: children,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 54,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: colors.softBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _messageController,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: InputDecoration(
                                    hintText: 'Send a message...',
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: colors.secondaryText,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: isSending ? null : _sendMessage,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEEF2FF),
                                    Color(0xFFDCE7FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF2F6BFF).withOpacity(0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isSending
                                    ? Icons.hourglass_top_rounded
                                    : Icons.send_outlined,
                                color: colors.secondaryText,
                                size: 24,
                              ),
                            ),
                          ),
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

  String _formatMessageTime(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }
    final date = value.toDate();
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;
    final suffix = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:${date.minute.toString().padLeft(2, '0')}$suffix';
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

  void _showRequestBookingSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RequestBookingSheet(
          chat: widget.chat,
          showRequestButton: true,
        );
      },
    ).then((requested) {
      if (requested == true) {
        _sendBookingRequest();
      }
    });
  }

  void _showItemDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RequestBookingSheet(
          chat: widget.chat,
          showRequestButton: false,
        );
      },
    );
  }

  Future<void> _sendBookingRequest() async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      return;
    }

    try {
      final chatRef = FirebaseFirestore.instance.collection('Chat').doc(_chatId);
      final listingId = widget.chat['itemId'] ?? '';
      if (listingId.isEmpty) {
        throw 'Missing listing id.';
      }

      final listingRef =
          FirebaseFirestore.instance.collection('Listing').doc(listingId);
      final listingDoc = await listingRef.get();
      final saleStatus =
          listingDoc.data()?['sale_status']?.toString().toLowerCase() ?? '';
      if (saleStatus != 'available') {
        throw 'This item is not available for booking.';
      }

      final existingPending = await chatRef
          .collection('ChatMessage')
          .where('message_type', isEqualTo: 'booking_request')
          .where('booking_request_status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existingPending.docs.isNotEmpty) {
        throw 'A booking request is already pending.';
      }

      final now = FieldValue.serverTimestamp();
      final requestRef = chatRef.collection('ChatMessage').doc();

      await requestRef.set({
        'message_id': requestRef.id,
        'chat_id': _chatId,
        'sender_id': _currentUserId,
        'sender_role': 'buyer',
        'message_type': 'booking_request',
        'booking_request_status': 'pending',
        'listing_id': widget.chat['itemId'] ?? '',
        'item_name': widget.chat['itemName'] ?? 'Item Name',
        'item_price': widget.chat['itemPrice'] ?? 'RM0.00',
        'item_image_path': widget.chat['itemImagePath'] ?? '',
        'created_at': now,
      });

      await chatRef.update({
        'last_message_text': 'Booking request sent',
        'last_message_sender_id': _currentUserId,
        'last_message_at': now,
        'updated_at': now,
        'seller_unread_count': FieldValue.increment(1),
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't send booking request: $error")),
      );
    }
  }

  Future<void> _updateBookingRequestStatus({
    required String messageId,
    required String status,
    String? appointmentDate,
    String? appointmentTime,
  }) async {
    if (_chatId.isEmpty || messageId.isEmpty) {
      return;
    }

    try {
      final chatRef = FirebaseFirestore.instance.collection('Chat').doc(_chatId);
      final listingId = widget.chat['itemId'] ?? '';
      if (listingId.isEmpty) {
        throw 'Missing listing id.';
      }
      final listingRef =
          FirebaseFirestore.instance.collection('Listing').doc(listingId);
      final now = FieldValue.serverTimestamp();
      final footer = status == 'accepted'
          ? 'Booking accepted'
          : 'Booking declined';
      final buyerId = widget.chat['buyerId'] ?? '';
      final buyerName = widget.chat['buyerName'] ?? 'Buyer Name';
      final buyerEmail =
          widget.chat['buyerEmail'] ?? 'buyer@siswa.unimas.my';

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final listingDoc = await transaction.get(listingRef);
        final listingData = listingDoc.data();
        final currentSaleStatus =
            listingData?['sale_status']?.toString().toLowerCase() ?? '';

        if (status == 'accepted' && currentSaleStatus != 'available') {
          throw 'This item is no longer available.';
        }

        transaction.update(
          chatRef.collection('ChatMessage').doc(messageId),
          {
            'booking_request_status': status,
            'buyer_id': buyerId,
            'seller_id': _currentUserId,
            if (appointmentDate != null) 'appointment_date': appointmentDate,
            if (appointmentTime != null) 'appointment_time': appointmentTime,
          },
        );

        transaction.update(chatRef, {
          'last_message_text': footer,
          'last_message_sender_id': _currentUserId,
          'last_message_at': now,
          'updated_at': now,
          'buyer_unread_count': FieldValue.increment(1),
        });

        if (status == 'accepted') {
          transaction.update(listingRef, {
            'sale_status': 'booked',
            'booked_by_id': buyerId,
            'booked_by_name': buyerName,
            'booked_by_email': buyerEmail,
            'booked_at': now,
            'appointment_date': appointmentDate,
            'appointment_time': appointmentTime,
            'updated_at': now,
            'updated_by': _currentUserId,
            'updated_by_role': 'seller',
          });

          final buyerCartRef = FirebaseFirestore.instance
              .collection('User')
              .doc(buyerId)
              .collection('Cart')
              .doc(listingId);
          transaction.delete(buyerCartRef);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text("Couldn't update booking request: $error")),
      );
    }
  }

  Future<Map<String, String>?> _showAcceptBookingDialog() async {
    var selectedDate = '';
    var selectedTime = '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final colors = StudentThemeColors.of(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate() async {
              final selected = await showDatePicker(
                context: dialogContext,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (selected == null) return;
              setDialogState(() {
                selectedDate =
                    '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
              });
            }

            Future<void> pickTime() async {
              final selected = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.now(),
              );
              if (selected == null) return;
              setDialogState(() {
                selectedTime =
                    '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
              });
            }

            Widget buildPickerField({
              required String value,
              required String hint,
              required IconData icon,
              required VoidCallback onTap,
            }) {
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.isEmpty ? hint : value,
                          style: TextStyle(
                            fontSize: 16,
                            color: value.isEmpty
                                ? colors.tertiaryText
                                : colors.primaryText,
                          ),
                        ),
                      ),
                      Icon(icon, size: 20, color: colors.secondaryText),
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: colors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 18, 18, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Accept Booking',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: colors.primaryText,
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.softBackground,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close, color: colors.icon),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please select the date and time for the booking appointment:',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Date:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          buildPickerField(
                            value: selectedDate,
                            hint: 'dd/mm/yyyy',
                            icon: Icons.calendar_today_outlined,
                            onTap: pickDate,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Time:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          buildPickerField(
                            value: selectedTime,
                            hint: '--:--',
                            icon: Icons.access_time_outlined,
                            onTap: pickTime,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedDate.isEmpty || selectedTime.isEmpty) {
                                  showTopSnackBarFromSnackBar(context, 
                                    const SnackBar(
                                      content: Text(
                                        'Please select both date and time.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(dialogContext, {
                                  'appointment_date': selectedDate,
                                  'appointment_time': selectedTime,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B63E),
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: const Color(0x3306B63E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Confirm',
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
      },
    );
  }

}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMine;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 330),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF1E293B)
                  : colors.softBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isMine ? Colors.white : colors.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 14,
                color: colors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadMessagesDivider extends StatelessWidget {
  const _UnreadMessagesDivider();

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: colors.divider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'UNREAD MESSAGES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.secondaryText,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: colors.divider,
          ),
        ),
      ],
    );
  }
}

class _ChatItemImage extends StatelessWidget {
  final String imagePath;

  const _ChatItemImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imagePath,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'Pic',
        style: TextStyle(
          fontSize: 16,
          color: colors.tertiaryText,
        ),
      ),
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final String itemName;
  final String itemPrice;
  final String imagePath;
  final String listingId;
  final String status;
  final String appointmentDate;
  final String appointmentTime;
  final VoidCallback? onViewDetails;

  const _BookingRequestCard({
    required this.itemName,
    required this.itemPrice,
    required this.imagePath,
    required this.listingId,
    required this.status,
    required this.appointmentDate,
    required this.appointmentTime,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final badgeColor = status == 'accepted'
        ? const Color(0xFFDCFCE7)
        : status == 'completed'
            ? const Color(0xFFE0E7FF)
            : status == 'cancelled'
                ? const Color(0xFFF3F4F6)
        : status == 'declined'
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFDE68A);
    final badgeTextColor = status == 'accepted'
        ? const Color(0xFF15803D)
        : status == 'completed'
            ? const Color(0xFF4338CA)
            : status == 'cancelled'
                ? const Color(0xFF4B5563)
        : status == 'declined'
            ? const Color(0xFFDC2626)
            : const Color(0xFF92400E);
    final badgeText = status == 'accepted'
        ? 'Accepted'
        : status == 'completed'
            ? 'Completed'
            : status == 'cancelled'
                ? 'Cancelled'
        : status == 'declined'
            ? 'Declined'
            : 'Pending';
    final footer = status == 'accepted'
        ? 'Booking accepted'
        : status == 'completed'
            ? 'Booking completed'
            : status == 'cancelled'
                ? 'Booking cancelled'
        : status == 'declined'
            ? 'Booking declined'
            : 'Booking request sent';
    final showDateTime = status == 'accepted' || status == 'completed';
    final canViewDetails = status == 'accepted' || status == 'completed';

    return Container(
      width: 240,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _smallCardImage(context: context, imagePath: imagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        itemPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                       child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      if (showDateTime) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Date: $appointmentDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: $appointmentTime',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.divider),
          if (canViewDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0x332F6BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View Booking Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Text(
                footer,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SellingBookingRequestCard extends StatelessWidget {
  final String itemName;
  final String itemPrice;
  final String imagePath;
  final String listingId;
  final String? status;
  final String appointmentDate;
  final String appointmentTime;
  final bool canAccept;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _SellingBookingRequestCard({
    required this.itemName,
    required this.itemPrice,
    required this.imagePath,
    required this.listingId,
    required this.status,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.canAccept,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final resolved = status == 'accepted' ||
        status == 'declined' ||
        status == 'completed' ||
        status == 'cancelled';
    final statusLabel = status == 'accepted'
        ? 'Accepted'
        : status == 'completed'
            ? 'Completed'
            : status == 'cancelled'
                ? 'Cancelled'
        : status == 'declined'
            ? 'Declined'
            : 'Pending';
    final statusColor = status == 'accepted'
        ? const Color(0xFFDCFCE7)
        : status == 'completed'
            ? const Color(0xFFE0E7FF)
            : status == 'cancelled'
                ? const Color(0xFFF3F4F6)
        : status == 'declined'
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFDE68A);
    final statusTextColor = status == 'accepted'
        ? const Color(0xFF15803D)
        : status == 'completed'
            ? const Color(0xFF4338CA)
            : status == 'cancelled'
                ? const Color(0xFF4B5563)
        : status == 'declined'
            ? const Color(0xFFDC2626)
            : const Color(0xFF92400E);
    final footerText = status == 'accepted'
        ? 'Booking accepted'
        : status == 'completed'
            ? 'Booking completed'
            : status == 'cancelled'
                ? 'Booking cancelled'
        : status == 'declined'
            ? 'Booking declined'
            : null;
    final showDateTime = status == 'accepted' || status == 'completed';
    final canViewDetails = status == 'accepted' || status == 'completed';

    return Container(
      width: 255,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _smallCardImage(context: context, imagePath: imagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        itemPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                      if (showDateTime) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Date: $appointmentDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: $appointmentTime',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.divider),
          if (!resolved)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                       height: 58,
                       child: ElevatedButton(
                         onPressed: canAccept ? onAccept : null,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: canAccept
                               ? const Color(0xFF06B63E)
                               : const Color(0xFFD1D5DB),
                           foregroundColor:
                               canAccept ? Colors.white : const Color(0xFF6B7280),
                           elevation: 8,
                           shadowColor: canAccept
                               ? const Color(0x3306B63E)
                               : Colors.transparent,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                         ),
                        child: const Text(
                          'Accept\nBooking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: onDecline,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1414),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0x33FF1414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Reject Booking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (canViewDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerBookingDetailPage(listingId: listingId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0x332F6BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View Booking Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Text(
                footerText!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestBookingSheet extends StatelessWidget {
  final Map<String, String> chat;
  final bool showRequestButton;

  const _RequestBookingSheet({
    required this.chat,
    required this.showRequestButton,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final itemName = chat['itemName'] ?? 'Item Name';
    final itemPrice = chat['itemPrice'] ?? 'RM0.00';
    final sellerName =
        chat['displayName'] ?? chat['sellerName'] ?? 'Seller Name';
    final sellerEmail = chat['sellerEmail'] ?? 'xxxxx@siswa.unimas.my';
    final itemImagePath = chat['itemImagePath'] ?? '';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.softBackground,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: colors.primaryText,
                        ),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: colors.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 224,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.softBackground,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: itemImagePath.isEmpty
                            ? Center(
                                child: Text(
                                  'Picture',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colors.tertiaryText,
                                  ),
                                ),
                              )
                            : Image.network(
                                itemImagePath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    'Picture',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: colors.tertiaryText,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itemPrice,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chat['itemDescription'] ?? 'Description',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.divider,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Seller',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sellerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sellerEmail,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (showRequestButton)
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: const Color(0x332F6BFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Request Booking',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _smallCardImage({required BuildContext context, required String imagePath}) {
  final colors = StudentThemeColors.of(context);
  return Container(
    width: 84,
    height: 84,
    decoration: BoxDecoration(
      color: colors.softBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: imagePath.isEmpty
        ? Center(
            child: Text(
              'Pic',
              style: TextStyle(
                fontSize: 18,
                color: colors.tertiaryText,
              ),
            ),
          )
        : Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                'Pic',
                style: TextStyle(
                  fontSize: 18,
                  color: colors.tertiaryText,
                ),
              ),
            ),
          ),
  );
}

class _BuyerRequestButton extends StatelessWidget {
  final String chatId;
  final String listingId;
  final VoidCallback onRequest;

  const _BuyerRequestButton({
    required this.chatId,
    required this.listingId,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: listingId.isEmpty
          ? null
          : FirebaseFirestore.instance.collection('Listing').doc(listingId).snapshots(),
      builder: (context, listingSnapshot) {
        final saleStatus = listingSnapshot.data?.data()?['sale_status']
                ?.toString()
                .toLowerCase() ??
            '';

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: chatId.isEmpty
              ? null
              : FirebaseFirestore.instance
                  .collection('Chat')
                  .doc(chatId)
                  .collection('ChatMessage')
                  .where('message_type', isEqualTo: 'booking_request')
                  .where('booking_request_status', isEqualTo: 'pending')
                  .limit(1)
                  .snapshots(),
          builder: (context, snapshot) {
            final hasPendingRequest =
                (snapshot.data?.docs.isNotEmpty ?? false);
            final isLocked = hasPendingRequest ||
                saleStatus == 'booked' ||
                saleStatus == 'completed' ||
                saleStatus == 'removed';
            final buttonLabel = hasPendingRequest
                ? 'Request Sent'
                : saleStatus == 'booked'
                    ? 'Booked'
                    : saleStatus == 'completed'
                        ? 'Completed'
                        : saleStatus == 'removed'
                            ? 'Unavailable'
                            : 'Request\nBooking';

            return SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: isLocked ? null : onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLocked
                      ? const Color(0xFFD0D5DD)
                      : const Color(0xFF2F6BFF),
                  foregroundColor:
                      isLocked ? colors.secondaryText : Colors.white,
                  disabledBackgroundColor: const Color(0xFFD0D5DD),
                  disabledForegroundColor: colors.secondaryText,
                  elevation: 8,
                  shadowColor: isLocked
                      ? const Color(0x22000000)
                      : const Color(0x332F6BFF),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

