import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ModelSelectorWidget extends StatelessWidget {
  const ModelSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Select AI Model'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: provider.availableModels.map((model) {
                final isCurrentModel = model.id == provider.currentModelId;
                final sizeInMB = (model.size / 1024 / 1024).round();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(model.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(model.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              model.supportsVision ? Icons.visibility : Icons.text_fields,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              model.supportsVision ? 'Vision Support' : 'Text Only',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.storage, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$sizeInMB MB',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isCurrentModel
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: isCurrentModel
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            await provider.downloadModel(model.id);
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}