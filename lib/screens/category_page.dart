import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'admin_light_theme.dart';

import 'admin_dashboard_page.dart';
import 'item_list_page.dart';
import 'report_list_admin_page.dart';
import 'sustainability_admin_page.dart';

String _displayUpdatedByValue(Map<String, dynamic> data) {
  final name = data['updated_by_name']?.toString().trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  return data['updated_by']?.toString().trim() ?? '-';
}

String _formatEmissionFactorValue(dynamic value) {
  final factor = _parseFactorValue(value);
  if (factor == null) {
    return '0 kg CO2 per item';
  }
  final text =
      factor % 1 == 0 ? factor.toStringAsFixed(0) : factor.toStringAsFixed(1);
  return '$text kg CO2 per item';
}

double? _parseFactorValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String _formatUpdatedAtValue(dynamic value) {
  if (value is! Timestamp) {
    return '-';
  }
  final date = value.toDate();
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CollectionReference<Map<String, dynamic>> _categoryCollection =
      FirebaseFirestore.instance.collection('Category');
  final Map<String, bool> _expandedCategories = {};

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
                    'Categories',
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
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showCategorySheet(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F6BFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.add, size: 24),
                              label: const Text(
                                'Add Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _categoryCollection
                                .orderBy('category_name')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _StateCard(
                                  message:
                                      "Couldn't load categories: ${snapshot.error}",
                                  textColor: const Color(0xFFB42318),
                                );
                              }

                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return const _StateCard(
                                  message: 'Loading categories...',
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const _StateCard(
                                  message:
                                      'No categories yet. Add one to start building subcategories.',
                                );
                              }

                              return Column(
                                children: docs.map((doc) {
                                  final data = doc.data();
                                  final category = <String, dynamic>{
                                    'id': doc.id,
                                    'title':
                                        data['category_name']?.toString().trim() ??
                                            'Untitled Category',
                                    'updatedBy': _displayUpdatedByValue(data),
                                    'updatedAt': _formatUpdatedAtValue(
                                      data['updated_at'],
                                    ),
                                  };

                                  final isExpanded =
                                      _expandedCategories[doc.id] ?? false;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: _CategoryGroupCard(
                                      category: category,
                                      expanded: isExpanded,
                                      subcategoryStream: _categoryCollection
                                          .doc(doc.id)
                                          .collection('SubCategory')
                                          .orderBy('subcategory_name')
                                          .snapshots(),
                                      onToggle: () {
                                        setState(() {
                                          _expandedCategories[doc.id] =
                                              !(_expandedCategories[doc.id] ??
                                                  false);
                                        });
                                      },
                                      onEditCategory: () {
                                        _showCategorySheet(
                                          context,
                                          category: category,
                                        );
                                      },
                                      onAddSubcategory: () {
                                        _showSubcategorySheet(
                                          context,
                                          categoryId: doc.id,
                                        );
                                      },
                                      onEditSubcategory: (subcategory) {
                                        _showSubcategorySheet(
                                          context,
                                          categoryId: doc.id,
                                          subcategory: subcategory,
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
                    routeToItems: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    selected: true,
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
        ),
      ),
    );
  }

  Future<void> _showCategorySheet(
    BuildContext context, {
    Map<String, dynamic>? category,
  }) async {
    final isEditing = category != null;
    final nameController = TextEditingController(
      text: category?['title']?.toString() ?? '',
    );

    await _showEditorSheet(
      context: context,
      title: isEditing ? 'Edit Category' : 'Add New Category',
      fields: [
        _EditorFieldData(
          label: 'Category Name',
          hintText: 'e.g., Electronics',
          controller: nameController,
        ),
      ],
      submitLabel: isEditing ? 'Save Changes' : 'Add Category',
      onSubmit: () async {
        final name = nameController.text.trim();

        if (name.isEmpty) {
          throw _FormMessageException(
            'Category name is required.',
          );
        }

        final audit = await _buildAuditFields();
        final payload = <String, dynamic>{
          'category_name': name,
          ...audit,
        };

        if (isEditing) {
          await _categoryCollection.doc(category['id'].toString()).set(
                payload,
                SetOptions(merge: true),
              );
        } else {
          await _categoryCollection.add(payload);
        }
      },
      successMessage: isEditing
          ? 'Category updated successfully.'
          : 'Category added successfully.',
    );
  }

  Future<void> _showSubcategorySheet(
    BuildContext context, {
    required String categoryId,
    Map<String, dynamic>? subcategory,
  }) async {
    final isEditing = subcategory != null;
    final nameController = TextEditingController(
      text: subcategory?['title']?.toString() ?? '',
    );
    final factorController = TextEditingController(
      text: subcategory?['factorValue']?.toString() ?? '',
    );

    await _showEditorSheet(
      context: context,
      title: isEditing ? 'Edit Subcategory' : 'Add New Subcategory',
      fields: [
        _EditorFieldData(
          label: 'Subcategory Name',
          hintText: 'e.g., Smartphones',
          controller: nameController,
        ),
        _EditorFieldData(
          label: 'Emission Factor (kg CO2)',
          hintText: '0',
          controller: factorController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'Carbon reduction per item',
        ),
      ],
      submitLabel: isEditing ? 'Save Changes' : 'Add Subcategory',
      onSubmit: () async {
        final name = nameController.text.trim();
        final factorValue = double.tryParse(factorController.text.trim());

        if (name.isEmpty || factorValue == null) {
          throw _FormMessageException(
            'Subcategory name and a valid emission factor are required.',
          );
        }

        final audit = await _buildAuditFields();
        final payload = <String, dynamic>{
          'subcategory_name': name,
          'ef_value': factorValue,
          ...audit,
        };

        final subcategoryCollection =
            _categoryCollection.doc(categoryId).collection('SubCategory');

        if (isEditing) {
          await subcategoryCollection.doc(subcategory['id'].toString()).set(
                payload,
                SetOptions(merge: true),
              );
        } else {
          await subcategoryCollection.add(payload);
        }
      },
      successMessage: isEditing
          ? 'Subcategory updated successfully.'
          : 'Subcategory added successfully.',
    );
  }

  Future<void> _showEditorSheet({
    required BuildContext context,
    required String title,
    required List<_EditorFieldData> fields,
    required String submitLabel,
    required Future<void> Function() onSubmit,
    required String successMessage,
  }) async {
    final adminTheme = buildAdminLightTheme(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (sheetContext) {
        bool isSaving = false;

        return Theme(
          data: adminTheme,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> handleSave() async {
                setModalState(() {
                  isSaving = true;
                });

                try {
                  await onSubmit();
                  if (!mounted) {
                    return;
                  }
                  Navigator.pop(sheetContext);
                  showTopSnackBarFromSnackBar(this.context, 
                    SnackBar(content: Text(successMessage)),
                  );
                } on _FormMessageException catch (error) {
                  if (!mounted) {
                    return;
                  }
                  showTopSnackBarFromSnackBar(this.context, 
                    SnackBar(content: Text(error.message)),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  showTopSnackBarFromSnackBar(this.context, 
                    SnackBar(content: Text('Couldn\'t save: $error')),
                  );
                } finally {
                  if (context.mounted) {
                    setModalState(() {
                      isSaving = false;
                    });
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 10, 28, 26),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9CED6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A2342),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._buildEditorFields(fields),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : handleSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2F6BFF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Text(
                                    submitLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          Navigator.pop(context);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF233B5E),
                                    side: const BorderSide(
                                      color: Color(0xFFD9E1EC),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildEditorFields(List<_EditorFieldData> fields) {
    final widgets = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      widgets.add(_SheetLabel(field.label));
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        _SheetField(
          hintText: field.hintText,
          controller: field.controller,
          keyboardType: field.keyboardType,
        ),
      );
      if (field.helperText != null) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Text(
            field.helperText!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7A90),
            ),
          ),
        );
      }
      if (i != fields.length - 1) {
        widgets.add(const SizedBox(height: 20));
      } else {
        widgets.add(const SizedBox(height: 24));
      }
    }
    return widgets;
  }

  Future<Map<String, dynamic>> _buildAuditFields() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    String updatedByName = 'Admin';

    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data();
      final storedName = userData?['name']?.toString().trim();
      if (storedName != null && storedName.isNotEmpty) {
        updatedByName = storedName;
      } else if ((currentUser.email ?? '').isNotEmpty) {
        updatedByName = currentUser.email!;
      }
    }

    return {
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': currentUser?.uid,
      'updated_by_name': updatedByName,
    };
  }

}

class _StateCard extends StatelessWidget {
  final String message;
  final Color textColor;

  const _StateCard({
    required this.message,
    this.textColor = const Color(0xFF31506E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }
}

class _CategoryGroupCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool expanded;
  final Stream<QuerySnapshot<Map<String, dynamic>>> subcategoryStream;
  final VoidCallback onToggle;
  final VoidCallback onEditCategory;
  final VoidCallback onAddSubcategory;
  final void Function(Map<String, dynamic> subcategory) onEditSubcategory;

  const _CategoryGroupCard({
    required this.category,
    required this.expanded,
    required this.subcategoryStream,
    required this.onToggle,
    required this.onEditCategory,
    required this.onAddSubcategory,
    required this.onEditSubcategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: const Color(0xFF4C647F),
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category['title']?.toString() ?? 'Electronics',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _ActionIconButton(
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF2F6BFF),
                  backgroundColor: const Color(0xFFEAF1FF),
                  onTap: onEditCategory,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE7ECF3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subcategories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF233B5E),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: onAddSubcategory,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFEAF1FF),
                            foregroundColor: const Color(0xFF2F6BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Add Subcategory',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: subcategoryStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _InlineMessage(
                          message: 'No subcategories yet. Please add one.',
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const _InlineMessage(
                          message: 'Loading subcategories...',
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const _InlineMessage(
                          message: 'No subcategories yet. Please add one.',
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final subcategory = <String, dynamic>{
                            'id': doc.id,
                            'title': data['subcategory_name']
                                    ?.toString()
                                    .trim() ??
                                'Untitled Subcategory',
                            'factor':
                                _formatEmissionFactorValue(data['ef_value']),
                            'factorValue': _parseFactorValue(data['ef_value']),
                            'updatedBy': data['updated_by_name']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? data['updated_by_name'].toString().trim()
                                : data['updated_by']?.toString().trim() ?? '-',
                            'updatedAt':
                                _formatUpdatedAtValue(data['updated_at']),
                          };

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SubcategoryCard(
                              subcategory: subcategory,
                              onEdit: () => onEditSubcategory(subcategory),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated by: ${category['updatedBy'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7A90),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated at: ${category['updatedAt'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7A90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final Map<String, dynamic> subcategory;
  final VoidCallback onEdit;

  const _SubcategoryCard({
    required this.subcategory,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory['title']?.toString() ?? 'Subcategory',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A2342),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ActionIconButton(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF2F6BFF),
                backgroundColor: const Color(0xFFEAF1FF),
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3FFF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF9FF0B9)),
            ),
            child: Text(
              subcategory['factor']?.toString() ?? '0 kg CO2 per item',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00914F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated by: ${subcategory['updatedBy'] ?? '-'}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7A90),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Updated at: ${subcategory['updatedAt'] ?? '-'}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7A90),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final Color textColor;

  const _InlineMessage({
    required this.message,
    this.textColor = const Color(0xFF6B7A90),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF233B5E),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String hintText;
  final TextInputType? keyboardType;
  final TextEditingController controller;

  const _SheetField({
    required this.hintText,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      controller: controller,
      style: const TextStyle(
        color: Color(0xFF0A2342),
        fontSize: 16,
      ),
      cursorColor: Color(0xFF2F6BFF),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8A94A6),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2F6BFF)),
        ),
      ),
    );
  }
}

class _EditorFieldData {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? helperText;

  const _EditorFieldData({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.helperText,
  });
}

class _FormMessageException implements Exception {
  final String message;

  const _FormMessageException(this.message);
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToItems;
  final bool routeToReports;
  final bool routeToImpact;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
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
        : routeToItems
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ItemListPage(),
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

