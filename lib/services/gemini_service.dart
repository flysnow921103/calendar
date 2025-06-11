import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiConfig.geminiApiKey,
    );
    _chat = _model.startChat();
  }

  Future<String> getResponse(String prompt) async {
    try {
      final response = await _chat.sendMessage(Content.text(prompt));
      return response.text ?? '無法獲取回應';
    } catch (e) {
      return '發生錯誤：$e';
    }
  }
}
