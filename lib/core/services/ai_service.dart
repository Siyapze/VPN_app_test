import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_models.dart';

/// OpenRouter AI service for chat completions
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKeyKey = 'openrouter_api_key';
  static const String _defaultModelKey = 'default_ai_model';
  static const String _conversationsKey = 'ai_conversations';

  String? _apiKey;
  AIModel _defaultModel = AIModel.gpt4oMini;
  final List<AIConversation> _conversations = [];

  /// Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);

    final modelId = prefs.getString(_defaultModelKey);
    if (modelId != null) {
      _defaultModel = AIModel.fromId(modelId) ?? AIModel.gpt4oMini;
    }

    await _loadConversations();
  }

  /// Set API key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  /// Get API key
  String? get apiKey => _apiKey;

  /// Check if API key is set
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Set default model
  Future<void> setDefaultModel(AIModel model) async {
    _defaultModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultModelKey, model.id);
  }

  /// Get default model
  AIModel get defaultModel => _defaultModel;

  /// Get all conversations
  List<AIConversation> get conversations => List.unmodifiable(_conversations);

  /// Send a prompt to AI
  Future<AIResponse> sendPrompt({
    required String prompt,
    AIModel? model,
    AIRequestConfig? config,
    List<AIMessage>? context,
    String? systemPrompt,
  }) async {
    if (!hasApiKey) {
      throw Exception(
        'OpenRouter API key not set. Please configure it in settings.',
      );
    }

    final selectedModel = model ?? _defaultModel;
    final requestConfig = config ?? AIRequestConfig.balanced;

    // Build messages
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (context != null) {
      for (final msg in context) {
        messages.add({'role': msg.role, 'content': msg.content});
      }
    }

    messages.add({'role': 'user', 'content': prompt});

    // Prepare request
    final requestBody = {
      'model': selectedModel.id,
      'messages': messages,
      'temperature': requestConfig.temperature,
      'max_tokens': requestConfig.maxTokens,
      'top_p': requestConfig.topP,
      'frequency_penalty': requestConfig.frequencyPenalty,
      'presence_penalty': requestConfig.presencePenalty,
      if (requestConfig.stop != null) 'stop': requestConfig.stop,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://stressless-vpn.app',
          'X-Title': 'StressLess VPN',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResponse(data, selectedModel);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'OpenRouter API error: ${error['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      throw Exception('Failed to send prompt: $e');
    }
  }

  /// Send message in conversation
  Future<AIResponse> sendMessage({
    required String conversationId,
    required String message,
    AIRequestConfig? config,
  }) async {
    final conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final userMessage = AIMessage.user(message);
    final updatedConversation = conversation.addMessage(userMessage);
    await _updateConversation(updatedConversation);

    try {
      final response = await sendPrompt(
        prompt: message,
        model: conversation.model,
        config: config,
        context: conversation.messages,
      );

      final assistantMessage = AIMessage.assistant(response.content);
      final finalConversation = updatedConversation.addMessage(
        assistantMessage,
      );
      await _updateConversation(finalConversation);

      return response;
    } catch (e) {
      // Remove the user message if the request failed
      await _updateConversation(conversation);
      rethrow;
    }
  }

  /// Create new conversation
  Future<AIConversation> createConversation({
    required String title,
    AIModel? model,
    String? systemPrompt,
    Map<String, dynamic>? settings,
  }) async {
    final conversation = AIConversation.create(
      title: title,
      model: model ?? _defaultModel,
      systemPrompt: systemPrompt,
      settings: settings,
    );

    _conversations.insert(0, conversation);
    await _saveConversations();
    return conversation;
  }

  /// Get conversation by ID
  AIConversation? getConversation(String id) {
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update conversation
  Future<void> updateConversation(AIConversation conversation) async {
    await _updateConversation(conversation);
  }

  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((conv) => conv.id == id);
    await _saveConversations();
  }

  /// Clear all conversations
  Future<void> clearAllConversations() async {
    _conversations.clear();
    await _saveConversations();
  }

  /// Test API key
  Future<bool> testApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get available models from OpenRouter
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    if (!hasApiKey) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    return [];
  }

  /// Parse OpenRouter response
  AIResponse _parseResponse(Map<String, dynamic> data, AIModel model) {
    final choice = data['choices'][0];
    final usage = data['usage'];

    return AIResponse(
      id: data['id'],
      content: choice['message']['content'],
      model: model,
      inputTokens: usage['prompt_tokens'] ?? 0,
      outputTokens: usage['completion_tokens'] ?? 0,
      cost: model.calculateCost(
        usage['prompt_tokens'] ?? 0,
        usage['completion_tokens'] ?? 0,
      ),
      timestamp: DateTime.now(),
      metadata: {
        'finish_reason': choice['finish_reason'],
        'total_tokens': usage['total_tokens'],
      },
    );
  }

  /// Update conversation in list
  Future<void> _updateConversation(AIConversation conversation) async {
    final index = _conversations.indexWhere(
      (conv) => conv.id == conversation.id,
    );
    if (index != -1) {
      _conversations[index] = conversation;
      await _saveConversations();
    }
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = prefs.getStringList(_conversationsKey) ?? [];

      _conversations.clear();
      for (final jsonStr in conversationsJson) {
        final conversation = AIConversation.fromJson(jsonDecode(jsonStr));
        _conversations.add(conversation);
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson =
          _conversations.map((conv) => jsonEncode(conv.toJson())).toList();

      await prefs.setStringList(_conversationsKey, conversationsJson);
    } catch (e) {
      print('Error saving conversations: $e');
    }
  }
}
