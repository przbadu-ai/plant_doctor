import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/chat_widget.dart';
import '../widgets/model_selector_widget.dart';
import '../widgets/model_indicator.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? threadId;
  
  const HomeScreen({super.key, this.threadId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.threadId != null) {
        context.read<AppProvider>().loadChatThread(widget.threadId!);
      }
    });
  }

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
                title: Text(context.read<LanguageProvider>().takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.read<LanguageProvider>().chooseFromGallery),
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
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      appBar: AppBar(
        leading: widget.threadId != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(langProvider.appTitle),
            const ModelIndicator(),
          ],
        ),
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
                tooltip: langProvider.toggleTheme,
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'models') {
                showDialog(
                  context: context,
                  builder: (context) => const ModelSelectorWidget(),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'new_chat') {
                final provider = Provider.of<AppProvider>(context, listen: false);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Start New Chat?'),
                    content: const Text('This will clear the current conversation. Your chat history will be saved.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('New Chat'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.createNewChat();
                }
              }
            },
            itemBuilder: (context) => [
              if (context.read<AppProvider>().messages.isNotEmpty)
                PopupMenuItem(
                  value: 'new_chat',
                  child: Row(
                    children: [
                      const Icon(Icons.add_comment_outlined),
                      const SizedBox(width: 12),
                      const Text('New Chat'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'models',
                child: Row(
                  children: [
                    const Icon(Icons.download_outlined),
                    const SizedBox(width: 12),
                    Text(langProvider.manageModels),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined),
                    const SizedBox(width: 12),
                    Text(langProvider.settings),
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
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                          langProvider.noModelDownloaded,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          langProvider.downloadModelMessage,
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
                        label: Text(langProvider.downloadModel),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          final status = await provider.getModelStatus();
                          final aiStatus = provider.getAIStatus();
                          final contextStatus = aiStatus['contextStatus'] as Map<String, dynamic>?;
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('AI Status'),
                              content: SingleChildScrollView(
                                child: Text(
                                  'Model Path: ${status['modelPath']}\n'
                                  'Model ID: ${status['modelId']}\n'
                                  'Model Exists: ${status['modelExists']}\n'
                                  'Is Model Ready: ${status['isModelReady']}\n\n'
                                  'Vision Status:\n'
                                  'Vision Available: ${aiStatus['isVisionAvailable']}\n'
                                  'Using Vision Mode: ${aiStatus['isUsingVisionMode']}\n'
                                  'Has Text Model: ${aiStatus['hasTextModel']}\n'
                                  'Has Vision Model: ${aiStatus['hasVisionModel']}\n\n'
                                  'Context Status:\n'
                                  'Messages: ${contextStatus?['messageCount']}/${contextStatus?['maxMessages']}\n'
                                  'Tokens: ~${contextStatus?['approximateTokens']}/${contextStatus?['maxTokens']}\n'
                                  'Near Limit: ${contextStatus?['isNearLimit']}\n'
                                  'Is Full: ${contextStatus?['isFull']}',
                                ),
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
                        child: const Text('Debug AI Status'),
                      ),
                    ],
                  ),
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
                          langProvider.downloadingModel,
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
              // Context warning banner
              if (provider.isContextNearLimit && !provider.isContextFull)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chat approaching limit. Consider starting a new chat for best performance.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Start New Chat?'),
                              content: const Text('This will clear the current conversation. Your chat history will be saved.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('New Chat'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            await provider.createNewChat();
                          }
                        },
                        child: const Text('New Chat'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.messages.isEmpty
                    ? _EmptyStateWidget(
                        onCameraPressed: () => _pickImage(ImageSource.camera),
                        onGalleryPressed: () => _pickImage(ImageSource.gallery),
                      )
                    : ChatWidget(messages: provider.messages),
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
                        onPressed: provider.isContextFull ? null : _showImageSourceDialog,
                        tooltip: provider.isContextFull ? 'Chat limit reached' : langProvider.addImage,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !provider.isContextFull,
                          decoration: InputDecoration(
                            hintText: provider.isContextFull 
                              ? 'Chat limit reached - Start a new chat' 
                              : langProvider.askAboutPlants,
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
                          onSubmitted: provider.isContextFull ? null : (text) {
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
                        onPressed: provider.isLoading || provider.isContextFull ? null : () {
                          final text = _messageController.text;
                          if (text.isNotEmpty) {
                            provider.sendMessage(text);
                            _messageController.clear();
                          }
                        },
                        tooltip: provider.isContextFull ? 'Chat limit reached' : langProvider.sendMessage,
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

class _EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;

  const _EmptyStateWidget({
    required this.onCameraPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Icon(
                Icons.local_florist_outlined,
                size: 60,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              langProvider.welcomeMessage,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              langProvider.getStartedMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _QuickActionCard(
                  icon: Icons.camera_alt_outlined,
                  title: langProvider.takePhoto,
                  subtitle: langProvider.takePhotoHint,
                  onTap: onCameraPressed,
                  color: theme.colorScheme.primary,
                ),
                _QuickActionCard(
                  icon: Icons.photo_library_outlined,
                  title: langProvider.chooseFromGallery,
                  subtitle: langProvider.choosePhotoHint,
                  onTap: onGalleryPressed,
                  color: theme.colorScheme.secondary,
                ),
                _QuickActionCard(
                  icon: Icons.eco_outlined,
                  title: langProvider.askQuestion,
                  subtitle: langProvider.askQuestionHint,
                  onTap: null,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      langProvider.tipMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
