import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/credit_card.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';
import '../widgets/card_progress_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService();
  late Future<List<_CardWithExpenses>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
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
    return result;
  }

  Future<void> _showAddExpenseModal() async {
    final formKey = GlobalKey<FormState>();
    CreditCard? selectedCard;
    final montoController = TextEditingController();

    // Cargamos las tarjetas para el dropdown
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Registrar gasto',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Selección de tarjeta ──────────────────────
                    DropdownButtonFormField<CreditCard>(
                      decoration: _inputDecoration('Tarjeta'),
                      dropdownColor: const Color(0xFF252540),
                      style: GoogleFonts.inter(color: Colors.white),
                      value: selectedCard,
                      hint: Text(
                        'Selecciona una tarjeta',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                      items: cards.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${c.banco} · ${c.nombreTarjeta}',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedCard = val),
                      validator: (val) =>
                          val == null ? 'Selecciona una tarjeta' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Monto ─────────────────────────────────────
                    TextFormField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration:
                          _inputDecoration('Monto (S/)').copyWith(
                        prefixText: 'S/ ',
                        prefixStyle:
                            GoogleFonts.inter(color: Colors.white70),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Ingresa un monto';
                        if (double.tryParse(val) == null) return 'Monto inválido';
                        if (double.parse(val) <= 0) return 'El monto debe ser mayor a 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Botón confirmar ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final monto =
                              double.parse(montoController.text);
                          try {
                            await _service.addExpense(
                              tarjetaId: selectedCard!.id,
                              monto: monto,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            _refresh();
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Registrar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF252540),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5),
      ),
      errorStyle: GoogleFonts.inter(color: Colors.red.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ??
        user?.email ??
        'Usuario';
    final firstName = displayName.split(' ').first;

    final currencyFormat =
        NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Text(
          'La Fija',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Avatar / logout
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.indigo.shade700,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            color: const Color(0xFF1A1A2E),
            onSelected: (val) async {
              if (val == 'logout') {
                await Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseModal,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuevo gasto',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Saludo ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $firstName 👋',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aquí va el progreso de tus tarjetas este ciclo.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Lista de tarjetas ─────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<_CardWithExpenses>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Error al cargar los datos.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.white54),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 80, horizontal: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.credit_card_off_rounded,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aún no tienes tarjetas registradas.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tus tarjetas desde Supabase\npara comenzar a trackear.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (ctx, i) {
                    final item = data[i];
                    final consumption = _service.getCurrentCycleConsumption(
                      item.card,
                      item.expenses,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CardProgressWidget(
                        card: item.card,
                        consumption: consumption,
                        currencyFormat: currencyFormat,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Espacio inferior para el FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Estructura auxiliar para agrupar tarjeta con sus gastos.
class _CardWithExpenses {
  final CreditCard card;
  final List<Expense> expenses;
  const _CardWithExpenses({required this.card, required this.expenses});
}
