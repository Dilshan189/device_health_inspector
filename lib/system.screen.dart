import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemScreen extends StatefulWidget {
  final Map<String, dynamic> systemInfo;

  const SystemScreen({super.key, required this.systemInfo});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  static const platform = MethodChannel('samples.flutter.dev/device_info');
  List<dynamic> _apps = [];
  Map<String, dynamic>? _malwareResult;
  bool _isLoadingMalware = false;
  bool _isLoadingApps = false;
  bool _showMalwareTab = false; // toggle between device info and tools

  @override
  void initState() {
    super.initState();
    _fetchAppManager();
  }

  Future<void> _fetchAppManager() async {
    setState(() => _isLoadingApps = true);
    try {
      final List<dynamic> appsInfo = await platform.invokeMethod(
        'getAppManagerList',
      );
      setState(() {
        _apps = appsInfo;
        _isLoadingApps = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingApps = false);
    }
  }

  Future<void> _runMalwareScan() async {
    setState(() => _isLoadingMalware = true);
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'scanForMalware',
      );
      setState(() {
        _malwareResult = Map<String, dynamic>.from(result);
        _isLoadingMalware = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMalware = false);
    }
  }

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return "0 B";
    int b = bytes is int ? bytes : (bytes is num ? bytes.toInt() : 0);
    if (b < 1024) return "$b B";
    if (b < 1024 * 1024) return "${(b / 1024).toStringAsFixed(1)} KB";
    if (b < 1024 * 1024 * 1024) {
      return "${(b / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        children: [
          _buildHeaderSection("System", "SPECS & TOOLS"),
          const SizedBox(height: 10),
          _buildTabToggles(),
          const SizedBox(height: 20),
          _showMalwareTab ? _buildToolsTab() : _buildDeviceInfoTab(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showMalwareTab = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_showMalwareTab
                        ? const Color(0xFF4776E6).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "Device Info",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_showMalwareTab
                            ? const Color(0xFF4776E6)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showMalwareTab = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _showMalwareTab
                        ? const Color(0xFF4776E6).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "Security & Apps",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _showMalwareTab
                            ? const Color(0xFF4776E6)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInfoTile(
            "Device Model",
            widget.systemInfo['model'],
            Icons.phone_android_rounded,
            const [Color(0xFF8E54E9), Color(0xFF4776E6)],
          ),
          _buildInfoTile(
            "Android Version",
            "v${widget.systemInfo['androidVersion']}",
            Icons.android_rounded,
            const [Color(0xFF11998E), Color(0xFF38EF7D)],
          ),
          _buildInfoTile(
            "Manufacturer",
            widget.systemInfo['manufacturer'],
            Icons.precision_manufacturing_rounded,
            const [Color(0xFFFFB75E), Color(0xFFED8F03)],
          ),
          _buildInfoTile(
            "Hardware Board",
            widget.systemInfo['board'],
            Icons.memory_rounded,
            const [Color(0xFF3DC5EB), Color(0xFF1596E7)],
          ),
          _buildInfoTile(
            "Security Brand",
            widget.systemInfo['brand']?.toString().toUpperCase(),
            Icons.security_rounded,
            const [Color(0xFFFF512F), Color(0xFFDD2476)],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMalwareScannerCard(),
          const SizedBox(height: 30),
          const Text(
            "App Manager",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingApps
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: _apps.map((a) => _buildAppManagerItem(a)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildMalwareScannerCard() {
    bool hasScanned = _malwareResult != null;
    int threats = 0;
    int scannedCount = 0;
    if (hasScanned) {
      threats = (_malwareResult!['threats'] as List).length;
      scannedCount = _malwareResult!['scannedCount'] ?? 0;
    }

    Color bgColor = hasScanned
        ? (threats > 0 ? const Color(0xFFFFF0F0) : const Color(0xFFF0FFF4))
        : Colors.white;
    Color iconColor = hasScanned
        ? (threats > 0 ? Colors.redAccent : Colors.greenAccent.shade700)
        : Colors.blueAccent;
    IconData icon = hasScanned
        ? (threats > 0 ? Icons.warning_rounded : Icons.verified_user_rounded)
        : Icons.shield_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: hasScanned
              ? (threats > 0
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.greenAccent)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: iconColor),
          const SizedBox(height: 16),
          Text(
            hasScanned
                ? (threats > 0 ? "Threats Detected!" : "Device is Secure")
                : "AeroGuard Security Shield",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: hasScanned ? iconColor : const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasScanned
                ? "Scanned $scannedCount apps. Found $threats potential risks."
                : "Scan your installed applications for malware, adware, and high-risk permissions.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingMalware)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.radar_rounded, color: Colors.white),
              label: Text(
                hasScanned ? "SCAN AGAIN" : "START SCAN",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _runMalwareScan,
            ),

          if (hasScanned && threats > 0) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Risky Apps:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...(_malwareResult!['threats'] as List).map(
              (threat) => _buildThreatItem(threat),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThreatItem(dynamic threat) {
    final String name = threat['name'] ?? 'Unknown';
    final String reasons =
        (threat['reasons'] as List?)?.join(", ") ?? "Unknown Risk";
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  reasons,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppManagerItem(dynamic app) {
    final String name = app['name'] ?? 'Unknown App';
    final String pkg = app['packageName'] ?? '';
    final int size = (app['size'] as num?)?.toInt() ?? 0;
    final String base64Icon = app['icon'] ?? '';

    Widget iconWidget = const Icon(Icons.android_rounded, color: Colors.grey);
    if (base64Icon.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(base64Icon);
        iconWidget = Image.memory(bytes, width: 44, height: 44);
      } catch (e) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  _formatBytes(size),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () {
              platform.invokeMethod('deleteFiles', {
                "category": "apps",
                "paths": [pkg],
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Uninstallation started...")),
              );
            },
          ),
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
                  colors: [Color(0xFF8E54E9), Color(0xFF4776E6)],
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
                colors: [Color(0xFF8E54E9), Color(0xFF4776E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4776E6).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String? value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? "N/A",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1C1E),
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
