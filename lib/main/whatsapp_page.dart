import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

//==================
class WhatsAppPairingPage extends StatefulWidget {
  const WhatsAppPairingPage({super.key});

  @override
  State<WhatsAppPairingPage> createState() => _WhatsAppPairingPageState();
}

//==================
class _WhatsAppPairingPageState extends State<WhatsAppPairingPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _status;
  String? _pairingCode;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  //==================
  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      final res = await DioClient.instance.getWaStatus();
      if (res.statusCode == 200 && mounted) {
        setState(() => _status = res.data);
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Gagal mengambil status WA', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //==================
  Future<void> _connect() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppSnackbar.show(context, 'Nomor HP jangan kosong, bang!', isError: true);
      return;
    }
    setState(() {
      _isConnecting = true;
      _pairingCode = null;
    });
    try {
      final res = await DioClient.instance.connectWa(phone);
      if (res.statusCode == 200 && res.data['status'] == true) {
        if (mounted) {
          final data = res.data['data'];
          setState(() {
            _pairingCode = data != null ? data['pairingCode'] : null;
          });
          AppSnackbar.show(context, res.data['message'] ?? 'Berhasil terkirim!');
          _fetchStatus();
        }
      } else {
        if (mounted) AppSnackbar.show(context, res.data['message'] ?? 'Gagal menghubungkan', isError: true);
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Error saat menghubungkan', isError: true);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  //==================
  Future<void> _disconnect(String phoneNumber) async {
    try {
      final res = await DioClient.instance.disconnectWa(phoneNumber);
      if (res.statusCode == 200 && mounted) {
        AppSnackbar.show(context, 'Berhasil diputus!');
        _fetchStatus();
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Gagal memutus koneksi', isError: true);
    }
  }

  //==================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bots = (_status?['bots'] as List?) ?? [];
    final limits = _status?['limits'] as Map?;

    return RefreshIndicator(
      color: AppColors.accentBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: _fetchStatus,
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
                          idKey: 'wa_header_card',
                          child: ModuleHeader(
                            title: "WA",
                            accentTitle: "PAIRING",
                            subtitle: "Link your device with a pairing code.",
                            isDark: isDark,
                          ),
                        ),
                      );
                    case 1:
                      if (limits == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: VisibilityAnimator(
                          idKey: 'wa_limit_card',
                          child: _buildLimitCard(limits, isDark),
                        ),
                      );
                    case 2:
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'wa_connect_form',
                          child: _buildConnectForm(isDark),
                        ),
                      );
                    case 3:
                      if (_pairingCode == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: VisibilityAnimator(
                          idKey: 'wa_pairing_card',
                          child: _buildPairingCodeCard(isDark),
                        ),
                      );
                    case 4:
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: SectionHeader("CONNECTED BOTS"),
                      );
                    case 5:
                      if (_isLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (bots.isEmpty) return _buildEmptyState(isDark);
                      return Column(
                        children: bots.map((bot) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VisibilityAnimator(
                            idKey: 'bot_tile_${bot['phoneNumber']}',
                            child: _buildBotTile(bot, isDark),
                          ),
                        )).toList(),
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
  Widget _buildLimitCard(Map limits, bool isDark) {
    final used = limits['used'] ?? 0;
    final max = limits['max'] ?? 0;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildLimitStat("USED", "$used", Icons.check_circle_outline, isDark),
          Container(width: 1, height: 40, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
          _buildLimitStat("MAX LIMIT", "$max", Icons.speed, isDark),
        ],
      ),
    );
  }

  //==================
  Widget _buildLimitStat(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: AppColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18, 
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  //==================
  //==================
  Widget _buildConnectForm(bool isDark) {
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("CONNECT NEW NUMBER", dotColor: AppColors.accentBlue),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: primaryTextColor,
            ),
            decoration: InputDecoration(
              hintText: "628...",
              prefixIcon: Icon(Icons.phone_android_rounded, size: 20, color: labelColor),
            ),
          ),
          const SizedBox(height: 20),
          
          // --- MULAI TOMBOL FLAT (Dinamis dengerin inputan Text) ---
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _phoneController,
            builder: (context, value, child) {
              // Cek form valid (nggak kosong) dan lagi nggak loading
              final bool isFormValid = value.text.trim().isNotEmpty;
              final bool isActive = isFormValid && !_isConnecting;

              return InkWell(
                onTap: isActive ? _connect : null, // Mati kalo form kosong / loading
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)) // Background Terang
                        : (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000)), // Background Pudar
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: _isConnecting
                        ? SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: primaryTextColor,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                !isFormValid ? Icons.lock_outline_rounded : Icons.qr_code_scanner_rounded, // Gembok kalo kosong
                                size: 14,
                                color: isActive ? primaryTextColor : labelColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "GET PAIRING CODE",
                                style: GoogleFonts.inter(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w900,
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
          // --- END TOMBOL FLAT ---
        ],
      ),
    );
  }

  //==================
  Widget _buildPairingCodeCard(bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Text(
              "PAIRING CODE READY",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              _pairingCode ?? "",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32, 
                fontWeight: FontWeight.w900, 
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, 
                letterSpacing: 8.0,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: AppColors.accentBlue.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            "Open WhatsApp > Linked Devices > Link with Phone Number",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11, 
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, 
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildBotTile(Map bot, bool isDark) {
    final phone = bot['phoneNumber'] ?? 'Unknown';
    final connected = bot['connected'] ?? false;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (connected ? AppColors.success : AppColors.error).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: (connected ? AppColors.success : AppColors.error).withOpacity(0.2)),
            ),
            child: Icon(
              connected ? Icons.link_rounded : Icons.link_off_rounded,
              color: connected ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone,
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: titleColor,
                  ),
                ),
                Text(
                  connected ? "CONNECTED" : "DISCONNECTED",
                  style: GoogleFonts.inter(
                    fontSize: 9, 
                    fontWeight: FontWeight.w900,
                    color: connected ? AppColors.success : AppColors.error,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _disconnect(phone),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            style: IconButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  //==================
  Widget _buildEmptyState(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(height: 16),
          Text(
            "No bots connected yet.",
            style: GoogleFonts.inter(
              fontSize: 12, 
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
