import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SayuraTube',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
      ),
      home: const LockScreen(),
    );
  }
}

// ==================== LOCK SCREEN ====================
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _pin = '';
  final String _savedPin = '1234';
  bool _wrongPin = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (canCheck) {
        bool result = await _auth.authenticate(
          localizedReason: 'SayuraTube unlock කරන්න',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (result && mounted) _goToHome();
      }
    } catch (_) {}
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const YouTubeScreen()),
    );
  }

  void _enterPin(String digit) {
    if (_pin.length >= 4) return;
    final newPin = _pin + digit;
    setState(() {
      _pin = newPin;
      _wrongPin = false;
    });
    if (newPin.length == 4) {
      if (newPin == _savedPin) {
        Future.delayed(const Duration(milliseconds: 200), _goToHome);
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _pin = '';
            _wrongPin = true;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            const Text(
              'SayuraTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _wrongPin ? '❌ PIN වැරදියි!' : 'PIN ඇතුල් කරන්න (optional)',
              style: TextStyle(
                color: _wrongPin ? Colors.red : Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.all(8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? Colors.red : Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Number pad
            ...([
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ].map(
              (row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((d) {
                  return GestureDetector(
                    onTap: () {
                      if (d == '⌫') {
                        setState(() {
                          if (_pin.isNotEmpty) {
                            _pin = _pin.substring(0, _pin.length - 1);
                          }
                        });
                      } else if (d.isNotEmpty) {
                        _enterPin(d);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900],
                      ),
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
            const SizedBox(height: 20),
            // ✅ Skip button — optional
            TextButton(
              onPressed: _goToHome,
              child: const Text(
                'Skip → PIN නැතිව Enter වෙන්න',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            // Fingerprint retry
            TextButton.icon(
              onPressed: _tryBiometric,
              icon: const Icon(Icons.fingerprint, color: Colors.red),
              label: const Text(
                'Fingerprint use කරන්න',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MAIN SCREEN ====================
class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;
  bool _isPiP = false;

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
  }

  // ✅ Real internet check
  Future<void> _checkInternetAndLoad() async {
    try {
      final result = await InternetAddress.lookup('youtube.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() => _hasInternet = true);
        _initWebView();
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
        _isLoading = false;
      });
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            await _controller.runJavaScript('''
              document.body.style.overflow = 'auto';
              document.documentElement.style.overflow = 'auto';
              document.body.style.touchAction = 'auto';
            ''');
          },
          onWebResourceError: (_) async {
            // Double check real internet
            try {
              await InternetAddress.lookup('youtube.com');
            } catch (_) {
              setState(() {
                _hasInternet = false;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://m.youtube.com'),
        headers: {'Cache-Control': 'no-cache'},
      );
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Exit?',
                style: TextStyle(color: Colors.white)),
            content: const Text('SayuraTube close කරන්නද?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('නෑ',
                    style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ඔව්',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isPiP) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SizedBox(
              width: 300,
              height: 180,
              child: WebViewWidget(controller: _controller),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _isPiP = false),
                child:
                    const Icon(Icons.fullscreen, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text(
            'SayuraTube',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => MyApp.of(context)?.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.picture_in_picture,
                  color: Colors.white),
              onPressed: () => setState(() => _isPiP = true),
            ),
          ],
        ),
        body: _hasInternet
            ? RefreshIndicator(
                color: Colors.red,
                onRefresh: () async {
                  await _checkInternetAndLoad();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(
                        child:
                            CircularProgressIndicator(color: Colors.red),
                      ),
                  ],
                ),
              )
            : _noInternetPage(),
      ),
    );
  }

  Widget _noInternetPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.grey, size: 80),
          const SizedBox(height: 20),
          const Text(
            'Internet නෑ!',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connection එක check කරලා retry කරන්න',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasInternet = true;
                _isLoading = true;
              });
              _checkInternetAndLoad();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
