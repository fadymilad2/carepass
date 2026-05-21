import 'dart:ui';

import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final AiSuggestion? suggestion;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.suggestion,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAi   => role == MessageRole.assistant;

  @override
  List<Object?> get props => [id, content, role];
}

enum MessageRole { user, assistant, system }

// ─────────────────────────────────────────────
class AiSuggestion extends Equatable {
  final String suggestedSpecialty;
  final List<String> suggestedTests;
  final List<String> possibleConditions;
  final String urgencyLevel;  // 'low' | 'medium' | 'high' | 'emergency'
  final String disclaimer;

  const AiSuggestion({
    required this.suggestedSpecialty,
    required this.suggestedTests,
    required this.possibleConditions,
    required this.urgencyLevel,
    required this.disclaimer,
  });

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'emergency': return const Color(0xFFE53E3E);
      case 'high':      return const Color(0xFFD69E2E);
      case 'medium':    return const Color(0xFF3182CE);
      default:          return const Color(0xFF38A169);
    }
  }

  String get urgencyLabel {
    switch (urgencyLevel) {
      case 'emergency': return '🚨 Emergency — Seek immediate care';
      case 'high':      return '⚠️ See a doctor soon';
      case 'medium':    return '📋 Schedule an appointment';
      default:          return '✅ Non-urgent';
    }
  }

  @override
  List<Object?> get props => [suggestedSpecialty, urgencyLevel];
}