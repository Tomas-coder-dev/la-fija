import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bank_catalog.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/supabase_service.dart';
import '../widgets/card_progress_widget.dart';
import '../widgets/progress_ring_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum CardSortOption { urgency, limit, custom }

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService();
  late Future<List<_CardWithExpenses>> _dataFuture;
  
  CardSortOption _sortOption = CardSortOption.urgency;
  List<_CardWithExpenses> _cachedData = [];

  int _currentIndex = 0; // 0: Tarjetas, 1: Gastos, 2: Membresía
  int _membresiaPage = 0;
  final PageController _membresiaPageController = PageController(viewportFraction: 1.0);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _membresiaPageController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadAllData();
    });
  }

  Future<List<_CardWithExpenses>> _loadAllData() async {
    final cards = await _service.getCards();
    final result = <_CardWithExpenses>[];
    for (final card in cards) {
      final expenses = await _service.getExpensesByCard(card.id);
      result.add(_CardWithExpenses(card: card, expenses: expenses));
    }
    _cachedData = result;
    _applySorting();
    return _cachedData;
  }

  void _applySorting() {
    if (_sortOption == CardSortOption.urgency) {
      _cachedData.sort((a, b) => _service.getDaysUntilCycleEnd(a.card).compareTo(_service.getDaysUntilCycleEnd(b.card)));
    } else if (_sortOption == CardSortOption.limit) {
      _cachedData.sort((a, b) => b.card.limiteCredito.compareTo(a.card.limiteCredito));
    }
    // custom mantiene el orden actual
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(expDate).inDays;

    if (diff == 0) {
      return 'Hoy, ${DateFormat('HH:mm').format(date)}';
    } else if (diff == 1) {
      return 'Ayer, ${DateFormat('HH:mm').format(date)}';
    } else if (diff < 7 && diff > 0) {
      return 'Hace $diff días';
    } else {
      return DateFormat('dd MMM, HH:mm', 'es_PE').format(date);
    }
  }

  // ======= MODAL DETALLE DE TARJETA =======

  void _showCardDetailModal(_CardWithExpenses item) {
    final bankData = BankCatalog.getBankData(item.card.banco);
    final cycleExpenses = _service.getCurrentCycleExpenses(item.card, item.expenses);
    cycleExpenses.sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo));
    final currencyFmt = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final totalCycleSpent = _service.getCurrentCycleConsumption(item.card, item.expenses);
    final daysRemaining = _service.getDaysUntilCycleEnd(item.card);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 50),
              decoration: const BoxDecoration(
                color: Color(0xFF141428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar & Header
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Mini Visual Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bankData.primaryColor, bankData.secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: bankData.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.credit_card_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.card.banco} · ${item.card.nombreTarjeta}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Límite: ${currencyFmt.format(item.card.limiteCredito)} · Cierra día ${item.card.diaCierre}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showDeleteCardConfirmation(item.card);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E38),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gastado en ciclo', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(currencyFmt.format(totalCycleSpent), style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E38),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Días de ciclo', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('$daysRemaining días restantes', style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gastos del ciclo actual (${cycleExpenses.length})',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Desliza para borrar',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Expenses List
                    Flexible(
                      child: cycleExpenses.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Text(
                                'No hay gastos registrados en este ciclo.',
                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: cycleExpenses.length,
                              itemBuilder: (ctx, idx) {
                                final exp = cycleExpenses[idx];
                                final catData = ExpenseCategory.fromKey(exp.categoria);

                                return Dismissible(
                                  key: Key(exp.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                                  ),
                                  onDismissed: (_) async {
                                    await _service.deleteExpense(exp.id);
                                    setModalState(() {
                                      cycleExpenses.removeAt(idx);
                                    });
                                    _refresh();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E38),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: catData.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text(catData.emoji, style: const TextStyle(fontSize: 16)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                catData.label,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                _formatRelativeDate(exp.fechaConsumo),
                                                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          currencyFmt.format(exp.monto),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ======= ELIMINAR TARJETA =======

  void _showDeleteCardConfirmation(CreditCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar tarjeta?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Se eliminará "${card.banco} ${card.nombreTarjeta}" y todos los gastos registrados en ella.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteCard(card.id);
                _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarjeta eliminada correctamente')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ======= MODALS CREAR Y AGREGAR =======

  Future<void> _showAddExpenseModal() async {
    final formKey = GlobalKey<FormState>();
    CreditCard? selectedCard;
    final montoController = TextEditingController();
    String selectedCategory = 'otros';

    List<CreditCard> cards = [];
    try {
      cards = await _service.getCards();
    } catch (_) {}

    if (!mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes tarjetas registradas.')),
      );
      return;
    }

    selectedCard = cards.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currentCardBank = selectedCard != null ? BankCatalog.getBankData(selectedCard!.banco) : null;

            return Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: Color(0xFF141428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 28,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Registrar Gasto', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('¿En qué gastaste hoy?', style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
                        const SizedBox(height: 20),

                        // Card selector
                        DropdownButtonFormField<CreditCard>(
                          decoration: _inputDecoration('Tarjeta de Crédito'),
                          dropdownColor: const Color(0xFF252540),
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                          value: selectedCard,
                          hint: Text('Selecciona una tarjeta', style: GoogleFonts.inter(color: Colors.white38)),
                          items: cards.map((c) {
                            final bData = BankCatalog.getBankData(c.banco);
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: bData.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${c.banco} · ${c.nombreTarjeta}', style: GoogleFonts.inter(color: Colors.white)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedCard = val),
                          validator: (val) => val == null ? 'Selecciona una tarjeta' : null,
                        ),
                        const SizedBox(height: 20),

                        // Category selector (emoji grid)
                        Text('Categoría', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: ExpenseCategory.all.length,
                          itemBuilder: (context, index) {
                            final cat = ExpenseCategory.all[index];
                            final isSelected = cat.key == selectedCategory;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedCategory = cat.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? cat.color.withOpacity(0.25) : const Color(0xFF1E1E38),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? cat.color : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: cat.color.withOpacity(0.3), blurRadius: 8)]
                                      : null,
                                ),
                                child: Tooltip(
                                  message: cat.label,
                                  child: Center(
                                    child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            ExpenseCategory.fromKey(selectedCategory).label,
                            style: GoogleFonts.inter(color: ExpenseCategory.fromKey(selectedCategory).color, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount input
                        TextFormField(
                          controller: montoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          decoration: _inputDecoration('Monto del consumo').copyWith(
                            prefixText: 'S/ ',
                            prefixStyle: GoogleFonts.inter(color: currentCardBank?.primaryColor ?? Colors.amber, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Ingresa un monto';
                            if (double.tryParse(val) == null) return 'Monto inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentCardBank?.primaryColor ?? Colors.indigo.shade500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                await _service.addExpense(
                                  tarjetaId: selectedCard!.id,
                                  monto: double.parse(montoController.text),
                                  categoria: selectedCategory,
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                
                                final cardIndex = _cachedData.indexWhere((c) => c.card.id == selectedCard!.id);
                                
                                _refresh();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Gasto registrado con éxito! 🎉'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  setState(() {
                                    _currentIndex = 2; // Ir a Membresía
                                  });
                                  if (cardIndex != -1) {
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (_membresiaPageController.hasClients) {
                                        _membresiaPageController.jumpToPage(cardIndex);
                                      }
                                    });
                                  }
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            child: Text('Registrar Gasto', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddCardModal() async {
    final formKey = GlobalKey<FormState>();
    BankData selectedBank = BankCatalog.banks.first;
    final nombreController = TextEditingController(text: selectedBank.network);
    final limiteController = TextEditingController();
    final cierreController = TextEditingController();
    final pagoController = TextEditingController();
    final metaController = TextEditingController(text: selectedBank.defaultExemptionTarget.toString());
    final membresiaController = TextEditingController(text: selectedBank.defaultMembershipFee.toString());
    String exemptionType = selectedBank.defaultExemptionType;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 50),
              decoration: const BoxDecoration(
                color: Color(0xFF141428),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 28,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Nueva Tarjeta de Crédito', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Elige tu banco y personaliza los detalles', style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
                        const SizedBox(height: 20),

                        // Card Preview Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [selectedBank.primaryColor, selectedBank.secondaryColor]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: selectedBank.primaryColor.withOpacity(0.4), blurRadius: 12),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedBank.name,
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedBank.isStrictMonthly ? '⚡ Consumo vital cada mes' : '✨ Meta flexible anual',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'S/ ${membresiaController.text}/año',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Selector de Banco
                        Text('Banco y Tarjeta', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: BankCatalog.banks.length,
                            itemBuilder: (context, index) {
                              final bank = BankCatalog.banks[index];
                              final isSelected = selectedBank == bank;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedBank = bank;
                                    nombreController.text = bank.network;
                                    metaController.text = bank.defaultExemptionTarget.toString();
                                    membresiaController.text = bank.defaultMembershipFee.toString();
                                    exemptionType = bank.defaultExemptionType;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(colors: [bank.primaryColor, bank.secondaryColor])
                                        : null,
                                    color: isSelected ? null : const Color(0xFF1E1E38),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: bank.primaryColor.withOpacity(0.4), blurRadius: 10)]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bank.name,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        bank.isStrictMonthly ? 'Strict Mensual' : 'Flexible',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: nombreController,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: _inputDecoration('Nombre / Tipo (Ej: Visa Signature, Bfree)'),
                          validator: (val) => val!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: limiteController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: _inputDecoration('Límite de Crédito (S/)'),
                          validator: (val) => double.tryParse(val!) == null ? 'Inválido' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: cierreController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: _inputDecoration('Día de Cierre (1-31)'),
                                validator: (val) {
                                  final num = int.tryParse(val!);
                                  if (num == null || num < 1 || num > 31) return 'Día 1-31';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: pagoController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: _inputDecoration('Día de Pago (1-31)'),
                                validator: (val) {
                                  final num = int.tryParse(val!);
                                  if (num == null || num < 1 || num > 31) return 'Día 1-31';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: membresiaController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: _inputDecoration('Costo de Membresía Anual (S/)'),
                          onChanged: (val) => setModalState(() {}),
                          validator: (val) => double.tryParse(val!) == null ? 'Inválido' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Requisito de Exoneración'),
                          dropdownColor: const Color(0xFF252540),
                          style: GoogleFonts.inter(color: Colors.white),
                          value: exemptionType,
                          items: const [
                            DropdownMenuItem(value: 'monthly_average', child: Text('Monto de consumo (S/)')),
                            DropdownMenuItem(value: 'monthly_purchase', child: Text('Cantidad de compras (unidades)')),
                          ],
                          onChanged: (val) => setModalState(() => exemptionType = val!),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: metaController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: _inputDecoration('Meta (Monto S/ o # de compras)'),
                          validator: (val) => double.tryParse(val!) == null ? 'Inválido' : null,
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedBank.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                await _service.addCard(
                                  banco: selectedBank.name,
                                  nombreTarjeta: nombreController.text,
                                  diaCierre: int.parse(cierreController.text),
                                  diaPago: int.parse(pagoController.text),
                                  metaMensual: double.parse(metaController.text),
                                  limiteCredito: double.parse(limiteController.text),
                                  membershipFee: double.parse(membresiaController.text),
                                  exemptionType: exemptionType,
                                  exemptionTarget: double.parse(metaController.text),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                _refresh();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Tarjeta creada con éxito! 💳'),
                                      backgroundColor: Colors.indigo,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                            child: Text('Crear Tarjeta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141428),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.greenAccent, size: 20),
              ),
              title: Text('Registrar Gasto', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Agrega un consumo a tu tarjeta', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddExpenseModal();
              },
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.credit_card_rounded, color: Colors.indigoAccent, size: 20),
              ),
              title: Text('Nueva Tarjeta', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Registra una tarjeta de crédito', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddCardModal();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E1E38),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ======= TABS DE LA NAVEGACIÓN =======

  Widget _buildTarjetasTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.credit_card_off_rounded, size: 40, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            Text('Aún no tienes tarjetas', style: GoogleFonts.inter(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Toca + para agregar tu primera tarjeta', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _showAddCardModal,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Añadir Tarjeta', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Tarjetas (${data.length})',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              PopupMenuButton<CardSortOption>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white70),
                color: const Color(0xFF1E1E38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                initialValue: _sortOption,
                onSelected: (val) {
                  setState(() {
                    _sortOption = val;
                    _applySorting();
                  });
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: CardSortOption.urgency,
                    child: Text('Más urgente (Cierre)', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: CardSortOption.limit,
                    child: Text('Mayor límite', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: CardSortOption.custom,
                    child: Text('Personalizado (Arrastrar)', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768 && _sortOption != CardSortOption.custom) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final item = data[i];
                    return CardProgressWidget(
                      card: item.card,
                      consumption: _service.getCurrentCycleConsumption(item.card, item.expenses),
                      currencyFormat: currencyFormat,
                      daysRemaining: _service.getDaysUntilCycleEnd(item.card),
                      onTap: () => _showCardDetailModal(item),
                      onDelete: () => _showDeleteCardConfirmation(item.card),
                    );
                  },
                );
              }
              
              if (_sortOption == CardSortOption.custom) {
                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 8,
                      shadowColor: Colors.black45,
                      child: child,
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _cachedData.removeAt(oldIndex);
                      _cachedData.insert(newIndex, item);
                    });
                  },
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final item = data[i];
                    return Padding(
                      key: ValueKey(item.card.id),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CardProgressWidget(
                        card: item.card,
                        consumption: _service.getCurrentCycleConsumption(item.card, item.expenses),
                        currencyFormat: currencyFormat,
                        daysRemaining: _service.getDaysUntilCycleEnd(item.card),
                        onTap: () => _showCardDetailModal(item),
                        onDelete: () => _showDeleteCardConfirmation(item.card),
                      ),
                    );
                  },
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: data.length,
                itemBuilder: (ctx, i) {
                  final item = data[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: CardProgressWidget(
                      card: item.card,
                      consumption: _service.getCurrentCycleConsumption(item.card, item.expenses),
                      currencyFormat: currencyFormat,
                      daysRemaining: _service.getDaysUntilCycleEnd(item.card),
                      onTap: () => _showCardDetailModal(item),
                      onDelete: () => _showDeleteCardConfirmation(item.card),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGastosTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    final allExpenses = <Expense>[];
    for (var item in data) {
      allExpenses.addAll(item.expenses);
    }
    allExpenses.sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo));

    if (allExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 40, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            Text('Sin gastos registrados', style: GoogleFonts.inter(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tus consumos aparecerán aquí', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    final totalSpentOverall = allExpenses.fold(0.0, (sum, e) => sum + e.monto);

    // Group by category
    final grouped = <String, List<Expense>>{};
    for (final exp in allExpenses) {
      grouped.putIfAbsent(exp.categoria, () => []).add(exp);
    }

    final categoryKeys = grouped.keys.toList();

    return Column(
      children: [
        // Total Spent Summary Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gasto Total Registrado', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(totalSpentOverall),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allExpenses.length} consumos',
                  style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        // Expense List Grouped by Category with Swipe-to-Delete
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryKeys.length,
            itemBuilder: (ctx, catIndex) {
              final catKey = categoryKeys[catIndex];
              final catData = ExpenseCategory.fromKey(catKey);
              final expenses = grouped[catKey]!;
              final subtotal = expenses.fold(0.0, (sum, e) => sum + e.monto);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Container(
                    margin: const EdgeInsets.only(bottom: 8, top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: catData.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: catData.color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(catData.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            catData.label,
                            style: GoogleFonts.inter(color: catData.color, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          currencyFormat.format(subtotal),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),

                  // Expense items with Dismissible
                  ...expenses.map((exp) {
                    final cardItem = data.firstWhere(
                      (c) => c.card.id == exp.tarjetaId,
                      orElse: () => data.first,
                    );
                    final card = cardItem.card;
                    final bankData = BankCatalog.getBankData(card.banco);

                    return Dismissible(
                      key: Key(exp.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await _service.deleteExpense(exp.id);
                        _refresh();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: catData.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(catData.emoji, style: const TextStyle(fontSize: 18))),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currencyFormat.format(exp.monto),
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bankData.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  card.banco,
                                  style: GoogleFonts.inter(color: bankData.primaryColor, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatRelativeDate(exp.fechaConsumo),
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
                            onPressed: () async {
                              await _service.deleteExpense(exp.id);
                              _refresh();
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                  if (catIndex < categoryKeys.length - 1) const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMembresiaTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.stars_rounded, size: 40, color: Colors.white24),
            ),
            const SizedBox(height: 20),
            Text('Sin tarjetas para evaluar membresía', style: GoogleFonts.inter(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Page indicator dots con color propio de cada banco
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(data.length, (i) {
            final isActive = i == _membresiaPage;
            final bankData = BankCatalog.getBankData(data[i].card.banco);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? bankData.primaryColor : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // Swipeable card ring carousel
        Expanded(
          child: PageView.builder(
            controller: _membresiaPageController,
            itemCount: data.length,
            onPageChanged: (i) => setState(() => _membresiaPage = i),
            itemBuilder: (ctx, i) {
              final item = data[i];
              final bankData = BankCatalog.getBankData(item.card.banco);
              final isCountBased = item.card.exemptionType == 'monthly_purchase';

              final double currentVal;
              final double targetVal = item.card.exemptionTarget;

              if (isCountBased) {
                currentVal = _service.getCurrentCycleExpenseCount(item.card, item.expenses).toDouble();
              } else {
                currentVal = _service.getCurrentCycleConsumption(item.card, item.expenses);
              }

              final progress = targetVal == 0 ? 1.0 : (currentVal / targetVal).clamp(0.0, 1.0);
              final daysRemaining = _service.getDaysUntilCycleEnd(item.card);
              final cycleEndDate = _service.getCycleEndDate(item.card);

              // Daily pace required
              final remaining = (targetVal - currentVal).clamp(0.0, double.infinity);
              final dailyNeeded = (bankData.isStrictMonthly && !isCountBased && remaining > 0 && daysRemaining > 0)
                  ? remaining / max(1, daysRemaining)
                  : 0.0;

              String centerLabel;
              if (targetVal == 0) {
                centerLabel = '🎉';
              } else {
                centerLabel = '${(progress * 100).toInt()}%';
              }

              String statusText;
              if (targetVal == 0) {
                statusText = 'Sin membresía — ¡Exonerado!';
              } else if (progress >= 1.0) {
                statusText = '¡Meta cumplida este mes!';
              } else if (isCountBased) {
                final remCount = (targetVal - currentVal).toInt();
                statusText = '${currentVal.toInt()} de ${targetVal.toInt()} consumos realizados\nFaltan $remCount compra(s)';
              } else {
                statusText = 'Gastaste ${currencyFormat.format(currentVal)} de ${currencyFormat.format(targetVal)}\nFalta: ${currencyFormat.format(targetVal - currentVal)}';
              }

              final hasPenalty = item.card.membershipFee > 0;

              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ProgressRingWidget(
                      progress: progress,
                      ringColor: bankData.primaryColor,
                      secondaryColor: bankData.secondaryColor,
                      centerLabel: centerLabel,
                      statusText: statusText,
                      cardName: '${item.card.banco} ${item.card.nombreTarjeta}',
                      showPenalty: hasPenalty,
                      penaltyText: hasPenalty ? 'Membresía anual: ${currencyFormat.format(item.card.membershipFee)}' : '',
                      isStrictMonthly: bankData.isStrictMonthly,
                      daysRemaining: daysRemaining,
                      cycleEndDate: cycleEndDate,
                      dailyNeeded: dailyNeeded,
                      currentValue: currentVal,
                      targetValue: targetVal,
                      isCountBased: isCountBased,
                      membershipFee: item.card.membershipFee,
                      size: MediaQuery.of(ctx).size.width * (bankData.isStrictMonthly ? 0.8 : 0.55),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Swipe hint
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 4),
          child: Text(
            data.length > 1 ? '← Desliza para ver tus otras tarjetas →' : '',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ?? user?.email ?? 'Usuario';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La Fija', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: -0.5)),
            Text(
              '${_getGreeting()}, $firstName 👋',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
            ),
            onPressed: () async => await Supabase.instance.client.auth.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionMenu,
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111125),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.indigoAccent,
          unselectedItemColor: Colors.white30,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.credit_card_rounded), label: 'Tarjetas'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Gastos'),
            BottomNavigationBarItem(icon: Icon(Icons.stars_rounded), label: 'Membresía'),
          ],
        ),
      ),
      body: FutureBuilder<List<_CardWithExpenses>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.indigoAccent, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text('Cargando datos...', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.white54), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (_currentIndex == 0) return _buildTarjetasTab(data, currencyFormat);
          if (_currentIndex == 1) return _buildGastosTab(data, currencyFormat);
          if (_currentIndex == 2) return _buildMembresiaTab(data, currencyFormat);

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CardWithExpenses {
  final CreditCard card;
  final List<Expense> expenses;
  const _CardWithExpenses({required this.card, required this.expenses});
}
