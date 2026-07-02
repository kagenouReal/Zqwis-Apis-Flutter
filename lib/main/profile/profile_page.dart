import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';

//==================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

//==================
class _ProfilePageState extends State<ProfilePage> {
  final _passController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  //==================
  Future<void> _handleAction(String action, {Map<String, dynamic>? payload}) async {
    setState(() => _loading = true);
    try {
      Response res;
      if (action == 'reset_apikey') res = await DioClient.instance.resetApikey();
      else if (action == 'change_password') res = await DioClient.instance.changePassword(payload?['newPassword']);
      else if (action == 'add_ip') res = await DioClient.instance.addIp(payload?['ip']);
      else if (action == 'delete_ip') res = await DioClient.instance.deleteIp(payload?['ip']);
      else throw 'Action not supported';

      if (res.statusCode == 200 && res.data['status'] == true) {
        if (mounted) {
          Notif.success(context, res.data['message'] ?? 'Action Success!');
          if (action == 'change_password') _passController.clear();
          context.read<AuthProvider>().refreshProfile();
        }
      } else {
        if (mounted) Notif.error(context, res.data['message'] ?? 'Action Failed');
      }
    } catch (_) {
      if (mounted) Notif.error(context, 'Connection Error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //==================
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Notif.success(context, '$label COPIED TO CLIPBOARD!');
  }

  //==================
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async {
        await auth.refreshProfile();
      },
      color: AppColors.accentBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
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
                        child: VisibilityAnimator(
                          idKey: 'profile_header',
                          child: ModuleHeader(
                            title: "USER",
                            accentTitle: "PROFILE",
                            subtitle: "Manage your account and API security.",
                            isDark: isDark,
                          ),
                        ),
                      );
                    case 1:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'balance_card',
                          child: _buildBalanceCard(user, isDark),
                        ),
                      );
                    case 2:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'api_activity_card',
                          child: _buildActivityCard(user, isDark),
                        ),
                      );
                    case 3:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'api_security_card',
                          child: _buildSecurityCard(user, isDark),
                        ),
                      );
                    case 4:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'ip_whitelist_card',
                          child: _buildIpWhitelistCard(user, isDark),
                        ),
                      );
                    case 5:
                      if (user.role == 'owner') return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'password_card',
                          child: _buildPasswordCard(isDark),
                        ),
                      );
                    case 6:
                      return const Padding(
                        padding: EdgeInsets.only(top: 40, bottom: 40),
                        child: CopyrightFooter(),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
                childCount: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildActivityCard(dynamic user, bool isDark) {
    final activity = user.activity ?? {};
    final totalSuccess = activity['totalSuccess'] ?? 0;
    final totalFailed = activity['totalFailed'] ?? 0;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("YOUR API ACTIVITY"),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActivityItem(
                icon: Icons.check_circle_outline_rounded,
                label: "SUCCESS REQUESTS",
                value: "$totalSuccess",
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildActivityItem(
                icon: Icons.error_outline_rounded,
                label: "FAILED REQUESTS",
                value: "$totalFailed",
                color: AppColors.error,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Track your successful and failed requests to API V1.",
            style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({required IconData icon, required String label, required String value, required Color color, required bool isDark}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.0)),
                Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildBalanceCard(dynamic user, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _buildBalanceItem(
                icon: Icons.monetization_on_rounded,
                label: "COINS",
                value: "${user.totalCoins}",
                color: AppColors.warning,
                isDark: isDark,
              ),
              Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildBalanceItem(
                icon: Icons.bolt_rounded,
                label: "LIMIT LEFT",
                value: user.limitDisplay,
                color: AppColors.accentBlue,
                isDark: isDark,
              ),
            ],
          ),
          if (user.isPremium) ...[
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PREMIUM STATUS", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: 1.0)),
                    Text(
                      user.isPermanentPremium 
                          ? "PERMANENT ACCESS" 
                          : "${user.premiumDaysLeft} DAYS REMAINING",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                  ),
                  child: Text(user.premiumType.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.accentBlue)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceItem({required IconData icon, required String label, required String value, required Color color, required bool isDark}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.0)),
                Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildSecurityCard(dynamic user, bool isDark) {
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("API SECURITY", dotColor: AppColors.accentBlue),
          Text(
            "Your API Key is used to authenticate requests to our services.",
            style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding dikecilin biar kotak gak kegedean
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user.apikey,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  onPressed: () => _copyToClipboard(user.apikey, "API Key"),
                ),
              ],
            ),
          ),
          if (user.role != 'owner') ...[
            const SizedBox(height: 16),
            // --- TOMBOL FLAT RESET API (Selalu Terang) ---
            InkWell(
              onTap: _loading ? null : () => _handleAction('reset_apikey'),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _loading 
                      ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
                      : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)), // Terang terus
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 14, color: primaryTextColor),
                            const SizedBox(width: 8),
                            Text(
                              "RESET API KEY",
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
            ),
          ],
        ],
      ),
    );
  }

  //==================
  Widget _buildIpWhitelistCard(dynamic user, bool isDark) {
    if (user.role == 'owner') return const SizedBox.shrink();
    
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader("IP WHITELIST"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.router_rounded, size: 10, color: AppColors.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      "MAX ${user.ipQuotaDisplay} IP",
                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.accentBlue, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            "Authorize specific IP addresses to access your API Key.",
            style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 20),

          if (user.whitelistIp.isEmpty)
            _buildEmptyState("No IP whitelisted", isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: user.whitelistIp.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ip = user.whitelistIp[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ip, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        onPressed: _loading ? null : () => _handleAction('delete_ip', payload: {'ip': ip}),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // --- TOMBOL FLAT ADD NEW IP (Selalu Terang) ---
          InkWell(
            onTap: _loading ? null : () => _showAddIpDialog(),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _loading 
                    ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
                    : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)), // Terang terus
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: _loading
                    ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: primaryTextColor),
                          const SizedBox(width: 8),
                          Text(
                            "ADD NEW IP",
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
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildPasswordCard(bool isDark) {
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("SECURITY", dotColor: AppColors.accentBlue),
          Text(
            "Update your password to keep your account secure.",
            style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passController,
            obscureText: true,
            style: GoogleFonts.jetBrainsMono(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter new password",
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: labelColor),
            ),
          ),
          const SizedBox(height: 16),
          
          // --- TOMBOL FLAT PASSWORD (Dinamis) ---
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _passController,
            builder: (context, value, child) {
              final bool isFormValid = value.text.trim().isNotEmpty;
              final bool isActive = isFormValid && !_loading;

              return InkWell(
                onTap: isActive
                    ? () => _handleAction('change_password', payload: {'newPassword': value.text.trim()})
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)) // Terang
                        : (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000)), // Pudar
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                !isFormValid ? Icons.lock_outline_rounded : Icons.update_rounded,
                                size: 14,
                                color: isActive ? primaryTextColor : labelColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "UPDATE PASSWORD",
                                style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: isActive ? primaryTextColor : labelColor,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  //==================
  Widget _buildEmptyState(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text, 
          style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        ),
      ),
    );
  }

  //==================
  void _showAddIpDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("WHITELIST NEW IP", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: TextFormField(
          controller: ipController,
          style: GoogleFonts.jetBrainsMono(fontSize: 14),
          decoration: const InputDecoration(hintText: "e.g. 192.168.1.1"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ),
          TextButton(
            onPressed: () {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(context);
                _handleAction('add_ip', payload: {'ip': ip});
              }
            },
            child: Text("ADD IP", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
          ),
        ],
      ),
    );
  }
}
