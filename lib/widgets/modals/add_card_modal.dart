import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/bank_catalog.dart';
import '../../providers/cards_provider.dart';

Future<void> showAddCardModal(BuildContext context) async {
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
      return Consumer(
        builder: (ctx, ref, _) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final theme = Theme.of(ctx);
              final isDark = theme.brightness == Brightness.dark;

              return Container(
                margin: const EdgeInsets.only(top: 50),
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
                          const SizedBox(height: 20),
                          Text('Nueva Tarjeta de Crédito', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                          const SizedBox(height: 6),
                          Text('Elige tu banco y personaliza los detalles', style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
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
                          Text('Banco y Tarjeta', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                      color: isSelected ? null : (isDark ? const Color(0xFF1E1E38) : Colors.grey[200]),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        bank.name,
                                        style: GoogleFonts.inter(
                                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: limiteController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Límite S/', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: cierreController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Día cierre', theme),
                                  validator: (v) => v!.isEmpty ? 'Req.' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: pagoController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Día pago', theme),
                                  validator: (v) => v!.isEmpty ? 'Req.' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                try {
                                  await ref.read(cardsProvider.notifier).addCard(
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
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Tarjeta agregada correctamente')),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                              child: Text('Guardar Tarjeta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
