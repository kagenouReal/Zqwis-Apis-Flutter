import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';
import 'package:zqwis/main/helper/notification_helper.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/back/myfunc/user_model.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<UserModel> _users = [];
  bool _loading = true;
  bool _isCreateExpanded = false;
  final _createUsernameController = TextEditingController();
  final _createPasswordController = TextEditingController();
  String _createRole = 'user';
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _handleCreateUser() async {
    final username = _createUsernameController.text.trim();
    final password = _createPasswordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      Notif.error(context, 'Username and Password required');
      return;
    }
    setState(() => _creating = true);
    try {
      final res = await DioClient.instance.createUser(username, password, _createRole);
      if (res.statusCode == 200 && mounted) {
        Notif.success(context, 'User created successfully!');
        _createUsernameController.clear();
        _createPasswordController.clear();
        setState(() { _isCreateExpanded = false; _creating = false; });
        _fetchUsers();
        context.read<AuthProvider>().refreshProfile();
      } else {
        if (mounted) { Notif.error(context, res.data['message'] ?? 'Failed to create user'); setState(() => _creating = false); }
      }
    } catch (_) {
      if (mounted) { Notif.error(context, 'Connection Error'); setState(() => _creating = false); }
    }
  }

  Future<void> _fetchUsers() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await DioClient.instance.listUsers();
      if (res.statusCode == 200 && mounted) {
        setState(() { _users = (res.data as List).map((e) => UserModel.fromJson(e)).toList(); _loading = false; });
      }
    } catch (_) {
      if (mounted) { setState(() => _loading = false); Notif.error(context, 'Failed to fetch users'); }
    }
  }

  Future<void> _updateLimit(String username, int amount) async {
    try {
      final res = await DioClient.instance.setLimit(username, amount);
      if (res.statusCode == 200 && mounted) { Notif.success(context, 'Limit updated for $username'); _fetchUsers(); context.read<AuthProvider>().refreshProfile(); }
    } catch (_) { if (mounted) Notif.error(context, 'Failed to update limit'); }
  }

  Future<void> _updateIpQuota(String username, int quota) async {
    try {
      final res = await DioClient.instance.setIpQuota(username, quota);
      if (res.statusCode == 200 && mounted) { Notif.success(context, 'IP Quota updated for $username'); _fetchUsers(); context.read<AuthProvider>().refreshProfile(); }
    } catch (_) { if (mounted) Notif.error(context, 'Failed to update IP quota'); }
  }

  Future<void> _deleteUser(String username) async {
    try {
      final res = await DioClient.instance.deleteUser(username);
      if (res.statusCode == 200 && mounted) { Notif.success(context, 'User $username deleted'); _fetchUsers(); context.read<AuthProvider>().refreshProfile(); }
    } catch (_) { if (mounted) Notif.error(context, 'Failed to delete user'); }
  }

  Future<void> _adminSetCoins(String username, int amount, String action, String reason) async {
    try {
      final res = await DioClient.instance.adminSetCoins(username, amount, action, reason);
      if (res.statusCode == 200 && mounted) { final actionText = action == 'add' ? 'Added' : 'Set'; Notif.success(context, '$actionText coins for $username success'); _fetchUsers(); } else { if (mounted) Notif.error(context, res.data['message'] ?? 'Action failed'); }
    } catch (_) { if (mounted) Notif.error(context, 'Connection error'); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppColors.accentBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                switch (index) {
                  case 0: return Padding(padding: const EdgeInsets.only(top: 16), child: VisibilityAnimator(idKey: 'admin_header', child: ModuleHeader(title: "ADMIN", accentTitle: "PANEL", subtitle: "Manage system users and infrastructure.", isDark: isDark)));
                  case 1: return Padding(padding: const EdgeInsets.only(top: 24), child: VisibilityAnimator(idKey: 'create_account_section', child: _buildCreateAccountSection(isDark)));
                  case 2: return const Padding(padding: EdgeInsets.only(top: 32), child: SectionHeader("USER MANAGEMENT"));
                  case 3: if (_loading) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator())); if (_users.isEmpty) return _buildEmptyState(isDark); return const SizedBox.shrink();
                  case 4: if (_loading || _users.isEmpty) return const SizedBox.shrink(); return Column(children: _users.map((user) => Padding(padding: const EdgeInsets.only(bottom: 12), child: VisibilityAnimator(idKey: 'user_card_${user.username}', child: _UserCardInteractive(user: user, isDark: isDark, onEditLimit: () => _showEditLimitDialog(user), onEditIpQuota: () => _showEditIpQuotaDialog(user), onManageCoins: () => _showManageCoinsDialog(user), onDelete: () => _showDeleteConfirmDialog(user))))).toList());
                  case 5: return const Padding(padding: EdgeInsets.only(top: 40, bottom: 40), child: CopyrightFooter());
                  default: return const SizedBox.shrink();
                }
              }, childCount: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountSection(bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final labelColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _isCreateExpanded = !_isCreateExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentBlue.withOpacity(0.2))), child: const Icon(Icons.person_add_outlined, color: AppColors.accentBlue, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("CREATE ACCOUNT", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900)), Text("Add new user to system infrastructure.", style: GoogleFonts.inter(fontSize: 10, color: labelColor))])),
            AnimatedRotation(turns: _isCreateExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 300), child: Icon(Icons.keyboard_arrow_down_rounded, color: labelColor, size: 24)),
          ])),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _createUsernameController,
            builder: (context, userVal, _) => ValueListenableBuilder<TextEditingValue>(
              valueListenable: _createPasswordController,
              builder: (context, passVal, _) {
                final bool isFormValid = userVal.text.trim().isNotEmpty && passVal.text.trim().isNotEmpty;
                final bool isActive = isFormValid && !_creating;

                return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: Column(children: [
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 20),
                  TextFormField(controller: _createUsernameController, style: GoogleFonts.inter(fontSize: 13), decoration: const InputDecoration(hintText: "Username", prefixIcon: Icon(Icons.person_outline, size: 18))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _createPasswordController, style: GoogleFonts.inter(fontSize: 13), obscureText: true, decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock_outline, size: 18))),
                  const SizedBox(height: 16),
                  
                  // ROLE SELECTOR FLAT
                  Row(children: [
                    Expanded(child: _ChoiceChipFlat(label: "USER", isSelected: _createRole == 'user', onTap: () => setState(() => _createRole = 'user'), isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _ChoiceChipFlat(label: "ADMIN", isSelected: _createRole == 'admin', onTap: () => setState(() => _createRole = 'admin'), isDark: isDark)),
                  ]),
                  
                  const SizedBox(height: 20),
                  
                  // TOMBOL CREATE FLAT
                  InkWell(
                    onTap: isActive ? _handleCreateUser : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000))
                            : (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: _creating
                            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryTextColor))
                            : Text("CREATE ACCOUNT", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? primaryTextColor : labelColor, letterSpacing: 2.0)),
                      ),
                    ),
                  ),
                ]));
              },
            ),
          ),
          crossFadeState: _isCreateExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return GlassCard(padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.people_outline_rounded, size: 48, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted), const SizedBox(height: 16), Text("No users found in the system.", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))]));
  }

  void _showManageCoinsDialog(UserModel user) {
    final amountController = TextEditingController(text: user.totalCoins.toString());
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("SET COINS: ${user.username.toUpperCase()}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: amountController, keyboardType: TextInputType.number, style: GoogleFonts.jetBrainsMono(fontSize: 14), decoration: const InputDecoration(hintText: "New balance", prefixIcon: Icon(Icons.monetization_on_outlined, size: 18)), autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { final amount = int.tryParse(amountController.text); if (amount != null) { Navigator.pop(context); _adminSetCoins(user.username, amount, 'set', reasonController.text.isEmpty ? "Admin adjustment" : reasonController.text); } }, child: Text("SET BALANCE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue))),
        ],
      ),
    );
  }

  void _showEditLimitDialog(UserModel user) {
    final controller = TextEditingController(text: user.limit.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("SET LIMIT: ${user.username.toUpperCase()}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: TextFormField(controller: controller, keyboardType: TextInputType.number, autofocus: true, style: GoogleFonts.jetBrainsMono(fontSize: 14), decoration: const InputDecoration(hintText: "Enter amount...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { final target = int.tryParse(controller.text); if (target != null) { Navigator.pop(context); _updateLimit(user.username, target); } }, child: Text("UPDATE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue))),
        ],
      ),
    );
  }

  void _showEditIpQuotaDialog(UserModel user) {
    final controller = TextEditingController(text: user.maxIpQuota.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("SET IP QUOTA: ${user.username.toUpperCase()}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: TextFormField(controller: controller, keyboardType: TextInputType.number, autofocus: true, style: GoogleFonts.jetBrainsMono(fontSize: 14), decoration: const InputDecoration(hintText: "Enter quota...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { final val = int.tryParse(controller.text); if (val != null) { Navigator.pop(context); _updateIpQuota(user.username, val); } }, child: Text("UPDATE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.brandBlue))),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("DELETE USER: ${user.username.toUpperCase()}", style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        content: Text("Are you sure you want to delete this user? This action cannot be undone.", style: GoogleFonts.inter(fontSize: 12, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); _deleteUser(user.username); }, child: Text("DELETE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent))),
        ],
      ),
    );
  }
}

