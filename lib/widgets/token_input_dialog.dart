import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/secure_config_service.dart';

class TokenInputDialog extends StatefulWidget {
  const TokenInputDialog({super.key});

  @override
  State<TokenInputDialog> createState() => _TokenInputDialogState();
}

class _TokenInputDialogState extends State<TokenInputDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    
    return AlertDialog(
      title: Text(langProvider.huggingFaceTokenRequired),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              langProvider.tokenRequiredMessage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              langProvider.getTokenFrom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SelectableText(
              'https://huggingface.co/settings/tokens',
              style: TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: langProvider.token,
                hintText: 'hf_xxxxxxxxxxxxxxxxxxxx',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return langProvider.pleaseEnterToken;
                }
                if (!value.startsWith('hf_')) {
                  return langProvider.tokenShouldStartWith;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              langProvider.tokenStoredSecurely,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(langProvider.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await SecureConfigService().saveToken(_controller.text);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            }
          },
          child: Text(langProvider.saveToken),
        ),
      ],
    );
  }
}