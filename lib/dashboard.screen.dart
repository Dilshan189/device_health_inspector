import 'package:flutter/material.dart';
import 'package:device_health_inspector/utils.dart';
import 'dart:ui';

class DashboardScreen extends StatelessWidget {
  final String batteryLevel;
  final Map<String, dynamic> ramInfo;
  final Map<String, dynamic> networkInfo;
  final Animation<double> floatAnimation;
  final VoidCallback onOptimize;
  final VoidCallback onCleanJunk;
  final VoidCallback onCpuCooler;

  const DashboardScreen({
    super.key,
    required this.batteryLevel,
    required this.ramInfo,
    required this.networkInfo,
    required this.floatAnimation,
    required this.onOptimize,
    required this.onCleanJunk,
    required this.onCpuCooler,
  });

  @override
  Widget build(BuildContext context) {
    double ramUsedPct = (ramInfo['used'] ?? 0) / (ramInfo['total'] ?? 1);
    int healthScore = (100 - (ramUsedPct * 40)).toInt();
    if (healthScore > 100) healthScore = 100;
    if (healthScore < 0) healthScore = 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        children: [
          _buildHeaderSection("AeroGuard", "OPTIMIZER"),
          const SizedBox(height: 10),
          _buildAnimatedGauge(healthScore),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildSmallStatCard(
                    "Battery",
                    batteryLevel,
                    Icons.bolt_rounded,
                    const [Color(0xFFFFB75E), Color(0xFFED8F03)],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSmallStatCard(
                    "RAM Free",
                    formatBytes(ramInfo['available']),
                    Icons.memory_rounded,
                    const [Color(0xFF3DC5EB), Color(0xFF1596E7)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    "Ghost Cleaner",
                    "Purge Orphaned Data",
                    Icons.folder_delete_rounded,
                    const [Color(0xFFFF512F), Color(0xFFDD2476)],
                    onCleanJunk,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionTile(
                    "Deep Freeze",
                    "CPU Throttling",
                    Icons.ac_unit_rounded,
                    const [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                    onCpuCooler,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RepaintBoundary(child: _buildNetworkCard()),
          const SizedBox(height: 20),
          RepaintBoundary(child: _buildQuickActions(healthScore)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String title, String sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                ).createShader(bounds),
                child: Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGauge(int score) {
    bool isHealthy = score > 70;
    Color primaryColor = isHealthy
        ? const Color(0xFF00C6FF)
        : const Color(0xFFF7971E);
    Color secondaryColor = isHealthy
        ? const Color(0xFF0072FF)
        : const Color(0xFFFFD200);

    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * floatAnimation.value),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            height: 260,
            width: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 60,
                  spreadRadius: 20,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
          ),
          // Inner Circle Background
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          // Background track (so it's not colored by the shader mask)
          SizedBox(
            height: 220,
            width: 220,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 22,
              backgroundColor: Colors.transparent,
              color: Colors.grey.withOpacity(0.15),
            ),
          ),
          // Progress indicator with gradient trick
          SizedBox(
            height: 220,
            width: 220,
            child: ShaderMask(
              shaderCallback: (rect) {
                return SweepGradient(
                  startAngle: 0.0,
                  endAngle: 3.14 * 2,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [primaryColor, secondaryColor, primaryColor],
                ).createShader(rect);
              },
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 22,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ).createShader(bounds),
                child: Text(
                  "$score",
                  style: const TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: Colors.white, // Need white for mask
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "HEALTH SCORE",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String label,
    String subLabel,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1C1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    String type = networkInfo['type'] ?? "None";
    String ssid = networkInfo['ssid'] ?? "Unknown";
    int strength = networkInfo['strength'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.wifi_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Network Engine",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type == "Wi-Fi" ? ssid : type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$strength%",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF11998E),
                  ),
                ),
                const Text(
                  "SIGNAL",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black26,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(int score) {
    bool isHealthy = score > 70;
    List<Color> gradientColor = isHealthy
        ? const [Color(0xFF1E3C72), Color(0xFF2A5298)]
        : const [Color(0xFFCB2D3E), Color(0xFFEF473A)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: gradientColor[0].withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColor,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ready for Optimization?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Boost performance now",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onOptimize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: gradientColor[0],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: Text(
                      "OPTIMIZE NOW",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: gradientColor[1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
