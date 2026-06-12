// Path: lib/features/auth/login_page.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'package:zqwis/main/helper/app_theme.dart';

//===============
class _ZqwisAnimatedHeader extends StatefulWidget {
  const _ZqwisAnimatedHeader();

  @override
  State<_ZqwisAnimatedHeader> createState() => _ZqwisAnimatedHeaderState();
}

//===============
class _ZqwisAnimatedHeaderState extends State<_ZqwisAnimatedHeader>
    with TickerProviderStateMixin {
  late final AnimationController _orbitCtrl;
  late final AnimationController _orbitRevCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _morphCtrl;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
    _orbitRevCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 8000))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _morphCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat(reverse: true);

    final rng = math.Random(7);
    final colors = [
      AppColors.brandBlue,
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
      AppColors.accentPurple,
      const Color(0xFFF59E0B),
    ];
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1.5,
        speed: rng.nextDouble() * 0.4 + 0.2,
        phase: rng.nextDouble() * math.pi * 2,
        color: colors[i % colors.length],
      ));
    }
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _orbitRevCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _morphCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _orbitCtrl, _orbitRevCtrl, _pulseCtrl,
        _floatCtrl, _shimmerCtrl, _morphCtrl,
      ]),
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        final orbit = _orbitCtrl.value;
        final orbitRev = _orbitRevCtrl.value;
        final morph = Curves.easeInOut.transform(_morphCtrl.value);
        final shimmer = _shimmerCtrl.value;

        return SizedBox(
          height: 196,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── 1. Floating particles ────────────────────────────────
              ...List.generate(_particles.length, (i) {
                final p = _particles[i];
                final floatY = math.sin(_floatCtrl.value * math.pi * 2 * p.speed + p.phase) * 9;
                final cx = (p.x - 0.5) * 260;
                final cy = (p.y - 0.5) * 130 + floatY;
                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 + cx - p.size / 2,
                  top: 80 + cy - p.size / 2,
                  child: Container(
                    width: p.size, height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color.withOpacity(0.55),
                      boxShadow: [BoxShadow(color: p.color.withOpacity(0.4), blurRadius: p.size * 3)],
                    ),
                  ),
                );
              }),

              // ── 2. Outer dashed ring (counter-rotate) ────────────────
              Transform.rotate(
                angle: -orbitRev * math.pi * 2,
                child: CustomPaint(
                  size: const Size(174, 174),
                  painter: _DashedRingPainter(
                    color: AppColors.brandBlue.withOpacity(0.20 + pulse * 0.10),
                    dashCount: 24, strokeWidth: 0.8, dashFraction: 0.45,
                  ),
                ),
              ),

              // ── 3. Mid dashed ring (forward) ─────────────────────────
              Transform.rotate(
                angle: orbit * math.pi * 2,
                child: CustomPaint(
                  size: const Size(130, 130),
                  painter: _DashedRingPainter(
                    color: AppColors.brandBlue.withOpacity(0.32 + pulse * 0.12),
                    dashCount: 16, strokeWidth: 1.0, dashFraction: 0.5,
                  ),
                ),
              ),

              // ── 4. Orbit dots ─────────────────────────────────────────
              _OrbitDot(progress: orbit, radius: 87, size: 7, color: AppColors.brandBlue),
              _OrbitDot(progress: orbit, radius: 65, size: 5.5, color: const Color(0xFF10B981), startAngle: math.pi * 0.65, speed: 1.45),
              _OrbitDot(progress: orbit, radius: 87, size: 4, color: const Color(0xFF06B6D4), startAngle: math.pi * 1.3, speed: 0.72),
              _OrbitDot(progress: orbit, radius: 61, size: 3.5, color: AppColors.accentPurple, startAngle: math.pi * 1.8, speed: -0.55),

              // ── 5. Morph blob behind card ─────────────────────────────
              CustomPaint(
                size: const Size(80, 80),
                painter: _MorphBlobPainter(
                  progress: morph,
                  color: AppColors.brandBlue.withOpacity(0.10 + pulse * 0.06),
                ),
              ),

              // ── 6. Center glow ────────────────────────────────────────
              Container(
                width: 52 + pulse * 6, height: 52 + pulse * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.brandBlue.withOpacity(0.18 + pulse * 0.10),
                    Colors.transparent,
                  ]),
                ),
              ),

              // ── 7. Center card (Microchip Z Logo) ─────────────────────
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Color.lerp(const Color(0x1AFFFFFF), const Color(0x40FFFFFF), pulse)!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withOpacity(0.18 + pulse * 0.14),
                      blurRadius: 24 + pulse * 10, spreadRadius: 1,
                    ),
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.45 : 0.08), blurRadius: 12),
                  ],
                ),
                child: Center(child: _ZLogoMark(pulse: pulse)),
              ),

              // ── 8. Shimmer brand text (RENAME & KECILIN) ──────────────
              Positioned(
                bottom: 0,
                child: _ShimmerBrand(progress: shimmer, isDark: isDark),
              ),
            ],
          ),
        );
      },
    );
  }
}

