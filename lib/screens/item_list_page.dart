import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/price_formatter.dart';
import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_detail_admin_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  static const double _tableWidth = 790;
  static const int _rowsPerPage = 10;
  bool showFilters = false;
  String selectedStatus = 'all';
  String selectedCategory = 'all';
  String selectedType = 'all';
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Listing')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Couldn't load items: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data?.docs
                    .map((doc) => _AdminListingItem.fromDoc(doc))
                    .toList() ??
                [];

            final filteredItems = items.where((item) {
              final matchesStatus = selectedStatus == 'all' ||
                  (selectedStatus == 'removed'
                      ? item.saleStatus.toLowerCase() == 'removed' ||
                          item.status.toLowerCase() == 'removed'
                      : item.status.toLowerCase() == selectedStatus);
              final matchesCategory = selectedCategory == 'all' ||
                  item.category.toLowerCase() == selectedCategory;
              final matchesType = selectedType == 'all' ||
                  item.type.toLowerCase() == selectedType;
              return matchesStatus && matchesCategory && matchesType;
            }).toList();
            final totalPages = filteredItems.isEmpty
                ? 1
                : ((filteredItems.length - 1) ~/ _rowsPerPage) + 1;
            final safePage = currentPage.clamp(1, totalPages);
            final startIndex =
                filteredItems.isEmpty ? 0 : (safePage - 1) * _rowsPerPage;
            final endIndex = filteredItems.isEmpty
                ? 0
                : ((startIndex + _rowsPerPage) > filteredItems.length
                    ? filteredItems.length
                    : (startIndex + _rowsPerPage));
            final pagedItems = filteredItems.sublist(startIndex, endIndex);

            final statusCounts = <String, int>{
              'pending': items.where((item) => item.status == 'pending').length,
              'approved': items.where((item) => item.status == 'approved').length,
              'rejected': items.where((item) => item.status == 'rejected').length,
              'removed': items
                  .where((item) =>
                      item.saleStatus.toLowerCase() == 'removed' ||
                      item.status == 'removed')
                  .length,
            };

            final categoryCounts = <String, int>{};
            for (final item in items) {
              final key = item.category.toLowerCase();
              categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
            }
            final sortedCategories = categoryCounts.keys.toList()..sort();

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A2342),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7A90),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFC9FDFF),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      showFilters = !showFilters;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFD9E1EC),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.filter_list_rounded,
                                          color: Color(0xFF4A5C78),
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF233B5E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (showFilters) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 20, 20, 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFFD9E1EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF233B5E),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 12,
                                        children: [
                                          _FilterOptionChip(
                                            label: 'All',
                                            selected: selectedStatus == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label:
                                                'Pending (${statusCounts['pending'] ?? 0})',
                                            selected:
                                                selectedStatus == 'pending',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'pending';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label:
                                                'Approved (${statusCounts['approved'] ?? 0})',
                                            selected:
                                                selectedStatus == 'approved',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'approved';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label:
                                                'Rejected (${statusCounts['rejected'] ?? 0})',
                                            selected:
                                                selectedStatus == 'rejected',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'rejected';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label:
                                                'Removed (${statusCounts['removed'] ?? 0})',
                                            selected:
                                                selectedStatus == 'removed',
                                            onTap: () {
                                              setState(() {
                                                selectedStatus = 'removed';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Category',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF233B5E),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 12,
                                        children: [
                                          _FilterOptionChip(
                                            label: 'All',
                                            selected: selectedCategory == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedCategory = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          ...sortedCategories.map(
                                            (categoryKey) => _FilterOptionChip(
                                              label: _titleCase(categoryKey),
                                              selected:
                                                  selectedCategory == categoryKey,
                                              onTap: () {
                                                setState(() {
                                                  selectedCategory = categoryKey;
                                                  currentPage = 1;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Listing Type',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF233B5E),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 12,
                                        children: [
                                          _FilterOptionChip(
                                            label: 'All',
                                            selected: selectedType == 'all',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'all';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label: 'Sale',
                                            selected: selectedType == 'sale',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'sale';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                          _FilterOptionChip(
                                            label: 'Donation',
                                            selected:
                                                selectedType == 'donation',
                                            onTap: () {
                                              setState(() {
                                                selectedType = 'donation';
                                                currentPage = 1;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFD9E1EC),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: SizedBox(
                                    width: _tableWidth,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            16,
                                            18,
                                            12,
                                          ),
                                          child: Row(
                                            children: const [
                                              SizedBox(
                                                width: 250,
                                                child: _HeaderText('Item', alignLeft: true),
                                              ),
                                              SizedBox(
                                                width: 88,
                                                child: _HeaderText('Type'),
                                              ),
                                              SizedBox(
                                                width: 120,
                                                child: _HeaderText('Category'),
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: _HeaderText('Date'),
                                              ),
                                              SizedBox(
                                                width: 102,
                                                child: _HeaderText('Status'),
                                              ),
                                              SizedBox(
                                                width: 92,
                                                child: _HeaderText('Actions'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFE7ECF3),
                                        ),
                                        if (filteredItems.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Text(
                                              'No items match the selected filters.',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF6B7A90),
                                              ),
                                            ),
                                          )
                                        else
                                          ...pagedItems.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final item = entry.value;
                                            return Column(
                                              children: [
                                                _ItemRow(
                                                  item: item,
                                                  onView: () {
                                                    _openItemDetail(item.toMap());
                                                  },
                                                ),
                                                if (index != pagedItems.length - 1)
                                                  const Divider(
                                                    height: 1,
                                                    thickness: 1,
                                                    color: Color(0xFFE7ECF3),
                                                  ),
                                              ],
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Showing ${filteredItems.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredItems.length} items',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF31506E),
                                      ),
                                    ),
                                  ),
                                  _PagerButton(
                                    label: 'Previous',
                                    enabled: safePage > 1,
                                    onTap: safePage > 1
                                        ? () {
                                            setState(() {
                                              currentPage = safePage - 1;
                                            });
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  _PageNumberButton(
                                    label: '$safePage',
                                    selected: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _PagerButton(
                                    label: 'Next',
                                    enabled: safePage < totalPages,
                                    onTap: safePage < totalPages
                                        ? () {
                                            setState(() {
                                              currentPage = safePage + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE3E8EF)),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    10 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AdminNavItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Items',
                        selected: true,
                      ),
                      _AdminNavItem(
                        icon: Icons.category_outlined,
                        label: 'Categories',
                        routeToCategories: true,
                      ),
                      _AdminNavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Home',
                        routeToDashboard: true,
                      ),
                  _AdminNavItem(
                    icon: Icons.error_outline,
                    label: 'Complaints',
                    routeToReports: true,
                  ),
                      _AdminNavItem(
                        icon: Icons.eco_outlined,
                        label: 'Impact',
                        routeToImpact: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openItemDetail(Map<String, String> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailAdminPage(item: item),
      ),
    );
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _AdminListingItem {
  final String id;
  final String title;
  final String price;
  final String type;
  final String category;
  final String createdAt;
  final String createdDate;
  final String description;
  final String seller;
  final String saleStatus;
  final String status;
  final String imagePath;

  const _AdminListingItem({
    required this.id,
    required this.title,
    required this.price,
    required this.type,
    required this.category,
    required this.createdAt,
    required this.createdDate,
    required this.description,
    required this.seller,
    required this.saleStatus,
    required this.status,
    required this.imagePath,
  });

  factory _AdminListingItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final listingType =
        data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final createdAt = data['created_at'];
    final createdDateTime =
        createdAt is Timestamp ? createdAt.toDate() : DateTime(2024, 1, 1);
    final createdDate = _dateString(createdDateTime);

    return _AdminListingItem(
      id: doc.id,
      title: data['title']?.toString() ??
          data['name']?.toString() ??
          'Item Name',
      price: (listingType == 'donation' || parsedPrice <= 0)
          ? 'Free'
          : formatRmPrice(parsedPrice),
      type: listingType == 'donation' ? 'Donation' : 'Sale',
      category: data['category_name']?.toString() ??
          data['category']?.toString() ??
          'Category',
      createdAt: createdDate.replaceFirst('-', '-\n'),
      createdDate: createdDate,
      description: data['description']?.toString() ?? 'Item description',
      seller: data['seller_name']?.toString() ??
          data['seller']?.toString() ??
          'Seller Name',
      saleStatus: data['sale_status']?.toString() ?? 'Available',
      status: data['listing_status']?.toString().toLowerCase() ?? 'pending',
      imagePath: data['image_path']?.toString() ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'id': id,
      'name': title,
      'title': title,
      'price': price,
      'type': type,
      'category': category,
      'createdAt': createdAt,
      'createdDate': createdDate,
      'description': description,
      'seller': seller,
      'saleStatus': saleStatus,
      'status': status,
      'imagePath': imagePath,
    };
  }

  static String _dateString(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F6BFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFD9E1EC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF4A5C78),
          ),
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignLeft;

  const _HeaderText(this.text, {this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF233B5E),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _AdminListingItem item;
  final VoidCallback onView;

  const _ItemRow({
    required this.item,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final typeIsDonation = item.type == 'Donation';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2342),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F6BFF),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeIsDonation
                        ? const Color(0xFFF1E5FF)
                        : const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.type,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: typeIsDonation
                          ? const Color(0xFF9B4DDB)
                          : const Color(0xFF2F6BFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              item.category,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF233B5E),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                item.createdAt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  color: Color(0xFF233B5E),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 102,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFFD9F9E5)
                        : isPending
                            ? const Color(0xFFFFF3BF)
                            : isRejected
                                ? const Color(0xFFFFE3E3)
                                : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _titleCase(status),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isApproved
                          ? const Color(0xFF067647)
                          : isPending
                              ? const Color(0xFFB67D00)
                              : isRejected
                                  ? const Color(0xFFB42318)
                                  : const Color(0xFF475467),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 36,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF1FF),
                    foregroundColor: const Color(0xFF2F6BFF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _PagerButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _PagerButton({
    required this.label,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9E1EC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled ? const Color(0xFF31506E) : const Color(0xFF98A5B8),
          ),
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _PageNumberButton({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2F6BFF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFD9E1EC),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF233B5E),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToCategories;
  final bool routeToReports;
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToCategories = false,
    this.routeToReports = false,
    this.routeToImpact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7A90);
    final VoidCallback? onTap = routeToDashboard
        ? () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardPage(),
              ),
              (route) => false,
            );
          }
        : routeToCategories
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryPage(),
                  ),
                );
              }
            : routeToReports
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportListAdminPage(),
                      ),
                    );
                  }
                : routeToImpact
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SustainabilityAdminPage(),
                          ),
                        );
                      }
                    : null;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
