import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HydroBuddyApp());

class HydroBuddyApp extends StatelessWidget {
  const HydroBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HydroBuddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HydrationHomePage(),
    );
  }
}

class HydrationHomePage extends StatefulWidget {
  const HydrationHomePage({super.key});

  @override
  State<HydrationHomePage> createState() => _HydrationHomePageState();
}

class _HydrationHomePageState extends State<HydrationHomePage> {
  String _userName = 'Friend';
  int _currentWater = 0;
  int _dailyGoal = 2500;
  int _reminderMinutes = 60; // Default: 60 mins (1 hour)
  int _tipIndex = 0;
  bool _celebratedToday = false;
  bool _reminderOn = false;
  Timer? _reminderTimer;
  Map<String, int> _historyMap = {};

  final List<Map<String, String>> _dailyIdeas = [
    {
      'category': '💧 Hydration Habit',
      'tip': 'Drink a glass of water right after waking up to kickstart your energy.'
    },
    {
      'category': '🥗 Balanced Plate Rule',
      'tip': 'Fill half your lunch/dinner plate with vegetables, one-quarter with protein (dal, eggs, paneer, chicken), and one-quarter with whole grains.'
    },
    {
      'category': '🍎 Smart Snacking',
      'tip': 'Swap fried evening snacks for a handful of roasted nuts, sprouts, or seasonal fruit to avoid energy crashes.'
    },
    {
      'category': '👀 Desk Wellness',
      'tip': 'Follow the 20-20-20 rule: every 20 mins, look 20 feet away for 20 seconds and relax your shoulders.'
    },
    {
      'category': '🍽️ Mindful Eating',
      'tip': 'Eat slowly without screens and finish dinner at least 2–3 hours before sleeping for better digestion.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatIntervalLabel(int mins) {
    if (mins == 30) return 'Every 30 mins';
    if (mins == 60) return 'Every 1 hr';
    return 'Every ${mins ~/ 60} hrs';
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName') ?? 'Friend';
    final savedGoal = prefs.getInt('dailyGoal') ?? 2500;
    final savedMinutes = prefs.getInt('reminderMinutes') ?? 60;
    final rawHistory = prefs.getString('historyMap');

    Map<String, int> loadedHistory = {};
    if (rawHistory != null) {
      final decoded = jsonDecode(rawHistory) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        loadedHistory[key] = value as int;
      });
    }

    final today = _todayKey();
    final todayAmount = loadedHistory[today] ?? 0;

    setState(() {
      _userName = savedName;
      _dailyGoal = savedGoal;
      _reminderMinutes = savedMinutes;
      _historyMap = loadedHistory;
      _currentWater = todayAmount;
      _celebratedToday = _currentWater >= _dailyGoal;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    _historyMap[_todayKey()] = _currentWater;

    final sortedKeys = _historyMap.keys.toList()..sort((a, b) => b.compareTo(a));
    if (sortedKeys.length > 30) {
      for (final oldKey in sortedKeys.sublist(30)) {
        _historyMap.remove(oldKey);
      }
    }

    await prefs.setString('userName', _userName);
    await prefs.setInt('dailyGoal', _dailyGoal);
    await prefs.setInt('reminderMinutes', _reminderMinutes);
    await prefs.setString('historyMap', jsonEncode(_historyMap));
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _startOrRestartTimer() {
    _reminderTimer?.cancel();
    if (_reminderOn) {
      _reminderTimer = Timer.periodic(
        Duration(minutes: _reminderMinutes),
        (timer) => _triggerWaterAlarm(),
      );
    }
  }

  void _toggleReminder(bool value) {
    setState(() {
      _reminderOn = value;
    });
    _startOrRestartTimer();

    if (_reminderOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Reminder ON (${_formatIntervalLabel(_reminderMinutes)})!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _triggerWaterAlarm() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '⏰ Time to Drink Water, $_userName!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Stay energized! Take a sip of water now and log it toward your daily goal.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Snooze'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _addWater(250);
            },
            icon: const Icon(Icons.local_drink),
            label: const Text('Drink +250 ml'),
          ),
        ],
      ),
    );
  }
  void _openSettingsDialog() {
    final nameController =
        TextEditingController(text: _userName == 'Friend' ? '' : _userName);
    int tempGoal = _dailyGoal;
    int tempMinutes = _reminderMinutes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('⚙️ Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rahul, Priya',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Daily Water Limit: $tempGoal ml',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: tempGoal.toDouble(),
                  min: 1000,
                  max: 5000,
                  divisions: 16,
                  label: '$tempGoal ml',
                  onChanged: (val) {
                    setDialogState(() {
                      tempGoal = val.round();
                    });
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alarm Reminder Interval',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [30, 60, 120, 180].map((mins) {
                    final label = mins == 30
                        ? '30 mins'
                        : mins == 60
                            ? '1 hr'
                            : '${mins ~/ 60} hrs';
                    return ChoiceChip(
                      label: Text(label),
                      selected: tempMinutes == mins,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            tempMinutes = mins;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  String entered = nameController.text.trim();
                  _userName = entered.isEmpty ? 'Friend' : entered;
                  _dailyGoal = tempGoal;
                  _reminderMinutes = tempMinutes;
                  _celebratedToday = _currentWater >= _dailyGoal;
                });
                _startOrRestartTimer();
                _saveData();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _open30DayHistoryDialog() {
    final today = DateTime.now();
    final List<String> last30Dates = List.generate(30, (index) {
      final d = today.subtract(Duration(days: index));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    int completedDays = last30Dates
        .where((date) => (_historyMap[date] ?? 0) >= _dailyGoal)
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📅 30-Day Tracker'),
            Text(
              'Goals Hit: $completedDays / 30 days',
              style: TextStyle(fontSize: 13, color: Colors.green.shade700),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ListView.builder(
            itemCount: last30Dates.length,
            itemBuilder: (context, index) {
              final dateStr = last30Dates[index];
              final amount = _historyMap[dateStr] ?? 0;
              final hit = amount >= _dailyGoal;
              final label = index == 0 ? '$dateStr (Today)' : dateStr;

              return ListTile(
                dense: true,
                leading: Icon(
                  hit ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: hit ? Colors.green : Colors.grey,
                ),
                title: Text(label),
                trailing: Text(
                  '$amount / $_dailyGoal ml',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hit ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addWater(int amount) {
    setState(() {
      _currentWater += amount;
    });
    _saveData();

    if (_currentWater >= _dailyGoal && !_celebratedToday) {
      _celebratedToday = true;
      _showCelebrationDialog();
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 Congratulations, $_userName!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You hit your $_dailyGoal ml daily hydration goal! Keep up this awesome healthy streak.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🥗 Bonus Food Tip: Pair your hydration with fiber-rich veggies and lean protein at your next meal!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetWater() {
    setState(() {
      _currentWater = 0;
      _celebratedToday = false;
    });
    _saveData();
  }

  void _nextTip() {
    setState(() {
      _tipIndex = (_tipIndex + 1) % _dailyIdeas.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentWater / _dailyGoal).clamp(0.0, 1.0);
    int percentage = (progress * 100).round();
    bool goalReached = _currentWater >= _dailyGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HydroBuddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '30-Day Tracker',
            onPressed: _open30DayHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Today',
            onPressed: _resetWater,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $_userName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  tooltip: 'Settings',
                  onPressed: _openSettingsDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
                        Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dailyIdeas[_tipIndex]['category']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _nextTip,
                          child: const Text('Next Idea →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dailyIdeas[_tipIndex]['tip']!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'General wellness & nutrition tips only — not medical advice.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

