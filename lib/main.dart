import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            seedColor: Colors.red, brightness: Brightness.dark),
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
  String _savedPin = '';
  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  bool _wrongPin = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('pin') ?? '';
      _pinEnabled = prefs.getBool('pin_enabled') ?? false;
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
      _loaded = true;
    });

    // PIN නැත් + Fingerprint නැත් → සෘජුවම app එකට
    if (!_pinEnabled && !_fingerprintEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToHome();
      });
      return;
    }

    // Fingerprint enable → try කරන්න
    if (_fingerprintEnabled) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (canCheck) {
        bool result = await _auth.authenticate(
          localizedReason: 'SayuraTube unlock කරන්න',
          options: const AuthenticationOptions(
              biometricOnly: false, stickyAuth: true),
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
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled,
                  color: Colors.red, size: 80),
              const SizedBox(height: 16),
              const Text('SayuraTube',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              if (_pinEnabled) ...[
                Text(
                  _wrongPin ? '❌ PIN වැරදියි!' : 'PIN ඇතුල් කරන්න',
                  style: TextStyle(
                      color: _wrongPin ? Colors.red : Colors.white70),
                ),
                const SizedBox(height: 20),
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
                        color: i < _pin.length
                            ? Colors.red
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ...([
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['', '0', '⌫'],
                ].map((row) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((d) {
                        return GestureDetector(
                          onTap: () {
                            if (d == '⌫') {
                              setState(() {
                                if (_pin.isNotEmpty) {
                                  _pin = _pin.substring(
                                      0, _pin.length - 1);
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
                              child: Text(d,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ))),
                const SizedBox(height: 20),
                if (_fingerprintEnabled)
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint,
                        color: Colors.red),
                    label: const Text('Fingerprint use කරන්න',
                        style: TextStyle(color: Colors.red)),
                  ),
              ] else ...[
                const Text('Lock set කර නැත',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _goToHome,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14)),
                  child: const Text('Enter →',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LOCK SETTINGS ====================
class LockSettingsScreen extends StatefulWidget {
  const LockSettingsScreen({super.key});

  @override
  State<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends State<LockSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  String _savedPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _settingPin = false;
  bool _confirmStep = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinEnabled = prefs.getBool('pin_enabled') ?? false;
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
      _savedPin = prefs.getString('pin') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_enabled', _pinEnabled);
    await prefs.setBool('fingerprint_enabled', _fingerprintEnabled);
    await prefs.setString('pin', _savedPin);
  }

  void _enterNewPin(String digit) {
    if (!_confirmStep) {
      if (_newPin.length < 4) {
        final p = _newPin + digit;
        setState(() => _newPin = p);
        if (p.length == 4) {
          setState(() {
            _confirmStep = true;
            _message = 'PIN confirm කරන්න';
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        final p = _confirmPin + digit;
        setState(() => _confirmPin = p);
        if (p.length == 4) {
          if (p == _newPin) {
            setState(() {
              _savedPin = p;
              _pinEnabled = true;
              _settingPin = false;
              _newPin = '';
              _confirmPin = '';
              _confirmStep = false;
              _message = '✅ PIN set වුණා!';
            });
            _save();
          } else {
            setState(() {
              _newPin = '';
              _confirmPin = '';
              _confirmStep = false;
              _message = '❌ PIN match වුණේ නෑ. නැවත try කරන්න';
            });
          }
        }
      }
    }
  }

  Widget _buildNumPad() {
    return Column(
      children: [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['', '0', '⌫'],
      ]
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((d) {
                  return GestureDetector(
                    onTap: () {
                      if (d == '⌫') {
                        setState(() {
                          if (!_confirmStep && _newPin.isNotEmpty) {
                            _newPin = _newPin.substring(
                                0, _newPin.length - 1);
                          } else if (_confirmStep &&
                              _confirmPin.isNotEmpty) {
                            _confirmPin = _confirmPin.substring(
                                0, _confirmPin.length - 1);
                          }
                        });
                      } else if (d.isNotEmpty) {
                        _enterNewPin(d);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900],
                      ),
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Lock Settings',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PIN toggle
            Card(
              color: Colors.grey[900],
              child: SwitchListTile(
                title: const Text('PIN Lock',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _pinEnabled
                      ? 'PIN: ${_savedPin.replaceAll(RegExp(r'.'), '●')}'
                      : 'PIN lock off',
                  style: const TextStyle(color: Colors.white54),
                ),
                value: _pinEnabled,
                activeColor: Colors.red,
                onChanged: (val) {
                  if (val) {
                    setState(() {
                      _settingPin = true;
                      _message = '';
                    });
                  } else {
                    setState(() {
                      _pinEnabled = false;
                      _savedPin = '';
                      _message = '';
                    });
                    _save();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // PIN change button
            if (_pinEnabled && !_settingPin)
              Card(
                color: Colors.grey[900],
                child: ListTile(
                  leading:
                      const Icon(Icons.edit, color: Colors.red),
                  title: const Text('PIN Change කරන්න',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      _settingPin = true;
                      _newPin = '';
                      _confirmPin = '';
                      _confirmStep = false;
                      _message = '';
                    });
                  },
                ),
              ),

            // PIN setup numpad
            if (_settingPin) ...[
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _message.isNotEmpty
                      ? _message
                      : (!_confirmStep
                          ? 'නව PIN enter කරන්න'
                          : 'PIN confirm කරන්න'),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final current =
                        !_confirmStep ? _newPin : _confirmPin;
                    return Container(
                      margin: const EdgeInsets.all(8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < current.length
                            ? Colors.red
                            : Colors.grey[800],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              _buildNumPad(),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _settingPin = false;
                    _newPin = '';
                    _confirmPin = '';
                    _confirmStep = false;
                    _message = '';
                  }),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],

            if (_message.isNotEmpty && !_settingPin) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(_message,
                    style: TextStyle(
                        color: _message.contains('✅')
                            ? Colors.green
                            : Colors.red)),
              ),
            ],

            const SizedBox(height: 12),

            // Fingerprint toggle
            Card(
              color: Colors.grey[900],
              child: SwitchListTile(
                title: const Text('Fingerprint / Face ID',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Biometric unlock',
                    style: TextStyle(color: Colors.white54)),
                value: _fingerprintEnabled,
                activeColor: Colors.red,
                onChanged: (val) async {
                  if (val) {
                    try {
                      bool canCheck =
                          await _auth.canCheckBiometrics;
                      if (canCheck) {
                        bool result = await _auth.authenticate(
                          localizedReason:
                              'Fingerprint enable කරන්න',
                          options: const AuthenticationOptions(
                              biometricOnly: false),
                        );
                        if (result) {
                          setState(
                              () => _fingerprintEnabled = true);
                          _save();
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Biometrics available නෑ')));
                        }
                      }
                    } catch (_) {}
                  } else {
                    setState(() => _fingerprintEnabled = false);
                    _save();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== YOUTUBE SCREEN ====================
class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
  }

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
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) async {
          setState(() => _isLoading = false);
          await _controller.runJavaScript('''
            document.body.style.overflow = 'auto';
            document.documentElement.style.overflow = 'auto';
            document.body.style.touchAction = 'auto';
          ''');
        },
        onNavigationRequest: (request) {
          if (request.url.startsWith('https://') ||
              request.url.startsWith('http://')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: (_) async {
          try {
            await InternetAddress.lookup('youtube.com');
          } catch (_) {
            setState(() {
              _hasInternet = false;
              _isLoading = false;
            });
          }
        },
      ))
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
                      style: TextStyle(color: Colors.grey))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ඔව්',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('SayuraTube',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => MyApp.of(context)?.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LockSettingsScreen()),
                );
              },
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
                          child: CircularProgressIndicator(
                              color: Colors.red)),
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
          const Text('Internet නෑ!',
              style: TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 10),
          const Text('Connection එක check කරලා retry කරන්න',
              style: TextStyle(color: Colors.grey)),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}
