import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
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
  final _broadcastController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.getOwnerManageData();
      if (res.statusCode == 200 && res.data['status'] == true) {
        setState(() {
          _system = res.data['data']['system'] ?? {};
          _settings = res.data['data']['settings'] ?? {};
          _broadcastController.text = _settings['broadcast'] ?? "";
        });
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Failed to load owner data");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final res = await DioClient.instance.updateOwnerSetting(key, value);
      if (res.statusCode == 200 && res.data['status'] == true) {
        if (mounted) Notif.success(context, "Setting updated");
        _fetchData();
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
        final res = await DioClient.instance.dio.post('/api/owner/manage', data: formData);
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ModuleHeader(title: "OWNER", accentTitle: "COMMAND", subtitle: "Full control over system and resources.", isDark: isDark).animate().fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildSystemHealth(isDark),
                  const SizedBox(height: 24),
                  _buildGlobalControls(isDark),
                  const SizedBox(height: 24),
                  _buildBroadcastSection(isDark),
                  const SizedBox(height: 40),
                  const CopyrightFooter(),
                ]),
              ),
            ),
          ],
        ),
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
          // TOMBOL BACKUP
          Expanded(child: _buildFlatActionButton("BACKUP", Icons.backup_rounded, _backupDb, isDark, borderColor, primaryTextColor)),
          const SizedBox(width: 8),
          // TOMBOL IMPORT
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
        // TOMBOL UPDATE BROADCAST
        _buildFlatActionButton("UPDATE BROADCAST", Icons.send_rounded, 
          () => _updateSetting('broadcast', _broadcastController.text), isDark, borderColor, primaryTextColor),
      ]),
    );
  }
  Widget _buildFlatActionButton(String label, IconData icon, VoidCallback onTap, bool isDark, Color borderColor, Color primaryTextColor) {
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    
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
