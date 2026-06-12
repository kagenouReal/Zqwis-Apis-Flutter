import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/back/myfunc/api_item_model.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/shared_widgets.dart';

//==================
class ApiListPage extends StatefulWidget {
const ApiListPage({super.key});

@override
State<ApiListPage> createState() => _ApiListPageState();
}

//==================
class _ApiListPageState extends State<ApiListPage> {
List<ApiItemModel> _apis = [];
bool _loading = true;
String? _currentCategory;

@override
void initState() {
super.initState();
_fetchApis();
}

//==================
@override
void didChangeDependencies() {
super.didChangeDependencies();
final urlCat = GoRouterState.of(context).uri.queryParameters['cat'];
if (urlCat != null && urlCat != _currentCategory) {
final decodedCat = Uri.decodeComponent(urlCat);
WidgetsBinding.instance.addPostFrameCallback((_) {
if (mounted) setState(() => _currentCategory = decodedCat);
});
} else if (urlCat == null && _currentCategory != null) {
WidgetsBinding.instance.addPostFrameCallback((_) {
if (mounted) setState(() => _currentCategory = null);
});
}
}

//==================
Future<void> _fetchApis() async {
try {
final res = await DioClient.instance.getApiList();
if (res.statusCode == 200) {
if (mounted) {
setState(() {
_apis = (res.data as List).map((e) => ApiItemModel.fromJson(e)).toList();
_loading = false;
});
}
}
} catch (_) {
if (mounted) {
setState(() => _loading = false);
AppSnackbar.show(context, 'Gagal mengambil daftar API', isError: true);
}
}
}

//==================
Map<String, List<ApiItemModel>> get _groupedApis {
final filtered = _currentCategory != null
? _apis.where((a) {
final catName = a.category.isEmpty ? "Uncategorized" : a.category;
return catName.toLowerCase() == _currentCategory!.toLowerCase();
}).toList()
: _apis;
final map = <String, List<ApiItemModel>>{};
for (final api in filtered) {
final cat = api.category.isEmpty ? "Uncategorized" : api.category;
map.putIfAbsent(cat, () => []).add(api);
}
return map;
}

List<String> get _allCategories {
return _apis
.map((a) => a.category.isEmpty ? "Uncategorized" : a.category)
.toSet()
.toList();
}

//==================
@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final userApiKey = context.read<AuthProvider>().user?.apikey ?? "";

return RefreshIndicator(
color: AppColors.accentBlue,
backgroundColor: Theme.of(context).colorScheme.surface,
onRefresh: _fetchApis,
child: CustomScrollView(
cacheExtent: 0,
physics: const BouncingScrollPhysics(),
slivers: [
//==================
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.only(left: 12, right: 12, top: 16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.only(bottom: 16),
child: Row(
children: [
IconButton(
icon: Icon(
Icons.chevron_left_rounded, size: 28,
color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
),
onPressed: () => context.go('/home'),
padding: EdgeInsets.zero,
alignment: Alignment.centerLeft,
),
Expanded(
child: SingleChildScrollView(
scrollDirection: Axis.horizontal,
physics: const BouncingScrollPhysics(),
child: Row(
children: [
_buildCatChip("All", _currentCategory == null, () => context.go('/docsmenu'), isDark),
..._allCategories.map((c) => _buildCatChip(
c.toUpperCase(),
_currentCategory?.toLowerCase() == c.toLowerCase(),
() => context.go('/docsmenu?cat=${Uri.encodeComponent(c)}'),
isDark,
)),
_buildCatChip("WHATSAPP", false, () => context.go('/whatsapp'), isDark),
],
).animate().fade(duration: 500.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
),
),
],
),
),
            VisibilityAnimator(
              idKey: 'docs_header_card',
              child: ModuleHeader(
                title: _currentCategory != null ? _currentCategory!.toUpperCase() : "Docs",
                accentTitle: _currentCategory != null ? "API" : "Menu",
                subtitle: "Browse, configure, and test APIs directly from the dashboard.",
                isDark: isDark,
              ),
            ),
const SizedBox(height: 32),
],
),
),
),

//==================
if (_loading)
SliverToBoxAdapter(
child: const Center(
child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
).animate().fade(),
)
else if (_groupedApis.isEmpty)
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 12),
child: _buildNotFoundCard(isDark)
.animate()
.fade()
.scaleXY(begin: 0.95, end: 1.0),
),
)
else
for (var category in _groupedApis.keys) ...[
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12, top: 16),
child: VisibilityAnimator(
idKey: 'cat_title_$category',
child: _buildCategoryTitle(category, isDark),
),
),
),
SliverPadding(
padding: const EdgeInsets.symmetric(horizontal: 12),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final api = _groupedApis[category]![index];
return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: VisibilityAnimator(
idKey: 'api_card_${api.path}_$index',
child: _ApiCardInteractive(api: api, apikey: userApiKey, isDark: isDark),
),
);
},
childCount: _groupedApis[category]!.length,
),
),
),
],

