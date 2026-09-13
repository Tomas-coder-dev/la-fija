import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/bank_catalog.dart';
import '../../models/credit_card.dart';
import '../../providers/cards_provider.dart';
import '../ui/custom_toast.dart';

Future<void> showAddCardModal(BuildContext context, {CreditCard? cardToEdit}) async {
  final isEditing = cardToEdit != null;
  final formKey = GlobalKey<FormState>();
  
  BankData selectedBank = isEditing 
      ? BankCatalog.getBankData(cardToEdit.banco) 
      : BankCatalog.banks.first;
      
  final nombreController = TextEditingController(text: isEditing ? cardToEdit.nombreTarjeta : selectedBank.network);
  final limiteController = TextEditingController(text: isEditing ? cardToEdit.limiteCredito.toString() : '');
  final cierreController = TextEditingController(text: isEditing ? cardToEdit.diaCierre.toString() : '');
  final pagoController = TextEditingController(text: isEditing ? cardToEdit.diaPago.toString() : '');
  final metaController = TextEditingController(text: isEditing ? cardToEdit.metaMensual.toString() : selectedBank.defaultExemptionTarget.toString());
  final membresiaController = TextEditingController(text: isEditing ? cardToEdit.membershipFee.toString() : selectedBank.defaultMembershipFee.toString());
  String exemptionType = isEditing ? cardToEdit.exemptionType : selectedBank.defaultExemptionType;

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
                          const SizedBox(height: 24),
                          Text(
                            isEditing ? 'Editar Tarjeta' : 'Nueva Tarjeta de Crédito', 
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEditing ? 'Actualiza los detalles de tu tarjeta' : 'Elige tu banco y personaliza los detalles', 
                            style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodySmall?.color)
                          ),
                          const SizedBox(height: 24),

                          // Card Preview Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [selectedBank.primaryColor, selectedBank.secondaryColor]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: selectedBank.primaryColor.withValues(alpha: 0.4), blurRadius: 12),
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
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedBank.isStrictMonthly ? '⚡ Consumo vital cada mes' : '✨ Meta flexible anual',
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

                          const SizedBox(height: 24),

                          // Selector de Banco
                          Text('Banco y Tarjeta', style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
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
                                      if (!isEditing || nombreController.text.isEmpty) {
                                        nombreController.text = bank.network;
                                      }
                                      if (!isEditing || metaController.text.isEmpty || metaController.text == '0.0') {
                                        metaController.text = bank.defaultExemptionTarget.toString();
                                      }
                                      if (!isEditing || membresiaController.text.isEmpty || membresiaController.text == '0.0') {
                                        membresiaController.text = bank.defaultMembershipFee.toString();
                                      }
                                      exemptionType = bank.defaultExemptionType;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 12),
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
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: limiteController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Límite de crédito (S/)', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: cierreController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Día de Cierre', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: pagoController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Día de Pago', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: metaController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Meta (Para no pagar membresía)', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: membresiaController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Costo Membresía Anual', theme),
                                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
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
                                  if (isEditing) {
                                    await ref.read(cardsProvider.notifier).updateCard(
                                      id: cardToEdit.id,
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
                                  } else {
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
                                  }
                                  
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    CustomToast.show(ctx, isEditing ? 'Tarjeta actualizada' : 'Tarjeta agregada');
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    CustomToast.show(ctx, 'Error: $e', isError: true);
                                  }
                                }
                              },
                              child: Text(isEditing ? 'Guardar Cambios' : 'Agregar Tarjeta', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
