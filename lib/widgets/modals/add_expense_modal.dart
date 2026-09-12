import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/bank_catalog.dart';
import '../../models/credit_card.dart';
import '../../models/expense_category.dart';
import '../../providers/cards_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../services/ai_service.dart';

Future<void> showAddExpenseModal(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  CreditCard? selectedCard;
  final montoController = TextEditingController();
  String selectedCategory = 'otros';

  bool isListening = false;
  bool isProcessingAI = false;
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
          final aiService = ref.read(aiServiceProvider);
          
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

              Future<void> parseVoiceInputWithAI(String text) async {
                if (text.isEmpty) return;
                
                setModalState(() {
                  isListening = false;
                  isProcessingAI = true;
                });

                final availableCards = cards.map((c) => c.banco).toList();
                final availableCategories = ExpenseCategory.all.map((c) => c.key).toList();

                final result = await aiService.parseExpenseVoice(
                  text: text,
                  availableCards: availableCards,
                  availableCategories: availableCategories,
                );

                if (result != null && ctx.mounted) {
                  setModalState(() {
                    if (result['monto'] != null) {
                      montoController.text = result['monto'].toString();
                    }
                    if (result['categoria'] != null && availableCategories.contains(result['categoria'])) {
                      selectedCategory = result['categoria'];
                    }
                    if (result['tarjeta_id'] != null) {
                      final matchedCard = cards.where((c) => 
                        c.banco.toLowerCase() == result['tarjeta_id'].toString().toLowerCase() ||
                        c.nombreTarjeta.toLowerCase() == result['tarjeta_id'].toString().toLowerCase()
                      ).firstOrNull;
                      
                      if (matchedCard != null) {
                        selectedCard = matchedCard;
                      }
                    }
                    isProcessingAI = false;
                  });
                } else {
                  if (ctx.mounted) {
                    setModalState(() => isProcessingAI = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('No se pudo procesar el audio con IA. Intenta de nuevo.'))
                    );
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
                        if (result.finalResult) {
                          parseVoiceInputWithAI(result.recognizedWords);
                        } else {
                          setModalState(() {}); // Force rebuild to show interim text if needed
                        }
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
                                onPressed: isProcessingAI ? null : listenVoice,
                                backgroundColor: isListening ? Colors.redAccent : theme.colorScheme.primary.withOpacity(0.1),
                                elevation: 0,
                                child: isProcessingAI
                                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))
                                    : Icon(
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
                          if (isProcessingAI)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('🧠 Gemini está extrayendo los datos...', style: GoogleFonts.inter(color: theme.colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic)),
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
                              
                              final isCountBased = c.exemptionType == 'count';
                              final currentConsumption = supabaseService.getCurrentCycleConsumption(c, expenses);
                              final currentCount = supabaseService.getCurrentCycleExpenses(c, expenses).length;
                              final targetValue = c.metaMensual;
                              
                              final progressText = targetValue > 0 ? (isCountBased 
                                ? '$currentCount/${targetValue.toInt()}'
                                : 'S/${currentConsumption.toStringAsFixed(0)}/S/${targetValue.toInt()}') : '';

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
                                    if (targetValue > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: currentConsumption >= targetValue || (isCountBased && currentCount >= targetValue) 
                                              ? Colors.green.withOpacity(0.2) 
                                              : Colors.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          progressText, 
                                          style: GoogleFonts.inter(
                                            fontSize: 10, 
                                            fontWeight: FontWeight.w600,
                                            color: currentConsumption >= targetValue || (isCountBased && currentCount >= targetValue) 
                                              ? Colors.green 
                                              : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
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
