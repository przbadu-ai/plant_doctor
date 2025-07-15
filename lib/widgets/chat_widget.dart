import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class ChatWidget extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatWidget({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(message: message);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasImage)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
            if (message.hasAnalysis)
              _AnalysisCard(analysis: message.analysis!),
            DefaultTextStyle(
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  h1: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  code: TextStyle(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: (isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant)
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _AnalysisCard extends StatelessWidget {
  final PlantDiseaseAnalysis analysis;

  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_florist, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Plant: ${analysis.plantType}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Health Status: ${analysis.healthStatus}'),
            if (analysis.diseases.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Detected Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...analysis.diseases.map((disease) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${disease.name} (${(disease.confidence * 100).toStringAsFixed(1)}% confidence)',
                        ),
                        Text(
                          '  Severity: ${disease.severity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSeverityColor(disease.severity),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...analysis.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $rec'),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.orange;
      case 'moderate':
        return Colors.deepOrange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}