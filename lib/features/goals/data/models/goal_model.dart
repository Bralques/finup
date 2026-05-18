import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class GoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final Color color;
  final String icon;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.color,
    this.icon = 'flag',
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
  bool get isAchieved => currentAmount >= targetAmount;

  int? get daysLeft {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      color: Color(int.parse((map['color'] as String? ?? '0xFF1E88E5').replaceFirst('#', '0xFF'))),
      icon: map['icon'] as String? ?? 'flag',
      isCompleted: map['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline?.toIso8601String().split('T').first,
        'color': '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        'icon': icon,
        'is_completed': isCompleted,
      };

  GoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    Color? color,
    String? icon,
    bool? isCompleted,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static GoalModel empty() => GoalModel(
        id: '',
        userId: '',
        name: '',
        targetAmount: 0,
        currentAmount: 0,
        color: AppColors.primary,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
