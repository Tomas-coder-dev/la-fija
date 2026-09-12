import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider((ref) => AIService());

class AIService {
  // IMPORTANTE: Por seguridad de GitHub, no podemos quemar la llave aquí.
  // Ahora se lee desde las variables de entorno al compilar.
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0, // Necesitamos respuestas deterministas y precisas
        responseMimeType: 'application/json', // Structured output
      ),
    );
  }

  /// Procesa un texto hablado y devuelve los datos estructurados
  Future<Map<String, dynamic>?> parseExpenseVoice({
    required String text,
    required List<String> availableCards,
    required List<String> availableCategories,
  }) async {
    try {
      final prompt = '''
Eres un asistente financiero experto. El usuario dictó la siguiente frase para registrar un gasto:
"$text"

Tu tarea es extraer los datos clave y devolver ÚNICAMENTE un JSON válido con esta estructura exacta:
{
  "monto": 0.0,
  "categoria": "...",
  "tarjeta_id": "..." 
}

Reglas:
1. Opciones permitidas para 'categoria': $availableCategories
2. Opciones permitidas para 'tarjeta_id' (bancos): $availableCards
3. Si el monto tiene céntimos o es dictado (ej. "cuarenta con cincuenta"), conviértelo a número (40.5).
4. Si no puedes deducir la tarjeta, devuelve null para 'tarjeta_id'.
5. Si no puedes deducir el monto, devuelve null para 'monto'.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        return jsonDecode(response.text!) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error parsing voice with Gemini: $e');
      return null;
    }
  }
}
