import 'package:device_health_inspector/bottom.nav.dart';
import 'package:device_health_inspector/file.viwer.dart';
import 'package:device_health_inspector/dashboard.screen.dart';
import 'package:device_health_inspector/storage.screen.dart';
import 'package:device_health_inspector/battery.screen.dart';
import 'package:device_health_inspector/system.screen.dart';
import 'package:device_health_inspector/sensor.screen.dart';
import 'package:device_health_inspector/hardware.test.screen.dart';
import 'package:device_health_inspector/digital_health.screen.dart';
import 'package:device_health_inspector/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  static const platform = MethodChannel('samples.flutter.dev/device_info');

  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isOptimizing = false;

  // Data State
  String _batteryLevel = ' --';
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _ramInfo = {};
  Map<String, dynamic> _systemInfo = {};
  Map<String, dynamic> _storageAnalysis = {};
  Map<String, dynamic> _batteryHealth = {};
  List<dynamic> _batteryHungryApps = [];
  Map<String, dynamic> _networkInfo = {};
  bool _hasUsagePermission = false;

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _refreshAll();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    try {
      final int battery = await platform.invokeMethod('getBatteryLevel');
      final Map<dynamic, dynamic> storage = await platform.invokeMethod(
        'getStorageInfo',
      );
      final Map<dynamic, dynamic> ram = await platform.invokeMethod(
        'getRamInfo',
      );
      final Map<dynamic, dynamic> sys = await platform.invokeMethod(
        'getSystemInfo',
      );
      final Map<dynamic, dynamic> battHealth = await platform.invokeMethod(
        'getBatteryHealth',
      );
      final Map<dynamic, dynamic> analysis = await platform.invokeMethod(
        'getStorageAnalysis',
      );
      final bool hasPermission = await platform.invokeMethod(
        'checkUsageStatsPermission',
      );
      final List<dynamic> hungryApps = await platform.invokeMethod(
        'getBatteryHungryApps',
      );
      final Map<dynamic, dynamic> network = await platform.invokeMethod(
        'getNetworkInfo',
      );

      setState(() {
        _batteryLevel = '$battery%';
        _storageInfo = Map<String, dynamic>.from(storage);
        _ramInfo = Map<String, dynamic>.from(ram);
        _systemInfo = Map<String, dynamic>.from(sys);
        _batteryHealth = Map<String, dynamic>.from(battHealth);
        _storageAnalysis = Map<String, dynamic>.from(analysis);
        _networkInfo = Map<String, dynamic>.from(network);
        _hasUsagePermission = hasPermission;
        _batteryHungryApps = hungryApps;
      });
    } catch (e) {
      debugPrint("Refresh Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(String category) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Clean $category?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove unused $category files to free up space?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "CLEAN",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isOptimizing = true);
      await Future.delayed(const Duration(seconds: 2));
      try {
        final int cleaned = await platform.invokeMethod('deleteCategory', {
          "category": category.toLowerCase(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Purged ${formatBytes(cleaned)} of $category."),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isOptimizing = false);
          _refreshAll();
        }
      }
    }
  }

  Future<void> _openFileViewer(String category) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FileViewer(category: category, platform: platform),
      ),
    );
  }

  String _optimizingMsg = "Optimizing...";

  Future<void> _handleOptimize() async {
    setState(() {
      _isOptimizing = true;
      _optimizingMsg = "Optimizing...";
    });
    await Future.delayed(const Duration(seconds: 3));
    try {
      await platform.invokeMethod('cleanJunk');
      await platform.invokeMethod('boostRam');
    } finally {
      if (mounted) {
        setState(() => _isOptimizing = false);
        _refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Device Optimized Successfully!"),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleCleanJunkCmd() async {
    setState(() {
      _isOptimizing = true;
      _optimizingMsg = "Scanning Orphaned Data...";
    });
    await Future.delayed(const Duration(seconds: 2));
    try {
      final dynamic cleaned = await platform.invokeMethod('cleanJunk');
      final cleanedSize = cleaned is int
          ? cleaned
          : (cleaned is num ? cleaned.toInt() : 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ghost Scanner Freed ${formatBytes(cleanedSize)}!"),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOptimizing = false);
        _refreshAll();
      }
    }
  }

  Future<void> _handleCpuCooler() async {
    setState(() {
      _isOptimizing = true;
      _optimizingMsg = "Deep Hibernating CPU...";
    });
    await Future.delayed(const Duration(seconds: 3));
    try {
      await platform.invokeMethod('deepHibernateCpu');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Deep Freeze applied successfully!"),
            backgroundColor: Colors.lightBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOptimizing = false);
        _refreshAll();
      }
    }
  }

  Future<void> _handleOpenUsageSettings() async {
    await platform.invokeMethod('openUsageSettings');
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardScreen(
                batteryLevel: _batteryLevel,
                ramInfo: _ramInfo,
                networkInfo: _networkInfo,
                floatAnimation: _floatController,
                onOptimize: _handleOptimize,
                onCleanJunk: _handleCleanJunkCmd,
                onCpuCooler: _handleCpuCooler,
              ),
              StorageScreen(
                storageInfo: _storageInfo,
                storageAnalysis: _storageAnalysis,
                onDelete: _handleDelete,
                onOpenFileViewer: _openFileViewer,
                onRefresh: _refreshAll,
              ),
              BatteryScreen(
                batteryLevel: _batteryLevel,
                batteryHealth: _batteryHealth,
                batteryHungryApps: _batteryHungryApps,
                hasUsagePermission: _hasUsagePermission,
                onOpenUsageSettings: _handleOpenUsageSettings,
                onRefresh: _refreshAll,
              ),
              const HardwareTestScreen(),
              const SensorScreen(),
              SystemScreen(systemInfo: _systemInfo),
              const DigitalHealthScreen(),
            ],
          ),
          if (_isOptimizing)
            AnimatedOptimizationOverlay(message: _optimizingMsg),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class AnimatedOptimizationOverlay extends StatefulWidget {
  final String message;
  const AnimatedOptimizationOverlay({super.key, required this.message});

  @override
  State<AnimatedOptimizationOverlay> createState() =>
      _AnimatedOptimizationOverlayState();
}

class _AnimatedOptimizationOverlayState
    extends State<AnimatedOptimizationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _spinController;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation =
        ColorTween(
          begin: const Color(0xFF1E3C72).withOpacity(0.95), // Deep blue
          end: const Color(0xFF11998E).withOpacity(0.95), // Success green
        ).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        String changingText = widget.message;
        if (_controller.value > 0.8) {
          changingText = "Ready for action...";
        } else if (_controller.value > 0.4) {
          changingText = "Analyzing & Cleaning...";
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: _colorAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning Custom Outer Ring
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _spinController.value * 2 * 3.1415926535,
                            child: SizedBox(
                              width: 170,
                              height: 170,
                              child: CircularProgressIndicator(
                                value: 0.75, // 3/4 circle
                                strokeWidth: 3,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Spinning Custom Inner Dotted/Dashed effect (reversed)
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_spinController.value * 2 * 3.1415926535,
                            child: SizedBox(
                              width: 130,
                              height: 130,
                              child: CircularProgressIndicator(
                                value: 0.3, // Small piece
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Main Progress Fill (Stationary)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _progressAnimation.value / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Percentage Text
                      Text(
                        "${_progressAnimation.value.toInt()}%",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  // Animated Text block
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      changingText,
                      key: ValueKey<String>(changingText),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "AeroGuard Optimization Engine",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
