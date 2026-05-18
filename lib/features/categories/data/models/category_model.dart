import 'package:flutter/material.dart';

enum CategoryType {
  income('income'),
  expense('expense');

  final String value;
  const CategoryType(this.value);

  static CategoryType fromValue(String v) =>
      CategoryType.values.firstWhere((e) => e.value == v, orElse: () => CategoryType.expense);
}

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final CategoryType type;
  final String icon;
  final Color color;
  final String? parentId;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentId,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: CategoryType.fromValue(map['type'] as String),
      icon: map['icon'] as String? ?? 'category',
      color: Color(int.parse((map['color'] as String? ?? '0xFF1E88E5').replaceFirst('#', '0xFF'))),
      parentId: map['parent_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'type': type.value,
        'icon': icon,
        'color': '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        'parent_id': parentId,
      };

  CategoryModel copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? icon,
    Color? color,
    String? parentId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt,
    );
  }
}

// Default categories seeded on first login
final defaultIncomeCategories = [
  _DefaultCategory('Salário', 'work', 0xFF43A047),
  _DefaultCategory('Freelance', 'computer', 0xFF26A69A),
  _DefaultCategory('Aluguel', 'home', 0xFF8E24AA),
  _DefaultCategory('Investimentos', 'trending_up', 0xFF1E88E5),
  _DefaultCategory('Outros', 'attach_money', 0xFF546E7A),
];

final defaultExpenseCategories = [
  _DefaultCategory('Alimentação', 'restaurant', 0xFFE53935),
  _DefaultCategory('Transporte', 'directions_car', 0xFFFF8F00),
  _DefaultCategory('Moradia', 'home', 0xFF8E24AA),
  _DefaultCategory('Saúde', 'local_hospital', 0xFFD81B60),
  _DefaultCategory('Educação', 'school', 0xFF039BE5),
  _DefaultCategory('Lazer', 'sports_esports', 0xFF7CB342),
  _DefaultCategory('Vestuário', 'checkroom', 0xFFFF7043),
  _DefaultCategory('Supermercado', 'shopping_cart', 0xFF6D4C41),
  _DefaultCategory('Assinaturas', 'subscriptions', 0xFF00ACC1),
  _DefaultCategory('Pets', 'pets', 0xFFFFB300),
  _DefaultCategory('Beleza', 'face', 0xFFD81B60),
  _DefaultCategory('Outros', 'category', 0xFF546E7A),
];

class _DefaultCategory {
  final String name;
  final String icon;
  final int colorValue;
  _DefaultCategory(this.name, this.icon, this.colorValue);
}
