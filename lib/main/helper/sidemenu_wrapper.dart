import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/main/helper/switchmode_provider.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/back/api/dio_client.dart'; 
import 'package:zqwis/back/myfunc/api_item_model.dart'; 
//===============
class _SidebarGridPainter extends CustomPainter {
final bool isDark;
_SidebarGridPainter({required this.isDark});
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.015)
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
bool shouldRepaint(covariant _SidebarGridPainter oldDelegate) => false;
}
//===============
class SidemenuWrapper extends StatefulWidget {
final Widget child;
const SidemenuWrapper({super.key, required this.child});
@override
State<SidemenuWrapper> createState() => _SidemenuWrapperState();
}
//===============
class _SidemenuWrapperState extends State<SidemenuWrapper> {
List<String> _categories = [];
bool _loadingCategories = true;
@override
void initState() {
super.initState();
_fetchCategories();
}
Future<void> _fetchCategories() async {
try {
final res = await DioClient.instance.getApiList();
if (res.statusCode == 200) {
final apis = (res.data as List).map((e) => ApiItemModel.fromJson(e)).toList();
final cats = apis.map((a) => a.category.isEmpty ? "Uncategorized" : a.category).toSet().toList();
if (mounted) {
setState(() {
_categories = cats;
_loadingCategories = false;
});
}
}
} catch (_) {
if (mounted) setState(() => _loadingCategories = false);
}
}
@override
//===============
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final bgColor = theme.scaffoldBackgroundColor;
final cardColor = theme.colorScheme.surface;
final textColor = theme.colorScheme.onSurface;
final borderColor = isDark
? Colors.white.withOpacity(0.08)
: Colors.black.withOpacity(0.08);
final zinc500 = isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);
final zinc400 = isDark ? const Color(0xFFA1A1AA) : const Color(0xFFA1A1AA);
return Scaffold(
backgroundColor: bgColor,
drawer: Drawer(
width: 288, 
backgroundColor: Colors.transparent, 
elevation: 0,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
child: ClipRect( 
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
child: Container(
decoration: BoxDecoration(
color: cardColor.withOpacity(0.95),
border: Border(right: BorderSide(color: borderColor, width: 1)),
),
child: Stack(
children: [
Positioned.fill(
child: ShaderMask(
shaderCallback: (rect) {
return const LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [Colors.transparent, Colors.white],
stops: [0.5, 1.0], 
).createShader(rect);
},
blendMode: BlendMode.dstIn,
child: CustomPaint(
painter: _SidebarGridPainter(isDark: isDark),
),
),
),
Column(
  children: [
    Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
        color: Colors.transparent,
      ),
      child: SafeArea(
        bottom: false, 
        child: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 16, left: 24, right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/zqwis.png', height: 44, errorBuilder: (c, e, s) => Icon(Icons.api, color: textColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0xCC10B981), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("MENU PANEL", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: zinc500, letterSpacing: 2.0)),
                    ],
                  ),
                ],
              ),
              const _ThemeToggleButton(),
            ],
          ),
        ),
      ),
    ),
