import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});
@override
State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen>
with TickerProviderStateMixin {
late final AnimationController _masterCtrl;
late final AnimationController _orbitCtrl; 
late final AnimationController _pulseCtrl; 
late final AnimationController _exitCtrl;
late final Animation<double> _logoScale;
late final Animation<double> _logoOpacity;
late final Animation<double> _logoRotate;
late final Animation<double> _gridOpacity;
late final Animation<double> _ring1Scale;
late final Animation<double> _ring1Opacity;
late final Animation<double> _ring2Scale;
late final Animation<double> _ring2Opacity;
late final Animation<double> _ring3Scale;
late final Animation<double> _ring3Opacity;
late final Animation<double> _dotsOpacity;
late final Animation<double> _taglineOpacity;
late final Animation<Offset> _taglineSlide;
late final Animation<double> _welcomeOpacity;
late final Animation<Offset> _welcomeSlide;
late final Animation<double> _brandOpacity;
late final Animation<Offset> _brandSlide;
late final Animation<double> _barProgress;
late final Animation<double> _barOpacity;
late final Animation<double> _particlesOpacity;
late final Animation<double> _exitOpacity;
bool _navigated = false;
final List<_ParticleData> _particles = [];
@override
void initState() {
super.initState();
_generateParticles();
_setupAnimations();
_startSequence();
}
void _generateParticles() {
final rng = math.Random(42);
for (int i = 0; i < 28; i++) {
_particles.add(_ParticleData(
x: rng.nextDouble(),
y: rng.nextDouble(),
size: rng.nextDouble() * 2.5 + 1,
opacity: rng.nextDouble() * 0.5 + 0.15,
delay: rng.nextDouble() * 1.2,
));
}
}
void _setupAnimations() {
_masterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
_orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
_pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
_exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
final c = _masterCtrl;
_gridOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)));
_logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: c, curve: const Interval(0.1, 0.45, curve: Curves.elasticOut)));
_logoOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.1, 0.25, curve: Curves.easeOut)));
_logoRotate = Tween<double>(begin: -0.3, end: 0).animate(CurvedAnimation(parent: c, curve: const Interval(0.1, 0.45, curve: Curves.easeOutCubic)));
_ring1Scale = Tween<double>(begin: 0.3, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack)));
_ring1Opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.2, 0.38, curve: Curves.easeOut)));
_ring2Scale = Tween<double>(begin: 0.2, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.28, 0.58, curve: Curves.easeOutBack)));
_ring2Opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.28, 0.44, curve: Curves.easeOut)));
_ring3Scale = Tween<double>(begin: 0.1, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.36, 0.66, curve: Curves.easeOutCubic)));
_ring3Opacity = Tween<double>(begin: 0, end: 0.35).animate(CurvedAnimation(parent: c, curve: const Interval(0.36, 0.5, curve: Curves.easeOut)));
_dotsOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.4, 0.58, curve: Curves.easeOut)));
_welcomeOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.45, 0.62, curve: Curves.easeOut)));
_welcomeSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: const Interval(0.45, 0.65, curve: Curves.easeOutCubic)));
_taglineOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.55, 0.72, curve: Curves.easeOut)));
_taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: const Interval(0.55, 0.75, curve: Curves.easeOutCubic)));
_brandOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.65, 0.80, curve: Curves.easeOut)));
_brandSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: const Interval(0.65, 0.82, curve: Curves.easeOutCubic)));
_barOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.65, 0.75, curve: Curves.easeOut)));
_barProgress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.70, 0.98, curve: Curves.easeInOut)));
_particlesOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: const Interval(0.25, 0.50, curve: Curves.easeOut)));
_exitOpacity = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));
}
Future<void> _startSequence() async {
await Future.delayed(const Duration(milliseconds: 60));
await _masterCtrl.forward();
await Future.delayed(const Duration(milliseconds: 320));
await _exitCtrl.forward();
if (mounted && !_navigated) {
_navigated = true;
context.go('/');
}
}
@override
void dispose() {
_masterCtrl.dispose();
_orbitCtrl.dispose();
_pulseCtrl.dispose();
_exitCtrl.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
final size = MediaQuery.of(context).size;
final isDark = Theme.of(context).brightness == Brightness.dark;
return Scaffold(
backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
body: AnimatedBuilder(
animation: Listenable.merge([_masterCtrl, _orbitCtrl, _pulseCtrl, _exitCtrl]),
builder: (context, _) {
return Opacity(
opacity: _exitOpacity.value,
child: Stack(
children: [
Opacity(
opacity: _gridOpacity.value * 0.6,
child: _GridBackground(size: size, isDark: isDark), 
),
Positioned(
top: -size.height * 0.15,
left: -size.width * 0.3,
child: _GlowOrb(
size: size.width * 1.2,
color: const Color(0xFF3B82F6),
opacity: 0.055 + _pulseCtrl.value * 0.02,
),
),
Positioned(
bottom: -size.height * 0.15,
right: -size.width * 0.3,
child: _GlowOrb(
size: size.width * 1.1,
color: const Color(0xFF06B6D4),
opacity: 0.045 + (1 - _pulseCtrl.value) * 0.02,
),
),
Opacity(
opacity: _particlesOpacity.value,
child: _ParticleField(particles: _particles, size: size),
),
Center(
child: SizedBox(
width: 260,
height: 260,
child: Stack(
alignment: Alignment.center,
children: [
Transform.scale(
scale: _ring3Scale.value,
child: Opacity(
opacity: _ring3Opacity.value,
child: const _DashedRing(diameter: 244, color: Color(0xFF8A8A9A), dashWidth: 3, gapWidth: 12, strokeWidth: 0.5),
),
),
Transform.scale(
scale: _ring2Scale.value,
child: Opacity(
opacity: _ring2Opacity.value,
child: Transform.rotate(
angle: -_orbitCtrl.value * math.pi * 2 * 0.35,
child: const _DashedRing(diameter: 194, color: Color(0xFF3B82F6), dashWidth: 4, gapWidth: 18, strokeWidth: 0.8),
),
),
),
Transform.scale(
scale: _ring1Scale.value,
child: Opacity(
opacity: _ring1Opacity.value,
child: Transform.rotate(
angle: _orbitCtrl.value * math.pi * 2,
child: const _DashedRing(diameter: 144, color: Color(0xFF3B82F6), dashWidth: 6, gapWidth: 14, strokeWidth: 1.2),
),
),
),
Opacity(
opacity: _dotsOpacity.value,
child: _OrbitDot(progress: _orbitCtrl.value, radius: 72, dotSize: 7, color: const Color(0xFF3B82F6), shadowColor: const Color(0xFF3B82F6), startAngle: 0),
),
Opacity(
opacity: _dotsOpacity.value,
child: _OrbitDot(progress: _orbitCtrl.value, radius: 57, dotSize: 5, color: const Color(0xFF10B981), shadowColor: const Color(0xFF10B981), startAngle: math.pi * 0.75, speed: 1.6),
),
Opacity(
opacity: _dotsOpacity.value,
child: _OrbitDot(progress: _orbitCtrl.value, radius: 97, dotSize: 4, color: const Color(0xFF06B6D4), shadowColor: const Color(0xFF06B6D4), startAngle: math.pi * 1.4, speed: 0.7),
),
Opacity(
opacity: _dotsOpacity.value * 0.7,
child: _OrbitDot(progress: _orbitCtrl.value, radius: 88, dotSize: 3, color: const Color(0xFF8B5CF6), shadowColor: const Color(0xFF8B5CF6), startAngle: math.pi * 0.3, speed: -0.5),
),
Transform.scale(
scale: _logoScale.value,
child: Transform.rotate(
angle: _logoRotate.value,
child: Opacity(
opacity: _logoOpacity.value,
child: _LogoCard(pulseValue: _pulseCtrl.value), 
),
),
),
],
),
),
),
Positioned(
top: size.height * 0.5 - 178,
left: 0, right: 0,
child: FadeTransition(
opacity: _welcomeOpacity,
child: SlideTransition(
position: _welcomeSlide,
child: Center(
child: Text(
'WELCOME',
style: GoogleFonts.inter(
fontSize: 11,
fontWeight: FontWeight.w900,
letterSpacing: 6.0,
color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A), 
),
),
),
),
),
),
Positioned(
top: size.height * 0.5 + 150,
left: 0, right: 0,
child: FadeTransition(
opacity: _taglineOpacity,
child: SlideTransition(
position: _taglineSlide,
child: Column(
children: [
RichText(
text: TextSpan(
children: [
TextSpan(
text: 'Zqwis',
style: GoogleFonts.inter(
fontSize: 32,
fontWeight: FontWeight.w900,
color: Theme.of(context).colorScheme.onSurface,
letterSpacing: -1.0,
),
),
TextSpan(
text: ' APIS',
style: GoogleFonts.inter(
fontSize: 32,
fontWeight: FontWeight.w900,
letterSpacing: -1.0,
foreground: Paint()
..shader = const LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
).createShader(const Rect.fromLTWH(0, 0, 160, 40)),
),
),
],
),
),
const SizedBox(height: 8),
Text(
'Production-grade API Infrastructure. All In One',
style: GoogleFonts.inter(
fontSize: 12,
fontWeight: FontWeight.w500,
color: const Color(0xFF71717A),
letterSpacing: 0.2,
),
),
],
),
),
),
),
Positioned(
bottom: 72,
left: 48, right: 48,
child: FadeTransition(
opacity: _barOpacity,
child: Column(
children: [
ClipRRect(
borderRadius: BorderRadius.circular(99),
child: Container(
height: 2,
color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
child: FractionallySizedBox(
alignment: Alignment.centerLeft,
widthFactor: _barProgress.value,
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(99),
gradient: const LinearGradient(
colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
),
boxShadow: [
BoxShadow(
color: const Color(0xFF3B82F6).withOpacity(0.6),
blurRadius: 8,
),
],
),
),
),
),
),
const SizedBox(height: 14),
Text(
_barProgress.value < 0.4 ? 'Initializing...' : _barProgress.value < 0.75 ? 'Loading modules...' : 'Ready.',
style: GoogleFonts.jetBrainsMono(
fontSize: 10,
fontWeight: FontWeight.w600,
color: const Color(0xFF52525B),
letterSpacing: 1.2,
),
),
],
),
),
),
Positioned(
bottom: 28,
left: 0, right: 0,
child: FadeTransition(
opacity: _brandOpacity,
child: SlideTransition(
position: _brandSlide,
child: Center(
child: Text(
'© 2026 KAGENOU·ZQWIS APIS',
style: GoogleFonts.inter(
fontSize: 9,
fontWeight: FontWeight.w900,
letterSpacing: 3.0,
color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFA1A1AA),
),
),
),
),
),
),
],
),
);
},
),
);
}
}
class _GridBackground extends StatelessWidget {
final Size size;
final bool isDark; 
const _GridBackground({required this.size, required this.isDark});
@override
Widget build(BuildContext context) {
return CustomPaint(
size: size,
painter: _GridPainter(isDark: isDark),
);
}
}
class _GridPainter extends CustomPainter {
final bool isDark; 
_GridPainter({required this.isDark});
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = isDark ? const Color(0xFF8A8A9A).withOpacity(0.08) : const Color(0xFF000000).withOpacity(0.05)
..strokeWidth = 0.5;
const cols = 10;
const rows = 18;
for (int i = 1; i < cols; i++) {
final x = size.width / cols * i;
canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
}
for (int i = 1; i < rows; i++) {
final y = size.height / rows * i;
canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
}
}
@override
bool shouldRepaint(covariant CustomPainter old) => false;
}
class _GlowOrb extends StatelessWidget {
final double size;
final Color color;
final double opacity;
const _GlowOrb({required this.size, required this.color, required this.opacity});
@override
Widget build(BuildContext context) {
return Container(
width: size,
height: size,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: RadialGradient(
colors: [color.withOpacity(opacity), Colors.transparent],
),
),
);
}
}
class _ParticleField extends StatelessWidget {
final List<_ParticleData> particles;
final Size size;
const _ParticleField({required this.particles, required this.size});
static const _colors = [Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF8B5CF6), Color(0xFFF59E0B)];
@override
Widget build(BuildContext context) {
return Stack(
children: particles.asMap().entries.map((e) {
final p = e.value;
final color = _colors[e.key % _colors.length];
return Positioned(
left: p.x * size.width,
top: p.y * size.height,
child: Container(
width: p.size,
height: p.size,
decoration: BoxDecoration(
color: color.withOpacity(p.opacity),
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: color.withOpacity(p.opacity * 0.6),
blurRadius: p.size * 3,
),
],
),
),
);
}).toList(),
);
}
}
class _DashedRing extends StatelessWidget {
final double diameter;
final Color color;
final double dashWidth;
final double gapWidth;
final double strokeWidth;
const _DashedRing({required this.diameter, required this.color, required this.dashWidth, required this.gapWidth, required this.strokeWidth});
@override
Widget build(BuildContext context) {
return SizedBox(
width: diameter,
height: diameter,
child: CustomPaint(
painter: _DashedRingPainter(color: color, dashWidth: dashWidth, gapWidth: gapWidth, strokeWidth: strokeWidth),
),
);
}
}
class _DashedRingPainter extends CustomPainter {
final Color color;
final double dashWidth;
final double gapWidth;
final double strokeWidth;
const _DashedRingPainter({required this.color, required this.dashWidth, required this.gapWidth, required this.strokeWidth});
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = color
..strokeWidth = strokeWidth
..style = PaintingStyle.stroke;
final center = Offset(size.width / 2, size.height / 2);
final radius = size.width / 2;
final circumference = 2 * math.pi * radius;
final totalDash = dashWidth + gapWidth;
final dashCount = (circumference / totalDash).floor();
final dashAngle = (dashWidth / circumference) * 2 * math.pi;
final gapAngle = (gapWidth / circumference) * 2 * math.pi;
double angle = -math.pi / 2;
for (int i = 0; i < dashCount; i++) {
canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, dashAngle, false, paint);
angle += dashAngle + gapAngle;
}
}
@override
bool shouldRepaint(covariant CustomPainter old) => false;
}
class _OrbitDot extends StatelessWidget {
final double progress;
final double radius;
final double dotSize;
final Color color;
final Color shadowColor;
final double startAngle;
final double speed;
const _OrbitDot({required this.progress, required this.radius, required this.dotSize, required this.color, required this.shadowColor, this.startAngle = 0, this.speed = 1.0});
@override
Widget build(BuildContext context) {
final angle = startAngle + progress * math.pi * 2 * speed;
final dx = math.cos(angle) * radius;
final dy = math.sin(angle) * radius;
return Transform.translate(
offset: Offset(dx, dy),
child: Container(
width: dotSize,
height: dotSize,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
boxShadow: [
BoxShadow(color: shadowColor.withOpacity(0.8), blurRadius: dotSize * 2.5, spreadRadius: dotSize * 0.3),
],
),
),
);
}
}
class _LogoCard extends StatelessWidget {
final double pulseValue;
const _LogoCard({required this.pulseValue});
@override
Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark; 
return Container(
width: 72,
height: 72,
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.surface,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: Color.lerp(
isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000), 
isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
pulseValue,
)!,
width: 1,
),
boxShadow: [
BoxShadow(
color: const Color(0xFF3B82F6).withOpacity(0.15 + pulseValue * 0.12),
blurRadius: 28 + pulseValue * 12,
spreadRadius: 2,
),
BoxShadow(
color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), 
blurRadius: 16,
),
],
),
child: Center(
child: _ApiLogoMark(pulseValue: pulseValue),
),
);
}
}
class _ApiLogoMark extends StatelessWidget {
final double pulseValue;
const _ApiLogoMark({required this.pulseValue});
@override
Widget build(BuildContext context) {
final bright = Color.lerp(const Color(0xFF3B82F6), const Color(0xFF60A5FA), pulseValue)!;
return Column(
mainAxisSize: MainAxisSize.min,
children: [
Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 9, height: 9, decoration: BoxDecoration(color: bright, borderRadius: BorderRadius.circular(3))),
const SizedBox(width: 4),
Container(width: 16, height: 9, decoration: BoxDecoration(color: bright.withOpacity(0.35), borderRadius: BorderRadius.circular(3))),
],
),
const SizedBox(height: 4),
Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 16, height: 9, decoration: BoxDecoration(color: bright.withOpacity(0.35), borderRadius: BorderRadius.circular(3))),
const SizedBox(width: 4),
Container(width: 9, height: 9, decoration: BoxDecoration(color: bright, borderRadius: BorderRadius.circular(3))),
],
),
const SizedBox(height: 4),
Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(width: 9, height: 9, decoration: BoxDecoration(color: bright.withOpacity(0.2), borderRadius: BorderRadius.circular(3))),
const SizedBox(width: 4),
Container(width: 9, height: 9, decoration: BoxDecoration(color: bright.withOpacity(0.2), borderRadius: BorderRadius.circular(3))),
],
),
],
);
}
}
class _ParticleData {
final double x, y, size, opacity, delay;
const _ParticleData({required this.x, required this.y, required this.size, required this.opacity, required this.delay});
}
