import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1A1A1A);       // preto principal
  static const accent = Color(0xFFD4FF57);         // amarelo-lima (card de saldo)
  static const accentDark = Color(0xFFB8E83A);

  // Semânticas
  static const income = Color(0xFF00C853);
  static const expense = Color(0xFFFF3D57);
  static const transfer = Color(0xFF2979FF);

  // Backgrounds
  static const backgroundLight = Color(0xFFEBF7EE); // menta suave
  static const backgroundDark = Color(0xFF0F1A12);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1C2B1F);
  static const cardDark = Color(0xFF243028);

  // Texto
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7B6E);
  static const textDark = Color(0xFFF5F5F5);
  static const textDarkSecondary = Color(0xFF9AB09E);

  // Categorias
  static const List<Color> categoryColors = [
    Color(0xFF00C853),
    Color(0xFF2979FF),
    Color(0xFFFF3D57),
    Color(0xFF9C27B0),
    Color(0xFFFF6D00),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFF03A9F4),
    Color(0xFF8BC34A),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFFD600),
  ];

  // Mood
  static const moodGreat = Color(0xFF00C853);
  static const moodGood = Color(0xFF8BC34A);
  static const moodNeutral = Color(0xFFFFD600);
  static const moodBad = Color(0xFFFF6D00);
  static const moodTerrible = Color(0xFFFF3D57);

  // Cobranças
  static const debtOwed = Color(0xFF00C853);   // me devem (verde)
  static const debtIOwe = Color(0xFFFF3D57);   // eu devo (vermelho)
}
