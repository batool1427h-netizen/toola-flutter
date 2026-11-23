import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera init error: $e");
  }
  runApp(const ToolaApp());
}

class ToolaApp extends StatelessWidget {
  const ToolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تـولا | Toola',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFFFD166),
        textTheme: GoogleFonts.alexandriaTextTheme(ThemeData.dark().textTheme),
      ),
      home: const ToolaMainNavigation(),
    );
  }
}

class ToolaMainNavigation extends StatefulWidget {
  const ToolaMainNavigation({super.key});

  @override
  State<ToolaMainNavigation> createState() => _ToolaMainNavigationState();
}

class _ToolaMainNavigationState extends State<ToolaMainNavigation> {
  int _currentIndex = 2; // Default to Camera (center)

  final List<Widget> _screens = [
    const ToolaRadarScreen(),
    const ToolaChatScreen(),
    const ToolaCameraScreen(),
    const ToolaStoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Bottom Snapchat Style Navigation Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C10).withOpacity(0.92),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavBtn(0, Icons.map_outlined, Icons.map, 'الرادار'),
                  _buildNavBtn(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'الدردشة'),
                  _buildNavBtn(2, Icons.camera_alt_outlined, Icons.camera_alt, 'الكاميرا', isCamera: true),
                  _buildNavBtn(3, Icons.people_outline, Icons.people, 'القصص'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBtn(int index, IconData icon, IconData activeIcon, String label, {bool isCamera = false}) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFFFFD166) : Colors.grey,
            size: isCamera ? 26 : 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFFFD166) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. NATIVE CAMERA SCREEN (FULLSCREEN REALTIME)
// ==========================================
class ToolaCameraScreen extends StatefulWidget {
  const ToolaCameraScreen({super.key});

  @override
  State<ToolaCameraScreen> createState() => _ToolaCameraScreenState();
}

class _ToolaCameraScreenState extends State<ToolaCameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras[_selectedCameraIdx],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _flipCamera() {
    if (cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx == 0) ? 1 : 0;
    _initCamera();
  }

  Future<void> _takeSnap() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    HapticFeedback.mediumImpact();
    try {
      final XFile photo = await _controller!.takePicture();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 تم التقاط السناب بنجاح ومشاركته عبر رادار تـولا بدون إنترنت!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      debugPrint("Take picture error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Viewfinder
          if (_isCameraReady && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_enhance, size: 54, color: Color(0xFFFFD166)),
                  SizedBox(height: 12),
                  Text('كاميرا تـولا اللاسلكية الأصلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),

          // Top App Bar
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: Color(0xFFFFD166), child: Text('T', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 8),
                      Text('المبرمجة بتول', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radar, color: Color(0xFFFFD166), size: 14),
                      SizedBox(width: 6),
                      Text('Mesh (بدون نت)', style: TextStyle(color: Color(0xFFFFD166), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Side Tools Bar
          Positioned(
            top: 110,
            left: 16,
            child: Column(
              children: [
                _buildSideBtn(Icons.flip_camera_ios, _flipCamera),
                const SizedBox(height: 12),
                _buildSideBtn(Icons.flash_on, () {}),
                const SizedBox(height: 12),
                _buildSideBtn(Icons.text_fields, () {}),
              ],
            ),
          ),

          // Bottom Shutter Button
          Positioned(
            bottom: 95,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takeSnap,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD166), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD166).withOpacity(0.4),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.55),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ==========================================
// 2. STORIES SCREEN
// ==========================================
class ToolaStoriesScreen extends StatelessWidget {
  const ToolaStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القصص واللحظات الحية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [const Color(0xFFFFD166).withOpacity(0.3), const Color(0xFF141418)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.4)),
            ),
            padding: const EdgeInsets.all(12),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Color(0xFFFFD166), child: Icon(Icons.add, color: Colors.black)),
                Spacer(),
                Text('قصتي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('انقري لإضافة لحظة', style: TextStyle(color: Color(0xFFFFD166), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. CHAT SCREEN
// ==========================================
class ToolaChatScreen extends StatelessWidget {
  const ToolaChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات واللحظات المشفرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد محادثات بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('أضيفي صديقاً لبدء إرسال اللحظات عبر P2P بدون نت', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. OFFLINE MESH RADAR SCREEN
// ==========================================
class ToolaRadarScreen extends StatelessWidget {
  const ToolaRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رادار تـولا اللاسلكي (Mesh Radar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.4), width: 2),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFFFD166),
                  child: Text('بتول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('الرادار يبحث عن الأجهزة القريبة...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Bluetooth LE + Wi-Fi Direct Mesh نشط', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
