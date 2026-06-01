import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'category_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';
import '../widgets/floating_dropdown_field.dart';

class SalesReportAdminPage extends StatefulWidget {
  const SalesReportAdminPage({super.key});

  @override
  State<SalesReportAdminPage> createState() => _SalesReportAdminPageState();
}

class _SalesReportAdminPageState extends State<SalesReportAdminPage> {
  final Map<String, Color> _categoryColors = const {
    'Electronics': Color(0xFF2F6BFF),
    'Clothing': Color(0xFF8B2CFF),
    'Furniture': Color(0xFFE61E8C),
    'Books': Color(0xFFF59E0B),
    'Home Appliances': Color(0xFF10B981),
  };

  late String _selectedYear;
  bool _showCategory = true;
  String _selectedCategory = 'All Categories';
  String? _selectedSubcategoryCategory;
  String _selectedSubcategory = 'All Subcategories';

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
  }

  bool _isSaleListing(Map<String, dynamic> data) {
    final type = data['listing_type']?.toString().toLowerCase() ?? '';
    return type == 'sell' || type == 'sale';
  }

  int? _extractYear(dynamic value) {
    if (value is Timestamp) return value.toDate().year;
    if (value is DateTime) return value.year;
    return null;
  }

  int? _extractMonthIndex(dynamic value) {
    if (value is Timestamp) return value.toDate().month - 1;
    if (value is DateTime) return value.month - 1;
    return null;
  }

  Color _colorForIndex(int index) {
    const palette = [
      Color(0xFF4C8DFF),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF06B6D4),
      Color(0xFF6366F1),
      Color(0xFFEF4444),
    ];
    return palette[index % palette.length];
  }

  List<String> _buildYearOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> listingDocs,
  ) {
    final years = <int>{DateTime.now().year};
    for (final doc in listingDocs) {
      final data = doc.data();
      final year =
          _extractYear(data['completed_at']) ?? _extractYear(data['created_at']);
      if (year != null) years.add(year);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted.map((year) => year.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Report',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A2342),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Monthly sales data and trends',
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
                      child:
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('Category')
                            .orderBy('category_name')
                            .snapshots(),
                        builder: (context, categorySnapshot) {
                          return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('Listing')
                                .where('sale_status', isEqualTo: 'completed')
                                .snapshots(),
                            builder: (context, listingSnapshot) {
                              if (categorySnapshot.hasError ||
                                  listingSnapshot.hasError) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Could not load sales report data right now.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF6B7A90),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final waitingForCategories =
                                  !categorySnapshot.hasData &&
                                      categorySnapshot.connectionState ==
                                          ConnectionState.waiting;
                              final waitingForListings = !listingSnapshot.hasData &&
                                  listingSnapshot.connectionState ==
                                      ConnectionState.waiting;

                              if (waitingForCategories || waitingForListings) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final categoryDocs =
                                  categorySnapshot.data?.docs ?? const [];
                              final allCompletedListings =
                                  listingSnapshot.data?.docs ?? const [];
                              final saleListingDocs = allCompletedListings
                                  .where((doc) => _isSaleListing(doc.data()))
                                  .toList();

                              final yearOptions = _buildYearOptions(
                                saleListingDocs,
                              );
                              final effectiveSelectedYear =
                                  yearOptions.contains(_selectedYear)
                                      ? _selectedYear
                                      : yearOptions.first;

                              final filteredSalesDocs =
                                  saleListingDocs.where((doc) {
                                final data = doc.data();
                                final year =
                                    _extractYear(data['completed_at']) ??
                                        _extractYear(data['created_at']);
                                return year?.toString() == effectiveSelectedYear;
                              }).toList();

                              final categorySeeds = categoryDocs
                                  .map(
                                    (doc) => _CategorySeed(
                                      id: doc.id,
                                      name:
                                          doc.data()['category_name']?.toString() ??
                                              'Category',
                                    ),
                                  )
                                  .toList()
                                ..sort(
                                  (a, b) => a.name.toLowerCase().compareTo(
                                        b.name.toLowerCase(),
                                      ),
                                );

                              final categorySeedById = {
                                for (final category in categorySeeds)
                                  category.id: category.name,
                              };
                              final categorySeedByName = {
                                for (final category in categorySeeds)
                                  category.name.toLowerCase(): category.name,
                              };
                              final categoryIdByName = {
                                for (final category in categorySeeds)
                                  category.name: category.id,
                              };

                              final monthlyTrend = List<double>.filled(12, 0);
                              final categoryCountMap = <String, int>{
                                for (final category in categorySeeds)
                                  category.name: 0,
                              };
                              final categoryTrendMap = <String, List<double>>{
                                for (final category in categorySeeds)
                                  category.name: List<double>.filled(12, 0),
                              };
                              final subcategoryCountByCategory =
                                  <String, Map<String, int>>{};
                              final subcategoryTrendByCategory =
                                  <String, Map<String, List<double>>>{};

                              for (final listingDoc in filteredSalesDocs) {
                                final data = listingDoc.data();
                                final monthIndex =
                                    _extractMonthIndex(data['completed_at']) ??
                                        _extractMonthIndex(data['created_at']);
                                if (monthIndex == null ||
                                    monthIndex < 0 ||
                                    monthIndex > 11) {
                                  continue;
                                }

                                final rawCategoryId =
                                    data['category_id']?.toString();
                                final rawCategoryName =
                                    data['category_name']?.toString();
                                final categoryName =
                                    (rawCategoryId != null
                                            ? categorySeedById[rawCategoryId]
                                            : null) ??
                                        (rawCategoryName != null
                                            ? categorySeedByName[
                                                rawCategoryName.toLowerCase()]
                                            : null) ??
                                        rawCategoryName;
                                if (categoryName == null ||
                                    categoryName.trim().isEmpty) {
                                  continue;
                                }

                                final subcategoryName =
                                    data['subcategory_name']?.toString().trim();

                                monthlyTrend[monthIndex] += 1;
                                categoryCountMap[categoryName] =
                                    (categoryCountMap[categoryName] ?? 0) + 1;
                                (categoryTrendMap[categoryName] ??=
                                        List<double>.filled(12, 0))[monthIndex] +=
                                    1;

                                if (subcategoryName != null &&
                                    subcategoryName.isNotEmpty) {
                                  final subcategoryCounts =
                                      subcategoryCountByCategory.putIfAbsent(
                                    categoryName,
                                    () => <String, int>{},
                                  );
                                  subcategoryCounts[subcategoryName] =
                                      (subcategoryCounts[subcategoryName] ?? 0) +
                                          1;

                                  final subcategoryTrends =
                                      subcategoryTrendByCategory.putIfAbsent(
                                    categoryName,
                                    () => <String, List<double>>{},
                                  );
                                  final monthValues =
                                      subcategoryTrends.putIfAbsent(
                                    subcategoryName,
                                    () => List<double>.filled(12, 0),
                                  );
                                  monthValues[monthIndex] += 1;
                                }
                              }

                              final categoryStats = categorySeeds
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => _SalesStat(
                                      name: entry.value.name,
                                      value:
                                          categoryCountMap[entry.value.name] ?? 0,
                                      color:
                                          _categoryColors[entry.value.name] ??
                                              _colorForIndex(entry.key),
                                    ),
                                  )
                                  .toList();

                              final categoryOptions = [
                                'All Categories',
                                ...categoryStats.map((stat) => stat.name),
                              ];
                              final effectiveSelectedCategory =
                                  categoryOptions.contains(_selectedCategory)
                                      ? _selectedCategory
                                      : 'All Categories';
                              final selectedCategoryStat = categoryStats.firstWhere(
                                (stat) => stat.name == effectiveSelectedCategory,
                                orElse: () => _SalesStat(
                                  name: 'All Categories',
                                  value: filteredSalesDocs.length,
                                  color: const Color(0xFF4C8DFF),
                                ),
                              );

                              final subcategoryCategoryOptions =
                                  categoryStats.map((stat) => stat.name).toList();
                              final effectiveSubcategoryCategory =
                                  subcategoryCategoryOptions.contains(
                                _selectedSubcategoryCategory,
                              )
                                      ? _selectedSubcategoryCategory
                                      : null;
                              final hasSelectedSubcategoryCategory =
                                  effectiveSubcategoryCategory != null;

                              final selectedCategorySubcategoryMap =
                                  subcategoryCountByCategory[
                                          effectiveSelectedCategory] ??
                                      const <String, int>{};
                              final selectedCategorySubcategorySeriesMap =
                                  subcategoryTrendByCategory[
                                          effectiveSelectedCategory] ??
                                      const <String, List<double>>{};
                              final selectedCategorySubcategoryStatModels =
                                  selectedCategorySubcategoryMap.entries
                                      .toList()
                                    ..sort((a, b) => a.key.compareTo(b.key));
                              final selectedCategorySubcategoryStats =
                                  selectedCategorySubcategoryStatModels
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _SalesStat(
                                          name: entry.value.key,
                                          value: entry.value.value,
                                          color: _colorForIndex(entry.key),
                                        ),
                                      )
                                      .toList();

                              final subcategoryStatsMap =
                                  hasSelectedSubcategoryCategory
                                      ? (subcategoryCountByCategory[
                                              effectiveSubcategoryCategory] ??
                                          const <String, int>{})
                                      : const <String, int>{};
                              final subcategorySeriesMap =
                                  hasSelectedSubcategoryCategory
                                      ? (subcategoryTrendByCategory[
                                              effectiveSubcategoryCategory] ??
                                          const <String, List<double>>{})
                                      : const <String, List<double>>{};
                              final subcategoryStatEntries =
                                  subcategoryStatsMap.entries.toList()
                                    ..sort((a, b) => a.key.compareTo(b.key));
                              final subcategoryStats = subcategoryStatEntries
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => _SalesStat(
                                      name: entry.value.key,
                                      value: entry.value.value,
                                      color: _colorForIndex(entry.key),
                                    ),
                                  )
                                  .toList();
                              final subcategoryOptions = [
                                'All Subcategories',
                                ...subcategoryStats.map((stat) => stat.name),
                              ];
                              final effectiveSelectedSubcategory =
                                  subcategoryOptions.contains(_selectedSubcategory)
                                      ? _selectedSubcategory
                                      : 'All Subcategories';
                              final selectedSubcategoryStat =
                                  effectiveSelectedSubcategory ==
                                              'All Subcategories' &&
                                          subcategoryStats.isNotEmpty
                                      ? _SalesStat(
                                          name: 'All Subcategories',
                                          value: subcategoryStats.fold<int>(
                                            0,
                                            (sum, stat) => sum + stat.value,
                                          ),
                                          color: const Color(0xFF4C8DFF),
                                        )
                                      : subcategoryStats.firstWhere(
                                          (stat) =>
                                              stat.name ==
                                              effectiveSelectedSubcategory,
                                          orElse: () => const _SalesStat(
                                            name: 'All Subcategories',
                                            value: 0,
                                            color: Color(0xFF4C8DFF),
                                          ),
                                        );

                              final subcategoryTrendSeries =
                                  effectiveSelectedSubcategory ==
                                              'All Subcategories'
                                      ? subcategoryStats
                                          .where(
                                            (stat) => subcategorySeriesMap
                                                .containsKey(stat.name),
                                          )
                                          .map(
                                            (stat) => _ChartSeries(
                                              color: stat.color,
                                              values:
                                                  subcategorySeriesMap[stat.name]!,
                                            ),
                                          )
                                          .toList()
                                      : [
                                          _ChartSeries(
                                            color: selectedSubcategoryStat.color,
                                            values: subcategorySeriesMap[
                                                    effectiveSelectedSubcategory] ??
                                                List<double>.filled(12, 0),
                                          ),
                                        ];

                              return SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 28),
                                child: Column(
                                  children: [
                                    _FilterShell(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: Color(0xFF6B7A90),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: FloatingDropdownField<String>(
                                              value: effectiveSelectedYear,
                                              items: yearOptions,
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
                                    _SummaryCard(
                                      year: effectiveSelectedYear,
                                      totalSales: filteredSalesDocs.length,
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _SegmentButton(
                                            label: 'By Category',
                                            selected: _showCategory,
                                            onTap: () {
                                              setState(() {
                                                _showCategory = true;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _SegmentButton(
                                            label: 'By Subcategory',
                                            selected: !_showCategory,
                                            onTap: () {
                                              setState(() {
                                                _showCategory = false;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _FilterShell(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Select Category',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF233B5E),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          FloatingDropdownField<String>(
                                            value: _showCategory
                                                ? effectiveSelectedCategory
                                                : effectiveSubcategoryCategory,
                                            items: _showCategory
                                                ? categoryOptions
                                                : subcategoryCategoryOptions,
                                            hint: _showCategory
                                                ? 'All Categories'
                                                : 'Select Category',
                                            onChanged: (value) {
                                              if (value == null) return;
                                              setState(() {
                                                if (_showCategory) {
                                                  _selectedCategory = value;
                                                } else {
                                                  _selectedSubcategoryCategory =
                                                      value;
                                                  _selectedSubcategory =
                                                      'All Subcategories';
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_showCategory)
                                      (effectiveSelectedCategory ==
                                              'All Categories'
                                          ? GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: categoryStats.length,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                mainAxisSpacing: 16,
                                                crossAxisSpacing: 16,
                                                childAspectRatio: 1.15,
                                              ),
                                              itemBuilder: (context, index) {
                                                final stat = categoryStats[index];
                                                return _SalesStatCard(stat: stat);
                                              },
                                            )
                                          : _SubcategorySummaryCard(
                                              stat: selectedCategoryStat,
                                              year: effectiveSelectedYear,
                                              categoryLabel:
                                                  selectedCategoryStat.name,
                                            ))
                                    else ...[
                                      if (hasSelectedSubcategoryCategory)
                                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection('Category')
                                              .doc(categoryIdByName[
                                                      effectiveSubcategoryCategory] ??
                                                  '')
                                              .collection('SubCategory')
                                              .snapshots(),
                                          builder: (context, subcategorySnapshot) {
                                            final subcategoryDocs =
                                                subcategorySnapshot.data?.docs ?? const [];
                                            final allSubcategoryNames = subcategoryDocs
                                                .map((doc) =>
                                                    doc.data()['subcategory_name']
                                                        ?.toString()
                                                        .trim() ??
                                                    '')
                                                .where((name) => name.isNotEmpty)
                                                .toList()
                                              ..sort();

                                            final mergedSubcategoryNames = [
                                              ...allSubcategoryNames,
                                              ...subcategoryStatsMap.keys.where(
                                                (name) =>
                                                    !allSubcategoryNames.contains(name),
                                              ),
                                            ];

                                            final mergedSubcategoryStats = mergedSubcategoryNames
                                                .asMap()
                                                .entries
                                                .map(
                                                  (entry) => _SalesStat(
                                                    name: entry.value,
                                                    value: subcategoryStatsMap[
                                                            entry.value] ??
                                                        0,
                                                    color: _colorForIndex(entry.key),
                                                  ),
                                                )
                                                .toList();

                                            final mergedSubcategorySeriesMap = {
                                              for (final entry
                                                  in mergedSubcategoryStats.asMap().entries)
                                                entry.value.name: _ChartSeries(
                                                  color: entry.value.color,
                                                  values: subcategorySeriesMap[
                                                          entry.value.name] ??
                                                      List<double>.filled(12, 0),
                                                ),
                                            };

                                            final mergedSubcategoryOptions = [
                                              'All Subcategories',
                                              ...mergedSubcategoryStats
                                                  .map((stat) => stat.name),
                                            ];
                                            final localSelectedSubcategory =
                                                mergedSubcategoryOptions.contains(
                                                      _selectedSubcategory,
                                                    )
                                                    ? _selectedSubcategory
                                                    : 'All Subcategories';
                                            final localSelectedSubcategoryStat =
                                                localSelectedSubcategory ==
                                                            'All Subcategories' &&
                                                        mergedSubcategoryStats
                                                            .isNotEmpty
                                                    ? _SalesStat(
                                                        name:
                                                            'All Subcategories',
                                                        value: mergedSubcategoryStats
                                                            .fold<int>(
                                                          0,
                                                          (sum, stat) =>
                                                              sum + stat.value,
                                                        ),
                                                        color: const Color(
                                                          0xFF4C8DFF,
                                                        ),
                                                      )
                                                    : mergedSubcategoryStats
                                                        .firstWhere(
                                                        (stat) =>
                                                            stat.name ==
                                                            localSelectedSubcategory,
                                                        orElse: () =>
                                                            const _SalesStat(
                                                          name:
                                                              'All Subcategories',
                                                          value: 0,
                                                          color: Color(
                                                            0xFF4C8DFF,
                                                          ),
                                                        ),
                                                      );
                                            final localSubcategoryTrendSeries =
                                                localSelectedSubcategory ==
                                                        'All Subcategories'
                                                    ? mergedSubcategoryStats
                                                        .where(
                                                          (stat) =>
                                                              mergedSubcategorySeriesMap
                                                                  .containsKey(
                                                            stat.name,
                                                          ),
                                                        )
                                                        .map(
                                                          (stat) =>
                                                              mergedSubcategorySeriesMap[
                                                                  stat.name]!,
                                                        )
                                                        .toList()
                                                    : [
                                                        mergedSubcategorySeriesMap[
                                                                localSelectedSubcategory] ??
                                                            _ChartSeries(
                                                              color:
                                                                  localSelectedSubcategoryStat
                                                                      .color,
                                                              values: List<
                                                                  double>.filled(
                                                                12,
                                                                0,
                                                              ),
                                                            ),
                                                      ];

                                            return Column(
                                              children: [
                                                _FilterShell(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Select Subcategory',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF233B5E),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      FloatingDropdownField<
                                                          String>(
                                                        value:
                                                            localSelectedSubcategory,
                                                        items:
                                                            mergedSubcategoryOptions,
                                                        hint:
                                                            'All Subcategories',
                                                        onChanged: (value) {
                                                          if (value == null) {
                                                            return;
                                                          }
                                                          setState(() {
                                                            _selectedSubcategory =
                                                                value;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                _SubcategorySummaryCard(
                                                  stat:
                                                      localSelectedSubcategoryStat,
                                                  year: effectiveSelectedYear,
                                                  categoryLabel:
                                                      effectiveSubcategoryCategory ??
                                                          'Select Category',
                                                ),
                                                const SizedBox(height: 24),
                                                _TrendCard(
                                                  values: localSelectedSubcategory ==
                                                          'All Subcategories'
                                                      ? (localSubcategoryTrendSeries
                                                              .isNotEmpty
                                                          ? localSubcategoryTrendSeries
                                                              .first.values
                                                          : List<double>.filled(
                                                              12,
                                                              0,
                                                            ))
                                                      : (mergedSubcategorySeriesMap[
                                                              localSelectedSubcategory]
                                                          ?.values ??
                                                          List<double>.filled(
                                                            12,
                                                            0,
                                                          )),
                                                  title:
                                                      '${effectiveSubcategoryCategory!} - $localSelectedSubcategory',
                                                  series: localSubcategoryTrendSeries,
                                                  monthlyBreakdown:
                                                      localSelectedSubcategory ==
                                                              'All Subcategories'
                                                          ? mergedSubcategorySeriesMap
                                                          : {
                                                              localSelectedSubcategory:
                                                                  mergedSubcategorySeriesMap[
                                                                          localSelectedSubcategory] ??
                                                                      _ChartSeries(
                                                                        color:
                                                                            localSelectedSubcategoryStat.color,
                                                                        values: List<double>.filled(
                                                                          12,
                                                                          0,
                                                                        ),
                                                                      ),
                                                            },
                                                  legendEntries:
                                                      localSelectedSubcategory ==
                                                              'All Subcategories'
                                                          ? {
                                                              for (final stat
                                                                  in mergedSubcategoryStats)
                                                                stat.name:
                                                                    stat.color,
                                                            }
                                                          : null,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                    if (_showCategory) ...[
                                      const SizedBox(height: 24),
                                      _TrendCard(
                                        values: _showCategory
                                            ? (effectiveSelectedCategory ==
                                                    'All Categories'
                                                ? monthlyTrend
                                                : (categoryTrendMap[
                                                        effectiveSelectedCategory] ??
                                                    List<double>.filled(12, 0)))
                                            : (effectiveSelectedSubcategory ==
                                                    'All Subcategories'
                                                ? (subcategoryTrendSeries
                                                        .isNotEmpty
                                                    ? subcategoryTrendSeries
                                                        .first.values
                                                    : List<double>.filled(
                                                        12,
                                                        0,
                                                      ))
                                                : (subcategorySeriesMap[
                                                        effectiveSelectedSubcategory] ??
                                                    List<double>.filled(12, 0))),
                                        title: _showCategory
                                            ? (effectiveSelectedCategory ==
                                                    'All Categories'
                                                ? 'Sales per Month Trend'
                                                : 'Sales per Month Trend - $effectiveSelectedCategory')
                                            : '${effectiveSubcategoryCategory!} - $effectiveSelectedSubcategory',
                                        series: _showCategory
                                            ? (effectiveSelectedCategory ==
                                                    'All Categories'
                                                ? null
                                                : [
                                                    _ChartSeries(
                                                      color:
                                                          selectedCategoryStat.color,
                                                      values: categoryTrendMap[
                                                              effectiveSelectedCategory] ??
                                                          List<double>.filled(
                                                              12, 0),
                                                    ),
                                                  ])
                                            : subcategoryTrendSeries,
                                        monthlyBreakdown: _showCategory &&
                                                effectiveSelectedCategory ==
                                                    'All Categories'
                                            ? categoryTrendMap.map(
                                                (key, value) => MapEntry(
                                                  key,
                                                  _ChartSeries(
                                                    color: _categoryColors[key] ??
                                                        _colorForIndex(
                                                          categoryOptions
                                                              .indexOf(key),
                                                        ),
                                                    values: value,
                                                  ),
                                                ),
                                              )
                                            : _showCategory &&
                                                    effectiveSelectedCategory !=
                                                        'All Categories'
                                                ? selectedCategorySubcategorySeriesMap
                                                    .map(
                                                    (key, value) => MapEntry(
                                                      key,
                                                      _ChartSeries(
                                                        color:
                                                            selectedCategorySubcategoryStats
                                                                .firstWhere(
                                                                  (stat) =>
                                                                      stat.name ==
                                                                      key,
                                                                  orElse: () =>
                                                                      const _SalesStat(
                                                                    name:
                                                                        'Subcategory',
                                                                    value: 0,
                                                                    color: Color(
                                                                      0xFF4C8DFF,
                                                                    ),
                                                                  ),
                                                                )
                                                                .color,
                                                        values: value,
                                                      ),
                                                    ),
                                                  )
                                                : (!_showCategory &&
                                                        effectiveSelectedSubcategory ==
                                                            'All Subcategories')
                                                    ? subcategorySeriesMap.map(
                                                        (key, value) => MapEntry(
                                                          key,
                                                          _ChartSeries(
                                                            color:
                                                                subcategoryStats
                                                                    .firstWhere(
                                                                      (stat) =>
                                                                          stat.name ==
                                                                          key,
                                                                      orElse: () =>
                                                                          const _SalesStat(
                                                                        name:
                                                                            'Subcategory',
                                                                        value: 0,
                                                                        color:
                                                                            Color(
                                                                          0xFF4C8DFF,
                                                                        ),
                                                                      ),
                                                                    )
                                                                    .color,
                                                            values: value,
                                                          ),
                                                        ),
                                                      )
                                                    : {
                                                        effectiveSelectedSubcategory:
                                                            _ChartSeries(
                                                          color:
                                                              selectedSubcategoryStat
                                                                  .color,
                                                          values: subcategorySeriesMap[
                                                                  effectiveSelectedSubcategory] ??
                                                              List<double>.filled(
                                                                12,
                                                                0,
                                                              ),
                                                        ),
                                                      },
                                        legendEntries: !_showCategory &&
                                                effectiveSelectedSubcategory ==
                                                    'All Subcategories'
                                            ? {
                                                for (final stat
                                                    in subcategoryStats)
                                                  if (subcategorySeriesMap
                                                      .containsKey(stat.name))
                                                    stat.name: stat.color,
                                              }
                                            : null,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
                  _SalesAdminNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Items',
                    routeToItems: true,
                  ),
                  _SalesAdminNavItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    routeToCategories: true,
                  ),
                  _SalesAdminNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Home',
                    routeToDashboard: true,
                  ),
                  _SalesAdminNavItem(
                    icon: Icons.error_outline,
                    label: 'Complaints',
                    routeToComplaints: true,
                  ),
                  _SalesAdminNavItem(
                    icon: Icons.eco_outlined,
                    label: 'Impact',
                    routeToImpact: true,
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

class _CategorySeed {
  final String id;
  final String name;

  const _CategorySeed({required this.id, required this.name});
}

class _FilterShell extends StatelessWidget {
  final Widget child;

  const _FilterShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String year;
  final int totalSales;

  const _SummaryCard({required this.year, required this.totalSales});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA93EFF), Color(0xFF7C1FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F32FF).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF8A1EFF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales $year',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '$totalSales',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'items sold across all categories',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
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

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F6BFF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : const Color(0xFFDCE3EE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF233B5E),
          ),
        ),
      ),
    );
  }
}

class _SalesStat {
  final String name;
  final int value;
  final Color color;

  const _SalesStat({
    required this.name,
    required this.value,
    required this.color,
  });
}

class _SalesStatCard extends StatelessWidget {
  final _SalesStat stat;

  const _SalesStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: stat.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF43556F),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${stat.value}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2342),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'items sold',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A90),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<double> values;
  final String title;
  final List<_ChartSeries>? series;
  final Map<String, _ChartSeries>? monthlyBreakdown;
  final Map<String, Color>? legendEntries;

  const _TrendCard({
    required this.values,
    this.title = 'Sales per Month Trend',
    this.series,
    this.monthlyBreakdown,
    this.legendEntries,
  });

  @override
  Widget build(BuildContext context) {
    return _InteractiveTrendCard(
      values: values,
      title: title,
      series: series,
      monthlyBreakdown: monthlyBreakdown,
      legendEntries: legendEntries,
    );
  }
}

class _InteractiveTrendCard extends StatefulWidget {
  final List<double> values;
  final String title;
  final List<_ChartSeries>? series;
  final Map<String, _ChartSeries>? monthlyBreakdown;
  final Map<String, Color>? legendEntries;

  const _InteractiveTrendCard({
    required this.values,
    required this.title,
    required this.series,
    required this.monthlyBreakdown,
    required this.legendEntries,
  });

  @override
  State<_InteractiveTrendCard> createState() => _InteractiveTrendCardState();
}

class _InteractiveTrendCardState extends State<_InteractiveTrendCard> {
  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _tooltipOverlayEntry;
  int? _selectedMonthIndex;

  @override
  void dispose() {
    _removeTooltipOverlay();
    super.dispose();
  }

  int _nearestMonthIndex(double dx, Rect chartRect) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var i = 0; i < 12; i++) {
      final pointX = chartRect.left + (chartRect.width * (i / 11));
      final distance = (pointX - dx).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  void _handleChartTap(TapDownDetails details, Size size) {
    final layout = _buildChartLayout(size, widget.series, widget.values);
    final localPosition = details.localPosition;
    final chartRect = layout.chartRect;

    if (!chartRect.inflate(18).contains(localPosition)) {
      setState(() {
        _selectedMonthIndex = null;
      });
      return;
    }

    setState(() {
      _selectedMonthIndex = _nearestMonthIndex(localPosition.dx, chartRect);
    });
    _showTooltipOverlay(size);
  }

  void _removeTooltipOverlay() {
    _tooltipOverlayEntry?.remove();
    _tooltipOverlayEntry = null;
  }

  void _showTooltipOverlay(Size size) {
    if (_selectedMonthIndex == null || widget.monthlyBreakdown == null) {
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox = _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || renderBox == null) {
      return;
    }

    _removeTooltipOverlay();

    final layout = _buildChartLayout(size, widget.series, widget.values);
    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final globalChartRect = layout.chartRect.shift(globalOffset);

    _tooltipOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeTooltipOverlay();
                  if (mounted) {
                    setState(() {
                      _selectedMonthIndex = null;
                    });
                  }
                },
              ),
            ),
            _MonthlyTrendTooltip(
              monthIndex: _selectedMonthIndex!,
              chartRect: globalChartRect,
              yAxisMax: layout.yAxisMax,
              monthlyBreakdown: widget.monthlyBreakdown!,
            ),
          ],
        );
      },
    );

    overlay.insert(_tooltipOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF2F6BFF), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2342),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, 360);
              final layout = _buildChartLayout(
                size,
                widget.series,
                widget.values,
              );
              return SizedBox(
                key: _chartKey,
                height: size.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _handleChartTap(details, size),
                  child: CustomPaint(
                    size: size,
                    painter: _TrendChartPainter(
                      values: widget.values,
                      series: widget.series,
                      highlightedMonthIndex: _selectedMonthIndex,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
          if (widget.legendEntries != null && widget.legendEntries!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 10,
                children: widget.legendEntries!.entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF43556F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final List<_ChartSeries>? series;
  final int? highlightedMonthIndex;

  const _TrendChartPainter({
    required this.values,
    this.series,
    this.highlightedMonthIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _buildChartLayout(size, series, values);
    final chartRect = layout.chartRect;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8EDF5)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF9BB0CC)
      ..strokeWidth = 1.4;
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final chartSeries = layout.chartSeries;
    final dynamicYLabels = layout.yLabels;
    for (var i = 0; i < dynamicYLabels.length; i++) {
      final dy =
          chartRect.bottom - (chartRect.height * (i / (dynamicYLabels.length - 1)));
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${dynamicYLabels[i]}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF93A5BF)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(chartRect.left - textPainter.width - 8, dy - 8));
    }

    for (var i = 0; i < 12; i++) {
      final dx = chartRect.left + (chartRect.width * (i / 11));
      canvas.drawLine(
        Offset(dx, chartRect.top),
        Offset(dx, chartRect.bottom),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom + 6),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    for (final chartSeriesEntry in chartSeries) {
      final linePaint = Paint()
        ..color = chartSeriesEntry.color
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;
      final pointBorderPaint = Paint()
        ..color = chartSeriesEntry.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final plotValues =
          series == null ? values : chartSeriesEntry.values;
      final path = Path();
      final points = <Offset>[];
      for (var i = 0; i < plotValues.length; i++) {
        final dx =
            chartRect.left + (chartRect.width * (i / (plotValues.length - 1)));
        final dy =
            chartRect.bottom - ((plotValues[i] / layout.yAxisMax) * chartRect.height);
        final point = Offset(dx, dy);
        points.add(point);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);

      for (final point in points) {
        canvas.drawCircle(point, 6, pointPaint);
        canvas.drawCircle(point, 6, pointBorderPaint);
      }

      if (highlightedMonthIndex != null &&
          highlightedMonthIndex! >= 0 &&
          highlightedMonthIndex! < points.length) {
        final highlightedPoint = points[highlightedMonthIndex!];
        final highlightPaint = Paint()
          ..color = chartSeriesEntry.color.withOpacity(0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(highlightedPoint, 11, highlightPaint);
        canvas.drawCircle(highlightedPoint, 7, pointPaint);
        canvas.drawCircle(highlightedPoint, 7, pointBorderPaint);
      }
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (var i = 0; i < months.length; i++) {
      final dx = chartRect.left + (chartRect.width * (i / 11));
      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(fontSize: 12, color: Color(0xFF93A5BF)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(dx - 8, chartRect.bottom + 12);
      canvas.rotate(-math.pi / 5.5);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.series != series ||
        oldDelegate.highlightedMonthIndex != highlightedMonthIndex;
  }
}

class _MonthlyTrendTooltip extends StatelessWidget {
  final int monthIndex;
  final Rect chartRect;
  final double yAxisMax;
  final Map<String, _ChartSeries> monthlyBreakdown;

  const _MonthlyTrendTooltip({
    required this.monthIndex,
    required this.chartRect,
    required this.yAxisMax,
    required this.monthlyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final entries = monthlyBreakdown.entries
        .map((entry) => MapEntry(entry.key, entry.value.values[monthIndex].round()))
        .toList();
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    final anchorValue = entries.isEmpty
        ? 0
        : entries
            .map((entry) => entry.value)
            .reduce((current, next) => current > next ? current : next);
    final pointX = chartRect.left + (chartRect.width * (monthIndex / 11));
    final clampedAnchorValue = anchorValue.clamp(0, yAxisMax.toInt()).toDouble();
    final pointY =
        chartRect.bottom - ((clampedAnchorValue / yAxisMax) * chartRect.height);
    const tooltipWidth = 205.0;
    const tooltipHeight = 178.0;
    final left = (pointX - 16).clamp(8.0, chartRect.right - tooltipWidth + 18);
    final top = (pointY - 88).clamp(8.0, chartRect.bottom - tooltipHeight + 8);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E9F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              months[monthIndex],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A2342),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Total: $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE8EDF5)),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final color = monthlyBreakdown[entry.key]?.color ?? const Color(0xFF4C8DFF);
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF233B5E),
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A2342),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

_ChartLayout _buildChartLayout(
  Size size,
  List<_ChartSeries>? series,
  List<double> values,
) {
  const leftPad = 52.0;
  const topPad = 16.0;
  const rightPad = 12.0;
  const bottomPad = 44.0;
  final chartRect = Rect.fromLTWH(
    leftPad,
    topPad,
    size.width - leftPad - rightPad,
    size.height - topPad - bottomPad,
  );

  final chartSeries =
      series ?? [const _ChartSeries(color: Color(0xFF4C8DFF), values: [])];
  final rawSeries =
      series == null ? [values] : chartSeries.map((entry) => entry.values).toList();
  final maxValue = rawSeries
      .expand((entry) => entry)
      .fold<double>(0, (max, value) => value > max ? value : max);
  final yAxisMax = maxValue <= 36
      ? 36.0
      : maxValue <= 280
          ? 280.0
          : ((maxValue / 10).ceil() * 10).toDouble();
  final yStep = yAxisMax / 4;
  final yLabels = [
    0,
    yStep.round(),
    (yStep * 2).round(),
    (yStep * 3).round(),
    yAxisMax.round(),
  ];

  return _ChartLayout(
    chartRect: chartRect,
    chartSeries: chartSeries,
    yAxisMax: yAxisMax,
    yLabels: yLabels,
  );
}

class _ChartLayout {
  final Rect chartRect;
  final List<_ChartSeries> chartSeries;
  final double yAxisMax;
  final List<int> yLabels;

  const _ChartLayout({
    required this.chartRect,
    required this.chartSeries,
    required this.yAxisMax,
    required this.yLabels,
  });
}

class _ChartSeries {
  final Color color;
  final List<double> values;

  const _ChartSeries({
    required this.color,
    required this.values,
  });
}

class _SubcategorySummaryCard extends StatelessWidget {
  final _SalesStat stat;
  final String year;
  final String categoryLabel;

  const _SubcategorySummaryCard({
    required this.stat,
    required this.year,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bulletColor = stat.name == 'All Subcategories'
        ? const Color(0xFFD3DAE6)
        : stat.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF43556F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7A90),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${stat.value}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2342),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total items sold in $year',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A90),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesAdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToItems;
  final bool routeToCategories;
  final bool routeToComplaints;
  final bool routeToImpact;

  const _SalesAdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
    this.routeToCategories = false,
    this.routeToComplaints = false,
    this.routeToImpact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F6BFF) : const Color(0xFF6B7A90);
    final VoidCallback? onTap = routeToDashboard
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            );
          }
        : routeToItems
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemListPage()),
                );
              }
            : routeToCategories
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryPage()),
                    );
                  }
                : routeToComplaints
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportListAdminPage()),
                        );
                      }
                    : routeToImpact
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SustainabilityAdminPage(),
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
                    fontWeight: FontWeight.w500,
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
