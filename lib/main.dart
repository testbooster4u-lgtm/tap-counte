import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const TapCounterApp());
}

class TapCounterApp extends StatelessWidget {
  const TapCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;
  List<Map<String, dynamic>> _history = [];
  SharedPreferences? _prefs;
  static const String appVersion = "v1.0.1";

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedCount = _prefs?.getInt('current_counter') ?? 0;
      final historyString = _prefs?.getString('tap_history');
      List<Map<String, dynamic>> loadedHistory = [];
      if (historyString != null && historyString.isNotEmpty) {
        loadedHistory = List<Map<String, dynamic>>.from(json.decode(historyString));
      }
      if (mounted) {
        setState(() {
          _counter = savedCount;
          _history = loadedHistory;
        });
      }
    } catch (_) {
      // Continues working in memory even if storage is unavailable
    }
  }

  void _incrementCounter() {
    // 1. Update UI immediately so taps always work
    setState(() {
      _counter++;
    });
    // 2. Trigger vibration and save in background
    HapticFeedback.lightImpact();
    _prefs?.setInt('current_counter', _counter);
  }

  void _resetCounter() {
    if (_counter == 0) return;

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}  ${_formatTime(now)}";

    final session = {
      'taps': _counter,
      'timestamp': formattedDate,
    };

    setState(() {
      _history.insert(0, session);
      _counter = 0;
    });

    HapticFeedback.mediumImpact();
    _prefs?.setInt('current_counter', 0);
    _prefs?.setString('tap_history', json.encode(_history));
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
    _prefs?.remove('tap_history');
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) {
    final int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final String amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return "${_twoDigits(hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)} $amPm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Tap Counter',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'App $appVersion',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Tap Area + Reset Button
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                // Full box tap detector
                Positioned.fill(
                  child: Material(
                    color: Colors.black,
                    child: InkWell(
                      onTap: _incrementCounter,
                      splashColor: Colors.white10,
                      highlightColor: Colors.white10,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_counter',
                              style: const TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'TAP ANYWHERE',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Small Reset Button placed cleanly at bottom of tap zone
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: _resetCounter,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Session History Section
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SESSION HISTORY',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (_history.isNotEmpty)
                        GestureDetector(
                          onTap: _clearHistory,
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _history.isEmpty
                        ? const Center(
                            child: Text(
                              'No sessions saved yet.\nTap Reset to log a session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _history.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white10, height: 12),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['taps']} taps',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item['timestamp'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
