import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final int _dailyGoal = 2500;
  int _tipIndex = 0;
  bool _celebratedToday = false;
  bool _reminderOn = false;
  Timer? _reminderTimer;

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
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _toggleReminder(bool value) {
    setState(() {
      _reminderOn = value;
    });
    _reminderTimer?.cancel();
    if (_reminderOn) {
      _reminderTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _triggerWaterAlarm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Hourly water reminder turned ON!'),
          duration: Duration(seconds: 2),
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

  void _editNameDialog() {
    final TextEditingController nameController =
        TextEditingController(text: _userName == 'Friend' ? '' : _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Rahul, Priya',
            border: OutlineInputBorder(),
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
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addWater(int amount) {
    setState(() {
      _currentWater += amount;
    });

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
            const Text(
              'You hit your 2,500 ml daily hydration goal! Keep up this awesome healthy streak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
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
        title: const Text('HydroBuddy & Wellness'),
        centerTitle: true,
        actions: [
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
                  tooltip: 'Edit Name',
                  onPressed: _editNameDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: _reminderOn ? Colors.orange.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _reminderOn ? Icons.alarm_on : Icons.alarm_off,
                          color: _reminderOn ? Colors.orange.shade800 : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hourly Reminder',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Testing alarm in 5 seconds...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Future.delayed(
                              const Duration(seconds: 5),
                              _triggerWaterAlarm,
                            );
                          },
                          child: const Text('Test 5s'),
                        ),
                        Switch(
                          value: _reminderOn,
                          onChanged: _toggleReminder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (goalReached)