//===============
class _GridBackgroundPainter extends CustomPainter {
  final bool isDark;
  _GridBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.01)
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
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) => false;
}

//===============
class _ZLogoMark extends StatelessWidget {
  final double pulse;
  const _ZLogoMark({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.brandBlue, const Color(0xFF60A5FA), pulse)!;
    return Text(
      'Z',
      style: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -1,
      ),
    );
  }
}

//===============
class _ShimmerBrand extends StatelessWidget {
  final double progress;
  final bool isDark;
  const _ShimmerBrand({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final offset = progress * 3 - 1;

    return Transform.translate(
      offset: const Offset(0, 16),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(offset - 1, 0),
          end: Alignment(offset, 0),
          colors: [
            isDark ? const Color(0xFF52525B) : const Color(0xFFD4D4D8),
            Colors.white,
            AppColors.brandBlue,
            isDark ? const Color(0xFF52525B) : const Color(0xFFD4D4D8),
          ],
          stops: const [0.0, 0.3, 0.55, 1.0],
        ).createShader(bounds),
        child: Text(
          'ZQWIS -> ALL IN ONE', 
          style: GoogleFonts.inter(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 2.0, 
            color: Colors.white
          ),
        ),
      ),
    );
  }
}

//===============
class _OrbitDot extends StatelessWidget {
  final double progress, radius, size, startAngle, speed;
  final Color color;
  const _OrbitDot({required this.progress, required this.radius, required this.size, required this.color, this.startAngle = 0, this.speed = 1.0});
  @override
  Widget build(BuildContext context) {
    final angle = startAngle + progress * math.pi * 2 * speed;
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: size * 3, spreadRadius: size * 0.2)],
        ),
      ),
    );
  }
}

//===============
class _DashedRingPainter extends CustomPainter {
  final Color color; final int dashCount; final double strokeWidth, dashFraction;
  const _DashedRingPainter({required this.color, required this.dashCount, required this.strokeWidth, required this.dashFraction});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2;
    final step = (math.pi * 2) / dashCount; final dashLen = step * dashFraction;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * step - math.pi / 2, dashLen, false, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.color != color;
}

//===============
class _MorphBlobPainter extends CustomPainter {
  final double progress; final Color color;
  const _MorphBlobPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    final path = Path(); const n = 8;
    for (int i = 0; i <= n; i++) {
      final a = (i / n) * math.pi * 2 - math.pi / 2;
      final wave = math.sin(a * 3 + progress * math.pi * 2) * 0.18;
      final rad = r * (1 + wave);
      final x = cx + math.cos(a) * rad; final y = cy + math.sin(a) * rad;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close(); canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _MorphBlobPainter old) => old.progress != progress || old.color != color;
}

//===============
class _Particle {
  final double x, y, size, speed, phase; final Color color;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.phase, required this.color});
}

//===============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

