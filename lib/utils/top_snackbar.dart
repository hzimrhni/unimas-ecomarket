import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeTopSnackBar;
Timer? _activeTopSnackBarTimer;

void showTopSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  showTopSnackBarFromSnackBar(
    context,
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

void showTopSnackBarFromSnackBar(BuildContext context, SnackBar snackBar) {
  _activeTopSnackBarTimer?.cancel();
  _activeTopSnackBar?.remove();
  _activeTopSnackBar = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  final media = MediaQuery.of(context);
  final topOffset = media.padding.top + 12;

  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: topOffset,
        left: 16,
        right: 16,
        child: IgnorePointer(
          ignoring: false,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: _TopSnackBarCard(snackBar: snackBar),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeTopSnackBar = entry;

  _activeTopSnackBarTimer = Timer(snackBar.duration, () {
    if (_activeTopSnackBar == entry) {
      _activeTopSnackBar?.remove();
      _activeTopSnackBar = null;
    } else {
      entry.remove();
    }
  });
}

class _TopSnackBarCard extends StatelessWidget {
  final SnackBar snackBar;

  const _TopSnackBarCard({required this.snackBar});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        snackBar.backgroundColor ?? const Color(0xFF323232);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.up,
      onDismissed: (_) {
        _activeTopSnackBarTimer?.cancel();
        _activeTopSnackBar?.remove();
        _activeTopSnackBar = null;
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: snackBar.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          child: IconTheme(
            data: IconThemeData(
              color: snackBar.action != null ? Colors.white : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: snackBar.content),
                if (snackBar.action != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: snackBar.action!.onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(snackBar.action!.label),
                  ),
                ],
                if (snackBar.showCloseIcon ?? false) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      _activeTopSnackBarTimer?.cancel();
                      _activeTopSnackBar?.remove();
                      _activeTopSnackBar = null;
                    },
                    child: Icon(
                      Icons.close,
                      color: snackBar.closeIconColor ?? Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
