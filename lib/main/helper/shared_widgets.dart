// lib/main/helper/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

//==================
class ModuleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? accentTitle;
  final bool isDark;

  const ModuleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.accentTitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColorPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textColorSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.white],
                stops: [0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: CustomPaint(painter: GridBackgroundPainter(isDark: isDark)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "$title ",
                              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: textColorPrimary, letterSpacing: -0.5),
                            ),
                            if (accentTitle != null)
                              TextSpan(
                                text: accentTitle,
                                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: -0.5),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColorSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x05FFFFFF) : const Color(0x05000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.3), shape: BoxShape.circle),
                              ).animate(onPlay: (ctrl) => ctrl.repeat()).scaleXY(begin: 1.0, end: 2.2, duration: 2.seconds).fade(end: 0),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text("ONLINE", style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: textColorPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ShimmerBrand(isDark: isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//==================
class _ShimmerBrand extends StatelessWidget {
  final bool isDark;
  const _ShimmerBrand({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, letterSpacing: 1.0);
    final blueStyle = GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ... "©Zqwis ".characters.map((char) => Text(char, style: baseStyle)),
        ... "Apis".characters.map((char) => Text(char, style: blueStyle)),
      ].animate(interval: 50.ms).fade(duration: 150.ms).slideX(begin: 0.1, end: 0).shimmer(delay: 1.seconds, duration: 1200.ms, color: Colors.white),
    );
  }
}

/// Glass card dengan backdrop blur + border konsisten
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor.withOpacity(isDark ? 0.8 : 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section header dengan dot + label uppercase
class SectionHeader extends StatelessWidget {
  final String title;
  final Color? dotColor;
  
  const SectionHeader(this.title, {super.key, this.dotColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = dotColor ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Copyright footer konsisten
class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Center(
          child: Text(
            "© 2026 KAGENOU  |  ZQWIS APIS",
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.lightTextSecondary,
              letterSpacing: 4.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Grid background painter reusable
class GridBackgroundPainter extends CustomPainter {
  final bool isDark;
  
  const GridBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark 
          ? Colors.white.withOpacity(0.015) 
          : Colors.black.withOpacity(0.01)
      ..strokeWidth = 1.0;

    const double boxSize = 14.0;

    for (double i = 0; i < size.width; i += boxSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += boxSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) => false;
}

/// Button subtle yang konsisten buat action-action kecil ato gede
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;
  final bool isLoading;
  final Color? color;
  final double? width;

  const ActionButton({
    super.key,
    required this.icon,
    this.label,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
    this.isLoading = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final labelColor = color ?? (isPrimary 
        ? AppColors.accentBlue 
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPrimary ? AppColors.accentBlue.withOpacity(0.5) : borderColor),
          color: isPrimary ? AppColors.accentBlue.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue))
            else ...[
              Icon(icon, size: 16, color: labelColor),
              if (label != null) ...[
                const SizedBox(width: 10),
                Text(
                  label!,
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    color: labelColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Tambahin di shared_widgets.dart
class VisibilityAnimator extends StatefulWidget {
  final String idKey;
  final Widget child;

  const VisibilityAnimator({
    super.key,
    required this.idKey,
    required this.child,
  });

  @override
  State<VisibilityAnimator> createState() => _VisibilityAnimatorState();
}

class _VisibilityAnimatorState extends State<VisibilityAnimator> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.idKey),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          if (mounted) setState(() => _isVisible = true);
        }
      },
      child: widget.child
          .animate(target: _isVisible ? 1 : 0)
          .fade(duration: 300.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
// Tambahin di shared_widgets.dart
class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isError
        ? (isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626))
        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}