//==================
const SliverToBoxAdapter(
child: Padding(
padding: EdgeInsets.only(bottom: 40, top: 16),
child: CopyrightFooter(),
),
),
],
),
);
}

//==================
Widget _buildCategoryTitle(String category, bool isDark) {
final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
return Row(
children: [
Text(
category.toUpperCase(),
style: GoogleFonts.inter(
fontSize: 14, fontWeight: FontWeight.w900,
color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
letterSpacing: 2.0,
),
),
const SizedBox(width: 16),
Expanded(
child: Container(
height: 1,
decoration: BoxDecoration(
gradient: LinearGradient(colors: [borderColor, Colors.transparent]),
),
),
),
],
);
}

//==================
Widget _buildCatChip(String label, bool selected, VoidCallback onTap, bool isDark) {
final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
return GestureDetector(
onTap: onTap,
child: AnimatedContainer(
duration: const Duration(milliseconds: 250),
curve: Curves.easeOutCubic,
margin: const EdgeInsets.only(right: 8),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: selected ? AppColors.accentBlue.withOpacity(0.15) : Theme.of(context).colorScheme.surface,
borderRadius: BorderRadius.circular(20),
border: Border.all(color: selected ? AppColors.accentBlue : borderColor),
),
child: Text(
label,
style: GoogleFonts.jetBrainsMono(
fontSize: 10,
fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
color: selected ? AppColors.accentBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
letterSpacing: 1.0,
),
),
),
);
}

//==================
Widget _buildNotFoundCard(bool isDark) {
return GlassCard(
padding: const EdgeInsets.all(24),
child: Text(
"Endpoints not found.",
style: GoogleFonts.inter(
fontSize: 12, fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
),
),
);
}
}

//==================
class _ApiCardInteractive extends StatefulWidget {
final ApiItemModel api;
final String apikey;
final bool isDark;

const _ApiCardInteractive({required this.api, required this.apikey, required this.isDark});

@override
State<_ApiCardInteractive> createState() => _ApiCardInteractiveState();
}