//===============
class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isLogin = true;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _retypePasswordCtrl = TextEditingController();
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _retypePasswordCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _usernameCtrl.clear();
      _passwordCtrl.clear();
      _retypePasswordCtrl.clear();
    });
  }

  Future<void> _handleAuth() async {
    setState(() => _error = null);
    final userText = _usernameCtrl.text.trim();
    final passText = _passwordCtrl.text.trim();
    if (userText.isEmpty || passText.isEmpty) {
      setState(() => _error = 'PLEASE FILL IN ALL FIELDS.');
      return;
    }

    final auth = context.read<AuthProvider>();

    if (_isLogin) {
      final ok = await auth.login(userText, passText);
      if (ok && mounted) {
        context.go('/home');
      } else {
        setState(() => _error = auth.errorMessage ?? 'INVALID USERNAME OR PASSWORD.');
      }
    } else {
      final retypeText = _retypePasswordCtrl.text.trim();
      if (retypeText.isEmpty) {
        setState(() => _error = 'PLEASE RETYPE YOUR PASSWORD.');
        return;
      }
      if (passText != retypeText) {
        setState(() => _error = 'PASSWORDS DO NOT MATCH.');
        return;
      }

      final ok = await auth.register(userText, passText);
      if (ok && mounted) {
        setState(() => _error = 'ACCOUNT CREATED. PLEASE SIGN IN.');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _isLogin = true;
            _retypePasswordCtrl.clear();
          });
        }
      } else {
        setState(() => _error = auth.errorMessage ?? 'REGISTRATION FAILED.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final borderColor = isDark ? AppColors.darkCardBorderSubtle : AppColors.lightCardBorderSubtle;
    final focusBorderColor = isDark ? const Color(0xFF52525B) : const Color(0xFFD4D4D8);
    final zinc500 = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final zinc800 = isDark ? AppColors.darkSurface : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -100, left: -100,
            child: Container(width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.brandBlue.withOpacity(isDark ? 0.05 : 0.08))),
          ),
          Positioned(
            bottom: -100, right: -100,
            child: Container(width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF06B6D4).withOpacity(isDark ? 0.05 : 0.08))),
          ),
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: const SizedBox()),
          ),

          // Main
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(offset: Offset(0, 30 * (1 - _fadeAnim.value)), child: child),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(isDark ? 0.8 : 0.95),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: borderColor),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  // ── ANIMATED HEADER ──────────────────────
                                  const _ZqwisAnimatedHeader(),
                                  const SizedBox(height: 24),

                                  // ── Title ────────────────────────────────
                                  Text(
                                    _isLogin ? 'Welcome Back' : 'Create Account',
                                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLogin ? 'SIGN IN TO YOUR ACCOUNT' : 'REGISTER TO GET STARTED',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: zinc500, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(height: 32),

                                  // ── Username ─────────────────────────────
                                  _buildLabel('USERNAME', zinc500),
                                  const SizedBox(height: 6),
                                  _buildField(controller: _usernameCtrl, hint: 'Enter username', obscure: false, borderColor: borderColor, focusColor: focusBorderColor, cardColor: cardColor, textColor: textColor),
                                  const SizedBox(height: 16),

                                  // ── Password ─────────────────────────────
                                  _buildLabel('PASSWORD', zinc500),
                                  const SizedBox(height: 6),
                                  _buildField(controller: _passwordCtrl, hint: _isLogin ? '••••••••' : 'Enter password', obscure: _isLogin, borderColor: borderColor, focusColor: focusBorderColor, cardColor: cardColor, textColor: textColor),

                                  // ── Retype ───────────────────────────────
                                  if (!_isLogin) ...[
                                    const SizedBox(height: 16),
                                    _buildLabel('RETYPE PASSWORD', zinc500),
                                    const SizedBox(height: 6),
                                    _buildField(controller: _retypePasswordCtrl, hint: 'Retype password', obscure: true, borderColor: borderColor, focusColor: focusBorderColor, cardColor: cardColor, textColor: textColor),
                                  ],

                                  // ── Error ────────────────────────────────
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: _error!.contains('created') ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF43F5E).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _error!.contains('created') ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFF43F5E).withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        _error!.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                                            color: _error!.contains('created') ? const Color(0xFF34D399) : const Color(0xFFFB7185)),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // ── Submit ───────────────────────────────
                                  SizedBox(
                                    width: double.infinity, height: 48,
                                    child: OutlinedButton(
                                      onPressed: auth.isLoading ? null : _handleAuth,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: cardColor,
                                        side: BorderSide(color: borderColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        foregroundColor: textColor,
                                      ).copyWith(
                                        overlayColor: WidgetStateProperty.resolveWith((s) {
                                          if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) {
                                            return isDark ? zinc800 : const Color(0xFFF4F4F5);
                                          }
                                          return null;
                                        }),
                                      ),
                                      child: auth.isLoading
                                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                                          : Text(
                                        _isLogin ? 'SIGN IN TO DASHBOARD' : 'CREATE FREE ACCOUNT',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: textColor),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                  Divider(color: borderColor, height: 1),
                                  const SizedBox(height: 24),

                                  // ── Toggle ───────────────────────────────
                                  GestureDetector(
                                    onTap: _switchMode,
                                    child: Text(
                                      _isLogin ? "DON'T HAVE AN ACCOUNT? SIGN UP" : 'ALREADY HAVE AN ACCOUNT? SIGN IN',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: zinc500, letterSpacing: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Opacity(
                        opacity: 0.4,
                        child: Text('© 2026 KAGENOU|ZQWIS APIS',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: zinc500, letterSpacing: 4.0)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //===============
  Widget _buildLabel(String text, Color color) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.5)),
    ),
  );

  //===============
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required Color borderColor,
    required Color focusColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2), blurStyle: BlurStyle.inner)],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.jetBrainsMono(fontSize: 14, color: textColor, letterSpacing: obscure ? 4.0 : 0.0),
        cursorColor: textColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.jetBrainsMono(color: textColor.withOpacity(0.3), letterSpacing: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: focusColor)),
          filled: true, fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
