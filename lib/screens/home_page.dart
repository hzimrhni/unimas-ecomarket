import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/price_formatter.dart';
import 'cart_page.dart';
import 'item_detail_page.dart';
import 'student_theme.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _priceFilterCap = 100;
  String userName = 'Loading...';
  String searchQuery = '';
  String? sortMode;
  double selectedMinPrice = 0;
  double? selectedMaxPrice;
  bool categoriesLoaded = false;
  int _randomFeedSeed = DateTime.now().microsecondsSinceEpoch;

  final List<_FilterCategory> categories = [];
  final Set<String> selectedSubcategoryIds = {};
  final Set<String> expandedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    fetchUserName();
    loadCategories();
  }

  void _refreshRandomFeed() {
    setState(() {
      _randomFeedSeed = DateTime.now().microsecondsSinceEpoch;
    });
  }

  Future<void> fetchUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('User')
        .doc(widget.userId)
        .get();

    if (!mounted) {
      return;
    }

    if (doc.exists) {
      setState(() {
        userName = doc.data()?['name']?.toString() ?? 'No Name';
      });
    } else {
      setState(() {
        userName = 'User';
      });
    }
  }

  Future<void> loadCategories() async {
    final categorySnapshot = await FirebaseFirestore.instance
        .collection('Category')
        .orderBy('category_name')
        .get();

    final loadedCategories = await Future.wait(
      categorySnapshot.docs.map((categoryDoc) async {
        final subcategorySnapshot = await categoryDoc.reference
            .collection('SubCategory')
            .orderBy('subcategory_name')
            .get();

        return _FilterCategory(
          id: categoryDoc.id,
          name: categoryDoc.data()['category_name']?.toString() ?? 'Category',
          subcategories: subcategorySnapshot.docs.map((subcategoryDoc) {
            final data = subcategoryDoc.data();
            return _FilterSubcategory(
              id: subcategoryDoc.id,
              name: data['subcategory_name']?.toString() ?? 'Subcategory',
            );
          }).toList(),
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      categories
        ..clear()
        ..addAll(loadedCategories);
      categoriesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_icon.png',
                  height: 66,
                  width: 66,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hello, $userName!',
                      maxLines: 3,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                    color: colors.cardBackground,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: colors.icon),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: colors.tertiaryText,
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 24,
                          color: colors.tertiaryText,
                        ),
                        filled: true,
                        fillColor: colors.cardBackground,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.tertiaryText),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Listing')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final listings = snapshot.data?.docs
                            .map((doc) => _ListingItem.fromDoc(doc))
                            .toList() ??
                        [];
                    final availableMaxPrice = _availableMaxPrice(listings);

                    return IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colors.cardBackground,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(46, 46),
                      ),
                      icon: Icon(
                        Icons.tune,
                        color: colors.icon,
                        size: 22,
                      ),
                      onPressed: () {
                        showFilterPanel(context, availableMaxPrice);
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Listing')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Couldn't load items: ${snapshot.error}",
                        textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final listings = snapshot.data?.docs
                          .map((doc) => _ListingItem.fromDoc(doc))
                          .toList() ??
                      [];
                  final visibleItems = _applyFilters(listings);

                  if (visibleItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No items match the current filter.',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.secondaryText,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: visibleItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      return itemCard(visibleItems[index], context);
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

  List<_ListingItem> _applyFilters(List<_ListingItem> listings) {
    final maxPriceCap = _availableMaxPrice(listings);
    final effectiveMax =
        ((selectedMaxPrice ?? maxPriceCap).clamp(selectedMinPrice, maxPriceCap))
            .toDouble();
    final hasUpperBound =
        selectedMaxPrice != null && selectedMaxPrice! < maxPriceCap - 0.01;

    final filtered = listings.where((item) {
      if (item.sellerId == widget.userId) {
        return false;
      }

      final sellerStatus = item.sellerStatus.toLowerCase();
      if (sellerStatus == 'suspended') {
        return false;
      }

      final status = item.listingStatus.toLowerCase();
      final saleStatus = item.saleStatus.toLowerCase();
      final isVisibleListingStatus = status.isEmpty ||
          status == 'available' ||
          status == 'active' ||
          status == 'approved';
      final isVisibleSaleStatus =
          saleStatus.isEmpty || saleStatus == 'available';
      if (!isVisibleListingStatus || !isVisibleSaleStatus) {
        return false;
      }

      final matchesSearch = searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery);
      if (!matchesSearch) {
        return false;
      }

      final matchesPrice = hasUpperBound
          ? item.price >= selectedMinPrice && item.price <= effectiveMax
          : item.price >= selectedMinPrice;
      if (!matchesPrice) {
        return false;
      }

      if (selectedSubcategoryIds.isEmpty) {
        return true;
      }

      return selectedSubcategoryIds.contains(item.subcategoryId) ||
          selectedSubcategoryIds.contains(item.subcategoryName);
    }).toList();

    if (sortMode == 'low_to_high') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortMode == 'high_to_low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else {
      int rankFor(String id) => Object.hash(id, _randomFeedSeed);
      filtered.sort((a, b) => rankFor(a.id).compareTo(rankFor(b.id)));
    }
    return filtered;
  }

  double _availableMaxPrice(List<_ListingItem> listings) {
    return _priceFilterCap;
  }

  Widget itemCard(_ListingItem item, BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final itemMap = item.toDetailMap();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailPage(item: itemMap),
          ),
        ).then((_) {
          if (mounted) {
            _refreshRandomFeed();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ListingImage(imagePath: item.imagePath),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 2),
            Text(
              item.formattedPrice,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: item.formattedPrice == 'Free'
                    ? const Color(0xFF2F6BFF)
                    : colors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showFilterPanel(BuildContext context, double availableMaxPrice) {
    final colors = StudentThemeColors.of(context);
    String? draftSortMode = sortMode;
    double draftMinPrice =
        selectedMinPrice.clamp(0, availableMaxPrice).toDouble();
    double draftMaxPrice =
        (selectedMaxPrice ?? availableMaxPrice)
            .clamp(draftMinPrice, availableMaxPrice)
            .toDouble();
    final draftSelectedSubcategories = Set<String>.from(selectedSubcategoryIds);
    final draftExpandedCategories = Set<String>.from(expandedCategoryIds);
    final hasAppliedFilters = sortMode != null ||
        selectedMinPrice > 0.01 ||
        selectedSubcategoryIds.isNotEmpty ||
        selectedMaxPrice != null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: colors.cardBackground,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                void updatePreset(double min, double max) {
                  setDialogState(() {
                    draftMinPrice = min.clamp(0, availableMaxPrice);
                    draftMaxPrice = max.clamp(draftMinPrice, availableMaxPrice);
                  });
                }

                return Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                  color: colors.cardBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Sort by Price',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChoiceButton(
                              label: 'Low to High',
                              selected: draftSortMode == 'low_to_high',
                              onTap: () {
                                setDialogState(() {
                                  draftSortMode =
                                      draftSortMode == 'low_to_high'
                                          ? null
                                          : 'low_to_high';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterChoiceButton(
                              label: 'High to Low',
                              selected: draftSortMode == 'high_to_low',
                              onTap: () {
                                setDialogState(() {
                                  draftSortMode =
                                      draftSortMode == 'high_to_low'
                                          ? null
                                          : 'high_to_low';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Min: ${_formatCurrency(draftMinPrice)}',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.secondaryText,
                            ),
                          ),
                          Text(
                            'Max: ${_formatCurrency(draftMaxPrice)}${draftMaxPrice >= availableMaxPrice - 0.01 ? '+' : ''}',
                            style: TextStyle(
                              fontSize: 15,
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF2F6BFF),
                          inactiveTrackColor: colors.softBackground,
                          thumbColor: const Color(0xFF2F6BFF),
                          overlayColor: const Color(0x332F6BFF),
                          rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                          trackHeight: 8,
                        ),
                        child: RangeSlider(
                          values: RangeValues(draftMinPrice, draftMaxPrice),
                          min: 0,
                          max: availableMaxPrice,
                          onChanged: (values) {
                            setDialogState(() {
                              draftMinPrice = values.start;
                              draftMaxPrice = values.end;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PricePresetButton(
                            width: 92,
                            label: 'Under RM20',
                            onTap: () =>
                                updatePreset(0, math.min(20, availableMaxPrice)),
                          ),
                          _PricePresetButton(
                            width: 84,
                            label: 'RM20-50',
                            onTap: () => updatePreset(
                              math.min(20, availableMaxPrice),
                              math.min(50, availableMaxPrice),
                            ),
                          ),
                          _PricePresetButton(
                            width: 84,
                            label: 'RM50-70',
                            onTap: () => updatePreset(
                              math.min(50, availableMaxPrice),
                              math.min(70, availableMaxPrice),
                            ),
                          ),
                          _PricePresetButton(
                            width: 90,
                            label: 'RM70-100',
                            onTap: () => updatePreset(
                              math.min(70, availableMaxPrice),
                              math.min(100, availableMaxPrice),
                            ),
                          ),
                          _PricePresetButton(
                            width: 84,
                            label: 'Over RM100',
                            onTap: () => updatePreset(
                              math.min(100, availableMaxPrice),
                              availableMaxPrice,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Category:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: !categoriesLoaded
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : ListView.builder(
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final expanded = draftExpandedCategories
                                      .contains(category.id);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            if (expanded) {
                                              draftExpandedCategories
                                                  .remove(category.id);
                                            } else {
                                              draftExpandedCategories
                                                  .add(category.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                expanded
                                                    ? Icons.keyboard_arrow_down
                                                    : Icons.chevron_right,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  category.name,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: colors.primaryText,
                                                ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (expanded)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 28,
                                            bottom: 6,
                                          ),
                                          child: Column(
                                            children: category.subcategories
                                                .map((subcategory) {
                                              final checked =
                                                  draftSelectedSubcategories
                                                      .contains(subcategory.id);
                                              return CheckboxListTile(
                                                contentPadding:
                                                    EdgeInsets.zero,
                                                dense: true,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                title: Text(
                                                  subcategory.name,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: colors.primaryText,
                                                  ),
                                                ),
                                                value: checked,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    if (value == true) {
                                                      draftSelectedSubcategories
                                                          .add(subcategory.id);
                                                    } else {
                                                      draftSelectedSubcategories
                                                          .remove(subcategory.id);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      if (hasAppliedFilters)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    draftSortMode = null;
                                    draftMinPrice = 0;
                                    draftMaxPrice = availableMaxPrice;
                                    draftSelectedSubcategories.clear();
                                    draftExpandedCategories.clear();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2F6BFF),
                                  side: const BorderSide(
                                    color: Color(0xFF2F6BFF),
                                  ),
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Clear Filter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    sortMode = draftSortMode;
                                    selectedMinPrice = draftMinPrice;
                                    selectedMaxPrice =
                                        draftMaxPrice >= availableMaxPrice - 0.01
                                            ? null
                                            : draftMaxPrice;
                                    selectedSubcategoryIds
                                      ..clear()
                                      ..addAll(draftSelectedSubcategories);
                                    expandedCategoryIds
                                      ..clear()
                                      ..addAll(draftExpandedCategories);
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(37, 99, 235, 1),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Filter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sortMode = draftSortMode;
                                selectedMinPrice = draftMinPrice;
                                selectedMaxPrice =
                                    draftMaxPrice >= availableMaxPrice - 0.01
                                        ? null
                                        : draftMaxPrice;
                                selectedSubcategoryIds
                                  ..clear()
                                  ..addAll(draftSelectedSubcategories);
                                expandedCategoryIds
                                  ..clear()
                                  ..addAll(draftExpandedCategories);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(37, 99, 235, 1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Apply Filter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static String _formatCurrency(double value) {
    return formatRmPrice(value);
  }
}

class _FilterChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF1FF)
              : colors.softBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color:
                selected ? const Color(0xFF2F6BFF) : colors.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _PricePresetButton extends StatelessWidget {
  final double width;
  final String label;
  final VoidCallback onTap;

  const _PricePresetButton({
    required this.width,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.softBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.secondaryText,
          ),
        ),
      ),
    );
  }
}

class _FilterCategory {
  final String id;
  final String name;
  final List<_FilterSubcategory> subcategories;

  const _FilterCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });
}

class _FilterSubcategory {
  final String id;
  final String name;

  const _FilterSubcategory({
    required this.id,
    required this.name,
  });
}

class _ListingItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String sellerName;
  final String sellerEmail;
  final String sellerId;
  final String sellerStatus;
  final String listingStatus;
  final String saleStatus;
  final String categoryId;
  final String subcategoryId;
  final String subcategoryName;
  final String listingType;

  const _ListingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.sellerName,
    required this.sellerEmail,
    required this.sellerId,
    required this.sellerStatus,
    required this.listingStatus,
    required this.saleStatus,
    required this.categoryId,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.listingType,
  });

  factory _ListingItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final listingType =
        data['listing_type']?.toString().toLowerCase() ?? 'sell';
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return _ListingItem(
      id: doc.id,
      name: data['title']?.toString() ??
          data['name']?.toString() ??
          'Item Name',
      description: data['description']?.toString() ?? 'Description',
      price: parsedPrice,
      imagePath: data['image_path']?.toString() ?? '',
      sellerName:
          data['seller_name']?.toString() ?? data['sellerName']?.toString() ?? 'Seller Name',
      sellerEmail: data['seller_email']?.toString() ??
          data['sellerEmail']?.toString() ??
          'seller@siswa.unimas.my',
      sellerId: data['seller_id']?.toString() ?? '',
      sellerStatus: data['seller_status']?.toString() ?? 'active',
      listingStatus: data['listing_status']?.toString() ?? '',
      saleStatus: data['sale_status']?.toString() ?? '',
      categoryId: data['category_id']?.toString() ?? '',
      subcategoryId: data['subcategory_id']?.toString() ?? '',
      subcategoryName: data['subcategory_name']?.toString() ?? '',
      listingType: listingType,
    );
  }

  String get formattedPrice {
    if (listingType == 'donation' || price <= 0) {
      return 'Free';
    }
    return formatRmPrice(price);
  }

  Map<String, String> toDetailMap() {
    return {
      'id': id,
      'name': name,
      'price': formattedPrice,
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

class _ListingImage extends StatelessWidget {
  final String imagePath;

  const _ListingImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
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
      width: double.infinity,
      color: colors.softBackground,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: colors.tertiaryText,
          ),
        ),
      ),
    );
  }
}
