import 'package:flutter/material.dart';

class ExpenseCategory {
  final String key;
  final String emoji;
  final String label;
  final Color color;

  const ExpenseCategory({
    required this.key,
    required this.emoji,
    required this.label,
    required this.color,
  });

  static const List<ExpenseCategory> all = [
    ExpenseCategory(key: 'comida', emoji: '🍔', label: 'Comida', color: Color(0xFFFF6B35)),
    ExpenseCategory(key: 'supermercado', emoji: '🛒', label: 'Súper', color: Color(0xFF4CAF50)),
    ExpenseCategory(key: 'combustible', emoji: '⛽', label: 'Combustible', color: Color(0xFFFF9800)),
    ExpenseCategory(key: 'transporte', emoji: '🚕', label: 'Transporte', color: Color(0xFF2196F3)),
    ExpenseCategory(key: 'entretenimiento', emoji: '🎬', label: 'Entreteni.', color: Color(0xFF9C27B0)),
    ExpenseCategory(key: 'ropa', emoji: '👕', label: 'Moda', color: Color(0xFFE91E63)),
    ExpenseCategory(key: 'salud', emoji: '💊', label: 'Salud', color: Color(0xFF00BCD4)),
    ExpenseCategory(key: 'tecnologia', emoji: '📱', label: 'Tech', color: Color(0xFF607D8B)),
    ExpenseCategory(key: 'hogar', emoji: '🏠', label: 'Hogar', color: Color(0xFF795548)),
    ExpenseCategory(key: 'educacion', emoji: '🎓', label: 'Educación', color: Color(0xFF3F51B5)),
    ExpenseCategory(key: 'viajes', emoji: '✈️', label: 'Viajes', color: Color(0xFF009688)),
    ExpenseCategory(key: 'regalos', emoji: '🎁', label: 'Regalos', color: Color(0xFFF44336)),
    ExpenseCategory(key: 'suscripciones', emoji: '📦', label: 'Suscripc.', color: Color(0xFF673AB7)),
    ExpenseCategory(key: 'otros', emoji: '💳', label: 'Otros', color: Color(0xFF9E9E9E)),
  ];

  static ExpenseCategory fromKey(String key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.last,
    );
  }
}
