import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import '../widgets/floating_dropdown_field.dart';

class SustainabilityAdminPage extends StatefulWidget {
  const SustainabilityAdminPage({super.key});

  @override
  State<SustainabilityAdminPage> createState() => _SustainabilityAdminPageState();
}

class _SustainabilityAdminPageState extends State<SustainabilityAdminPage> {
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedFactorGroups = {};
  late final List<String> _years;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _years = List.generate(3, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Sustainability',
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          return _buildErrorState();
                        }

                        final isLoading =
                            (!categorySnapshot.hasData &&
                                    categorySnapshot.connectionState ==
                                        ConnectionState.waiting) ||
                                (!listingSnapshot.hasData &&
                                    listingSnapshot.connectionState ==
                                        ConnectionState.waiting);

                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final metrics = _buildMetrics(
                          categorySnapshot.data?.docs ?? const [],
                          listingSnapshot.data?.docs ?? const [],
                        );

                        final categoryDocs = categorySnapshot.data?.docs ?? const [];
                        final listingDocs = listingSnapshot.data?.docs ?? const [];
                        final filteredListingDocs = listingDocs.where((doc) {
                          final data = doc.data();
                          final year =
                              _extractYear(data['completed_at']) ??
                              _extractYear(data['created_at']);
                          return year == _selectedYear;
                        }).toList();
                        final filteredMetrics = _buildMetrics(
                          categoryDocs,
                          filteredListingDocs,
                        );

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFDCE3EE),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: Color(0xFF6B7A90),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: FloatingDropdownField<String>(
                                        value: _selectedYear,
                                        items: _years,
                                        hint: 'Select Year',
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _selectedYear = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _HeroMetricCard(
                                backgroundColor: const Color(0xFF06BA42),
                                title: 'Total Carbon Saved',
                                value:
                                    '${_formatKg(filteredMetrics.totalCarbonReduced)} kg CO2e',
                                subtitle:
                                    'Equivalent to about ${filteredMetrics.treesEquivalent} trees per year',
                                icon: Icons.eco_outlined,
                                iconColor: const Color(0xFF06A845),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SmallMetricCard(
                                      background: const LinearGradient(
                                        colors: [
                                          Color(0xFF357CFF),
                                          Color(0xFF1E5AE6),
                                        ],
                                      ),
                                      title: 'Items Sold/Donated',
                                      value:
                                          filteredMetrics.completedItemsCount.toString(),
                                      icon: Icons.inventory_2_outlined,
                                      iconColor: const Color(0xFF2F6BFF),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SmallMetricCard(
                                      background: const LinearGradient(
                                        colors: [
                                          Color(0xFFB24BFF),
                                          Color(0xFF8A1EFF),
                                        ],
                                      ),
                                      title: 'Avg. per Item',
                                      value:
                                          '${_formatKg(filteredMetrics.averageCarbonPerItem)} kg',
                                      icon: Icons.trending_up_rounded,
                                      iconColor: const Color(0xFF8A1EFF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _SectionCard(
                                title: 'Carbon Reduction by Category',
                                child: filteredMetrics.categoryStats.isEmpty
                                    ? const Text(
                                        'No completed item sustainability data yet.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7A90),
                                        ),
                                      )
                                    : Column(
                                        children: filteredMetrics.categoryStats.map((
                                          category,
                                        ) {
                                          final isLast = identical(
                                            category,
                                            filteredMetrics.categoryStats.last,
                                          );
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: isLast ? 0 : 18,
                                            ),
                                            child: _CategoryProgressStreamCard(
                                              key: ValueKey(category.id),
                                              categoryId: category.id,
                                              name: category.name,
                                              items:
                                                  '${category.completedItemsCount} ${category.completedItemsCount == 1 ? 'item' : 'items'} sold/donated',
                                              total:
                                                  '${_formatKg(category.totalCarbon)} kg CO2e',
                                              progress: category.progress,
                                              expanded:
                                                  _expandedCategories[
                                                      category.id] ??
                                                  false,
                                              listingDocs: filteredListingDocs,
                                              onToggle: () {
                                                setState(() {
                                                  _expandedCategories[
                                                          category.id] =
                                                      !(_expandedCategories[
                                                              category.id] ??
                                                          false);
                                                });
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                              const SizedBox(height: 20),
                              _SectionCard(
                                title: 'Emission Factors by Subcategory',
                                icon: Icons.auto_awesome_outlined,
                                description:
                                    'Carbon footprint avoided when items are reused instead of manufactured new.',
                                child: categoryDocs.isEmpty
                                    ? const Text(
                                        'No category or subcategory data yet.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7A90),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: categoryDocs.asMap().entries.map((
                                          entry,
                                        ) {
                                          final doc = entry.value;
                                          final isLast =
                                              entry.key == categoryDocs.length - 1;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: isLast ? 0 : 18,
                                            ),
                                            child: _FactorGroupStream(
                                              categoryId: doc.id,
                                              category:
                                                  doc.data()['category_name']
                                                      ?.toString() ??
                                                  'Category',
                                              expanded:
                                                  _expandedFactorGroups[doc.id] ??
                                                  false,
                                              onToggle: () {
                                                setState(() {
                                                  _expandedFactorGroups[doc.id] =
                                                      !(_expandedFactorGroups[
                                                              doc.id] ??
                                                          false);
                                                });
                                              },
                                              formatKg: _formatKg,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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
                    routeToItems: true,
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
                    selected: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Could not load sustainability data right now.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7A90),
          ),
        ),
      ),
    );
  }

  _AdminSustainabilityMetrics _buildMetrics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> categoryDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs,
  ) {
    final categories = categoryDocs
        .map(
          (doc) => _CategorySeed(
            id: doc.id,
            name: doc.data()['category_name']?.toString() ?? 'Category',
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final categorySeedByName = {
      for (final category in categories) category.name.toLowerCase(): category,
    };
    final categorySeedById = {
      for (final category in categories) category.id: category,
    };

    final categoryItemCounts = <String, int>{};
    final categoryCarbonTotals = <String, double>{};

    var totalCarbonReduced = 0.0;

    for (final listingDoc in listingDocs) {
      final data = listingDoc.data();
      final categoryId = data['category_id']?.toString();
      final categoryName = data['category_name']?.toString();

      final categorySeed = categoryId != null
          ? categorySeedById[categoryId]
          : categoryName != null
              ? categorySeedByName[categoryName.toLowerCase()]
              : null;

      if (categorySeed == null) {
        continue;
      }

      final carbonReduction = _asDouble(data['carbon_reduction']);
      final efUsed = _asDouble(data['ef_used']);
      final listingCarbon = carbonReduction > 0
          ? carbonReduction
          : efUsed > 0
              ? efUsed
              : 0.0;

      totalCarbonReduced += listingCarbon;
      categoryItemCounts[categorySeed.id] =
          (categoryItemCounts[categorySeed.id] ?? 0) + 1;
      categoryCarbonTotals[categorySeed.id] =
          (categoryCarbonTotals[categorySeed.id] ?? 0) + listingCarbon;
    }

    final maxCategoryCarbon = categories.fold<double>(0, (currentMax, category) {
      final total = categoryCarbonTotals[category.id] ?? 0;
      return math.max(currentMax, total);
    });

    final categoryStats = categories.map((category) {
      final categoryTotal = categoryCarbonTotals[category.id] ?? 0;
      final categoryCount = categoryItemCounts[category.id] ?? 0;

      return _AdminCategoryStat(
        id: category.id,
        name: category.name,
        completedItemsCount: categoryCount,
        totalCarbon: categoryTotal,
        progress: maxCategoryCarbon > 0 ? categoryTotal / maxCategoryCarbon : 0.0,
      );
    }).toList();

    final completedItemsCount = listingDocs.length;
    final averageCarbonPerItem =
        completedItemsCount > 0 ? totalCarbonReduced / completedItemsCount : 0.0;
    final treesEquivalent = (totalCarbonReduced / 22).toStringAsFixed(2);

    return _AdminSustainabilityMetrics(
      totalCarbonReduced: totalCarbonReduced,
      completedItemsCount: completedItemsCount,
      averageCarbonPerItem: averageCarbonPerItem,
      treesEquivalent: treesEquivalent,
      categoryStats: categoryStats,
    );
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

  String? _extractYear(Object? value) {
    if (value is Timestamp) {
      return value.toDate().year.toString();
    }
    if (value is DateTime) {
      return value.year.toString();
    }
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed.year.toString();
    }
    final match = RegExp(r'(\d{4})').firstMatch(raw);
    return match?.group(1);
  }

}

double _asStaticDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

List<Map<String, Object>> _buildCategorySubcategoryRows({
  required String categoryId,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> subcategoryDocs,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs,
}) {
  final totals = <String, double>{};
  final counts = <String, int>{};
  final docsById = {
    for (final doc in subcategoryDocs) doc.id: doc,
  };
  final docsByName = {
    for (final doc in subcategoryDocs)
      (doc.data()['subcategory_name']?.toString().toLowerCase() ?? ''): doc,
  };

  for (final listingDoc in listingDocs) {
    final data = listingDoc.data();
    final listingCategoryId = data['category_id']?.toString();
    if (listingCategoryId != null && listingCategoryId != categoryId) {
      continue;
    }

    if (listingCategoryId == null) {
      continue;
    }

    final subcategoryId = data['subcategory_id']?.toString();
    final subcategoryName = data['subcategory_name']?.toString().toLowerCase();
    final matchedDoc = subcategoryId != null
        ? docsById[subcategoryId]
        : subcategoryName != null
            ? docsByName[subcategoryName]
            : null;

    if (matchedDoc == null) {
      continue;
    }

    final carbonReduction = _asStaticDouble(data['carbon_reduction']);
    final efUsed = _asStaticDouble(data['ef_used']);
    final fallbackEf = _asStaticDouble(matchedDoc.data()['ef_value']);
    final total = carbonReduction > 0
        ? carbonReduction
        : efUsed > 0
            ? efUsed
            : fallbackEf;

    totals[matchedDoc.id] = (totals[matchedDoc.id] ?? 0) + total;
    counts[matchedDoc.id] = (counts[matchedDoc.id] ?? 0) + 1;
  }

  final categoryTotal = totals.values.fold<double>(0, (sum, value) => sum + value);

  return subcategoryDocs.map((doc) {
    final data = doc.data();
    final total = totals[doc.id] ?? 0;
    final count = counts[doc.id] ?? 0;
    final efValue = _asStaticDouble(data['ef_value']);
    return {
      'name': data['subcategory_name']?.toString() ?? 'Subcategory',
      'items': '${count} ${count == 1 ? 'item' : 'items'}',
      'factor': '${_formatKgStatic(efValue)} kg CO2e per item',
      'total': '${_formatKgStatic(total)} kg',
      'progress': categoryTotal > 0 ? total / categoryTotal : 0.0,
    };
  }).toList();
}

String _formatKgStatic(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

class _AdminSustainabilityMetrics {
  final double totalCarbonReduced;
  final int completedItemsCount;
  final double averageCarbonPerItem;
  final String treesEquivalent;
  final List<_AdminCategoryStat> categoryStats;

  const _AdminSustainabilityMetrics({
    required this.totalCarbonReduced,
    required this.completedItemsCount,
    required this.averageCarbonPerItem,
    required this.treesEquivalent,
    required this.categoryStats,
  });
}

class _CategorySeed {
  final String id;
  final String name;

  const _CategorySeed({
    required this.id,
    required this.name,
  });
}

class _SubcategorySeed {
  final String id;
  final String categoryId;
  final String name;
  final double efValue;

  const _SubcategorySeed({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.efValue,
  });
}

class _AdminCategoryStat {
  final String id;
  final String name;
  final int completedItemsCount;
  final double totalCarbon;
  final double progress;

  const _AdminCategoryStat({
    required this.id,
    required this.name,
    required this.completedItemsCount,
    required this.totalCarbon,
    required this.progress,
  });
}

class _HeroMetricCard extends StatelessWidget {
  final Color backgroundColor;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _HeroMetricCard({
    required this.backgroundColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  final Gradient background;
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SmallMetricCard({
    required this.background,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.icon,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF06BA42), size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A2342),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 14),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF334A68),
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final String name;
  final String items;
  final String total;
  final double progress;
  final List<Map<String, Object>> subcategories;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryProgressCard({
    super.key,
    required this.name,
    required this.items,
    required this.total,
    required this.progress,
    required this.subcategories,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: const Color(0xFF4C647F),
                  size: 24,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A2342),
                    ),
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00914F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              items,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7A90),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE1E6EE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF06BA42)),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            ...subcategories.map((subcategory) {
              final isLast = identical(subcategory, subcategories.last);
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: _SubcategoryProgressRow(
                  name: subcategory['name'] as String,
                  items: subcategory['items'] as String,
                  factor: subcategory['factor'] as String,
                  total: subcategory['total'] as String,
                  progress: subcategory['progress'] as double,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CategoryProgressStreamCard extends StatelessWidget {
  final String categoryId;
  final String name;
  final String items;
  final String total;
  final double progress;
  final bool expanded;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs;
  final VoidCallback onToggle;

  const _CategoryProgressStreamCard({
    super.key,
    required this.categoryId,
    required this.name,
    required this.items,
    required this.total,
    required this.progress,
    required this.expanded,
    required this.listingDocs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Category')
          .doc(categoryId)
          .collection('SubCategory')
          .orderBy('subcategory_name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CategoryProgressCard(
            name: name,
            items: items,
            total: total,
            progress: progress,
            subcategories: const [],
            expanded: expanded,
            onToggle: onToggle,
          );
        }

        final subcategoryDocs = snapshot.data?.docs ?? const [];
        final subcategories = _buildCategorySubcategoryRows(
          categoryId: categoryId,
          subcategoryDocs: subcategoryDocs,
          listingDocs: listingDocs,
        );

        return _CategoryProgressCard(
          name: name,
          items: items,
          total: total,
          progress: progress,
          subcategories: subcategories,
          expanded: expanded,
          onToggle: onToggle,
        );
      },
    );
  }
}

class _SubcategoryProgressRow extends StatelessWidget {
  final String name;
  final String items;
  final String factor;
  final String total;
  final double progress;

  const _SubcategoryProgressRow({
    required this.name,
    required this.items,
    required this.factor,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: 88,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF9FF0B9),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A2342),
                      ),
                    ),
                  ),
                  Text(
                    total,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00914F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$items • $factor',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7A90),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEFF2F6),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF06BA42)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FactorGroup extends StatelessWidget {
  final String category;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Map<String, String>> subcategories;

  const _FactorGroup({
    required this.category,
    required this.expanded,
    required this.onToggle,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  color: const Color(0xFF4C647F),
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2342),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 12),
          ...subcategories.map((subcategory) {
            final isLast = identical(subcategory, subcategories.last);
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: _FactorTile(
                title: subcategory['name']!,
                value: subcategory['factor']!,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _FactorGroupStream extends StatelessWidget {
  final String categoryId;
  final String category;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(double value) formatKg;

  const _FactorGroupStream({
    required this.categoryId,
    required this.category,
    required this.expanded,
    required this.onToggle,
    required this.formatKg,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Category')
          .doc(categoryId)
          .collection('SubCategory')
          .orderBy('subcategory_name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return _FactorGroup(
          category: category,
          expanded: expanded,
          onToggle: onToggle,
          subcategories: docs
              .map(
                (doc) => {
                  'name': doc.data()['subcategory_name']?.toString() ??
                      'Subcategory',
                  'factor':
                      '${formatKg(_asStaticDouble(doc.data()['ef_value']))} kg CO2',
                },
              )
              .toList(),
        );
      },
    );
  }
}

class _FactorTile extends StatelessWidget {
  final String title;
  final String value;

  const _FactorTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FFF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9FF0B9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A2342),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00914F),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToItems;
  final bool routeToCategories;
  final bool routeToReports;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
    this.routeToCategories = false,
    this.routeToReports = false,
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
        : routeToItems
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemListPage(),
                  ),
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
