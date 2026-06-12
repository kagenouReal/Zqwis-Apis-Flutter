import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});
  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  bool _loading = false;
  Map<String, dynamic> _availableMissions = {};
  bool _fetchingMissions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.role != 'owner') { _fetchMissionsList(); } else { setState(() => _fetchingMissions = false); }
    });
  }

  Future<void> _fetchMissionsList() async {
    try {
      final res = await DioClient.instance.getMissions(action: 'list');
      if (res.statusCode == 200 && res.data['status'] == true && mounted) { setState(() { _availableMissions = res.data['data'] ?? {}; _fetchingMissions = false; }); }
    } catch (_) { if (mounted) setState(() => _fetchingMissions = false); }
  }

  Future<void> _claimMission(String missionId) async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.claimMission(missionId);
      if (res.statusCode == 200 && res.data['status'] == true && mounted) {
        Notif.success(context, res.data['message'] ?? "Mission Completed!");
        context.read<AuthProvider>().refreshProfile();
        _updateMissionLocally(missionId);
      } else {
        if (mounted) Notif.error(context, res.data['message'] ?? "Claim Failed");
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Connection Error");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateMissionLocally(String missionId) {
    if (_availableMissions.isEmpty) return;
    setState(() { for (var category in _availableMissions.values) { if (category is List) { for (var m in category) { if (m['id'] == missionId) { m['isCompleted'] = true; return; } } } } });
  }

  Future<void> _handleSocialMission(String missionId, String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      try { final ok = await launchUrl(uri, mode: LaunchMode.externalApplication); if (ok) { await Future.delayed(const Duration(seconds: 1)); await _claimMission(missionId); } } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: user.role == 'owner' ? () async {} : _fetchMissionsList,
        color: AppColors.accentBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  ModuleHeader(title: "DAILY", accentTitle: "MISSIONS", subtitle: "Complete tasks to earn free coins.", isDark: isDark).animate().fade().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  if (user.role == 'owner') _buildOwnerState(isDark) else if (_fetchingMissions) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (_availableMissions.isEmpty) _buildEmptyState(isDark) else ... _availableMissions.entries.map((entry) => _buildMissionsSection(entry.key.toUpperCase(), entry.value as List, user.missions?['completed'] as List? ?? [], isDark)).toList(),
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
  Widget _buildMissionsSection(String title, List missions, List completed, bool isDark) {
    // Siapin variabel warna biar gampang dipanggil di ternary operator ntar
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA); // Warna pudar (abu-abu)
    final textColor = isDark ? Colors.white : Colors.black; // Warna terang (kontras)
    // Coba sesuaikan AppColors.darkCardBorder lu kalau ada error, gw pake default sini
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1); 

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title),
      const SizedBox(height: 16),
      ...missions.map((m) {
        final isCompleted = m['isCompleted'] ?? completed.contains(m['id']); // Udah pernah di-claim
        final canClaim = m['canClaim'] ?? false; // Misi beres, siap di-claim
        final hasUrl = m['url'] != null && (m['url'] as String).isNotEmpty; // Misi tipe GO (kunjungi link)

        // STATUS AKTIF (Terang): Jika belum claimed DAN (sudah bisa claim ATAU tipe misi GO)
        final bool isActive = !isCompleted && (canClaim || hasUrl);
        final bool isBtnLoading = _loading && isActive;

        // LOGIKA ICON & LABEL
        String btnLabel = isCompleted ? "CLAIMED" : (hasUrl ? "GO" : "CLAIM");
        IconData btnIcon = isCompleted 
            ? Icons.check_circle_outline_rounded // Kalo udah claimed
            : (!isActive && !hasUrl) 
                ? Icons.lock_outline_rounded     // Kalo blm kelar misi (gembok)
                : (hasUrl ? Icons.launch_rounded : Icons.redeem_rounded); // Kalo siap claim / GO

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: borderColor)
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['name'] ?? "Mission", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 4), 
                Text("+${m['reward']} COINS", style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold))
              ])
            ),
            
            // --- MULAI TOMBOL FLAT ALA SEND REQUEST ---
            InkWell(
              onTap: (isBtnLoading || !isActive) 
                  ? null // Kalo lagi loading atau gak aktif, fungsi dimatiin (null)
                  : (hasUrl ? () => _handleSocialMission(m['id'], m['url']) : () => _claimMission(m['id'])),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (isBtnLoading || !isActive)
                      ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000)) // Background Pudar
                      : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)), // Background Terang
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: isBtnLoading
                      ? SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: textColor),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              btnIcon,
                              size: 12,
                              color: (!isActive) ? labelColor : textColor, // Warna Icon dinamis
                            ),
                            const SizedBox(width: 8),
                            Text(
                              btnLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10, 
                                fontWeight: FontWeight.w900,
                                color: (!isActive) ? labelColor : textColor, // Warna Teks dinamis
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // --- END TOMBOL FLAT ---

          ]),
        );
      }).toList(),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildEmptyState(bool isDark) {
    return GlassCard(padding: const EdgeInsets.all(40), child: Column(children: [const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey), const SizedBox(height: 16), Text("No missions available at the moment.", style: GoogleFonts.inter(color: Colors.grey))]));
  }

  Widget _buildOwnerState(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.accentBlue)),
        const SizedBox(height: 24),
        Text("OWNER DETECTED", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Text("You have unlimited resources and system access. Missions are only for standard users.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ]),
    );
  }
}
