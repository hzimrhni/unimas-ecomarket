import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../utils/top_snackbar.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/price_formatter.dart';
import 'student_theme.dart';
import '../widgets/floating_dropdown_field.dart';

class AddItemPage extends StatefulWidget {
  final String userId;
  final String? listingId;
  final Map<String, String>? initialItem;

  const AddItemPage({
    super.key,
    required this.userId,
    this.listingId,
    this.initialItem,
  });

  bool get isEditMode => listingId != null && initialItem != null;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _subcategoryKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();

  bool isForSale = true;
  bool isSubmitting = false;
  bool _prefilled = false;
  XFile? selectedImage;
  String existingImagePath = '';
  final Map<String, String> _validationErrors = {};
  final _currencyFormatter = _BankPriceInputFormatter();

  List<_CategoryOption> categories = [];
  String? selectedCategoryId;
  String? selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categorySnapshot = await FirebaseFirestore.instance
        .collection('Category')
        .orderBy('category_name')
        .get();

    final loadedCategories = await Future.wait(
      categorySnapshot.docs.map((categoryDoc) async {
        final subSnapshot = await categoryDoc.reference
            .collection('SubCategory')
            .orderBy('subcategory_name')
            .get();

        return _CategoryOption(
          id: categoryDoc.id,
          name: categoryDoc.data()['category_name']?.toString() ?? 'Category',
          subcategories: subSnapshot.docs.map((subDoc) {
            final data = subDoc.data();
            final efValue = data['ef_value'];
            final parsedEf = efValue is num
                ? efValue.toDouble()
                : double.tryParse(efValue?.toString() ?? '') ?? 0;

            return _SubcategoryOption(
              id: subDoc.id,
              name: data['subcategory_name']?.toString() ?? 'Subcategory',
              efValue: parsedEf,
            );
          }).toList(),
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      categories = loadedCategories;
      if (widget.isEditMode) {
        _applyInitialItem();
      } else {
        selectedCategoryId = null;
        selectedSubcategoryId = null;
      }
    });
  }

  void _applyInitialItem() {
    if (_prefilled || widget.initialItem == null) {
      return;
    }

    final item = widget.initialItem!;
    _titleController.text = item['title'] ?? item['name'] ?? '';
    _descriptionController.text = item['description'] ?? '';

    final rawListingType =
        (item['listingTypeRaw'] ?? item['listingType'] ?? 'sell').toLowerCase();
    isForSale = rawListingType == 'sell' || rawListingType == 'sale';

    final rawPrice = item['priceValue'] ?? '';
    if (rawPrice.isNotEmpty && rawPrice != '0' && rawPrice != '0.0') {
      final initialPrice = double.tryParse(rawPrice) ?? 0;
      _priceController.text = initialPrice.toStringAsFixed(2);
    }

    selectedCategoryId = item['categoryId'];
    selectedSubcategoryId = item['subcategoryId'];
    existingImagePath = item['imagePath'] ?? '';

    if (selectedCategoryId != null &&
        !categories.any((category) => category.id == selectedCategoryId)) {
      selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    final selectedCategory = _selectedCategory;
    if (selectedCategory != null &&
        (selectedSubcategoryId == null ||
            !selectedCategory.subcategories
                .any((subcategory) => subcategory.id == selectedSubcategoryId))) {
      selectedSubcategoryId = selectedCategory.subcategories.isNotEmpty
          ? selectedCategory.subcategories.first.id
          : null;
    }

    _prefilled = true;
  }

  _CategoryOption? get _selectedCategory {
    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        return category;
      }
    }
    return null;
  }

  _SubcategoryOption? get _selectedSubcategory {
    final selectedCategory = _selectedCategory;
    if (selectedCategory == null) {
      return null;
    }

    for (final subcategory in selectedCategory.subcategories) {
      if (subcategory.id == selectedSubcategoryId) {
        return subcategory;
      }
    }
    return null;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from phone'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Use camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image == null || !mounted) {
      return;
    }

    final extension = image.name.toLowerCase();
    if (!(extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg') ||
        extension.endsWith('.png'))) {
      _showMessage('Please choose a JPG or PNG image.', isError: true);
      return;
    }

