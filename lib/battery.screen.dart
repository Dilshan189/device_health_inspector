import 'dart:convert';
import 'package:flutter/material.dart';

class BatteryScreen extends StatelessWidget {
  final String batteryLevel;
  final Map<String, dynamic> batteryHealth;
  final List<dynamic> batteryHungryApps;
  final bool hasUsagePermission;
  final VoidCallback onOpenUsageSettings;
  final VoidCallback onRefresh;

  const BatteryScreen({
    super.key,
    required this.batteryLevel,
    required this.batteryHealth,
    required this.batteryHungryApps,
    required this.hasUsagePermission,
    required this.onOpenUsageSettings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          children: [
            _buildHeaderSection("Power", "CORE"),
            const SizedBox(height: 10),
            _buildBatteryVisual(),
            const SizedBox(height: 30),
            _buildBatteryStats(),
            const SizedBox(height: 32),
            _buildHungryAppsSection(),
            const SizedBox(height: 100),
          ],
        ),
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
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
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
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0072FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6FF).withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        // Inner circle
        Container(
          height: 180,
          width: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF0072FF).withOpacity(0.1),
              width: 8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              ).createShader(bounds),
              child: Text(
                batteryLevel,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0072FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                batteryHealth['health']?.toUpperCase() ?? "HEALTHY",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0072FF),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatteryStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildStatRow(
              "Status",
              batteryHealth['status'] ?? "Discharging",
              Icons.power_rounded,
              const [Color(0xFF00C6FF), Color(0xFF0072FF)],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: Colors.grey.withOpacity(0.1),
                thickness: 1.5,
              ),
            ),
            _buildStatRow(
              "Temperature",
              batteryHealth['temp'] ?? "32°C",
              Icons.thermostat_rounded,
              const [Color(0xFFFF512F), Color(0xFFDD2476)],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: Colors.grey.withOpacity(0.1),
                thickness: 1.5,
              ),
            ),
            _buildStatRow(
              "Voltage",
              batteryHealth['voltage'] ?? "4.0V",
              Icons.flash_on_rounded,
              const [Color(0xFFF2C94C), Color(0xFFF2994A)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: gradient[0], size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildHungryAppsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Usage Analysis",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const Spacer(),
              if (!hasUsagePermission)
                TextButton.icon(
                  onPressed: onOpenUsageSettings,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text("Grant Permission"),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasUsagePermission)
            _buildPermissionPrompt()
          else if (batteryHungryApps.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  "No usage data yet",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                itemCount: batteryHungryApps.length,
                separatorBuilder: (context, index) => Divider(
                  indent: 84,
                  color: Colors.grey.withOpacity(0.1),
                  thickness: 1.5,
                  height: 32,
                ),
                itemBuilder: (context, index) {
                  final app = batteryHungryApps[index];
                  final String? iconBase64 = app['icon'];
                  final int usageMs = app['usageTime'] ?? 0;
                  final hours = (usageMs / (1000 * 60 * 60)).floor();
                  final minutes = ((usageMs / (1000 * 60)) % 60).floor();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              iconBase64 != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        base64Decode(
                                          iconBase64.replaceAll(
                                            RegExp(r'\s+'),
                                            '',
                                          ),
                                        ),
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.android,
                                      color: Colors.green,
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app['name'] ?? "Unknown",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF1A1C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${hours}h ${minutes}m in foreground",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionPrompt() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB75E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFFFB75E).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB75E).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB75E).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFFED8F03),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Usage Permission Required",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "To see which apps use the most battery, we need Usage Stats permission.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onOpenUsageSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED8F03),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFED8F03).withOpacity(0.4),
              ),
              child: const Text(
                "GRANT PERMISSION",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
