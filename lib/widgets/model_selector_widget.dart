import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/secure_config_service.dart';
import 'token_input_dialog.dart';

class ModelSelectorWidget extends StatelessWidget {
  const ModelSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select AI Model',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: provider.availableModels.map((model) {
                final isCurrentModel = model.id == provider.currentModelId;
                final sizeInMB = model.estimatedSize != null 
                    ? (model.estimatedSize! / 1024 / 1024).round()
                    : null;
                
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
                              sizeInMB != null ? '$sizeInMB MB' : 'Size TBD',
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
                            // Check if token is needed for HuggingFace models
                            if (model.url.contains('huggingface.co') && 
                                !SecureConfigService().hasToken) {
                              Navigator.of(context).pop();
                              final tokenSaved = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const TokenInputDialog(),
                              );
                              if (tokenSaved == true) {
                                await provider.downloadModel(model.id);
                              }
                            } else {
                              Navigator.of(context).pop();
                              await provider.downloadModel(model.id);
                            }
                          },
                  ),
                );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}