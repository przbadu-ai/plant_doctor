import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashTestButton extends StatelessWidget {
  const CrashTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Test Crash Reporting',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Crash Reporting'),
            content: const Text('This will send a test crash to Firebase Crashlytics. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _testCrash();
                },
                child: const Text('Test Crash'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _testCrash() {
    FirebaseCrashlytics.instance.log('Testing crash reporting');
    FirebaseCrashlytics.instance.setCustomKey('test_key', 'test_value');
    
    // Force a crash
    FirebaseCrashlytics.instance.crash();
  }
}