//===============
Expanded(
  child: ListView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    children: [
      _buildSectionHeader("OVERVIEW", zinc400),
      const _NavLink(href: '/home', icon: Icons.dashboard_outlined, text: "Dashboard"),
      const _NavLink(href: '/missions', icon: Icons.assignment_turned_in_outlined, text: "Daily Missions"),

      const SizedBox(height: 28),
      _buildSectionHeader("DOCUMENTATION", zinc400),
      const _NavLink(href: '/docsmenu', icon: Icons.folder_open_outlined, text: "API Explorer"),
      if (_loadingCategories)
        const Padding(
          padding: EdgeInsets.only(left: 32, top: 12),
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (_categories.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(left: 14, top: 4),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: borderColor))),
          child: Column(
            children: _categories.map((cat) {
              return _NavLink(
                href: '/docsmenu?cat=${Uri.encodeComponent(cat)}', 
                icon: Icons.subdirectory_arrow_right, 
                text: cat,
                isSub: true,
              );
            }).toList(),
          ),
        ),
              const SizedBox(height: 28),
      _buildSectionHeader("BOT AUTOMATION", zinc400),
      const _NavLink(href: '/whatsapp', icon: Icons.chat_bubble_outline_rounded, text: "WhatsApp"),
              const SizedBox(height: 28),
      _buildSectionHeader("SHOP", zinc400),
      const _NavLink(href: '/store', icon: Icons.shopping_bag_outlined, text: "Official Store"),
      const SizedBox(height: 28),
      _buildSectionHeader("SYSTEM", zinc400),
      const _NavLink(href: '/profile', icon: Icons.person_outline, text: "My Profile"),
      Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final role = auth.user?.role ?? "GUEST";
          if (role == 'admin' || role == 'owner') {
            return Container(
              margin: const EdgeInsets.only(left: 14, top: 4),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: borderColor))),
              child: Column(
                children: [
                  const _NavLink(href: '/adminmenu', icon: Icons.subdirectory_arrow_right, text: "Admin Panel", isSub: true),
                  if (role == 'owner')
                    const _NavLink(href: '/ownermenu', icon: Icons.subdirectory_arrow_right, text: "Owner Panel", isSub: true),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    ],
  ),
),
//===============
Container(
padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 4),
decoration: BoxDecoration(
border: Border(top: BorderSide(color: borderColor)),
color: Colors.transparent, 
),
child: Consumer<AuthProvider>(
builder: (context, auth, _) {
final username = auth.user?.username ?? "Unknown Node";
final role = auth.user?.role?.toUpperCase() ?? "GUEST";
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Row(
children: [
Stack(
children: [
Container(
width: 36, height: 36,
decoration: BoxDecoration(
color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000), 
borderRadius: BorderRadius.circular(10),
border: Border.all(color: borderColor),
),
child: Center(
child: Text(
username[0].toUpperCase(),
style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: textColor),
),
),
),
Positioned(
bottom: -2, right: -2,
child: Container(
width: 10, height: 10,
decoration: BoxDecoration(
color: const Color(0xFF10B981),
shape: BoxShape.circle,
border: Border.all(color: isDark ? const Color(0xFF09090B) : Colors.white, width: 2),
),
),
),
],
),
const SizedBox(width: 12),
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text("@$username", 
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: textColor), 
              overflow: TextOverflow.ellipsis
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          Text("ROLE: $role", style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.bold, color: zinc400, letterSpacing: 1.5)),
          const SizedBox(width: 8),
          Container(width: 3, height: 3, decoration: BoxDecoration(color: zinc500, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Icon(Icons.monetization_on_outlined, size: 8, color: zinc400),
          const SizedBox(width: 2),
          Text("${auth.user?.totalCoins ?? 0}", style: GoogleFonts.jetBrainsMono(fontSize: 8, fontWeight: FontWeight.bold, color: zinc400)),
        ],
      ),
    ],
  ),
),

],
),
),
GestureDetector(
onTap: () {
auth.logout();
context.go('/');
},
child: Container(
width: 36, height: 36,
decoration: BoxDecoration(
color: isDark ? const Color(0x1AF43F5E) : const Color(0x0DF43F5E),
borderRadius: BorderRadius.circular(10),
border: Border.all(color: const Color(0x33F43F5E)),
),
child: const Center(child: Icon(Icons.exit_to_app_rounded, color: Color(0xFFF43F5E), size: 16)),
),
),
],
);
},
),
),
],
),
],
),
),
),
),
),
//===============
body: Stack(
clipBehavior: Clip.none, 
children: [
Positioned(
top: -100, left: -50,
child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(isDark ? 0.03 : 0.05))),
),
Positioned(
bottom: -100, right: -50,
child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF06B6D4).withOpacity(isDark ? 0.03 : 0.05))),
),
Positioned.fill(
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), 
child: const SizedBox.expand(), 
),
),
Column(
  children: [
    Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.95), 
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
child: SafeArea(
  bottom: false,
  child: Builder(
    builder: (ctx) => Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x05FFFFFF)
                      : const Color(0x05000000),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),

            Image.asset(
              'assets/zqwis.png',
              height: 44,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.api, color: textColor),
            ),
          ],
        ),
      ),
    ),
  ),
),
    ),
