import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';

class LocalStorageService {
  static const String boxName = 'offline_cache';
  
  // Claves
  static const String cardsKey = 'cards_list';
  static const String expensesKey = 'expenses_list';
  static const String pendingSyncKey = 'pending_sync';

  Box get _box => Hive.box(boxName);

  // --- Tarjetas ---
  void saveCardsLocally(List<CreditCard> cards) {
    final listMap = cards.map((c) => c.toJson()).toList();
    _box.put(cardsKey, jsonEncode(listMap));
  }

  List<CreditCard> getLocalCards() {
    final data = _box.get(cardsKey);
    if (data == null) return [];
    
    final List<dynamic> listMap = jsonDecode(data);
    return listMap.map((e) => CreditCard.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // --- Gastos ---
  void saveExpensesLocally(List<Expense> expenses) {
    final listMap = expenses.map((e) => e.toJson()).toList();
    _box.put(expensesKey, jsonEncode(listMap));
  }

  List<Expense> getLocalExpenses() {
    final data = _box.get(expensesKey);
    if (data == null) return [];
    
    final List<dynamic> listMap = jsonDecode(data);
    return listMap.map((e) => Expense.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
