import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _loading = false;
  Map<String, dynamic> _products = {'premium': {}, 'limit': {}};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await DioClient.instance.dio.get('/api/shopping/list');
      if (res.statusCode == 200 && res.data['status'] == true) {
        final data = res.data['data'];
        if (data is Map) {
          setState(() => _products = Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}
  }

  // Helper untuk cast aman di UI
  Map<String, dynamic> _getSafeMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }


  Future<void> _buyPremium(String packageType) async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.buyPremium(packageType);
      if (res.statusCode == 200 && res.data['status'] == true && mounted) {
        Notif.success(context, "Premium Activated Successfully!");
        context.read<AuthProvider>().refreshProfile();
      } else {
        if (mounted) Notif.error(context, res.data['message'] ?? "Purchase Failed");
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Connection Error");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buyLimit(String packageType) async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.buyLimit(packageType);
      if (res.statusCode == 200 && res.data['status'] == true && mounted) {
        Notif.success(context, "API Limits Added Successfully!");
        context.read<AuthProvider>().refreshProfile();
      } else {
        if (mounted) Notif.error(context, res.data['message'] ?? "Purchase Failed");
      }
    } catch (_) {
      if (mounted) Notif.error(context, "Connection Error");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: () async { await auth.refreshProfile(); },
      color: AppColors.accentBlue,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                switch (index) {
                  case 0: return Padding(padding: const EdgeInsets.only(top: 16), child: VisibilityAnimator(idKey: 'store_header', child: ModuleHeader(title: "OFFICIAL", accentTitle: "STORE", subtitle: "Upgrade your account to premium features.", isDark: isDark)));
                  case 1: return CardWrapper(uniqueId: 'premium_card', child: _buildPremiumSection(user, isDark));
                  case 2: return CardWrapper(uniqueId: 'limit_card', child: _buildLimitSection(user, isDark));
                  case 3: return const Padding(padding: EdgeInsets.only(top: 40, bottom: 40), child: CopyrightFooter());
                  default: return const SizedBox.shrink();
                }
              }, childCount: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitSection(dynamic user, bool isDark) {
    final limitData = _getSafeMap(_products['limit']);
    final bool canBuy = user.role != 'owner';
    
    // Mapping icons untuk id paket (hardcode mapping kecil untuk icon saja)
    final icons = {'100': Icons.bolt_rounded, '500': Icons.auto_awesome_rounded, '1000': Icons.rocket_launch_rounded};
    final colors = {'100': AppColors.accentBlue, '500': AppColors.brandBlue, '1000': AppColors.accentCyan};

    // Setup warna untuk tombol flat
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader("API QUOTA PACKS"),
        if (!canBuy) Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentBlue.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue, size: 20), const SizedBox(width: 12), Expanded(child: Text("Owner accounts have unlimited quota. Purchasing is disabled.", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBlue)))]))) else ...[const SizedBox(height: 8), Text("Add one-time extra requests to your current balance.", style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)), const SizedBox(height: 16)],
        ... limitData.entries.map((entry) {
          final id = entry.key;
          final pkg = _getSafeMap(entry.value);
          final price = (pkg['coinsRequired'] ?? 0) as int;
          final limit = (pkg['limit'] ?? 0) as int;

          // CEK KOIN & ROLE
          final isTooExpensive = user.totalCoins < price;
          final bool isDisabled = !canBuy || isTooExpensive;
          final bool isActive = !isDisabled && !_loading;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: borderColor)
            ),
            child: Row(children: [
              Icon(icons[id] ?? Icons.bolt_rounded, color: colors[id] ?? AppColors.accentBlue, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$limit API Limits", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text("$price COINS", style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))])),
              
              // --- TOMBOL FLAT LIMIT ---
              InkWell(
                onTap: !isActive ? null : () => _showBuyLimitDialog({'id': id, 'name': '$limit API Limits', 'price': price}),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: !isActive
                        ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
                        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(!isActive ? Icons.lock_outline_rounded : Icons.add_shopping_cart_rounded, size: 12, color: !isActive ? labelColor : primaryTextColor),
                              const SizedBox(width: 8),
                              Text("BUY", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: !isActive ? labelColor : primaryTextColor, letterSpacing: 1.5)),
                            ],
                          ),
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
      ]),
    );
  }


  void _showBuyLimitDialog(Map<String, dynamic> pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("CONFIRM QUOTA PURCHASE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: Text("Are you sure you want to add ${pkg['name']} for ${pkg['price']} coins?", style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); _buyLimit(pkg['id'] as String); }, child: Text("CONFIRM", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue))),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(dynamic user, bool isDark) {
    final premiumData = _getSafeMap(_products['premium']);
    final bool canBuy = user.role == 'user';

    // Mapping icons dan colors
    final icons = {'7day': Icons.flash_on_rounded, '30day': Icons.star_rounded, 'permanent': Icons.diamond_rounded};
    final colors = {'7day': AppColors.brandBlue, '30day': AppColors.accentPurple, 'permanent': AppColors.warning};

    // Setup warna untuk tombol flat
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader("PREMIUM PACKAGES"),
        if (!canBuy) Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentBlue.withOpacity(0.2))), child: Row(children: [const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue, size: 20), const SizedBox(width: 12), Expanded(child: Text("Your current role (${user.role.toUpperCase()}) already has high privileges. Premium is for standard users.", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBlue)))]))),
        ... premiumData.entries.map((entry) {
          final id = entry.key;
          final pkg = _getSafeMap(entry.value);
          final price = (pkg['coinsRequired'] ?? 0) as int;
          final days = (pkg['days'] ?? 0) as int;
          final name = days == -1 ? "Permanent Access" : "$days Days Premium";

          // CEK KOIN & ROLE
          final isTooExpensive = user.totalCoins < price;
          final bool isDisabled = !canBuy || isTooExpensive;
          final bool isActive = !isDisabled && !_loading;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: borderColor)
            ),
            child: Row(children: [
              Icon(icons[id] ?? Icons.diamond_rounded, color: colors[id] ?? AppColors.warning, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text("$price COINS", style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87))])),
              
              // --- TOMBOL FLAT PREMIUM ---
              InkWell(
                onTap: !isActive ? null : () => _showBuyConfirmDialog({'id': id, 'name': name, 'price': price}),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: !isActive
                        ? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
                        : (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(!isActive ? Icons.lock_outline_rounded : Icons.shopping_cart_outlined, size: 12, color: !isActive ? labelColor : primaryTextColor),
                              const SizedBox(width: 8),
                              Text("BUY", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: !isActive ? labelColor : primaryTextColor, letterSpacing: 1.5)),
                            ],
                          ),
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  void _showBuyConfirmDialog(Map<String, dynamic> pkg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("CONFIRM PURCHASE", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: Text("Are you sure you want to buy ${pkg['name']} for ${pkg['price']} coins?", style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); _buyPremium(pkg['id'] as String); }, child: Text("CONFIRM", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue))),
        ],
      ),
    );
  }
}