//==================
class _ApiCardInteractiveState extends State<_ApiCardInteractive> {
bool _isExpanded = false;
bool _loading = false;
final Map<String, String> _inputs = {};
dynamic _result;
int? _status;

String get _baseUrl => DioClient.instance.dio.options.baseUrl;
String get _exampleUrl => widget.api.example.replaceAll(
"<apikey>", widget.apikey.isEmpty ? "<apikey>" : widget.apikey);

String get _curlCmd {
final method = widget.api.method.isEmpty ? "GET" : widget.api.method;
if (widget.api.curl.isNotEmpty) {
return widget.api.curl
.replaceAll("<DOMAIN>", _baseUrl)
.replaceAll("<apikey>", widget.apikey.isEmpty ? "<apikey>" : widget.apikey);
}
return 'curl -X $method "$_baseUrl$_exampleUrl" -H "Accept: application/json"';
}


//==================
Color get _methodColor {
switch (widget.api.method.toUpperCase()) {
case "POST": return AppColors.success;
case "PUT": return AppColors.warning;
case "DELETE": return AppColors.error;
default: return AppColors.accentBlue;
}
}

//==================
Future<void> _handleTest() async {
setState(() {
_loading = true;
_result = null;
_status = null;
});
try {
final dio = Dio(BaseOptions(baseUrl: _baseUrl, validateStatus: (status) => true));
String finalPath = widget.api.path;
Map<String, dynamic> qParams = {};
dynamic bodyData;

if (widget.apikey.isNotEmpty) qParams['apikey'] = widget.apikey;
if (widget.api.method.toUpperCase() == "GET") {
qParams.addAll(_inputs);
} else {
bodyData = _inputs;
}

final res = await dio.request(
finalPath,
data: bodyData,
queryParameters: qParams,
options: Options(method: widget.api.method.isEmpty ? "GET" : widget.api.method),
);
_status = res.statusCode;
_result = res.data;
} catch (e) {
_status = 500;
_result = {"error": "Connection Failed or Server Offline"};
}
if (mounted) setState(() => _loading = false);
}

//==================
void _handleCopy(String text, String label) {
Clipboard.setData(ClipboardData(text: text));
AppSnackbar.show(context, '$label berhasil disalin ke clipboard!');
}

//==================
@override
Widget build(BuildContext context) {
final api = widget.api;
final isDark = widget.isDark;

final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
final focusBorderColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

final paramsList = api.method.toUpperCase() == "GET"
? api.query
: (api.body.isNotEmpty ? api.body : api.query);
final isFormValid = paramsList.every((q) => _inputs[q]?.trim().isNotEmpty ?? false);

return GlassCard(
padding: EdgeInsets.zero,
child: Column(
children: [
//================== Card Header
InkWell(
onTap: () => setState(() => _isExpanded = !_isExpanded),
borderRadius: BorderRadius.circular(16),
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
decoration: BoxDecoration(
color: _methodColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(999),
border: Border.all(color: _methodColor.withOpacity(0.2)),
),
child: Text(
api.method.isEmpty ? "GET" : api.method.toUpperCase(),
style: GoogleFonts.inter(
fontSize: 10, fontWeight: FontWeight.w900,
color: _methodColor, letterSpacing: 1.5,
),
),
),
const SizedBox(width: 12),
Row(
children: [
Container(
width: 6, height: 6,
decoration: const BoxDecoration(
color: AppColors.success,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
Text(
"ONLINE",
style: GoogleFonts.inter(
fontSize: 9, fontWeight: FontWeight.bold,
color: labelColor, letterSpacing: 1.5,
),
),
],
),
],
),
const SizedBox(height: 12),
Text(
api.path,
style: GoogleFonts.jetBrainsMono(
fontSize: 14, fontWeight: FontWeight.w900,
color: titleColor, letterSpacing: -0.5,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
],
),
),
AnimatedRotation(
turns: _isExpanded ? 0.5 : 0.0,
duration: const Duration(milliseconds: 300),
child: Icon(Icons.keyboard_arrow_down_rounded, color: labelColor, size: 24),
),
],
),
const SizedBox(height: 12),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 2.0),
child: Text(
api.desc,
style: GoogleFonts.inter(
fontSize: 12, fontWeight: FontWeight.w500,
color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
height: 1.5,
),
),
),
],
),
),
),

