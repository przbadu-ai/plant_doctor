import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../models/chat_thread.dart';
import '../widgets/model_indicator.dart';
import 'home_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(langProvider.appTitle),
            const ModelIndicator(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingThreads) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.chatThreads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_florist_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getNoChatsMessage(langProvider),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                    child: Text(
                      _getStartChatMessage(langProvider),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: provider.chatThreads.length,
            itemBuilder: (context, index) {
              final thread = provider.chatThreads[index];
              return _ChatThreadListItem(
                thread: thread,
                onTap: () {
                  provider.loadChatThread(thread.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(threadId: thread.id),
                    ),
                  );
                },
                onDelete: () => _showDeleteConfirmation(context, provider, thread),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<AppProvider>().createNewThread();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(threadId: context.read<AppProvider>().currentThreadId),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(_getNewChatLabel(context.read<LanguageProvider>())),
      ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, AppProvider provider, ChatThread thread) {
    final langProvider = context.read<LanguageProvider>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getDeleteTitle(langProvider)),
          content: Text(_getDeleteMessage(langProvider)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(langProvider.cancel),
            ),
            TextButton(
              onPressed: () {
                provider.deleteThread(thread.id);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(_getDeleteLabel(langProvider)),
            ),
          ],
        );
      },
    );
  }
  
  String _getNoChatsMessage(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'No diagnosis history';
      case AppLanguage.spanish:
        return 'Sin historial de diagnósticos';
      case AppLanguage.hindi:
        return 'कोई निदान इतिहास नहीं';
    }
  }
  
  String _getStartChatMessage(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'Take or upload a photo of your plant to diagnose diseases';
      case AppLanguage.spanish:
        return 'Toma o sube una foto de tu planta para diagnosticar enfermedades';
      case AppLanguage.hindi:
        return 'बीमारियों का निदान करने के लिए अपने पौधे की फोटो लें या अपलोड करें';
    }
  }
  
  String _getNewChatLabel(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'New Diagnosis';
      case AppLanguage.spanish:
        return 'Nuevo Diagnóstico';
      case AppLanguage.hindi:
        return 'नया निदान';
    }
  }
  
  String _getDeleteTitle(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'Delete Chat?';
      case AppLanguage.spanish:
        return '¿Eliminar Chat?';
      case AppLanguage.hindi:
        return 'चैट हटाएं?';
    }
  }
  
  String _getDeleteMessage(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'This action cannot be undone.';
      case AppLanguage.spanish:
        return 'Esta acción no se puede deshacer.';
      case AppLanguage.hindi:
        return 'यह क्रिया पूर्ववत नहीं की जा सकती।';
    }
  }
  
  String _getDeleteLabel(LanguageProvider lang) {
    switch (lang.currentLanguage) {
      case AppLanguage.english:
        return 'Delete';
      case AppLanguage.spanish:
        return 'Eliminar';
      case AppLanguage.hindi:
        return 'हटाएं';
    }
  }
}

class _ChatThreadListItem extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const _ChatThreadListItem({
    required this.thread,
    required this.onTap,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Dismissible(
      key: Key(thread.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: thread.thumbnailImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    thread.thumbnailImage!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              : CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.local_florist,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
          title: Text(
            thread.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thread.lastMessage != null)
                Text(
                  thread.lastMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(
                dateFormat.format(thread.updatedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}