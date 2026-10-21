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
  static const String appVersion = "v1.0.0";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('current_counter') ?? 0;
      final String? historyString = prefs.getString('tap_history');
      if (historyString != null) {
        _history = List<Map<String, dynamic>>.from(json.decode(historyString));
      }
    });
  }

  Future<void> _incrementCounter() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
    });
    await prefs.setInt('current_counter', _counter);
  }

  Future<void> _resetCounter() async {
    if (_counter == 0) return;
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}  ${_formatTime(now)}";

    final session = {
      'taps': _counter,
      'timestamp': formattedDate,
    };

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history.insert(0, session);
      _counter = 0;
    });

    await prefs.setInt('current_counter', 0);
    await prefs.setString('tap_history', json.encode(_history));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history.clear();
    });
    await prefs.remove('tap_history');
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
          // Main Tap Area
          Expanded(
            flex: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _incrementCounter,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 32),
                    // Small Reset Button
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: _resetCounter,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.redAccent, fontSize: 11),
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
                                    item['timestamp'],
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