    setState(() {
      selectedImage = image;
      _validationErrors.remove('image');
    });
  }

  bool get _hasUnsavedChanges {
    if (isSubmitting) {
      return false;
    }

    if (widget.isEditMode && widget.initialItem != null) {
      final item = widget.initialItem!;
      final initialTitle = item['title'] ?? item['name'] ?? '';
      final initialDescription = item['description'] ?? '';
      final initialListingType =
          (item['listingTypeRaw'] ?? item['listingType'] ?? 'sell').toLowerCase();
      final initialIsForSale =
          initialListingType == 'sell' || initialListingType == 'sale';
      final initialPrice =
          item['priceValue'] == null || item['priceValue'] == '0'
              ? ''
              : item['priceValue']!;

      return _titleController.text.trim() != initialTitle ||
          _descriptionController.text.trim() != initialDescription ||
          isForSale != initialIsForSale ||
          _priceController.text.trim() != initialPrice ||
          (selectedCategoryId ?? '') != (item['categoryId'] ?? '') ||
          (selectedSubcategoryId ?? '') != (item['subcategoryId'] ?? '') ||
          selectedImage != null;
    }

    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
        selectedImage != null ||
        !isForSale;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Do you wish to discard your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final selectedCategory = _selectedCategory;
    final selectedSubcategory = _selectedSubcategory;

    double price = 0;
    if (isForSale) {
      price = _parsePriceInput(_priceController.text);
    }

    final validationOrder = <(String, GlobalKey)>[
      ('image', _imageKey),
      ('title', _titleKey),
      ('description', _descriptionKey),
      ('category', _categoryKey),
      ('subcategory', _subcategoryKey),
      if (isForSale) ('price', _priceKey),
    ];
    final nextErrors = <String, String>{};

    if (selectedImage == null && existingImagePath.isEmpty) {
      nextErrors['image'] = 'Please choose picture';
    }
    if (title.isEmpty) {
      nextErrors['title'] = 'Please fill up Item Title';
    }
    if (description.isEmpty) {
      nextErrors['description'] = 'Please fill up Description';
    }
    if (selectedCategory == null) {
      nextErrors['category'] = 'Please fill up Category';
    }
    if (selectedSubcategory == null) {
      nextErrors['subcategory'] = 'Please fill up Subcategory';
    }
    if (isForSale) {
      if (_priceController.text.trim().isEmpty) {
        nextErrors['price'] = 'Please fill up Price';
      } else if (price < 0) {
        nextErrors['price'] = 'Please enter a valid price';
      }
    }

    if (nextErrors.isNotEmpty) {
      setState(() {
        _validationErrors
          ..clear()
          ..addAll(nextErrors);
      });
      for (final entry in validationOrder) {
        if (nextErrors.containsKey(entry.$1)) {
          _scrollToField(entry.$2);
          break;
        }
      }
      return;
    }

    var effectiveIsForSale = isForSale;
    if (effectiveIsForSale && price <= 0) {
      effectiveIsForSale = false;
      setState(() {
        isForSale = false;
        _priceController.clear();
      });
    }

    setState(() {
      isSubmitting = true;
      _validationErrors.clear();
    });

    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(widget.userId)
          .get();
      final sellerData = sellerDoc.data() ?? {};

      String imageUrl = existingImagePath;
      if (selectedImage != null) {
        final previousImagePath = existingImagePath;
        final imageBytes = await _buildCompressedImageBytes(selectedImage!);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('listing_images/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await storageRef.getDownloadURL();

        if (widget.isEditMode &&
            previousImagePath.isNotEmpty &&
            previousImagePath != imageUrl) {
          try {
            await FirebaseStorage.instance.refFromURL(previousImagePath).delete();
          } catch (_) {
            // Keep the update flow successful even if the old image was already gone.
          }
        }
      }

      final payload = <String, dynamic>{
        'seller_id': widget.userId,
        'seller_name': sellerData['name']?.toString() ?? 'Seller Name',
        'seller_email':
            sellerData['unimas_email']?.toString() ?? 'seller@siswa.unimas.my',
        'seller_status':
            sellerData['user_status']?.toString().toLowerCase() ?? 'active',
        'category_id': selectedCategory!.id,
        'category_name': selectedCategory.name,
        'subcategory_id': selectedSubcategory!.id,
        'subcategory_name': selectedSubcategory.name,
        'title': title,
        'description': description,
        'price': effectiveIsForSale ? price : 0,
        'listing_type': effectiveIsForSale ? 'sell' : 'donation',
        'image_path': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (widget.isEditMode) {
        await FirebaseFirestore.instance
            .collection('Listing')
            .doc(widget.listingId)
            .update(payload);
      } else {
        payload.addAll({
          'listing_status': 'pending',
          'sale_status': 'available',
          'created_at': FieldValue.serverTimestamp(),
          'booked_by_id': null,
          'receiver_id': null,
          'booked_at': null,
          'completed_at': null,
          'ef_used': null,
          'carbon_reduction': null,
        });
        await FirebaseFirestore.instance.collection('Listing').add(payload);
      }

      if (!mounted) {
        return;
      }

      final resultItem = <String, String>{
        'id': widget.listingId ?? '',
        'sellerId': widget.userId,
        'title': title,
        'name': title,
        'description': description,
        'priceValue': effectiveIsForSale ? price.toString() : '0',
        'price': effectiveIsForSale
            ? formatRmPrice(price)
            : 'Free',
        'imagePath': imageUrl,
        'category': selectedCategory!.name,
        'categoryId': selectedCategory.id,
        'subcategory': selectedSubcategory!.name,
        'subcategoryId': selectedSubcategory.id,
        'listingType': effectiveIsForSale ? 'Sale' : 'Donation',
        'listingTypeRaw': effectiveIsForSale ? 'sell' : 'donation',
        'saleStatus': widget.initialItem?['saleStatus'] ?? 'Available',
        'listingStatus': widget.initialItem?['listingStatus'] ?? 'pending',
      };

      Navigator.pop(context, resultItem);
      showTopSnackBarFromSnackBar(context, 
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Item updated successfully.'
                : 'Item added successfully.',
          ),
        ),
      );
    } catch (error) {
      _showMessage(
        widget.isEditMode
            ? 'Couldn\'t update item: $error'
            : 'Couldn\'t add item: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<Uint8List> _buildCompressedImageBytes(XFile image) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 1080,
      minHeight: 1080,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    if (compressed != null) {
      return compressed;
    }

    return File(image.path).readAsBytes();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    showTopSnackBarFromSnackBar(context, 
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    final selectedCategory = _selectedCategory;
    final subcategories = selectedCategory?.subcategories ?? const [];

    return WillPopScope(
      onWillPop: () async => _confirmDiscard(),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.arrow_back, color: colors.icon),
                            onPressed: () async {
                              if (await _confirmDiscard() && mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.isEditMode ? 'Update Item' : 'Add Item',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Column(
                      key: _imageKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.softBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _validationErrors.containsKey('image')
                                    ? Colors.red
                                    : colors.border,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildImagePreview(),
                            ),
                          ),
                        ),
                        _buildErrorText(_validationErrors['image']),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Listing Type'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeButton(
                            label: 'For Sale',
                            selected: isForSale,
                            onTap: () {
                              setState(() {
                                isForSale = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeButton(
                            label: 'For Donation',
                            selected: !isForSale,
                            onTap: () {
                              setState(() {
                                isForSale = false;
                                _priceController.text = '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Item Title'),
                    const SizedBox(height: 8),
                    _buildField(
                      key: _titleKey,
                      controller: _titleController,
                      hintText: 'Enter item title',
                      errorText: _validationErrors['title'],
                      onChanged: (_) => _clearValidationError('title'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Description'),
                    const SizedBox(height: 8),
                    _buildField(
                      key: _descriptionKey,
                      controller: _descriptionController,
                      hintText: 'Describe your item',
                      maxLines: 4,
                      errorText: _validationErrors['description'],
                      onChanged: (_) => _clearValidationError('description'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Category'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      key: _categoryKey,
                      value: selectedCategoryId,
                      items: categories.map((category) => category.id).toList(),
                      errorText: _validationErrors['category'],
                      itemLabelBuilder: (id) =>
                          categories.firstWhere((category) => category.id == id).name,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                          selectedSubcategoryId = null;
                          _validationErrors.remove('category');
                          _validationErrors.remove('subcategory');
                        });
                      },
                      hint: 'Select Category',
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Subcategory'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      key: _subcategoryKey,
                      value: selectedSubcategoryId,
                      items: subcategories.map((subcategory) => subcategory.id).toList(),
                      errorText: _validationErrors['subcategory'],
                      itemLabelBuilder: (id) => subcategories
                          .firstWhere((subcategory) => subcategory.id == id)
                          .name,
                      onChanged: (value) {
                        setState(() {
                          selectedSubcategoryId = value;
                          _validationErrors.remove('subcategory');
                        });
                      },
                      hint: 'Select Subcategory',
                    ),
                    if (isForSale) ...[
                      const SizedBox(height: 16),
                      _buildLabel('Price'),
                      const SizedBox(height: 8),
                      _buildField(
                        key: _priceKey,
                        controller: _priceController,
                        hintText: '0.00',
                        keyboardType: TextInputType.number,
                        inputFormatters: [_currencyFormatter],
                        errorText: _validationErrors['price'],
                        onChanged: (_) => _clearValidationError('price'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isSubmitting
                              ? 'Saving...'
                              : (widget.isEditMode ? 'Update Item' : 'Add Item'),
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
    );
  }

  Widget _buildImagePreview() {
    final colors = StudentThemeColors.of(context);
    if (selectedImage != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Image.file(File(selectedImage!.path)),
        ),
      );
    }

    if (existingImagePath.isNotEmpty) {
      return Container(
        color: colors.softBackground,
        child: Center(
          child: Image.network(
            existingImagePath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _imagePrompt(),
          ),
        ),
      );
    }

    return _imagePrompt();
  }

  Widget _imagePrompt() {
    final colors = StudentThemeColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: colors.icon),
        const SizedBox(height: 12),
        Text(
          'Tap to choose image',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'JPG or PNG • phone or camera',
          style: TextStyle(
            fontSize: 13,
            color: colors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final colors = StudentThemeColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colors.primaryText,
      ),
    );
  }

  Widget _buildField({
    GlobalKey? key,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colors = StudentThemeColors.of(context);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(color: colors.primaryText),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: colors.tertiaryText),
            filled: true,
            fillColor: colors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : colors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : const Color(0xFF2F6BFF),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        _buildErrorText(errorText),
      ],
    );
  }

  Widget _buildDropdown<T>({
    GlobalKey? key,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T item)? itemLabelBuilder,
    String? errorText,
    String hint = 'Please select',
  }) {
    final colors = StudentThemeColors.of(context);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingDropdownField<T>(
          value: items.contains(value) ? value : null,
          items: items,
          hint: hint,
          onChanged: onChanged,
          itemLabelBuilder: itemLabelBuilder,
          backgroundColor: colors.cardBackground,
          menuBackgroundColor: colors.cardBackground,
          textColor: colors.primaryText,
          hintColor: colors.tertiaryText,
          borderColor: errorText != null ? Colors.red : colors.border,
          focusedBorderColor:
              errorText != null ? Colors.red : const Color(0xFF2F6BFF),
          iconColor: colors.icon,
          selectedItemBackgroundColor: colors.softBackground,
          shadowColor: colors.shadow,
          borderRadius: 12,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        _buildErrorText(errorText),
      ],
    );
  }

  Widget _buildErrorText(String? errorText) {
    if (errorText == null || errorText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        errorText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  void _clearValidationError(String field) {
    if (!_validationErrors.containsKey(field)) {
      return;
    }
    setState(() {
      _validationErrors.remove(field);
    });
  }

  void _scrollToField(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.18,
    );
  }

  double _parsePriceInput(String rawValue) {
    final sanitized = rawValue.replaceAll(',', '').trim();
    return double.tryParse(sanitized) ?? -1;
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StudentThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F6BFF) : colors.softBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2F6BFF) : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : colors.primaryText,
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String id;
  final String name;
  final List<_SubcategoryOption> subcategories;

  const _CategoryOption({
    required this.id,
    required this.name,
    required this.subcategories,
  });
}

class _SubcategoryOption {
  final String id;
  final String name;
  final double efValue;

  const _SubcategoryOption({
    required this.id,
    required this.name,
    required this.efValue,
  });
}

class _BankPriceInputFormatter extends TextInputFormatter {
  static const int _maxCents = 10000000;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final cappedDigits = _capDigitsToMax(digitsOnly);
    final normalizedDigits = cappedDigits.replaceFirst(RegExp(r'^0+'), '');
    final safeDigits = normalizedDigits.isEmpty ? '0' : normalizedDigits;
    final padded = safeDigits.padLeft(3, '0');
    final wholePart = padded.substring(0, padded.length - 2);
    final decimalPart = padded.substring(padded.length - 2);
    final trimmedWholePart =
        wholePart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = '$trimmedWholePart.$decimalPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _capDigitsToMax(String digitsOnly) {
    final maxDigits = _maxCents.toString();
    if (digitsOnly.length < maxDigits.length) {
      return digitsOnly;
    }
    if (digitsOnly.length > maxDigits.length) {
      return maxDigits;
    }
    return digitsOnly.compareTo(maxDigits) > 0 ? maxDigits : digitsOnly;
  }
}

