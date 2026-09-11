import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bank_catalog.dart';
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
  
  int _currentIndex = 0; // 0: Tarjetas, 1: Gastos, 2: Membresía

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

  // ======= MODALS (Agregar Gasto / Tarjeta) =======
  Future<void> _showAddExpenseModal() async {
    final formKey = GlobalKey<FormState>();
    CreditCard? selectedCard;
    final montoController = TextEditingController();

    List<CreditCard> cards = [];
    try { cards = await _service.getCards(); } catch (_) {}

    if (!mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes tarjetas registradas.')));
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registrar Gasto', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<CreditCard>(
                      decoration: _inputDecoration('Tarjeta'),
                      dropdownColor: const Color(0xFF252540),
                      style: GoogleFonts.inter(color: Colors.white),
                      value: selectedCard,
                      hint: Text('Selecciona una tarjeta', style: GoogleFonts.inter(color: Colors.white54)),
                      items: cards.map((c) => DropdownMenuItem(value: c, child: Text('${c.banco} · ${c.nombreTarjeta}', style: GoogleFonts.inter(color: Colors.white)))).toList(),
                      onChanged: (val) => setModalState(() => selectedCard = val),
                      validator: (val) => val == null ? 'Selecciona una tarjeta' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: _inputDecoration('Monto (S/)').copyWith(prefixText: 'S/ ', prefixStyle: GoogleFonts.inter(color: Colors.white70)),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Ingresa un monto';
                        if (double.tryParse(val) == null) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            await _service.addExpense(tarjetaId: selectedCard!.id, monto: double.parse(montoController.text));
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            _refresh();
                          } catch (e) {
                            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        child: Text('Registrar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Future<void> _showAddCardModal() async {
    final formKey = GlobalKey<FormState>();
    BankData? selectedBank;
    final nombreController = TextEditingController();
    final limiteController = TextEditingController();
    final cierreController = TextEditingController();
    final pagoController = TextEditingController();
    final metaController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nueva Tarjeta', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 24),
                      Text('Diseño de Tarjeta', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: BankCatalog.banks.length,
                          itemBuilder: (context, index) {
                            final bank = BankCatalog.banks[index];
                            final isSelected = selectedBank == bank;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedBank = bank),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.indigo.shade600 : const Color(0xFF252540),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? Colors.indigo.shade400 : Colors.transparent, width: 2),
                                ),
                                child: Center(child: Text(bank.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500))),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: nombreController, style: GoogleFonts.inter(color: Colors.white), decoration: _inputDecoration('Nombre (Ej: Visa, CMR)'), validator: (val) => val!.isEmpty ? 'Requerido' : null),
                      const SizedBox(height: 16),
                      TextFormField(controller: limiteController, keyboardType: TextInputType.number, style: GoogleFonts.inter(color: Colors.white), decoration: _inputDecoration('Límite de Crédito (S/)'), validator: (val) => double.tryParse(val!) == null ? 'Inválido' : null),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: cierreController, keyboardType: TextInputType.number, style: GoogleFonts.inter(color: Colors.white), decoration: _inputDecoration('Día Cierre'), validator: (val) => int.tryParse(val!) == null ? 'Inválido' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: pagoController, keyboardType: TextInputType.number, style: GoogleFonts.inter(color: Colors.white), decoration: _inputDecoration('Día Pago'), validator: (val) => int.tryParse(val!) == null ? 'Inválido' : null)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: metaController, keyboardType: TextInputType.number, style: GoogleFonts.inter(color: Colors.white), decoration: _inputDecoration('Meta para no pagar membresía (S/)'), validator: (val) => double.tryParse(val!) == null ? 'Inválido' : null),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          onPressed: () async {
                            if (selectedBank == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Selecciona un diseño'))); return; }
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await _service.addCard(
                                banco: selectedBank!.name,
                                nombreTarjeta: nombreController.text,
                                diaCierre: int.parse(cierreController.text),
                                diaPago: int.parse(pagoController.text),
                                metaMensual: double.parse(metaController.text),
                                limiteCredito: double.parse(limiteController.text),
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              _refresh();
                            } catch (e) {
                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          child: Text('Crear Tarjeta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
              title: Text('Registrar Gasto', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); _showAddExpenseModal(); },
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.indigoAccent),
              title: Text('Nueva Tarjeta', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); _showAddCardModal(); },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white54),
      filled: true, fillColor: const Color(0xFF252540),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5)),
    );
  }

  // ======= TABS =======

  Widget _buildTarjetasTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card_off, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Aún no tienes tarjetas.', style: GoogleFonts.inter(color: Colors.white38)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showAddCardModal, child: const Text('Añadir Primera Tarjeta')),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 450, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 1.2),
            itemCount: data.length,
            itemBuilder: (ctx, i) => CardProgressWidget(card: data[i].card, consumption: _service.getCurrentCycleConsumption(data[i].card, data[i].expenses), currencyFormat: currencyFormat),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: CardProgressWidget(card: data[i].card, consumption: _service.getCurrentCycleConsumption(data[i].card, data[i].expenses), currencyFormat: currencyFormat),
          ),
        );
      },
    );
  }

  Widget _buildGastosTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    // Aplanar todos los gastos
    final allExpenses = <Expense>[];
    for (var item in data) { allExpenses.addAll(item.expenses); }
    allExpenses.sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo)); // Más recientes primero

    if (allExpenses.isEmpty) {
      return Center(child: Text('No tienes gastos registrados aún.', style: GoogleFonts.inter(color: Colors.white38)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allExpenses.length,
      itemBuilder: (ctx, i) {
        final exp = allExpenses[i];
        final card = data.firstWhere((c) => c.card.id == exp.tarjetaId).card;
        return ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFF252540), child: Icon(Icons.shopping_bag, color: Colors.white70)),
          title: Text(currencyFormat.format(exp.monto), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('${card.banco} ${card.nombreTarjeta} • ${DateFormat('dd MMM yyyy').format(exp.fechaConsumo)}', style: GoogleFonts.inter(color: Colors.white54)),
        );
      },
    );
  }

  Widget _buildMembresiaTab(List<_CardWithExpenses> data, NumberFormat currencyFormat) {
    if (data.isEmpty) return const Center(child: Text('Sin tarjetas.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (ctx, i) {
        final item = data[i];
        final consumption = _service.getCurrentCycleConsumption(item.card, item.expenses);
        final progress = (consumption / item.card.metaMensual).clamp(0.0, 1.0);
        
        Color progressColor = Colors.greenAccent;
        if (progress > 0.9) progressColor = Colors.blueAccent;
        else if (progress > 0.5) progressColor = Colors.orangeAccent;
        else progressColor = Colors.redAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF252540), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.card.banco} ${item.card.nombreTarjeta}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso Membresía', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  Text('${currencyFormat.format(consumption)} / ${currencyFormat.format(item.card.metaMensual)}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              if (progress >= 1.0)
                Text('¡Meta cumplida este mes! 🎉', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))
              else
                Text('Falta ${currencyFormat.format(item.card.metaMensual - consumption)} para llegar a la meta.', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Text('La Fija', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async => await Supabase.instance.client.auth.signOut(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionMenu,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Tarjetas'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Membresía'),
        ],
      ),
      body: FutureBuilder<List<_CardWithExpenses>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          
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
