import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';

import 'admin_light_theme.dart';
import 'admin_dashboard_page.dart';
import 'item_list_page.dart';
import '../widgets/floating_dropdown_field.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, String> user;

  const UserDetailPage({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const List<String> _facultyList = [
    'Faculty of Science Computer and Technology',
    'Faculty of Economics and Business',
    'Faculty of Engineering',
    'Faculty of Applied and Creative Arts',
    'Faculty of Cognitive Sciences and Human Development',
    'Faculty of Medicine and Health Sciences',
    'Faculty of Social Sciences and Humanities',
    'Faculty of Resource Science and Technology',
    'Faculty of Language and Communication',
    'Faculty of Built Environment',
  ];

  static const List<String> _collegeList = [
    'Cempaka',
    'Kenanga',
    'Allamanda',
    'Bunga Raya',
    'Sakura',
    'Seroja',
    'Dahlia',
    'Tun Ahmad Zaidi',
    'Rafflesia',
    'Not in any college',
  ];

  static const List<String> _yearList = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Post Graduate',
  ];

  late Map<String, String> user;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    user = Map<String, String>.from(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final status = (user['status'] ?? '').toLowerCase();
    final isSuspended = status == 'suspended';
    final statusText = user['status'] ?? 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFFC9FDFF),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF233B5E),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'User Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _InfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldBlock(
                                label: 'Name',
                                value: user['fullName'] ?? 'John Doe',
                              ),
                              const SizedBox(height: 22),
                              _FieldBlock(
                                label: 'Email',
                                value: user['email'] ?? 'john@example.com',
                              ),
                              const SizedBox(height: 22),
                              _FieldBlock(
                                label: 'Phone Number',
                                value: user['phone'] ?? '+1 234-567-8901',
                              ),
                              const SizedBox(height: 22),
                              _FieldBlock(
                                label: 'Faculty',
                                value: user['faculty'] ?? 'Computer Science',
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'College',
                                      value: user['college'] ??
                                          'Engineering College',
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Year of Study',
                                      value: user['year'] ?? 'Year 3',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FieldBlock(
                                      label: 'Joined At',
                                      value:
                                          user['createdAt'] ?? '2024-01-15',
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Account Status',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _StatusChip(
                                          text: statusText,
                                          status: status,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildActivitySection(user['id'] ?? ''),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing ? null : _showEditSheet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6BFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              isProcessing ? 'Saving...' : 'Edit Information',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : (isSuspended
                                      ? _reactivateUser
                                      : _suspendUser),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSuspended
                                  ? const Color(0xFF0AAA41)
                                  : const Color(0xFFFF1010),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: Icon(
                              isSuspended
                                  ? Icons.check_circle_outline
                                  : Icons.block,
                            ),
                            label: Text(
                              isProcessing
                                  ? 'Updating...'
                                  : isSuspended
                                  ? 'Activate User'
                                  : 'Suspend User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  ),
                  _AdminNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Home',
                    routeToDashboard: true,
                  ),
                  _AdminNavItem(
                    icon: Icons.error_outline,
                    label: 'Reports',
                  ),
                  _AdminNavItem(
                    icon: Icons.eco_outlined,
                    label: 'Impact',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSheet() async {
    final nameController = TextEditingController(
      text: _editableValue(user['name']),
    );
    final phoneController = TextEditingController(
      text: _editableValue(user['phone']),
    );
    String? selectedCollege = _normalizeOption(
      _editableValue(user['college']),
      _collegeList,
    );
    String? selectedFaculty = _normalizeOption(
      _editableValue(user['faculty']),
      _facultyList,
    );
    String? selectedYear = _normalizeYearOption(user['year']);
    final adminTheme = buildAdminLightTheme(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isSaving = false;

        return Theme(
          data: adminTheme,
          child: StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> handleSave() async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final college = selectedCollege;
              final faculty = selectedFaculty;
              final yearText = selectedYear;

              if (name.isEmpty ||
                  phone.isEmpty ||
                  college == null ||
                  faculty == null ||
                  yearText == null) {
                showTopSnackBarFromSnackBar(this.context, 
                  const SnackBar(
                    content: Text('Please fill all fields with valid values.'),
                  ),
                );
                return;
              }

              final shouldSave = await showDialog<bool>(
                context: this.context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Save Changes'),
                    content: const Text(
                      'Are you sure you want to save these changes?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );

              if (shouldSave != true) {
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              try {
                await FirebaseFirestore.instance
                    .collection('User')
                    .doc(user['id'])
                    .update({
                      'name': name,
                      'phone': phone,
                      'college': college,
                      'faculty': faculty,
                      'year_of_study': yearText,
                    });

                if (!mounted) {
                  return;
                }

                setState(() {
                  user['name'] = name;
                  user['fullName'] = name;
                  user['phone'] = phone;
                  user['college'] = college;
                  user['faculty'] = faculty;
                  user['year'] = yearText!;
                });

                Navigator.pop(sheetContext);
                showTopSnackBarFromSnackBar(this.context, 
                  const SnackBar(content: Text('User information updated.')),
                );
              } catch (error) {
                if (!mounted) {
                  return;
                }
                showTopSnackBarFromSnackBar(this.context, 
                  SnackBar(content: Text('Couldn\'t update user: $error')),
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() {
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                          width: 56,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9CED6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Edit User Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A2342),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SheetField(label: 'Name', controller: nameController),
                      const SizedBox(height: 16),
                      _SheetField(
                        label: 'Phone Number',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _SheetDropdown(
                        label: 'College',
                        value: selectedCollege,
                        items: _collegeList,
                        onChanged: (value) {
                          setSheetState(() {
                            selectedCollege = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _SheetDropdown(
                        label: 'Faculty',
                        value: selectedFaculty,
                        items: _facultyList,
                        onChanged: (value) {
                          setSheetState(() {
                            selectedFaculty = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _SheetDropdown(
                        label: 'Year of Study',
                        value: selectedYear,
                        items: _yearList,
                        onChanged: (value) {
                          setSheetState(() {
                            selectedYear = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
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
                                  isSaving ? 'Saving...' : 'Save Changes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(sheetContext),
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

  Widget _buildActivitySection(String userId) {
    if (userId.isEmpty) {
      return _buildActivityCard(
        purchases: '0',
        sales: '0',
        donations: '0',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Listing')
          .where('seller_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, sellerListingSnapshot) {
        final sellerListings = sellerListingSnapshot.data?.docs ?? [];
        final completedSellerListings = sellerListings.where((doc) {
          final status = doc.data()['sale_status']?.toString().toLowerCase() ?? '';
          return status == 'completed';
        }).toList();

        final salesCount = completedSellerListings.where((doc) {
          final type = doc.data()['listing_type']?.toString().toLowerCase() ?? '';
          return type == 'sell' || type == 'sale';
        }).length;

        final donationCount = completedSellerListings.where((doc) {
          final type = doc.data()['listing_type']?.toString().toLowerCase() ?? '';
          return type == 'donation' || type == 'donate';
        }).length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Listing')
              .where('booked_by_id', isEqualTo: userId)
              .where('sale_status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, purchaseSnapshot) {
            final purchasesCount = purchaseSnapshot.data?.docs.length ?? 0;

            return _buildActivityCard(
              purchases: '$purchasesCount',
              sales: '$salesCount',
              donations: '$donationCount',
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String purchases,
    required String sales,
    required String donations,
  }) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2342),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActivityBox(
                  label: 'Total Purchases',
                  value: purchases,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActivityBox(
                  label: 'Total Sales',
                  value: sales,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActivityBox(
                  label: 'Total Donations',
                  value: donations,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _suspendUser() async {
    final shouldSuspend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suspend user?'),
          content: const Text(
            'This user will lose access until reactivated by admin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Suspend'),
            ),
          ],
        );
      },
    );

    if (shouldSuspend != true) {
      return;
    }

    final previousStatus = user['status']?.toLowerCase() ?? 'active';
    setState(() {
      isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance.collection('User').doc(user['id']).update({
        'user_status': 'suspended',
        'previous_user_status': previousStatus,
      });

      final listingSnapshot = await FirebaseFirestore.instance
          .collection('Listing')
          .where('seller_id', isEqualTo: user['id'])
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in listingSnapshot.docs) {
        batch.update(doc.reference, {'seller_status': 'suspended'});
      }
      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        user['status'] = 'suspended';
      });
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('User suspended successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text('Couldn\'t suspend user: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _reactivateUser() async {
    final shouldReactivate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Activate user?'),
          content: const Text(
            'This user will regain access based on their previous account status.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activate'),
            ),
          ],
        );
      },
    );

    if (shouldReactivate != true) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user['id'])
          .get();
      final previousStatus =
          userDoc.data()?['previous_user_status']?.toString().toLowerCase();
      final restoredStatus = (previousStatus != null && previousStatus.isNotEmpty)
          ? previousStatus
          : 'active';

      await FirebaseFirestore.instance.collection('User').doc(user['id']).update({
        'user_status': restoredStatus,
        'previous_user_status': FieldValue.delete(),
      });

      final listingSnapshot = await FirebaseFirestore.instance
          .collection('Listing')
          .where('seller_id', isEqualTo: user['id'])
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in listingSnapshot.docs) {
        batch.update(doc.reference, {'seller_status': restoredStatus});
      }
      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        user['status'] = restoredStatus;
      });
      showTopSnackBarFromSnackBar(context, 
        const SnackBar(content: Text('User reactivated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopSnackBarFromSnackBar(context, 
        SnackBar(content: Text('Couldn\'t reactivate user: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  String _editableValue(String? value) {
    if (value == null || value == '-' || value == 'Not completed') {
      return '';
    }
    return value;
  }

  String _editableYearValue(String? value) {
    final text = _editableValue(value);
    if (text.startsWith('Year ')) {
      return text.replaceFirst('Year ', '');
    }
    return text;
  }

  String? _normalizeOption(String value, List<String> options) {
    if (value.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  String? _normalizeYearOption(String? value) {
    final text = _editableValue(value);
    if (text.isEmpty) {
      return null;
    }

    for (final option in _yearList) {
      if (option.toLowerCase() == text.toLowerCase()) {
        return option;
      }
    }

    final yearNumber = int.tryParse(_editableYearValue(text));
    if (yearNumber != null && yearNumber >= 1 && yearNumber <= 4) {
      return 'Year $yearNumber';
    }

    return null;
  }

}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E1EC)),
      ),
      child: child,
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final String value;

  const _FieldBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A2342),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final String status;

  const _StatusChip({
    required this.text,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == 'suspended';
    final isActive = status == 'active';
    final isVerified = status == 'verified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSuspended
            ? const Color(0xFFFFE3E3)
            : isActive
                ? const Color(0xFFD9F9E5)
                : isVerified
                    ? const Color(0xFFEAF1FF)
                    : const Color(0xFFFFF3BF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isSuspended
              ? const Color(0xFFB42318)
              : isActive
                  ? const Color(0xFF067647)
                  : isVerified
                      ? const Color(0xFF2F6BFF)
                      : const Color(0xFFB67D00),
        ),
      ),
    );
  }
}

class _ActivityBox extends StatelessWidget {
  final String label;
  final String value;

  const _ActivityBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A2342),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _SheetField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF233B5E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF0A2342),
            fontSize: 16,
          ),
          cursorColor: Color(0xFF2F6BFF),
          decoration: InputDecoration(
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
        ),
      ],
    );
  }
}

class _SheetDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF233B5E),
          ),
        ),
        const SizedBox(height: 8),
        FloatingDropdownField<String>(
          value: value,
          items: items,
          hint: label,
          onChanged: onChanged,
          borderColor: const Color(0xFFD9E1EC),
          focusedBorderColor: const Color(0xFF2F6BFF),
          borderRadius: 18,
          height: 56,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool routeToDashboard;
  final bool routeToItems;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.routeToDashboard = false,
    this.routeToItems = false,
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

