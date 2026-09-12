import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/bank_catalog.dart';
import '../../models/credit_card.dart';
import '../../models/expense_category.dart';
import '../../providers/cards_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../services/supabase_service.dart';

Future<void> showAddExpenseModal(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  CreditCard? selectedCard;
  final montoController = TextEditingController();
  String selectedCategory = 'otros';

  bool isListening = false;
  final stt.SpeechToText speech = stt.SpeechToText();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final cardsState = ref.watch(cardsProvider);
          final expensesState = ref.watch(expensesProvider);
          final supabaseService = ref.read(supabaseServiceProvider);
          
          final cards = cardsState.value ?? [];
          final expenses = expensesState.value ?? [];

          if (cards.isEmpty && !cardsState.isLoading) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(ctx).dialogBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: const Center(child: Text('No tienes tarjetas registradas.')),
            );
          }

          if (selectedCard == null && cards.isNotEmpty) {
            // Inteligencia: Sugerir la mejor tarjeta por defecto
            final recommended = supabaseService.getRecommendedCard(cards, expenses, 0.0);
            selectedCard = recommended ?? cards.first;
          }

          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final theme = Theme.of(ctx);
              final isDark = theme.brightness == Brightness.dark;
              final currentCardBank = selectedCard != null ? BankCatalog.getBankData(selectedCard!.banco) : null;
              
              final recommendedCard = supabaseService.getRecommendedCard(cards, expenses, double.tryParse(montoController.text) ?? 0.0);
              final isRecommended = recommendedCard != null && selectedCard?.id == recommendedCard.id;

              void parseVoiceInput(String text) {
                final lower = text.toLowerCase();
                
                // 1. Extraer monto (buscando números)
                final amountMatch = RegExp(r'\d+(\.\d+)?').firstMatch(lower);
                if (amountMatch != null) {
                  montoController.text = amountMatch.group(0)!;
                }

                // 2. Extraer Categoría
                for (final cat in ExpenseCategory.all) {
                  if (lower.contains(cat.label.toLowerCase()) || lower.contains(cat.key.toLowerCase())) {
                    selectedCategory = cat.key;
                    break;
                  }
                }
                // Sinónimos comunes
                if (lower.contains('supermercado') || lower.contains('plaza vea') || lower.contains('wong')) selectedCategory = 'super';
                if (lower.contains('gasolina') || lower.contains('grifo') || lower.contains('taxi')) selectedCategory = 'transporte';
                if (lower.contains('restaurante') || lower.contains('cena') || lower.contains('almuerzo')) selectedCategory = 'comida';
                if (lower.contains('cine') || lower.contains('netflix')) selectedCategory = 'entretenimiento';
                if (lower.contains('ropa') || lower.contains('zapato')) selectedCategory = 'ropa';
                if (lower.contains('medicina') || lower.contains('farmacia') || lower.contains('pastilla')) selectedCategory = 'salud';

                // 3. Extraer Tarjeta
                for (final card in cards) {
                  if (lower.contains(card.banco.toLowerCase()) || lower.contains(card.nombreTarjeta.toLowerCase())) {
                    selectedCard = card;
                    break;
                  }
                }
              }

              Future<void> listenVoice() async {
                if (!isListening) {
                  bool available = await speech.initialize(
                    onStatus: (status) => print('STT Status: $status'),
                    onError: (error) => print('STT Error: $error'),
                  );
                  if (available) {
                    setModalState(() => isListening = true);
                    speech.listen(
                      localeId: 'es_PE',
                      onResult: (result) {
                        setModalState(() {
                          parseVoiceInput(result.recognizedWords);
                          if (result.finalResult) {
                            isListening = false;
                          }
                        });
                      },
                    );
                  }
                } else {
                  setModalState(() => isListening = false);
                  speech.stop();
                }
              }

              return Container(
                margin: const EdgeInsets.only(top: 60),
                decoration: BoxDecoration(
                  color: theme.dialogBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Registrar Gasto', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                                  const SizedBox(height: 4),
                                  Text('¿En qué gastaste hoy?', style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
                                ],
                              ),
                              FloatingActionButton.small(
                                onPressed: listenVoice,
                                backgroundColor: isListening ? Colors.redAccent : theme.colorScheme.primary.withOpacity(0.1),
                                elevation: 0,
                                child: Icon(
                                  isListening ? Icons.mic : Icons.mic_none, 
                                  color: isListening ? Colors.white : theme.colorScheme.primary
                                ),
                              ),
                            ],
                          ),
                          if (isListening)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Te escucho... ej: "45 soles en comida con BCP"', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontStyle: FontStyle.italic)),
                            ),
                          const SizedBox(height: 20),

                          // Asistente Financiero Banner
                          if (recommendedCard != null && isRecommended)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '¡Sugerencia! Usa esta tarjeta para acercarte a tu meta de membresía mensual.',
                                      style: GoogleFonts.inter(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Card selector
                          DropdownButtonFormField<CreditCard>(
                            decoration: _inputDecoration('Tarjeta de Crédito', theme),
                            dropdownColor: isDark ? const Color(0xFF252540) : Colors.white,
                            style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600),
                            value: selectedCard,
                            hint: Text('Selecciona una tarjeta', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color)),
                            items: cards.map((c) {
                              final bData = BankCatalog.getBankData(c.banco);
                              final isRec = recommendedCard?.id == c.id;
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
                                    Text('${c.banco} · ${c.nombreTarjeta}', style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color)),
                                    if (isRec) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                    ]
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedCard = val),
                            validator: (val) => val == null ? 'Selecciona una tarjeta' : null,
                          ),
                          const SizedBox(height: 20),

                          // Category selector (emoji grid)
                          Text('Categoría', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                    color: isSelected ? cat.color.withOpacity(0.25) : (isDark ? const Color(0xFF1E1E38) : Colors.grey[200]),
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
                            style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w700),
                            onChanged: (_) => setModalState(() {}), // Trigger recommender
                            decoration: _inputDecoration('Monto del consumo', theme).copyWith(
                              prefixText: 'S/ ',
                              prefixStyle: GoogleFonts.inter(color: currentCardBank?.primaryColor ?? theme.colorScheme.primary, fontSize: 22, fontWeight: FontWeight.w700),
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
                                backgroundColor: currentCardBank?.primaryColor ?? theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                try {
                                  await ref.read(expensesProvider.notifier).addExpense(
                                    tarjetaId: selectedCard!.id,
                                    monto: double.parse(montoController.text),
                                    categoria: selectedCategory,
                                  );
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('¡Gasto registrado con éxito! 🎉'),
                                        backgroundColor: Colors.green,
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
    },
  );
}

InputDecoration _inputDecoration(String label, ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E1E38) : Colors.grey[200],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}
