import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DigitalHealthScreen extends StatefulWidget {
  const DigitalHealthScreen({super.key});

  @override
  State<DigitalHealthScreen> createState() => _DigitalHealthScreenState();
}

class _DigitalHealthScreenState extends State<DigitalHealthScreen> {
  static const platform = MethodChannel('samples.flutter.dev/device_info');
  List<dynamic> _apps = [];
  bool _isLoading = true;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _fetchScreenTime();
  }

  Future<void> _fetchScreenTime() async {
    setState(() => _isLoading = true);
    try {
      final bool hasPerm = await platform.invokeMethod(
        'checkUsageStatsPermission',
      );
      if (!hasPerm) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> stats = await platform.invokeMethod(
        'getScreenTimeStats',
      );
      setState(() {
        _apps = stats;
        _hasPermission = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermission = false;
        });
      }
    }
  }

  String _formatDuration(int milliseconds) {
    int minutes = (milliseconds / (1000 * 60)).floor();
    int hours = (minutes / 60).floor();
    minutes = minutes % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Digital Detox",
            style: TextStyle(
              color: Color(0xFF1A1C1E),
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 20),
              const Text(
                "Permission Required",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enable usage access to see Screen Time stats and activate Detox mode.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  platform.invokeMethod('openUsageSettings');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "GRANT PERMISSION",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _fetchScreenTime,
                child: const Text("I have granted it, Refresh"),
              ),
            ],
          ),
        ),
      );
    }

    int totalUsage = _apps.fold(
      0,
      (sum, item) => sum + ((item['usageTime'] as num?)?.toInt() ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Digital Detox",
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalTimeCard(totalUsage),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "App Usage Today",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2024),
                  ),
                ),
                GestureDetector(
                  onTap: _fetchScreenTime,
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._apps.map((app) => _buildAppItem(app)),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalTimeCard(int totalUsage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203A43).withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.spa_rounded, color: Colors.greenAccent, size: 40),
          const SizedBox(height: 16),
          const Text(
            "Total Screen Time",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(totalUsage),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
              ),
              label: const Text(
                "START FOCUS MODE",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Focus Mode activated! Distractions are now silenced.",
                    ),
                    backgroundColor: Color(0xFF2C5364),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(dynamic app) {
    final String name = app['name'] ?? 'Unknown App';
    final int usageTime = (app['usageTime'] as num?)?.toInt() ?? 0;
    final String base64Icon = app['icon'] ?? '';

    Widget iconWidget = const Icon(Icons.android_rounded, color: Colors.grey);
    if (base64Icon.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(base64Icon);
        iconWidget = Image.memory(bytes, width: 44, height: 44);
      } catch (e) {
        // Fallback to default
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: iconWidget,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2024),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(usageTime),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1ABC9C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.timer_rounded, color: Colors.black26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("App Timer set for $name. (Demo)"),
                  backgroundColor: Colors.blueAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