//===============
    Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: widget.child, 
      ),
    ),
  ],
),
],
),
);
}
//===============
Widget _buildSectionHeader(String title, Color color) {
return Padding(
padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
child: Row(
children: [
Container(width: 8, height: 1, color: color.withOpacity(0.5)),
const SizedBox(width: 8),
Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
],
),
);
}
}
//===============
class _NavLink extends StatelessWidget {
final String href;
final IconData icon;
final String text;
final bool isSub;
const _NavLink({required this.href, required this.icon, required this.text, this.isSub = false});
@override
//===============
Widget build(BuildContext context) {
final state = GoRouterState.of(context);
final currentUri = state.uri;
final currentPath = currentUri.path;
final currentCat = currentUri.queryParameters['cat'];
final targetUri = Uri.parse(href);
final targetPath = targetUri.path;
final isCategoryLink = targetUri.hasQuery;
final targetCat = targetUri.queryParameters['cat'];
bool isActive = false;
if (isCategoryLink) {
isActive = (currentPath == targetPath) && (currentCat == targetCat);
} else {
if (targetPath == '/docsmenu') {
isActive = (currentPath == targetPath) && (currentCat == null);
} else {
isActive = currentPath.startsWith(targetPath);
}
}
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final activeTextColor = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
final inactiveTextColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
return InkWell(
onTap: () {
if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
if (!isActive) context.go(href); 
},
borderRadius: BorderRadius.circular(8),
child: Container(
padding: EdgeInsets.symmetric(horizontal: isSub ? 12 : 10, vertical: isSub ? 8 : 10),
decoration: const BoxDecoration(
color: Colors.transparent, 
),
child: Row(
children: [
if (isActive)
Container(
width: 3, height: isSub ? 14 : 18,
decoration: BoxDecoration(color: activeTextColor, borderRadius: BorderRadius.circular(4)), 
margin: const EdgeInsets.only(right: 12),
),
if (!isActive) const SizedBox(width: 15),
Icon(icon, size: isSub ? 14 : 18, color: isActive ? const Color(0xFF3B82F6) : inactiveTextColor),
const SizedBox(width: 12),
Expanded(
child: Text(
text,
style: GoogleFonts.jetBrainsMono(
fontSize: isSub ? 9 : 10,
fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, 
color: isActive ? activeTextColor : inactiveTextColor,
letterSpacing: 1.0, 
),
overflow: TextOverflow.ellipsis,
),
),
],
),
),
);
}
}
//===============
class _ThemeToggleButton extends StatelessWidget {
const _ThemeToggleButton();
@override
Widget build(BuildContext context) {
final themeProvider = context.watch<SwitchmodeProvider>();
final isDark = themeProvider.isDarkMode;
final bgColor = Theme.of(context).scaffoldBackgroundColor;
final borderColor = isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);
return GestureDetector(
onTap: () => themeProvider.toggleTheme(),
child: Container(
width: 56, height: 28, 
decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
child: Stack(
alignment: Alignment.center,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Icon(Icons.light_mode_outlined, size: 12, color: isDark ? const Color(0xFF3F3F46) : Colors.transparent),
Icon(Icons.dark_mode_outlined, size: 12, color: isDark ? Colors.transparent : const Color(0xFFD4D4D8)),
],
),
AnimatedAlign(
duration: const Duration(milliseconds: 300),
curve: Curves.easeOutCubic,
alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
child: Container(
margin: const EdgeInsets.symmetric(horizontal: 4),
width: 20, height: 20,
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface,
shape: BoxShape.circle,
border: Border.all(color: borderColor),
boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
),
child: Center(
child: Icon(
isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
size: 10,
color: isDark ? const Color(0xFF60A5FA) : const Color(0xFFF59E0B),
),
),
),
),
],
),
),
);
}
}
