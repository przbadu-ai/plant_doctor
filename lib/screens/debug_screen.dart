import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  Future<void> _clearAllModelData(BuildContext context) async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_model_path');
      await prefs.remove('current_model_id');
      
      // Clear all model files
      final dir = await getApplicationDocumentsDirectory();
      
      // Clear models directory
      final modelsDir = Directory('${dir.path}/models');
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
      }
      
      // Clear any .task files in root directory (iOS)
      final files = await dir.list().toList();
      for (var file in files) {
        if (file is File && file.path.endsWith('.task')) {
          await file.delete();
          Logger.log('Deleted: ${file.path}');
        }
        // Also delete XNNPack cache files
        if (file is File && file.path.contains('xnnpack_cache')) {
          await file.delete();
          Logger.log('Deleted cache: ${file.path}');
        }
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All model data cleared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Model Data'),
              subtitle: const Text('Removes all downloaded models and cache'),
              onTap: () => _showConfirmDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Model Data?'),
        content: const Text(
          'This will delete all downloaded models and cache files. '
          'You will need to download models again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllModelData(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}