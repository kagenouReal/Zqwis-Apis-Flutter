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
  StatsModel? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) Notif.error(context, 'Gagal membuka link');
      }
    } catch (_) {
      if (mounted) Notif.error(context, 'Error link');
    }
  }

  Future<void> _fetchStats() async {
    try {
      final res = await DioClient.instance.getStats();
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _stats = StatsModel.fromJson(res.data);
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingStats = false);
        Notif.error(context, 'Gagal mengambil metrics');
      }
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return "STABLE";
    try {
      final d = DateTime.parse(iso).toLocal();
      return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}";
    } catch (_) {
      return "STABLE";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _stats?.total ?? 0;
    final success = _stats?.success ?? 0;
    final ratio = total == 0 ? 100.0 : (success / total * 100);

    return RefreshIndicator(
      color: AppColors.accentBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: _fetchStats,
      child: CustomScrollView(
        cacheExtent: 500,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  switch (index) {
                    case 0:
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: VisibilityAnimator(idKey: 'banner_card', child: _buildBannerCard(isDark)),
                      );
                    case 1:
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: VisibilityAnimator(idKey: 'metrics_card', child: _buildMetricsCard(isDark, ratio)),
                      );
                    case 2:
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: VisibilityAnimator(idKey: 'project_card', child: _buildProjectInfoCard(isDark)),
                      );
                    case 3:
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CopyrightFooter(),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
                childCount: 4,
              ),
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
          const SizedBox(height: 8),
          Text(
            "kage nyscrep web ampe keluat mani.",
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            textAlign: TextAlign.center,
          ).animate(delay: 600.ms).fade(duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(bool isDark, double ratio) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final valueColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("LIVE METRICS", dotColor: AppColors.accentBlue),
          if (_loadingStats)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator()),
            ).animate().fade()
          else
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                _buildMetricBox(icon: "⊞", title: "Total", value: "${_stats?.total ?? 0}", iconColor: AppColors.accentBlue, bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: valueColor, borderColor: borderColor),
                _buildMetricBox(icon: "✓", title: "Success", value: "${_stats?.success ?? 0}", iconColor: const Color(0xFF10B981), bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: const Color(0xFF10B981), borderColor: borderColor),
                _buildMetricBox(icon: "✕", title: "Failed", value: "${_stats?.failed ?? 0}", iconColor: const Color(0xFFF43F5E), bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: const Color(0xFFF43F5E), borderColor: borderColor),
                _buildMetricBox(icon: "◷", title: "Crash", value: _formatTime(_stats?.lastCrash), iconColor: const Color(0xFF06B6D4), bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: const Color(0xFF06B6D4), borderColor: borderColor),
              ].animate(interval: 100.ms).fade(duration: 400.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
            ),
          const SizedBox(height: 20),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SYSTEM HEALTH", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isDark ? AppColors.accentGlow : const Color(0xCCEFF6FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? const Color(0x333B82F6) : const Color(0x80BFDBFE))),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio),
                  duration: 1.seconds,
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) => Text("${value.toStringAsFixed(1)}%", style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4, width: double.infinity,
            decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : AppColors.lightSurface, borderRadius: BorderRadius.circular(999), border: Border.all(color: borderColor)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (ratio / 100).clamp(0.0, 1.0),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)]), boxShadow: const [BoxShadow(color: Color(0x803B82F6), blurRadius: 8)])),
            ).animate().scaleX(begin: 0, end: 1, duration: 1200.ms, curve: Curves.easeOutCirc, alignment: Alignment.centerLeft),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({required String icon, required String title, required String value, required Color iconColor, required Color bgColor, required Color valueColor, required Color borderColor}) {
    final isNumber = int.tryParse(value) != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: iconColor.withOpacity(0.2))),
            child: Center(child: Text(icon, style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.darkTextSecondary, letterSpacing: 1.5), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                if (isNumber)
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: int.parse(value)),
                    duration: 1200.ms, curve: Curves.easeOutQuart,
                    builder: (context, val, child) => Text('$val', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis),
                  )
                else
                  Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoCard(bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("PROJECT INFO", dotColor: AppColors.darkTextMuted),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: [
              _buildInfoBox(icon: Icons.person_outline_rounded, title: "Creator", value: "Kagenou?", iconColor: AppColors.darkTextSecondary, bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, borderColor: borderColor),
              _buildInfoBox(icon: Icons.code_rounded, title: "Github", value: "kagenouReal", iconColor: AppColors.accentBlue, bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: AppColors.accentBlue, borderColor: borderColor, url: "https://github.com/kagenouReal"),
              _buildInfoBox(icon: Icons.chat_bubble_outline_rounded, title: "WhatsApp", value: "+60 111...", iconColor: const Color(0xFF10B981), bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: const Color(0xFF10B981), borderColor: borderColor, url: "https://wa.me/601112260297"),
              _buildInfoBox(icon: Icons.send_rounded, title: "Telegram", value: "@Kagenouonly", iconColor: const Color(0xFF06B6D4), bgColor: isDark ? AppColors.darkSurface : AppColors.lightSurface, valueColor: const Color(0xFF06B6D4), borderColor: borderColor, url: "https://t.me/Kagenouonly"),
            ].animate(interval: 100.ms).fade(duration: 400.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({required IconData icon, required String title, required String value, required Color iconColor, required Color bgColor, required Color valueColor, required Color borderColor, String? url}) {
    return InkWell(
      onTap: url != null ? () => _openUrl(url) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: iconColor.withOpacity(0.2))),
              child: Center(child: Icon(icon, color: iconColor, size: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.darkTextSecondary, letterSpacing: 1.5), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(child: Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis)),
                      if (url != null) Icon(Icons.arrow_outward_rounded, size: 10, color: valueColor),
                    ],
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
