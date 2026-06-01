import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'student_theme.dart';

class SustainabilityRecordPage extends StatefulWidget {
  const SustainabilityRecordPage({super.key});

  @override
  State<SustainabilityRecordPage> createState() => _SustainabilityRecordPageState();
}

class _SustainabilityRecordPageState extends State<SustainabilityRecordPage> {
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedTipCategories = {};

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: SafeArea(
        child: currentUser == null
            ? Center(
                child: Text(
                  'Please sign in to view your sustainability record.',
                  style: TextStyle(color: colors.primaryText),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Category')
                    .orderBy('category_name')
                    .snapshots(),
                builder: (context, categorySnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('Listing')
                        .where('sale_status', isEqualTo: 'completed')
                        .snapshots(),
                    builder: (context, listingSnapshot) {
                      if (categorySnapshot.hasError || listingSnapshot.hasError) {
                        return _buildErrorState(context);
                      }

                      final isLoading =
                          (!categorySnapshot.hasData &&
                                  categorySnapshot.connectionState ==
                                      ConnectionState.waiting) ||
                              (!listingSnapshot.hasData &&
                                  listingSnapshot.connectionState ==
                                      ConnectionState.waiting);

                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final categoryDocs = categorySnapshot.data?.docs ?? const [];
                      final userListings = (listingSnapshot.data?.docs ?? const [])
                          .where((doc) => _belongsToUser(doc.data(), currentUser.uid))
                          .toList();
                      final metrics = _buildMetrics(categoryDocs, userListings);
                      final pieSegments = metrics.categoryCards
                          .map(
                            (card) => _RecordSegment(
                              percentage: card.percentage,
                              color: card.color,
                              label: card.name,
                              value: card.totalLabel,
                            ),
                          )
                          .toList();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildBackButton(context),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Sustainability Record',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                              decoration: _cardDecoration(),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Carbon Saved',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_formatKg(metrics.totalCarbon)} kg CO2e',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF06A845),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Equivalent to about ${_treesEquivalent(metrics.totalCarbon)} trees per year',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                              decoration: _cardDecoration(borderRadius: 24),
                              child: Column(
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: CustomPaint(
                                        painter: _PieChartPainter(pieSegments),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (metrics.categoryCards.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: colors.softBackground,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: colors.border),
                                      ),
                                      child: Text(
                                        'No sustainability record yet.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: colors.secondaryText,
                                        ),
                                      ),
                                    )
                                  else
                                    ...metrics.categoryCards.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final card = entry.value;
                                      final isExpanded =
                                          _expandedCategories[card.id] ?? false;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              index == metrics.categoryCards.length - 1
                                                  ? 0
                                                  : 14,
                                        ),
                                        child: _CategoryBreakdownStreamCard(
                                          card: card,
                                          listingDocs: userListings,
                                          expanded: isExpanded,
                                          onToggle: () {
                                            setState(() {
                                              _expandedCategories[card.id] =
                                                  !isExpanded;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _EmissionFactorsTipsCard(
                              categories: categoryDocs,
                              expandedCategories: _expandedTipCategories,
                              onToggle: (categoryId) {
                                setState(() {
                                  _expandedTipCategories[categoryId] =
                                      !(_expandedTipCategories[categoryId] ?? false);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  _RecordMetrics _buildMetrics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categories,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userListings,
  ) {
    if (categories.isEmpty || userListings.isEmpty) {
      return const _RecordMetrics(totalCarbon: 0, categoryCards: []);
    }

    final totalsByCategory = <String, double>{};
    final categoryNameById = <String, String>{};

    for (final categoryDoc in categories) {
      categoryNameById[categoryDoc.id] =
          categoryDoc.data()['category_name']?.toString() ?? 'Category';
    }

    var totalCarbon = 0.0;
    for (final listingDoc in userListings) {
      final data = listingDoc.data();
      final categoryId = data['category_id']?.toString();
      if (categoryId == null || !categoryNameById.containsKey(categoryId)) {
        continue;
      }
      final carbon = _asDouble(data['carbon_reduction']) > 0
          ? _asDouble(data['carbon_reduction'])
          : _asDouble(data['ef_used']);
      totalCarbon += carbon;
      totalsByCategory[categoryId] = (totalsByCategory[categoryId] ?? 0) + carbon;
    }

    if (totalCarbon <= 0) {
      return const _RecordMetrics(totalCarbon: 0, categoryCards: []);
    }

    final categoryCards = categories.asMap().entries
        .map((entry) {
          final doc = entry.value;
          final categoryTotal = totalsByCategory[doc.id] ?? 0;
          if (categoryTotal <= 0) {
            return null;
          }
          final percentage = ((categoryTotal / totalCarbon) * 100).round();
          return _CategoryCardData(
            id: doc.id,
            name: categoryNameById[doc.id] ?? 'Category',
            percentage: percentage,
            color: _categoryColor(entry.key),
            totalLabel: '${_formatKg(categoryTotal)} kg CO2e',
            subcategoriesStream: doc.reference
                .collection('SubCategory')
                .orderBy('subcategory_name')
                .snapshots(),
          );
        })
        .whereType<_CategoryCardData>()
        .toList();

    return _RecordMetrics(
      totalCarbon: totalCarbon,
      categoryCards: categoryCards,
    );
  }

  Color _categoryColor(int index) {
    final hue = (index * 67) % 360;
    return HSVColor.fromAHSV(1, hue.toDouble(), 0.86, 0.82).toColor();
  }

  BoxDecoration _cardDecoration({double borderRadius = 20}) {
    final colors = StudentThemeColors.of(context);
    return BoxDecoration(
      color: colors.cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: colors.border),
      boxShadow: [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          size: 22,
          color: colors.icon,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBackButton(context),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Sustainability Record',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(borderRadius: 22),
            child: Text(
              'Could not load sustainability data right now.',
              style: TextStyle(
                fontSize: 15,
                color: colors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _belongsToUser(Map<String, dynamic> data, String userId) {
    final sellerId = data['seller_id']?.toString();
    final bookedById = data['booked_by_id']?.toString();
    final receiverId = data['receiver_id']?.toString();
    return sellerId == userId || bookedById == userId || receiverId == userId;
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _formatKg(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _treesEquivalent(double totalCarbon) {
    return (totalCarbon / 22).toStringAsFixed(2);
  }
}

class _EmissionFactorsTipsCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> categories;
  final Map<String, bool> expandedCategories;
  final ValueChanged<String> onToggle;

  const _EmissionFactorsTipsCard({
    required this.categories,
    required this.expandedCategories,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: Color(0xFF12B76A),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emission Factors by Subcategory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Carbon saved shows the greenhouse gas emissions avoided when a used item is reused instead of a similar new item being made. The values below are emission factors that help estimate the climate impact avoided for each completed reuse.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'The formula used to calculate carbon saved is as below:\nCarbon saved = number of items x emission factor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: colors.tertiaryText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...categories.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final categoryId = doc.id;
            final categoryName =
                doc.data()['category_name']?.toString() ?? 'Category';
            final expanded = expandedCategories[categoryId] ?? false;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == categories.length - 1 ? 0 : 6,
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onToggle(categoryId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_down
                                : Icons.chevron_right,
                            size: 20,
                            color: colors.icon,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryName,
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
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 0, 8),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: doc.reference
                            .collection('SubCategory')
                            .orderBy('subcategory_name')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final subcategoryDocs = snapshot.data?.docs ?? const [];
                          if (subcategoryDocs.isEmpty) {
                            return Text(
                              'No subcategories available.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.tertiaryText,
                              ),
                            );
                          }

                          return Column(
                            children: subcategoryDocs.map((subDoc) {
                              final data = subDoc.data();
                              final name = data['subcategory_name']?.toString() ??
                                  'Subcategory';
                              final efValue = _asDoubleStatic(data['ef_value']);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.softBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primaryText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${_formatKgStatic(efValue)} kg CO2e',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF067647),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecordMetrics {
  final double totalCarbon;
  final List<_CategoryCardData> categoryCards;

  const _RecordMetrics({
    required this.totalCarbon,
    required this.categoryCards,
  });
}

class _CategoryCardData {
  final String id;
  final String name;
  final int percentage;
  final Color color;
  final String totalLabel;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? subcategoriesStream;

  const _CategoryCardData({
    required this.id,
    required this.name,
    required this.percentage,
    required this.color,
    required this.totalLabel,
    required this.subcategoriesStream,
  });
}

class _CategoryBreakdownCard extends StatelessWidget {
  final _CategoryCardData card;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryBreakdownCard({
    required this.card,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: colors.icon,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: card.color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: card.color.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                    child: Text(
                        '${card.percentage}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      card.totalLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF06A845),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.divider),
                ),
              ),
              child: _SubcategoryBreakdownList(
                card: card,
                listingDocs: const [],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownStreamCard extends StatelessWidget {
  final _CategoryCardData card;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryBreakdownStreamCard({
    required this.card,
    required this.listingDocs,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: colors.icon,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: card.color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: card.color.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${card.percentage}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      card.totalLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF06A845),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.divider),
                ),
              ),
              child: _SubcategoryBreakdownList(
                card: card,
                listingDocs: listingDocs,
              ),
            ),
        ],
      ),
    );
  }
}

class _SubcategoryBreakdownList extends StatelessWidget {
  final _CategoryCardData card;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs;

  const _SubcategoryBreakdownList({
    required this.card,
    required this.listingDocs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    if (card.subcategoriesStream == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          'No subcategories yet.',
          style: TextStyle(
            fontSize: 14,
            color: colors.secondaryText,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: card.subcategoriesStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              'No subcategories yet.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
          );
        }

        final totalsBySubcategory = <String, double>{};
        final countsBySubcategory = <String, int>{};
        final docsById = {
          for (final doc in docs) doc.id: doc,
        };
        final docsByName = {
          for (final doc in docs)
            (doc.data()['subcategory_name']?.toString().toLowerCase() ?? ''): doc,
        };

        for (final listingDoc in listingDocs) {
          final listingData = listingDoc.data();
          final listingCategoryId = listingData['category_id']?.toString();
          if (listingCategoryId != card.id) {
            continue;
          }

          final listingSubcategoryId = listingData['subcategory_id']?.toString();
          final listingSubcategoryName =
              listingData['subcategory_name']?.toString().toLowerCase();
          final matchedDoc = listingSubcategoryId != null
              ? docsById[listingSubcategoryId]
              : listingSubcategoryName != null
                  ? docsByName[listingSubcategoryName]
                  : null;

          if (matchedDoc == null) {
            continue;
          }

          final carbonReduction = _asStaticDouble(listingData['carbon_reduction']);
          final efUsed = _asStaticDouble(listingData['ef_used']);
          final fallbackEf = _asStaticDouble(matchedDoc.data()['ef_value']);
          final total = carbonReduction > 0
              ? carbonReduction
              : efUsed > 0
                  ? efUsed
                  : fallbackEf;

          totalsBySubcategory[matchedDoc.id] =
              (totalsBySubcategory[matchedDoc.id] ?? 0) + total;
          countsBySubcategory[matchedDoc.id] =
              (countsBySubcategory[matchedDoc.id] ?? 0) + 1;
        }

        final categoryTotal = totalsBySubcategory.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            children: docs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data();
              final numericValue = totalsBySubcategory[doc.id] ?? 0;
              final percentage = categoryTotal > 0
                  ? ((numericValue / categoryTotal) * 100).round()
                  : 0;
              final factor = '${_formatKgStatic(numericValue)} kg CO2e';

              return Padding(
                padding: EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 18),
                child: _SubcategoryRow(
                  name: data['subcategory_name']?.toString() ?? 'Subcategory',
                  value: factor,
                  percentage: percentage,
                  itemCount: countsBySubcategory[doc.id] ?? 0,
                  color: card.color,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  final String name;
  final String value;
  final int percentage;
  final int itemCount;
  final Color color;

  const _SubcategoryRow({
    required this.name,
    required this.value,
    required this.percentage,
    required this.itemCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$value ($percentage%)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF06A845),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${itemCount} ${itemCount == 1 ? 'item' : 'items'}',
          style: TextStyle(
            fontSize: 12,
            color: colors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: colors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecordSegment {
  final int percentage;
  final Color color;
  final String label;
  final String value;

  const _RecordSegment({
    required this.percentage,
    required this.color,
    required this.label,
    required this.value,
  });
}

double _asStaticDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String _formatKgStatic(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

double _asDoubleStatic(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

class _PieChartPainter extends CustomPainter {
  final List<_RecordSegment> segments;

  const _PieChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = 2 * math.pi * (segment.percentage / 100);
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final borderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = 2 * math.pi * (segment.percentage / 100);
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
