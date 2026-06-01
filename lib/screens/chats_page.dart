import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_detail_page.dart';
import 'student_theme.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  bool showingBuying = true;

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your chats.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chats',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Chat')
                    .where('buyer_id', isEqualTo: currentUser.uid)
                    .snapshots(),
                builder: (context, buyingSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('Chat')
                        .where('seller_id', isEqualTo: currentUser.uid)
                        .snapshots(),
                    builder: (context, sellingSnapshot) {
                      final buyingUnreadChats = buyingSnapshot.data?.docs
                              .where(
                                (doc) =>
                                    ((doc.data()['buyer_unread_count'] as num?)
                                            ?.toInt() ??
                                        0) >
                                    0,
                              )
                              .length ??
                          0;
                      final sellingUnreadChats = sellingSnapshot.data?.docs
                              .where(
                                (doc) =>
                                    ((doc.data()['seller_unread_count'] as num?)
                                            ?.toInt() ??
                                        0) >
                                    0,
                              )
                              .length ??
                          0;

                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.softBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _tabButton(
                            label: 'Buy Item',
                                selected: showingBuying,
                                unreadChats: buyingUnreadChats,
                                onTap: () {
                                  setState(() {
                                    showingBuying = true;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _tabButton(
                            label: 'Sell Item',
                                selected: !showingBuying,
                                unreadChats: sellingUnreadChats,
                                onTap: () {
                                  setState(() {
                                    showingBuying = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Chat')
                      .where(
                        showingBuying ? 'buyer_id' : 'seller_id',
                        isEqualTo: currentUser.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Couldn't load chats: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data?.docs
                            .map((doc) => _ChatListItem.fromDoc(
                                  doc,
                                  currentUserId: currentUser.uid,
                                ))
                            .where(
                              (chat) => chat.lastMessageText.trim().isNotEmpty,
                            )
                            .toList() ??
                        [];

                    chats.sort((a, b) => b.sortDate.compareTo(a.sortDate));

                    if (chats.isEmpty) {
                      return Center(
                        child: Text(
                          showingBuying
                              ? 'No buying chats yet.'
                              : 'No selling chats yet.',
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.secondaryText,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _buildChatCard(
                          context: context,
                          currentUserId: currentUser.uid,
                          chat: chat,
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

  Widget _tabButton({
    required String label,
    required bool selected,
    required int unreadChats,
    required VoidCallback onTap,
  }) {
    final colors = StudentThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? colors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: selected ? colors.primaryText : colors.secondaryText,
              ),
            ),
            if (unreadChats > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: Color(0xFF2F6BFF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadChats > 9 ? '9+' : unreadChats.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _unreadBadge(int count) {
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0xFF2F6BFF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTrailingUnread(_ChatListItem chat) {
    final colors = StudentThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          chat.formattedTime,
          style: TextStyle(
            fontSize: 15,
            color: colors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 26,
          height: 20,
          child: chat.unreadCount > 0
              ? Align(
                  alignment: Alignment.centerRight,
                  child: _unreadBadge(chat.unreadCount),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildChatCard({
    required BuildContext context,
    required String currentUserId,
    required _ChatListItem chat,
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
              builder: (_) => ChatDetailPage(
                chat: chat.toChatMap(currentUserId: currentUserId),
              ),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChatListImage(imagePath: chat.itemImagePath),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.itemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chat.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chat.lastMessageText.isEmpty
                          ? 'Start chatting'
                          : chat.lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildTrailingUnread(chat),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListItem {
  final String id;
  final String chatRole;
  final String displayName;
  final String counterpartyEmail;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String buyerEmail;
  final String sellerName;
  final String sellerEmail;
  final String itemId;
  final String itemName;
  final String itemPrice;
  final String itemImagePath;
  final String itemDescription;
  final String lastMessageText;
  final DateTime sortDate;
  final int unreadCount;

  const _ChatListItem({
    required this.id,
    required this.chatRole,
    required this.displayName,
    required this.counterpartyEmail,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.sellerName,
    required this.sellerEmail,
    required this.itemId,
    required this.itemName,
    required this.itemPrice,
    required this.itemImagePath,
    required this.itemDescription,
    required this.lastMessageText,
    required this.sortDate,
    required this.unreadCount,
  });

  factory _ChatListItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? {};
    final buyerId = data['buyer_id']?.toString() ?? '';
    final sellerId = data['seller_id']?.toString() ?? '';
    final isBuying = buyerId == currentUserId;
    final updatedAt = data['updated_at'];
    final lastMessageAt = data['last_message_at'];

    final sortTimestamp = (updatedAt is Timestamp
            ? updatedAt
            : lastMessageAt is Timestamp
                ? lastMessageAt
                : null)
        ?.toDate();

    return _ChatListItem(
      id: doc.id,
      chatRole: isBuying ? 'buying' : 'selling',
      displayName: isBuying
          ? data['seller_name']?.toString() ?? 'Seller Name'
          : data['buyer_name']?.toString() ?? 'Buyer Name',
      counterpartyEmail: isBuying
          ? data['seller_email']?.toString() ?? 'seller@siswa.unimas.my'
          : data['buyer_email']?.toString() ?? 'buyer@siswa.unimas.my',
      buyerId: buyerId,
      sellerId: sellerId,
      buyerName: data['buyer_name']?.toString() ?? 'Buyer Name',
      buyerEmail: data['buyer_email']?.toString() ?? 'buyer@siswa.unimas.my',
      sellerName: data['seller_name']?.toString() ?? 'Seller Name',
      sellerEmail:
          data['seller_email']?.toString() ?? 'seller@siswa.unimas.my',
      itemId: data['listing_id']?.toString() ?? '',
      itemName: data['item_name']?.toString() ?? 'Item Name',
      itemPrice: data['item_price']?.toString() ?? 'RM0.00',
      itemImagePath: data['item_image_path']?.toString() ?? '',
      itemDescription: data['item_description']?.toString() ?? 'Description',
      lastMessageText: data['last_message_text']?.toString() ?? '',
      sortDate: sortTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: isBuying
          ? ((data['buyer_unread_count'] as num?)?.toInt() ?? 0)
          : ((data['seller_unread_count'] as num?)?.toInt() ?? 0),
    );
  }

  String get formattedTime {
    if (sortDate == DateTime.fromMillisecondsSinceEpoch(0)) {
      return '-';
    }

    final now = DateTime.now();
    final isToday = now.year == sortDate.year &&
        now.month == sortDate.month &&
        now.day == sortDate.day;

    if (isToday) {
      final hour = sortDate.hour > 12
          ? sortDate.hour - 12
          : sortDate.hour == 0
              ? 12
              : sortDate.hour;
      final suffix = sortDate.hour >= 12 ? 'pm' : 'am';
      return '$hour:${sortDate.minute.toString().padLeft(2, '0')}$suffix';
    }

    return '${sortDate.day.toString().padLeft(2, '0')}/${sortDate.month.toString().padLeft(2, '0')}';
  }

  Map<String, String> toChatMap({required String currentUserId}) {
    return {
      'chatId': id,
      'chatRole': chatRole,
      'currentUserId': currentUserId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'sellerName': sellerName,
      'sellerEmail': sellerEmail,
      'displayName': displayName,
      'itemId': itemId,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'itemImagePath': itemImagePath,
      'itemDescription': itemDescription,
    };
  }
}

class _ChatListImage extends StatelessWidget {
  final String imagePath;

  const _ChatListImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colors.softBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? Center(
              child: Text(
                'Pic',
                style: TextStyle(
                  fontSize: 16,
                  color: StudentThemeColors.of(context).tertiaryText,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StudentThemeColors.of(context).tertiaryText,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  'Pic',
                  style: TextStyle(
                    fontSize: 16,
                    color: StudentThemeColors.of(context).tertiaryText,
                  ),
                ),
              ),
            ),
    );
  }
}
