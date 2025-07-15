import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../widgets/chat_widget.dart';
import '../widgets/model_selector_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          context.read<AppProvider>().analyzePlantImage(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Doctor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ModelSelectorWidget(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<AppProvider>().clearChat();
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (!provider.isModelReady && !provider.isDownloading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.error != null) ...[
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Model Initialization Failed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.download_for_offline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No AI model downloaded',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Download a model to start diagnosing plant diseases',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ModelSelectorWidget(),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Model'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        final status = await provider.getModelStatus();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Model Status'),
                            content: Text(
                              'Model Path: ${status['modelPath']}\n'
                              'Model ID: ${status['modelId']}\n'
                              'Model Exists: ${status['modelExists']}\n'
                              'Is Model Ready: ${status['isModelReady']}\n'
                              'Current Model ID: ${status['currentModelId']}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Debug Model Status'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.isDownloading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SizedBox(
                    //   width: 200,
                    //   height: 200,
                    //   child: CircularProgressIndicator(
                    //     value: provider.downloadProgress > 0 ? provider.downloadProgress : null,
                    //     strokeWidth: 8,
                    //   ),
                    // ),
                    // const SizedBox(height: 32),
                    Text(
                      'Downloading Model',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.downloadStatus.isNotEmpty 
                        ? provider.downloadStatus 
                        : 'Preparing download...',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (provider.downloadProgress > 0) ...[
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: provider.downloadProgress,
                        minHeight: 8,
                      ),
                    ],
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ChatWidget(messages: provider.messages),
              ),
              if (provider.isLoading)
                const LinearProgressIndicator(),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _showImageSourceDialog,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about plant diseases...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.isNotEmpty) {
                            provider.sendMessage(text);
                            _messageController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        final text = _messageController.text;
                        if (text.isNotEmpty) {
                          provider.sendMessage(text);
                          _messageController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}