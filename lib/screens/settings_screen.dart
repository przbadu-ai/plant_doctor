import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/model_selector_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(langProvider.settings),
          ),
          body: ListView(
            children: [
              // Language Section
              _SectionHeader(title: langProvider.language),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: AppLanguage.values.map((language) {
                    return RadioListTile<AppLanguage>(
                      title: Text(language.displayName),
                      subtitle: Text(_getLanguageSubtitle(language, langProvider)),
                      value: language,
                      groupValue: langProvider.currentLanguage,
                      onChanged: (value) {
                        if (value != null) {
                          langProvider.setLanguage(value);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              
              // Theme Section
              _SectionHeader(title: langProvider.theme),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text(_getThemeTitle(ThemeMode.system, langProvider)),
                          secondary: const Icon(Icons.brightness_auto),
                          value: ThemeMode.system,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(_getThemeTitle(ThemeMode.light, langProvider)),
                          secondary: const Icon(Icons.light_mode),
                          value: ThemeMode.light,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(_getThemeTitle(ThemeMode.dark, langProvider)),
                          secondary: const Icon(Icons.dark_mode),
                          value: ThemeMode.dark,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Models Section
              _SectionHeader(title: langProvider.manageModels),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(langProvider.manageModels),
                  subtitle: Text(_getManageModelsSubtitle(langProvider)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ModelSelectorWidget(),
                    );
                  },
                ),
              ),
              
              // About Section
              _SectionHeader(title: langProvider.about),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Doctor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getAboutText(langProvider),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      const Text('Version: 1.0.0'),
                      const SizedBox(height: 8),
                      Text(_getPoweredByText(langProvider)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
  
  String _getLanguageSubtitle(AppLanguage language, LanguageProvider provider) {
    switch (language) {
      case AppLanguage.english:
        return provider.currentLanguage == AppLanguage.english ? 'Default language' : 'Idioma predeterminado';
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.hindi:
        return 'हिन्दी';
    }
  }
  
  String _getThemeTitle(ThemeMode mode, LanguageProvider provider) {
    switch (mode) {
      case ThemeMode.system:
        return provider.currentLanguage == AppLanguage.english ? 'System' :
               provider.currentLanguage == AppLanguage.spanish ? 'Sistema' : 'सिस्टम';
      case ThemeMode.light:
        return provider.currentLanguage == AppLanguage.english ? 'Light' :
               provider.currentLanguage == AppLanguage.spanish ? 'Claro' : 'प्रकाश';
      case ThemeMode.dark:
        return provider.currentLanguage == AppLanguage.english ? 'Dark' :
               provider.currentLanguage == AppLanguage.spanish ? 'Oscuro' : 'अंधेरा';
    }
  }
  
  String _getManageModelsSubtitle(LanguageProvider provider) {
    switch (provider.currentLanguage) {
      case AppLanguage.english:
        return 'Download and manage AI models';
      case AppLanguage.spanish:
        return 'Descargar y gestionar modelos de IA';
      case AppLanguage.hindi:
        return 'AI मॉडल डाउनलोड और प्रबंधित करें';
    }
  }
  
  String _getAboutText(LanguageProvider provider) {
    switch (provider.currentLanguage) {
      case AppLanguage.english:
        return 'Plant Doctor is an AI-powered app for identifying plant diseases and providing treatment recommendations. It uses advanced machine learning models to analyze plant symptoms and suggest appropriate remedies.';
      case AppLanguage.spanish:
        return 'Plant Doctor es una aplicación impulsada por IA para identificar enfermedades de plantas y proporcionar recomendaciones de tratamiento. Utiliza modelos avanzados de aprendizaje automático para analizar síntomas de plantas y sugerir remedios apropiados.';
      case AppLanguage.hindi:
        return 'Plant Doctor पौधों की बीमारियों की पहचान करने और उपचार की सिफारिशें प्रदान करने के लिए एक AI-संचालित ऐप है। यह पौधों के लक्षणों का विश्लेषण करने और उपयुक्त उपचार सुझाने के लिए उन्नत मशीन लर्निंग मॉडल का उपयोग करता है।';
    }
  }
  
  String _getPoweredByText(LanguageProvider provider) {
    switch (provider.currentLanguage) {
      case AppLanguage.english:
        return 'Powered by Google Gemma';
      case AppLanguage.spanish:
        return 'Desarrollado con Google Gemma';
      case AppLanguage.hindi:
        return 'Google Gemma द्वारा संचालित';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}