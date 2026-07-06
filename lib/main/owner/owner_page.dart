import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/back/myfunc/stats_model.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});
  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  bool _isLoading = true;
  Map<String, dynamic> _system = {};
  Map<String, dynamic> _settings = {};
  StatsModel? _stats;
  final _broadcastController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resSet = await DioClient.instance.getBroadcast();
      final resSys = await DioClient.instance.getSystemInfo();
      final resStats = await DioClient.instance.getStats();
      
      if (mounted) {
        setState(() {
          _settings = resSet.data['data'] ?? {};
          _system = resSys.data['data'] ?? {};
          _stats = resStats.data['status'] == true ? StatsModel.fromJson(resStats.data['data']) : null;
          _broadcastController.text = _settings['broadcast'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Notif.error(context, "Failed to load owner data");
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
// ... rest of methods unchanged ...

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final res = await DioClient.instance.updateOwnerSetting(key, value);
      if (res.statusCode == 200 && res.data['status'] == true) {
        if (mounted) {
            Notif.success(context, "Setting updated");
            _fetchData();
        }
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Update failed");
    }
  }

  Future<void> _backupDb() async {
    try {
      final res = await DioClient.instance.backupDatabase();
      if (res.statusCode == 200 && res.data['status'] == true) {
        if (mounted) Notif.success(context, res.data['message']);
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Backup failed");
    }
  }

  Future<void> _importDb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        final formData = FormData.fromMap({'file': MultipartFile.fromBytes(result.files.single.bytes!, filename: result.files.single.name)});
        final res = await DioClient.instance.dio.post('/api/owner/manage/db/import', data: formData);
        if (mounted) {
          if (res.statusCode == 200 && res.data['status'] == true) {
            Notif.success(context, res.data['message']);
          } else {
            Notif.error(context, res.data['message'] ?? "Import failed");
          }
        }
      }
    } catch (e) {
      if (mounted) Notif.error(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final total = _stats?.total ?? 0;
    final success = _stats?.success ?? 0;
    final ratio = total == 0 ? 100.0 : (success / total * 100);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.accentBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CardWrapper(uniqueId: 'owner_header', child: ModuleHeader(title: "OWNER", accentTitle: "COMMAND", subtitle: "Full control over system and resources.", isDark: isDark)),
                  CardWrapper(uniqueId: 'metrics_card', child: _buildMetricsCard(isDark, ratio)),
                  CardWrapper(uniqueId: 'system_health_card', child: _buildSystemHealth(isDark)),
                  CardWrapper(uniqueId: 'global_controls_card', child: _buildGlobalControls(isDark)),
                  CardWrapper(uniqueId: 'broadcast_section_card', child: _buildBroadcastSection(isDark)),
                  const Padding(padding: EdgeInsets.only(top: 40), child: CopyrightFooter()),
                ]),

              ),
            ),
          ],
        ),
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
          const SectionHeader("LIVE METRICS"),
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

  Widget _buildSystemHealth(bool isDark) {
    final mem = _system['memory'] ?? {};
    final cpu = _system['cpu'] ?? {};
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader("SYSTEM HEALTH"),
        const SizedBox(height: 16),
        _buildHealthTile(icon: Icons.memory_rounded, title: "Memory", value: "${mem['used']} / ${mem['total']}", subtitle: "Usage: ${mem['percent']}", color: AppColors.accentPurple),
        const SizedBox(height: 12),
        _buildHealthTile(icon: Icons.speed_rounded, title: "CPU", value: "${cpu['cores']} Cores", subtitle: cpu['model']?.toString() ?? "Unknown", color: AppColors.accentBlue),
        const SizedBox(height: 12),
        _buildHealthTile(icon: Icons.timer_rounded, title: "Uptime", value: _system['uptime']?.toString() ?? "0s", subtitle: "Platform: ${_system['platform']} (${_system['arch']})", color: const Color(0xFF10B981)),
      ]),
    );
  }

  Widget _buildHealthTile({required IconData icon, required String title, required String value, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900)), Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)]))
      ]),
    );
  }

  Widget _buildGlobalControls(bool isDark) {
    bool isMaintenance = _settings['maintenance'] ?? false;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader("GLOBAL CONTROLS"),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          title: Text("Maintenance Mode", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)), 
          subtitle: Text("Disables all APIs for regular users", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)), 
          value: isMaintenance, 
          activeColor: AppColors.accentBlue, 
          onChanged: (val) => _updateSetting('maintenance', val)
        ),
        const Divider(),
        const SizedBox(height: 16),
        const SectionHeader("DATABASE UTILITIES"),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildFlatActionButton("BACKUP", Icons.backup_rounded, _backupDb, isDark, borderColor, primaryTextColor)),
          const SizedBox(width: 8),
          Expanded(child: _buildFlatActionButton("IMPORT", Icons.upload_file_rounded, _importDb, isDark, borderColor, primaryTextColor)),
        ]),
      ]),
    );
  }

  Widget _buildBroadcastSection(bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader("BROADCAST MESSAGE"),
        const SizedBox(height: 16),
        TextField(
          controller: _broadcastController, 
          maxLines: 3, 
          decoration: InputDecoration(
            hintText: "Enter message for all users...", 
            hintStyle: GoogleFonts.inter(fontSize: 12), 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
            filled: true, 
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
          )
        ),
        const SizedBox(height: 12),
        _buildFlatActionButton("UPDATE BROADCAST", Icons.send_rounded, 
          () => _updateSetting('broadcast', _broadcastController.text), isDark, borderColor, primaryTextColor),
      ]),
    );
  }

  Widget _buildFlatActionButton(String label, IconData icon, VoidCallback onTap, bool isDark, Color borderColor, Color primaryTextColor) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isLoading
              ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
              : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: primaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: primaryTextColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
