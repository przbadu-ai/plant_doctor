import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  spanish('es', 'Español'),
  hindi('hi', 'हिन्दी');

  final String code;
  final String displayName;
  
  const AppLanguage(this.code, this.displayName);
  
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.english;
  
  AppLanguage get currentLanguage => _currentLanguage;
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _currentLanguage = AppLanguage.fromCode(languageCode);
    notifyListeners();
  }
  
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }
  
  String getLocalizedPrompt(String key) {
    switch (key) {
      case 'welcome':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return 'Welcome to PlantDoctor! I can help you identify plant diseases, suggest treatments, and answer farming questions. Upload a photo of your plant or ask me anything!';
          case AppLanguage.spanish:
            return '¡Bienvenido a PlantDoctor! Puedo ayudarte a identificar enfermedades de plantas, sugerir tratamientos y responder preguntas sobre agricultura. ¡Sube una foto de tu planta o pregúntame lo que quieras!';
          case AppLanguage.hindi:
            return 'PlantDoctor में आपका स्वागत है! मैं पौधों की बीमारियों की पहचान करने, उपचार सुझाने और खेती के सवालों के जवाब देने में आपकी मदद कर सकता हूं। अपने पौधे की फोटो अपलोड करें या मुझसे कुछ भी पूछें!';
        }
      case 'chat_cleared':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return 'Chat cleared. How can I help you with your plants today?';
          case AppLanguage.spanish:
            return 'Chat borrado. ¿Cómo puedo ayudarte con tus plantas hoy?';
          case AppLanguage.hindi:
            return 'चैट साफ़ हो गई। आज मैं आपके पौधों के बारे में आपकी कैसे मदद कर सकता हूं?';
        }
      case 'analyze_plant':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return 'Analyze this plant for diseases';
          case AppLanguage.spanish:
            return 'Analizar esta planta para enfermedades';
          case AppLanguage.hindi:
            return 'बीमारियों के लिए इस पौधे का विश्लेषण करें';
        }
      case 'ai_role':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return '''You are PlantDoctor AI, an expert in plant diseases and agricultural practices. 
      Your role is to:
      1. Identify plant diseases from descriptions
      2. Provide detailed analysis of symptoms
      3. Suggest organic and chemical remedies
      4. Give preventive measures
      5. Answer farming-related questions
      
      Always be helpful, accurate, and provide practical advice for farmers. Respond in English.''';
          case AppLanguage.spanish:
            return '''Eres PlantDoctor AI, un experto en enfermedades de plantas y prácticas agrícolas.
      Tu rol es:
      1. Identificar enfermedades de plantas a partir de descripciones
      2. Proporcionar análisis detallado de síntomas
      3. Sugerir remedios orgánicos y químicos
      4. Dar medidas preventivas
      5. Responder preguntas relacionadas con la agricultura
      
      Siempre sé útil, preciso y proporciona consejos prácticos para los agricultores. Responde en español.''';
          case AppLanguage.hindi:
            return '''आप PlantDoctor AI हैं, पौधों की बीमारियों और कृषि प्रथाओं के विशेषज्ञ।
      आपकी भूमिका है:
      1. विवरण से पौधों की बीमारियों की पहचान करना
      2. लक्षणों का विस्तृत विश्लेषण प्रदान करना
      3. जैविक और रासायनिक उपचार सुझाना
      4. निवारक उपाय देना
      5. खेती से संबंधित प्रश्नों का उत्तर देना
      
      हमेशा मददगार, सटीक रहें और किसानों के लिए व्यावहारिक सलाह दें। हिंदी में जवाब दें।''';
        }
      case 'image_analysis_prompt':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return '''I have uploaded an image of a plant that may have disease issues. 
        Since I cannot process images directly, please help me by:
        
        1. Asking me to describe what I see in the plant (color changes, spots, wilting, etc.)
        2. Based on my description, identify possible diseases
        3. Suggest treatments and preventive measures
        
        Please start by asking me to describe the plant's symptoms.''';
          case AppLanguage.spanish:
            return '''He subido una imagen de una planta que puede tener problemas de enfermedades.
        Como no puedo procesar imágenes directamente, por favor ayúdame:
        
        1. Pidiéndome que describa lo que veo en la planta (cambios de color, manchas, marchitamiento, etc.)
        2. Basándote en mi descripción, identifica posibles enfermedades
        3. Sugiere tratamientos y medidas preventivas
        
        Por favor, empieza pidiéndome que describa los síntomas de la planta.''';
          case AppLanguage.hindi:
            return '''मैंने एक पौधे की तस्वीर अपलोड की है जिसमें बीमारी की समस्या हो सकती है।
        चूंकि मैं सीधे तस्वीरों को प्रोसेस नहीं कर सकता, कृपया मेरी मदद करें:
        
        1. मुझसे पूछें कि मैं पौधे में क्या देख रहा हूं (रंग परिवर्तन, धब्बे, मुरझाना, आदि)
        2. मेरे विवरण के आधार पर, संभावित बीमारियों की पहचान करें
        3. उपचार और निवारक उपाय सुझाएं
        
        कृपया मुझसे पौधे के लक्षणों का वर्णन करने के लिए कहकर शुरू करें।''';
        }
      case 'error_message':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return 'Sorry, I encountered an error. Please try again.';
          case AppLanguage.spanish:
            return 'Lo siento, encontré un error. Por favor, inténtalo de nuevo.';
          case AppLanguage.hindi:
            return 'क्षमा करें, मुझे एक त्रुटि का सामना करना पड़ा। कृपया पुनः प्रयास करें।';
        }
      case 'image_upload_help':
        switch (_currentLanguage) {
          case AppLanguage.english:
            return '''I see you've uploaded an image. While I cannot directly analyze images, I can still help you identify plant diseases!

Please describe what you see:
• What type of plant is it?
• What color are the affected areas?
• Are there spots, wilting, or discoloration?
• Which parts are affected (leaves, stems, roots)?
• How widespread is the problem?

The more details you provide, the better I can help diagnose and suggest treatments.''';
          case AppLanguage.spanish:
            return '''Veo que has subido una imagen. Aunque no puedo analizar imágenes directamente, ¡aún puedo ayudarte a identificar enfermedades de plantas!

Por favor describe lo que ves:
• ¿Qué tipo de planta es?
• ¿De qué color son las áreas afectadas?
• ¿Hay manchas, marchitamiento o decoloración?
• ¿Qué partes están afectadas (hojas, tallos, raíces)?
• ¿Qué tan extendido está el problema?

Cuantos más detalles proporciones, mejor podré ayudar a diagnosticar y sugerir tratamientos.''';
          case AppLanguage.hindi:
            return '''मैं देख रहा हूं कि आपने एक तस्वीर अपलोड की है। हालांकि मैं सीधे तस्वीरों का विश्लेषण नहीं कर सकता, फिर भी मैं पौधों की बीमारियों की पहचान करने में आपकी मदद कर सकता हूं!

कृपया बताएं कि आप क्या देख रहे हैं:
• यह किस प्रकार का पौधा है?
• प्रभावित क्षेत्र किस रंग के हैं?
• क्या धब्बे, मुरझाना या रंग बदलना है?
• कौन से हिस्से प्रभावित हैं (पत्तियां, तने, जड़ें)?
• समस्या कितनी व्यापक है?

जितने अधिक विवरण आप प्रदान करेंगे, उतना बेहतर मैं निदान करने और उपचार सुझाने में मदद कर सकूंगा।''';
        }
      default:
        return key;
    }
  }
  
  // UI Translations
  String get appTitle => _currentLanguage == AppLanguage.english ? 'Plant Doctor' :
                         _currentLanguage == AppLanguage.spanish ? 'Doctor de Plantas' : 'पौधा डॉक्टर';
  
  String get settings => _currentLanguage == AppLanguage.english ? 'Settings' :
                        _currentLanguage == AppLanguage.spanish ? 'Configuración' : 'सेटिंग्स';
  
  String get language => _currentLanguage == AppLanguage.english ? 'Language' :
                        _currentLanguage == AppLanguage.spanish ? 'Idioma' : 'भाषा';
  
  String get theme => _currentLanguage == AppLanguage.english ? 'Theme' :
                     _currentLanguage == AppLanguage.spanish ? 'Tema' : 'थीम';
  
  String get about => _currentLanguage == AppLanguage.english ? 'About' :
                     _currentLanguage == AppLanguage.spanish ? 'Acerca de' : 'के बारे में';
  
  String get manageModels => _currentLanguage == AppLanguage.english ? 'Manage Models' :
                            _currentLanguage == AppLanguage.spanish ? 'Gestionar Modelos' : 'मॉडल प्रबंधित करें';
  
  String get clearChat => _currentLanguage == AppLanguage.english ? 'Clear chat' :
                         _currentLanguage == AppLanguage.spanish ? 'Borrar chat' : 'चैट साफ़ करें';
  
  String get toggleTheme => _currentLanguage == AppLanguage.english ? 'Toggle theme' :
                           _currentLanguage == AppLanguage.spanish ? 'Cambiar tema' : 'थीम बदलें';
  
  String get askAboutPlants => _currentLanguage == AppLanguage.english ? 'Ask about plant diseases...' :
                              _currentLanguage == AppLanguage.spanish ? 'Pregunta sobre enfermedades de plantas...' : 
                              'पौधों की बीमारियों के बारे में पूछें...';
  
  String get addImage => _currentLanguage == AppLanguage.english ? 'Add image' :
                        _currentLanguage == AppLanguage.spanish ? 'Añadir imagen' : 'तस्वीर जोड़ें';
  
  String get sendMessage => _currentLanguage == AppLanguage.english ? 'Send message' :
                           _currentLanguage == AppLanguage.spanish ? 'Enviar mensaje' : 'संदेश भेजें';
  
  String get takePhoto => _currentLanguage == AppLanguage.english ? 'Take Photo' :
                         _currentLanguage == AppLanguage.spanish ? 'Tomar Foto' : 'फोटो लें';
  
  String get chooseFromGallery => _currentLanguage == AppLanguage.english ? 'Choose from Gallery' :
                                 _currentLanguage == AppLanguage.spanish ? 'Elegir de la Galería' : 'गैलरी से चुनें';
  
  String get noModelDownloaded => _currentLanguage == AppLanguage.english ? 'No AI model downloaded' :
                                 _currentLanguage == AppLanguage.spanish ? 'No hay modelo de IA descargado' : 'कोई AI मॉडल डाउनलोड नहीं किया गया';
  
  String get downloadModelMessage => _currentLanguage == AppLanguage.english ? 'Download a model to start diagnosing plant diseases' :
                                    _currentLanguage == AppLanguage.spanish ? 'Descarga un modelo para empezar a diagnosticar enfermedades de plantas' : 
                                    'पौधों की बीमारियों का निदान शुरू करने के लिए एक मॉडल डाउनलोड करें';
  
  String get downloadModel => _currentLanguage == AppLanguage.english ? 'Download Model' :
                             _currentLanguage == AppLanguage.spanish ? 'Descargar Modelo' : 'मॉडल डाउनलोड करें';
  
  String get downloadingModel => _currentLanguage == AppLanguage.english ? 'Downloading Model' :
                                _currentLanguage == AppLanguage.spanish ? 'Descargando Modelo' : 'मॉडल डाउनलोड हो रहा है';
  
  String get close => _currentLanguage == AppLanguage.english ? 'Close' :
                     _currentLanguage == AppLanguage.spanish ? 'Cerrar' : 'बंद करें';
  
  String get selectAIModel => _currentLanguage == AppLanguage.english ? 'Select AI Model' :
                             _currentLanguage == AppLanguage.spanish ? 'Seleccionar Modelo de IA' : 'AI मॉडल चुनें';
  
  String get visionSupport => _currentLanguage == AppLanguage.english ? 'Vision Support' :
                             _currentLanguage == AppLanguage.spanish ? 'Soporte de Visión' : 'दृष्टि समर्थन';
  
  String get textOnly => _currentLanguage == AppLanguage.english ? 'Text Only' :
                        _currentLanguage == AppLanguage.spanish ? 'Solo Texto' : 'केवल टेक्स्ट';
  
  String get sizeTBD => _currentLanguage == AppLanguage.english ? 'Size TBD' :
                       _currentLanguage == AppLanguage.spanish ? 'Tamaño por determinar' : 'आकार निर्धारित नहीं';
  
  String get huggingFaceTokenRequired => _currentLanguage == AppLanguage.english ? 'Hugging Face Token Required' :
                                        _currentLanguage == AppLanguage.spanish ? 'Se requiere token de Hugging Face' : 'Hugging Face टोकन आवश्यक है';
  
  String get tokenRequiredMessage => _currentLanguage == AppLanguage.english ? 'To download Gemma 3n models, you need a Hugging Face token.' :
                                    _currentLanguage == AppLanguage.spanish ? 'Para descargar modelos Gemma 3n, necesitas un token de Hugging Face.' : 
                                    'Gemma 3n मॉडल डाउनलोड करने के लिए, आपको Hugging Face टोकन की आवश्यकता है।';
  
  String get getTokenFrom => _currentLanguage == AppLanguage.english ? 'Get your token from:' :
                            _currentLanguage == AppLanguage.spanish ? 'Obtén tu token de:' : 'अपना टोकन यहाँ से प्राप्त करें:';
  
  String get token => _currentLanguage == AppLanguage.english ? 'Token' :
                     _currentLanguage == AppLanguage.spanish ? 'Token' : 'टोकन';
  
  String get pleaseEnterToken => _currentLanguage == AppLanguage.english ? 'Please enter your token' :
                                _currentLanguage == AppLanguage.spanish ? 'Por favor ingresa tu token' : 'कृपया अपना टोकन दर्ज करें';
  
  String get tokenShouldStartWith => _currentLanguage == AppLanguage.english ? 'Token should start with hf_' :
                                    _currentLanguage == AppLanguage.spanish ? 'El token debe comenzar con hf_' : 'टोकन hf_ से शुरू होना चाहिए';
  
  String get tokenStoredSecurely => _currentLanguage == AppLanguage.english ? 'Your token will be stored securely on this device.' :
                                   _currentLanguage == AppLanguage.spanish ? 'Tu token se almacenará de forma segura en este dispositivo.' : 
                                   'आपका टोकन इस डिवाइस पर सुरक्षित रूप से संग्रहीत किया जाएगा।';
  
  String get cancel => _currentLanguage == AppLanguage.english ? 'Cancel' :
                      _currentLanguage == AppLanguage.spanish ? 'Cancelar' : 'रद्द करें';
  
  String get saveToken => _currentLanguage == AppLanguage.english ? 'Save Token' :
                         _currentLanguage == AppLanguage.spanish ? 'Guardar Token' : 'टोकन सहेजें';
}