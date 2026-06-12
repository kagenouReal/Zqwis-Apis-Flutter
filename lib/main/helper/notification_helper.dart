import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';

class Notif {
  static OverlayEntry? _currentOverlay;

  /// Tampilkan notifikasi sukses (biru/hijau transparan)
  static void success(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  /// Tampilkan notifikasi error (merah transparan)
  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  /// Base method untuk menampilkan overlay
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (_) {}
      _currentOverlay = null;
    }

    final overlayState = Overlay.of(context);
    
    _currentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 24,
          right: 24,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: _TopNotificationWidget(
                message: message.toUpperCase(), // Pro look usually uses uppercase
                isError: isError,
                onDismiss: () {
                  if (_currentOverlay != null) {
                    try {
                      _currentOverlay!.remove();
                    } catch (_) {}
                    _currentOverlay = null;
                  }
                },
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_currentOverlay!);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> {
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isExiting = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = widget.isError
        ? (isDark ? const Color(0xFF1A1012) : const Color(0xFFFFF5F5))
        : (isDark ? const Color(0xFF0D0D0F) : const Color(0xFFFAFAFA));
        
    final borderColor = widget.isError
        ? const Color(0xFFF43F5E).withOpacity(0.4)
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06));

    final iconColor = widget.isError 
        ? const Color(0xFFF43F5E) 
        : AppColors.accentBlue;

    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: iconColor,
            size: 14,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.message,
              style: GoogleFonts.jetBrainsMono( // Mono for that pro dev look
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    )
    .animate(target: _isExiting ? 0 : 1)
    .slideY(begin: -0.4, end: 0, duration: 250.ms, curve: Curves.easeOutCubic)
    .fade(duration: 200.ms);
  }
}
