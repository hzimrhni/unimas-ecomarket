import 'package:flutter/material.dart';

class FloatingDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemLabelBuilder;
  final Color backgroundColor;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color iconColor;
  final Color menuBackgroundColor;
  final Color selectedItemBackgroundColor;
  final Color shadowColor;
  final double borderRadius;
  final double height;
  final int maxVisibleItems;
  final double itemHeight;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;

  const FloatingDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.itemLabelBuilder,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF0A2342),
    this.hintColor = const Color(0xFF0A2342),
    this.borderColor = const Color(0xFFC8D3E1),
    this.focusedBorderColor = const Color(0xFF2F6BFF),
    this.iconColor = const Color(0xFF1F2937),
    this.menuBackgroundColor = Colors.white,
    this.selectedItemBackgroundColor = const Color(0xFFE6E6E6),
    this.shadowColor = const Color(0x14000000),
    this.borderRadius = 16,
    this.height = 52,
    this.maxVisibleItems = 5,
    this.itemHeight = 56,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 18),
    this.textStyle,
  });

  @override
  State<FloatingDropdownField<T>> createState() =>
      _FloatingDropdownFieldState<T>();
}

class _FloatingDropdownFieldState<T> extends State<FloatingDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _expanded = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_expanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  String _itemLabel(T item) {
    return widget.itemLabelBuilder?.call(item) ?? item.toString();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }

    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final size = renderBox.size;
    final fieldTopLeft = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final desiredMenuHeight = widget.itemHeight *
        (widget.items.length < widget.maxVisibleItems
            ? widget.items.length
            : widget.maxVisibleItems);
    final spaceBelow = screenHeight - fieldTopLeft.dy - size.height - 16;
    final spaceAbove = fieldTopLeft.dy - 16;
    final openUpward =
        spaceBelow < desiredMenuHeight && spaceAbove > spaceBelow;
    final availableHeight =
        (openUpward ? spaceAbove : spaceBelow).clamp(0.0, desiredMenuHeight);
    final menuHeight = availableHeight < widget.itemHeight
        ? widget.itemHeight
        : availableHeight;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: openUpward
                ? Offset(0, -(menuHeight + 6))
                : Offset(0, size.height + 6),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: size.width,
                constraints: BoxConstraints(
                  maxHeight: menuHeight,
                ),
                decoration: BoxDecoration(
                  color: widget.menuBackgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: widget.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Scrollbar(
                    thumbVisibility: widget.items.length > widget.maxVisibleItems,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final selected = item == widget.value;
                        final isFirst = index == 0;
                        final isLast = index == widget.items.length - 1;

                        return Material(
                          color: selected
                              ? widget.selectedItemBackgroundColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isFirst ? widget.borderRadius : 0),
                            topRight: Radius.circular(isFirst ? widget.borderRadius : 0),
                            bottomLeft: Radius.circular(isLast ? widget.borderRadius : 0),
                            bottomRight:
                                Radius.circular(isLast ? widget.borderRadius : 0),
                          ),
                          child: InkWell(
                            onTap: () => _selectItem(item),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isFirst ? widget.borderRadius : 0),
                              topRight: Radius.circular(isFirst ? widget.borderRadius : 0),
                              bottomLeft: Radius.circular(isLast ? widget.borderRadius : 0),
                              bottomRight:
                                  Radius.circular(isLast ? widget.borderRadius : 0),
                            ),
                            child: SizedBox(
                              height: widget.itemHeight,
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _itemLabel(item),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: widget.textColor,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _expanded = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _expanded = false;
      });
    }
  }

  void _selectItem(T item) {
    widget.onChanged(item);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.value != null ? _itemLabel(widget.value as T) : widget.hint;
    final effectiveTextStyle = widget.textStyle ??
        TextStyle(
          fontSize: 16,
          color: widget.textColor,
          fontWeight: FontWeight.w500,
        );

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        key: _fieldKey,
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          height: widget.height,
          padding: widget.contentPadding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _expanded ? widget.focusedBorderColor : widget.borderColor,
              width: _expanded ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: effectiveTextStyle.copyWith(
                    color: widget.value == null ? widget.hintColor : widget.textColor,
                  ),
                ),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: widget.iconColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