//================== Expanded Steps Playground
AnimatedCrossFade(
firstChild: const SizedBox(width: double.infinity),
secondChild: Padding(
padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 8),
child: Container(
decoration: BoxDecoration(
border: Border(left: BorderSide(color: borderColor, width: 2)),
),
padding: const EdgeInsets.only(left: 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
//— Step 1: Routing Target
_buildStepSection(
step: "1", title: "ROUTING TARGET",
isDark: isDark, borderColor: borderColor,
child: Container(
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
borderRadius: BorderRadius.circular(8),
border: Border.all(color: borderColor),
),
padding: const EdgeInsets.all(16),
child: Column(
children: [
_buildRoutingRow("URL", "$_baseUrl$_exampleUrl", () => _handleCopy("$_baseUrl$_exampleUrl", "URL"), isDark),
Padding(
padding: const EdgeInsets.symmetric(vertical: 12),
child: Divider(color: borderColor, height: 1),
),
_buildRoutingRow("cURL", _curlCmd, () => _handleCopy(_curlCmd, "cURL"), isDark),
],
),
),
),
const SizedBox(height: 32),

//— Step 2: Parameters
if (paramsList.isNotEmpty) ...[
_buildStepSection(
step: "2",
title: api.method.toUpperCase() == "GET" ? "PARAMETERS" : "BODY (JSON)",
isDark: isDark, borderColor: borderColor,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: paramsList.map((q) {
return Padding(
padding: const EdgeInsets.only(bottom: 16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
q.toUpperCase(),
style: GoogleFonts.inter(
fontSize: 10, fontWeight: FontWeight.bold,
color: labelColor, letterSpacing: 1.5,
),
),
const SizedBox(height: 8),
TextFormField(
onChanged: (val) => setState(() => _inputs[q] = val),
style: GoogleFonts.jetBrainsMono(
fontSize: 12,
color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
),
decoration: InputDecoration(
hintText: "Enter ${q.toLowerCase()}...",
hintStyle: GoogleFonts.jetBrainsMono(
color: labelColor.withOpacity(0.6), fontSize: 12,
),
filled: true,
fillColor: isDark ? Colors.transparent : AppColors.lightSurface,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: BorderSide(color: borderColor),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
),
),
),
],
),
);
}).toList(),
),
),
const SizedBox(height: 16),
],

//— Step 3 (or 2): Output Terminal
_buildStepSection(
step: paramsList.isNotEmpty ? "3" : "2",
title: "OUTPUT TERMINAL",
isDark: isDark, borderColor: borderColor,
isBlueTheme: true,
extraHeader: _status != null
? Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
decoration: BoxDecoration(
color: _status! >= 200 && _status! < 300
? AppColors.success.withOpacity(0.1)
: AppColors.error.withOpacity(0.1),
borderRadius: BorderRadius.circular(4),
border: Border.all(
color: _status! >= 200 && _status! < 300
? AppColors.success.withOpacity(0.3)
: AppColors.error.withOpacity(0.3),
),
),
child: Text(
"HTTP $_status",
style: GoogleFonts.jetBrainsMono(
fontSize: 9, fontWeight: FontWeight.bold,
color: _status! >= 200 && _status! < 300 ? AppColors.success : AppColors.error,
),
),
).animate().scale(curve: Curves.easeOutBack, duration: 300.ms)
: null,
child: Container(
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
borderRadius: BorderRadius.circular(8),
border: Border.all(color: borderColor),
),
child: Column(
children: [
//— Terminal top bar
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: isDark ? const Color(0x05FFFFFF) : const Color(0x05000000),
border: Border(bottom: BorderSide(color: borderColor)),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, shape: BoxShape.circle)),
const SizedBox(width: 6),
Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, shape: BoxShape.circle)),
const SizedBox(width: 6),
Container(width: 8, height: 8, decoration: BoxDecoration(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, shape: BoxShape.circle)),
],
),
InkWell(
onTap: (_result == null || _loading)
? null
: () => _handleCopy(const JsonEncoder.withIndent('').convert(_result), "JSON"),
child: Text(
"COPY JSON",
style: GoogleFonts.inter(
fontSize: 8, fontWeight: FontWeight.w900,
color: (_result == null || _loading) ? labelColor.withOpacity(0.5) : AppColors.accentBlue,
letterSpacing: 1.5,
),
),
),
],
),
),

