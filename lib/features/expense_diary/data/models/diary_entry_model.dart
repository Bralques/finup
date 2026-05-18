import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum DiaryMood {
  great('great', 'Ótimo', '😄', AppColors.moodGreat),
  good('good', 'Bom', '🙂', AppColors.moodGood),
  neutral('neutral', 'Neutro', '😐', AppColors.moodNeutral),
  bad('bad', 'Ruim', '😕', AppColors.moodBad),
  terrible('terrible', 'Péssimo', '😢', AppColors.moodTerrible);

  final String value;
  final String label;
  final String emoji;
  final Color color;
  const DiaryMood(this.value, this.label, this.emoji, this.color);

  static DiaryMood? fromValue(String? v) {
    if (v == null) return null;
    return DiaryMood.values.firstWhere((e) => e.value == v, orElse: () => DiaryMood.neutral);
  }
}

class DiaryEntryModel {
  final String id;
  final String userId;
  final DateTime date;
  final String? note;
  final DiaryMood? mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    this.note,
    this.mood,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntryModel.fromMap(Map<String, dynamic> map) {
    return DiaryEntryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      mood: DiaryMood.fromValue(map['mood'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'date': date.toIso8601String().split('T').first,
        'note': note,
        'mood': mood?.value,
      };

  DiaryEntryModel copyWith({String? note, DiaryMood? mood}) {
    return DiaryEntryModel(
      id: id,
      userId: userId,
      date: date,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
