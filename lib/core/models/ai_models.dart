import 'package:json_annotation/json_annotation.dart';

part 'ai_models.g.dart';

/// Available AI models for OpenRouter
enum AIModel {
  @JsonValue('openai/gpt-4o')
  gpt4o('openai/gpt-4o', 'GPT-4o', 'OpenAI', 0.005, 0.015),
  
  @JsonValue('openai/gpt-4o-mini')
  gpt4oMini('openai/gpt-4o-mini', 'GPT-4o Mini', 'OpenAI', 0.00015, 0.0006),
  
  @JsonValue('anthropic/claude-3.5-sonnet')
  claude35Sonnet('anthropic/claude-3.5-sonnet', 'Claude 3.5 Sonnet', 'Anthropic', 0.003, 0.015),
  
  @JsonValue('anthropic/claude-3-haiku')
  claude3Haiku('anthropic/claude-3-haiku', 'Claude 3 Haiku', 'Anthropic', 0.00025, 0.00125),
  
  @JsonValue('mistralai/mistral-large')
  mistralLarge('mistralai/mistral-large', 'Mistral Large', 'Mistral AI', 0.004, 0.012),
  
  @JsonValue('mistralai/mistral-small')
  mistralSmall('mistralai/mistral-small', 'Mistral Small', 'Mistral AI', 0.001, 0.003),
  
  @JsonValue('google/gemini-pro-1.5')
  geminiPro15('google/gemini-pro-1.5', 'Gemini Pro 1.5', 'Google', 0.00125, 0.005),
  
  @JsonValue('meta-llama/llama-3.1-70b-instruct')
  llama31_70b('meta-llama/llama-3.1-70b-instruct', 'Llama 3.1 70B', 'Meta', 0.00088, 0.00088),
  
  @JsonValue('meta-llama/llama-3.1-8b-instruct')
  llama31_8b('meta-llama/llama-3.1-8b-instruct', 'Llama 3.1 8B', 'Meta', 0.00018, 0.00018);

  const AIModel(this.id, this.displayName, this.provider, this.inputPrice, this.outputPrice);

  final String id;
  final String displayName;
  final String provider;
  final double inputPrice; // Price per 1K tokens
  final double outputPrice; // Price per 1K tokens

  /// Get model by ID
  static AIModel? fromId(String id) {
    for (final model in AIModel.values) {
      if (model.id == id) return model;
    }
    return null;
  }

  /// Get models by provider
  static List<AIModel> getByProvider(String provider) {
    return AIModel.values.where((model) => model.provider == provider).toList();
  }

  /// Get all providers
  static List<String> getAllProviders() {
    return AIModel.values.map((model) => model.provider).toSet().toList();
  }

  /// Calculate estimated cost for tokens
  double calculateCost(int inputTokens, int outputTokens) {
    return (inputTokens / 1000 * inputPrice) + (outputTokens / 1000 * outputPrice);
  }
}

/// AI chat message
@JsonSerializable()
class AIMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) => _$AIMessageFromJson(json);
  Map<String, dynamic> toJson() => _$AIMessageToJson(this);

  /// Create user message
  factory AIMessage.user(String content, {Map<String, dynamic>? metadata}) {
    return AIMessage(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create assistant message
  factory AIMessage.assistant(String content, {Map<String, dynamic>? metadata}) {
    return AIMessage(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create system message
  factory AIMessage.system(String content, {Map<String, dynamic>? metadata}) {
    return AIMessage(
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}

/// AI chat conversation
@JsonSerializable()
class AIConversation {
  final String id;
  final String title;
  final List<AIMessage> messages;
  final AIModel model;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  const AIConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) => _$AIConversationFromJson(json);
  Map<String, dynamic> toJson() => _$AIConversationToJson(this);

  /// Create new conversation
  factory AIConversation.create({
    required String title,
    required AIModel model,
    String? systemPrompt,
    Map<String, dynamic>? settings,
  }) {
    final now = DateTime.now();
    final messages = <AIMessage>[];
    
    if (systemPrompt != null) {
      messages.add(AIMessage.system(systemPrompt));
    }

    return AIConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      messages: messages,
      model: model,
      createdAt: now,
      updatedAt: now,
      settings: settings,
    );
  }

  /// Add message to conversation
  AIConversation addMessage(AIMessage message) {
    return AIConversation(
      id: id,
      title: title,
      messages: [...messages, message],
      model: model,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      settings: settings,
    );
  }

  /// Update conversation title
  AIConversation updateTitle(String newTitle) {
    return AIConversation(
      id: id,
      title: newTitle,
      messages: messages,
      model: model,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      settings: settings,
    );
  }

  /// Get total token count estimate
  int get estimatedTokenCount {
    return messages.fold(0, (total, message) => total + _estimateTokens(message.content));
  }

  /// Estimate tokens in text (rough approximation)
  int _estimateTokens(String text) {
    return (text.length / 4).ceil(); // Rough estimate: 1 token ≈ 4 characters
  }

  /// Calculate estimated cost
  double get estimatedCost {
    final tokens = estimatedTokenCount;
    return model.calculateCost(tokens ~/ 2, tokens ~/ 2); // Assume 50/50 input/output
  }
}

/// AI request configuration
@JsonSerializable()
class AIRequestConfig {
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final List<String>? stop;

  const AIRequestConfig({
    this.temperature = 0.7,
    this.maxTokens = 1000,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stop,
  });

  factory AIRequestConfig.fromJson(Map<String, dynamic> json) => _$AIRequestConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AIRequestConfigToJson(this);

  /// Default configuration for different use cases
  static const AIRequestConfig creative = AIRequestConfig(
    temperature: 0.9,
    maxTokens: 1500,
    topP: 0.9,
  );

  static const AIRequestConfig balanced = AIRequestConfig(
    temperature: 0.7,
    maxTokens: 1000,
    topP: 1.0,
  );

  static const AIRequestConfig precise = AIRequestConfig(
    temperature: 0.3,
    maxTokens: 800,
    topP: 0.8,
  );
}

/// AI response from OpenRouter
@JsonSerializable()
class AIResponse {
  final String id;
  final String content;
  final AIModel model;
  final int inputTokens;
  final int outputTokens;
  final double cost;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.id,
    required this.content,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.cost,
    required this.timestamp,
    this.metadata,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) => _$AIResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AIResponseToJson(this);

  /// Total tokens used
  int get totalTokens => inputTokens + outputTokens;
}
