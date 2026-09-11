import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_catalog.dart';
import '../models/credit_card.dart';

class CardProgressWidget extends StatelessWidget {
  final CreditCard card;
  final double consumption;
  final NumberFormat currencyFormat;

  const CardProgressWidget({
    super.key,
    required this.card,
    required this.consumption,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final bankData = BankCatalog.getBankData(card.banco);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ?? 'USUARIO';
    final firstName = displayName.split(' ').first.toUpperCase();
    
    // Extract tier name (e.g. "BCP Platinum" -> "PLATINUM")
    final bankPrefix = bankData.name.split(' ').first; // "BCP"
    final tierName = bankData.name.replaceFirst(bankPrefix, '').trim().toUpperCase(); // "PLATINUM"

    final available = card.limiteCredito - consumption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La Tarjeta Física (UI)
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bankData.primaryColor, bankData.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: bankData.primaryColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ruido / Textura sutil
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://www.transparenttextures.com/patterns/stardust.png'),
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
              ),
              // Elemento geométrico decorativo
              Positioned(
                right: -50,
                bottom: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bankData.accentColor.withOpacity(0.1),
                  ),
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Logo/Banco y Red (VISA/AMEX)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bankPrefix,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          bankData.network,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    // Centro: Variedad (PLATINUM, BLACK, etc)
                    Center(
                      child: Text(
                        tierName.isEmpty ? 'CLÁSICA' : tierName,
                        style: GoogleFonts.inter(
                          color: bankData.accentColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 6.0,
                        ),
                      ),
                    ),
                    // Bottom: Nombre y Sparkle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          firstName,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome,
                          color: bankData.accentColor.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Información debajo de la tarjeta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bankData.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '•••• ${card.nombreTarjeta}', // Usamos el nombreTarjeta como identificador o últimos 4
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Límite:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                  Text(currencyFormat.format(card.limiteCredito), style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Disponible:', style: GoogleFonts.inter(color: Colors.green.shade400, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(currencyFormat.format(available > 0 ? available : 0), style: GoogleFonts.inter(color: Colors.green.shade400, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