class _UserCardInteractive extends StatefulWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onEditLimit;
  final VoidCallback onEditIpQuota;
  final VoidCallback onManageCoins;
  final VoidCallback onDelete;
  const _UserCardInteractive({required this.user, required this.isDark, required this.onEditLimit, required this.onEditIpQuota, required this.onManageCoins, required this.onDelete});
  @override
  State<_UserCardInteractive> createState() => _UserCardInteractiveState();
}

class _UserCardInteractiveState extends State<_UserCardInteractive> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = widget.isDark;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accentBlue.withOpacity(0.2))), child: Center(child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accentBlue)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.username, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: titleColor)), Text(user.role.toUpperCase(), style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.accentBlue, fontWeight: FontWeight.w900, letterSpacing: 1.0))])),
            AnimatedRotation(turns: _isExpanded ? 0.5 : 0.0, duration: const Duration(milliseconds: 300), child: Icon(Icons.keyboard_arrow_down_rounded, color: labelColor, size: 24)),
          ])),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0), child: Column(children: [
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 16),
            _buildStatRow("LIMIT STATUS", user.limitDisplay, isDark),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              SizedBox(width: (MediaQuery.of(context).size.width - 64) / 3, child: ActionButton(icon: Icons.edit_rounded, label: "LIMIT", onTap: widget.onEditLimit, isDark: isDark)),
              SizedBox(width: (MediaQuery.of(context).size.width - 64) / 3, child: ActionButton(icon: Icons.security_rounded, label: "IP", onTap: widget.onEditIpQuota, isDark: isDark)),
              SizedBox(width: (MediaQuery.of(context).size.width - 64) / 3, child: ActionButton(icon: Icons.monetization_on_outlined, label: "COINS", onTap: widget.onManageCoins, isDark: isDark)),
              SizedBox(width: (MediaQuery.of(context).size.width - 64) / 3, child: ActionButton(icon: Icons.delete_outline_rounded, label: "DELETE", onTap: widget.onDelete, isDark: isDark)),
            ]),
          ])),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ]),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(6), border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)), child: Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)))]);
  }
}

class _ChoiceChipFlat extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  
  const _ChoiceChipFlat({required this.label, required this.isSelected, required this.onTap, required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final activeColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final inactiveColor = isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? (isDark ? Colors.white24 : Colors.black26) : borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
