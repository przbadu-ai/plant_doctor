import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
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
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : themeProvider.themeMode == ThemeMode.light
                          ? Icons.dark_mode
                          : Icons.brightness_auto,
                ),
                tooltip: 'Toggle theme',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Clear chat',
            onPressed: () {
              context.read<AppProvider>().clearChat();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'models') {
                showDialog(
                  context: context,
                  builder: (context) => const ModelSelectorWidget(),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'models',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined),
                    SizedBox(width: 12),
                    Text('Manage Models'),
                  ],
                ),
              ),
            ],
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Model Initialization Failed',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.download_for_offline_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No AI model downloaded',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download a model to start diagnosing plant diseases',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                        if (!context.mounted) return;
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
              child: Container(
                padding: const EdgeInsets.all(32.0),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Downloading Model',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.downloadStatus.isNotEmpty 
                            ? provider.downloadStatus 
                            : 'Preparing download...',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (provider.downloadProgress > 0) ...[
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: provider.downloadProgress,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(provider.downloadProgress * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(12.0),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        onPressed: _showImageSourceDialog,
                        tooltip: 'Add image',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask about plant diseases...',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
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
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: provider.isLoading ? null : () {
                          final text = _messageController.text;
                          if (text.isNotEmpty) {
                            provider.sendMessage(text);
                            _messageController.clear();
                          }
                        },
                        tooltip: 'Send message',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}