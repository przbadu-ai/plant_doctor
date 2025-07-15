import 'package:flutter/material.dart';
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
    return AlertDialog(
      title: const Text('Hugging Face Token Required'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To download Gemma 3n models, you need a Hugging Face token.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Get your token from:',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                labelText: 'Token',
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
                  return 'Please enter your token';
                }
                if (!value.startsWith('hf_')) {
                  return 'Token should start with hf_';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Your token will be stored securely on this device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
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
          child: const Text('Save Token'),
        ),
      ],
    );
  }
}