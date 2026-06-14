import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/back/myfunc/stats_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _broadcast;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBroadcast();
  }

  Future<void> _fetchBroadcast() async {
    try {
      final res = await DioClient.instance.getSettings();
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _broadcast = res.data['data']['broadcast'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.accentBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: _fetchBroadcast,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_broadcast != null && _broadcast!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: VisibilityAnimator(idKey: 'broadcast_card', child: _buildBroadcastCard(isDark)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: VisibilityAnimator(idKey: 'banner_card', child: _buildBannerCard(isDark)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildWelcomeSection(isDark),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: CopyrightFooter(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastCard(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.campaign_rounded, color: AppColors.accentBlue, size: 20),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ANNOUNCEMENT", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(
                  _broadcast ?? "",
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/Mmarika.jpg',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 180,
                color: isDark ? Colors.white10 : Colors.black12,
                child: const Center(child: Icon(Icons.broken_image, size: 40)),
              ),
            ),
          ).animate().fade(duration: 800.ms).scaleXY(begin: 0.85, end: 1.0, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.accentGlow : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isDark ? const Color(0x333B82F6) : const Color(0x80BFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PingingDot(),
                const SizedBox(width: 8),
                Text(
                  "SYSTEM ACTIVE",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: 1.5),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack).shimmer(delay: 1500.ms, duration: 1500.ms, color: Colors.white30),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "Zqwis ", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, letterSpacing: -0.5)),
                TextSpan(text: "Apis", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: -0.5)),
              ],
            ),
          ).animate(delay: 450.ms).fade(duration: 500.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Welcome to Zqwis Ecosystem",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
        ).animate().fade().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          "Explore various high-performance APIs for your projects. Stable, secure, and fast.",
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ).animate(delay: 200.ms).fade(),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildQuickStat(Icons.bolt_rounded, "Fast", AppColors.accentBlue),
            _buildQuickStat(Icons.security_rounded, "Secure", const Color(0xFF10B981)),
            _buildQuickStat(Icons.auto_awesome_rounded, "Modern", AppColors.accentPurple),
          ].animate(interval: 100.ms).fade().scale(),
        ),
      ],
    );
  }

  Widget _buildQuickStat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PingingDot extends StatefulWidget {
  const _PingingDot();

  @override
  State<_PingingDot> createState() => _PingingDotState();
}

class _PingingDotState extends State<_PingingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: false);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8, height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_animation.value * 1.5),
              child: Opacity(
                opacity: 1.0 - _animation.value,
                child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF60A5FA))),
              ),
            ),
          ),
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentBlue)),
        ],
      ),
    );
  }
}
