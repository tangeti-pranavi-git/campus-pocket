import 'dart:math' as math;
import 'package:flutter/material.dart';

class AiParticleBackground extends StatefulWidget {
  final Widget child;
  const AiParticleBackground({super.key, required this.child});

  @override
  State<AiParticleBackground> createState() => _AiParticleBackgroundState();
}

class _AiParticleBackgroundState extends State<AiParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0B0A), Color(0xFF1A1412), Color(0xFF0F0B0A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(particles, _controller.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 2 + 1;
  double speed = math.Random().nextDouble() * 0.02 + 0.01;
  double opacity = math.Random().nextDouble() * 0.5 + 0.1;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      double curY = (particle.y - animationValue * particle.speed) % 1.0;
      double curX = particle.x;

      paint.color = const Color(0xFFFF8A00).withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(curX * size.width, curY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
