import 'package:eco_collect/models/geocampus_campus_zone.dart';
import 'package:flutter/material.dart';

/// Shared bird's-eye campus map: zone nodes sized by health, optional taps.
class CampusMapOverview extends StatelessWidget {
  const CampusMapOverview({
    super.key,
    required this.zoneHealth,
    this.height = 200,
    this.onZoneTap,
  });

  final Map<String, int> zoneHealth;
  final double height;
  final void Function(String zoneId)? onZoneTap;

  static const List<({double x, double y, String id})> _layout = [
    (x: 0.50, y: 0.22, id: 'quad'),
    (x: 0.20, y: 0.42, id: 'eng'),
    (x: 0.80, y: 0.40, id: 'sci'),
    (x: 0.32, y: 0.70, id: 'lib'),
    (x: 0.62, y: 0.66, id: 'dorms'),
    (x: 0.86, y: 0.78, id: 'sports'),
  ];

  Color _nodeColor(int health, Color accent) {
    final t = (health / 100.0).clamp(0.0, 1.0);
    return Color.lerp(Colors.orange.shade800, accent, t) ?? accent;
  }

  @override
  Widget build(BuildContext context) {
    final zones = GeocampusCampusZone.campusDefaults;
    final byId = {for (final z in zones) z.id: z};

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = height;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  size: Size(w, h),
                  painter: _CampusPathsPainter(
                    points: _layout
                        .map((e) => Offset(e.x * w, e.y * h))
                        .toList(),
                  ),
                ),
                ..._layout.map((node) {
                  final z = byId[node.id];
                  if (z == null) return const SizedBox.shrink();
                  final health = zoneHealth[z.id] ?? z.baseHealth;
                  final cx = node.x * w - 26;
                  final cy = node.y * h - 26;
                  return Positioned(
                    left: cx,
                    top: cy,
                    child: GestureDetector(
                      onTap:
                          onZoneTap == null ? null : () => onZoneTap!(z.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _nodeColor(health, z.accent),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: z.accent.withOpacity(0.45),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$health%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 72,
                            child: Text(
                              z.name.split(' ').first,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampusPathsPainter extends CustomPainter {
  _CampusPathsPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0D2818),
          const Color(0xFF1B4332),
          const Color(0xFF081C15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      bg,
    );

    if (points.length < 2) return;
    final line = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);

    final grid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _CampusPathsPainter oldDelegate) =>
      oldDelegate.points != points;
}
