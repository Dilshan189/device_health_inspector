import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key});

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        children: [
          _buildHeaderSection("Hardware", "LABORATORY"),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildTestCard(
                  "Screen Test",
                  "Check for dead pixels & colors",
                  Icons.screenshot_monitor_rounded,
                  const [Color(0xFF8E54E9), Color(0xFF4776E6)],
                  () => _startScreenTest(context),
                ),
                _buildTestCard(
                  "Multi-Touch",
                  "Verify screen responsiveness",
                  Icons.touch_app_rounded,
                  const [Color(0xFFFFB75E), Color(0xFFED8F03)],
                  () => _startTouchTest(context),
                ),
                _buildTestCard(
                  "Vibration",
                  "Test vibration motor",
                  Icons.vibration_rounded,
                  const [Color(0xFF3DC5EB), Color(0xFF1596E7)],
                  () => _testVibration(),
                ),
                _buildTestCard(
                  "Torch Test",
                  "Check flashlight hardware",
                  Icons.flashlight_on_rounded,
                  const [Color(0xFFFF512F), Color(0xFFDD2476)],
                  () {}, // Needs a package or custom native code
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
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
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
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
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38EF7D).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.build_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    String title,
    String sub,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradientColors[0].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: gradientColors[1],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startScreenTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FullScreenColorTest()),
    );
  }

  void _startTouchTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TouchTestPage()),
    );
  }

  void _testVibration() {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Vibration Triggered"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class FullScreenColorTest extends StatefulWidget {
  const FullScreenColorTest({super.key});

  @override
  State<FullScreenColorTest> createState() => _FullScreenColorTestState();
}

class _FullScreenColorTestState extends State<FullScreenColorTest> {
  int _colorIndex = 0;
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.white,
    Colors.black,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_colorIndex < _colors.length - 1) {
            _colorIndex++;
          } else {
            Navigator.pop(context);
          }
        });
      },
      child: Scaffold(
        backgroundColor: _colors[_colorIndex],
        body: Center(
          child: _colorIndex == 0
              ? const Text(
                  "Tap to switch colors\nCheck for dead pixels",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black26,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class TouchTestPage extends StatefulWidget {
  const TouchTestPage({super.key});

  @override
  State<TouchTestPage> createState() => _TouchTestPageState();
}

class _TouchTestPageState extends State<TouchTestPage> {
  final Set<int> _touchedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Touch Test - Fill all boxes"),
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int cols = 8;
          int rows = (constraints.maxHeight / (constraints.maxWidth / cols))
              .floor();
          int total = cols * rows;

          return GestureDetector(
            onPanUpdate: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              Offset localPos = box.globalToLocal(details.globalPosition);
              double cellW = constraints.maxWidth / cols;
              double cellH = constraints.maxHeight / rows;

              int c = (localPos.dx / cellW).floor();
              int r = (localPos.dy / cellH).floor();

              if (c >= 0 && c < cols && r >= 0 && r < rows) {
                setState(() {
                  _touchedIndices.add(r * cols + c);
                  if (_touchedIndices.length == total) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Touch Test Passed!")),
                    );
                  }
                });
              }
            },
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: total,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
              ),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: _touchedIndices.contains(index)
                        ? Colors.green.withOpacity(0.5)
                        : Colors.white10,
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