//— Terminal body
Container(
width: double.infinity,
height: 200,
padding: const EdgeInsets.all(16),
child: _result == null && !_loading
? Center(
child: Text(
"~ Awaiting Response ~",
style: GoogleFonts.jetBrainsMono(
fontSize: 10, color: labelColor.withOpacity(0.5), letterSpacing: 2.0,
),
),
)
: _loading
? Center(
child: Text(
"Calling Server...",
style: GoogleFonts.jetBrainsMono(
fontSize: 10, color: labelColor, letterSpacing: 2.0,
),
).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).fade(begin: 0.3, end: 1.0),
)
: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
child: Text(
const JsonEncoder.withIndent('').convert(_result),
style: GoogleFonts.jetBrainsMono(
fontSize: 11,
color: isDark ? const Color(0xFFD4D4D8) : AppColors.lightTextSecondary,
),
).animate().fade().slideY(begin: 0.05, end: 0),
),
),

//— Send button
InkWell(
onTap: (_loading || !isFormValid) ? null : _handleTest,
child: AnimatedContainer(
duration: const Duration(milliseconds: 300),
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 14),
decoration: BoxDecoration(
color: (_loading || !isFormValid)
? (isDark ? const Color(0x04FFFFFF) : const Color(0x05000000))
: (isDark ? const Color(0x0DFFFFFF) : const Color(0x06000000)),
border: Border(top: BorderSide(color: borderColor)),
),
child: Center(
child: _loading
? SizedBox(
width: 12, height: 12,
child: CircularProgressIndicator(
strokeWidth: 1.5,
color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
),
)
: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
(!isFormValid && paramsList.isNotEmpty) ? Icons.lock_outline_rounded : Icons.send_rounded,
size: 10,
color: (_loading || !isFormValid) ? labelColor : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
),
const SizedBox(width: 8),
Text(
"SEND REQUEST",
style: GoogleFonts.inter(
fontSize: 10, fontWeight: FontWeight.w900,
color: (_loading || !isFormValid) ? labelColor : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
),
),
],
),
),
),
crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
duration: const Duration(milliseconds: 300),
),
],
),
);
}

//==================
Widget _buildStepSection({
required String step,
required String title,
required Widget child,
required bool isDark,
required Color borderColor,
bool isBlueTheme = false,
Widget? extraHeader,
}) {
final dotFill = isBlueTheme ? AppColors.accentBlue : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

return Stack(
clipBehavior: Clip.none,
children: [
Positioned(
left: -37,
top: -4,
child: Container(
width: 24, height: 24,
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface,
shape: BoxShape.circle,
border: Border.all(
color: isBlueTheme ? AppColors.accentBlue : borderColor,
width: 2,
),
boxShadow: isBlueTheme ? [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 12)] : null,
),
child: Center(
child: Container(
width: 6, height: 6,
decoration: BoxDecoration(color: dotFill, shape: BoxShape.circle),
),
),
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
"$step. $title",
style: GoogleFonts.inter(
fontSize: 10, fontWeight: FontWeight.w900,
color: labelColor, letterSpacing: 2.0,
),
),
if (extraHeader != null) extraHeader,
],
),
const SizedBox(height: 16),
child,
],
),
],
);
}

//==================
Widget _buildRoutingRow(String label, String value, VoidCallback onCopy, bool isDark) {
final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
final valueColor = isDark ? const Color(0xFFD4D4D8) : AppColors.lightTextSecondary;

return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(
width: 48,
child: Text(
label,
style: GoogleFonts.inter(
fontSize: 9, fontWeight: FontWeight.bold,
color: labelColor, letterSpacing: 2.0,
),
),
),
Expanded(
child: Text(
value,
style: GoogleFonts.jetBrainsMono(fontSize: 10, color: valueColor),
),
),
InkWell(
onTap: onCopy,
child: Icon(Icons.copy_rounded, size: 14, color: labelColor),
),
],
);
}
}
