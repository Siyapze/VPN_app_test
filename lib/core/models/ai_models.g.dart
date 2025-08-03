// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIMessage _$AIMessageFromJson(Map<String, dynamic> json) => AIMessage(
  role: json['role'] as String,
  content: json['content'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AIMessageToJson(AIMessage instance) => <String, dynamic>{
  'role': instance.role,
  'content': instance.content,
  'timestamp': instance.timestamp.toIso8601String(),
  'metadata': instance.metadata,
};

AIConversation _$AIConversationFromJson(Map<String, dynamic> json) =>
    AIConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      messages:
          (json['messages'] as List<dynamic>)
              .map((e) => AIMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
      model: $enumDecode(_$AIModelEnumMap, json['model']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AIConversationToJson(AIConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'messages': instance.messages,
      'model': _$AIModelEnumMap[instance.model]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'settings': instance.settings,
    };

const _$AIModelEnumMap = {
  AIModel.gpt4o: 'openai/gpt-4o',
  AIModel.gpt4oMini: 'openai/gpt-4o-mini',
  AIModel.claude35Sonnet: 'anthropic/claude-3.5-sonnet',
  AIModel.claude3Haiku: 'anthropic/claude-3-haiku',
  AIModel.mistralLarge: 'mistralai/mistral-large',
  AIModel.mistralSmall: 'mistralai/mistral-small',
  AIModel.geminiPro15: 'google/gemini-pro-1.5',
  AIModel.llama31_70b: 'meta-llama/llama-3.1-70b-instruct',
  AIModel.llama31_8b: 'meta-llama/llama-3.1-8b-instruct',
};

AIRequestConfig _$AIRequestConfigFromJson(Map<String, dynamic> json) =>
    AIRequestConfig(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 1000,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      stop: (json['stop'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AIRequestConfigToJson(AIRequestConfig instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'maxTokens': instance.maxTokens,
      'topP': instance.topP,
      'frequencyPenalty': instance.frequencyPenalty,
      'presencePenalty': instance.presencePenalty,
      'stop': instance.stop,
    };

AIResponse _$AIResponseFromJson(Map<String, dynamic> json) => AIResponse(
  id: json['id'] as String,
  content: json['content'] as String,
  model: $enumDecode(_$AIModelEnumMap, json['model']),
  inputTokens: (json['inputTokens'] as num).toInt(),
  outputTokens: (json['outputTokens'] as num).toInt(),
  cost: (json['cost'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AIResponseToJson(AIResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'model': _$AIModelEnumMap[instance.model]!,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
      'cost': instance.cost,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
    };
