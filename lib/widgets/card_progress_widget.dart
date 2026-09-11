import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_catalog.dart';
import '../models/credit_card.dart';

class CardProgressWidget extends StatefulWidget {
  final CreditCard card;
  final double consumption;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int? daysRemaining;

  const CardProgressWidget({
    super.key,
    required this.card,
    required this.consumption,
    required this.currencyFormat,
    this.onTap,
    this.onDelete,
    this.daysRemaining,
  });

  @override
  State<CardProgressWidget> createState() => _CardProgressWidgetState();
}

class _CardProgressWidgetState extends State<CardProgressWidget> {
  double _xRotation = 0.0;
  double _yRotation = 0.0;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _yRotation -= details.delta.dx * 0.01;
      _xRotation += details.delta.dy * 0.01;
      
      // Clamp the rotation
      _yRotation = _yRotation.clamp(-0.2, 0.2);
      _xRotation = _xRotation.clamp(-0.2, 0.2);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _xRotation = 0.0;
      _yRotation = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankData = BankCatalog.getBankData(widget.card.banco);
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] as String? ?? 'USUARIO';
    final firstName = displayName.split(' ').first.toUpperCase();
    
    // Extract tier name (e.g. "BCP Platinum" -> "PLATINUM")
    final bankPrefix = bankData.name.split(' ').first; // "BCP"
    final tierName = bankData.name.replaceFirst(bankPrefix, '').trim().toUpperCase(); // "PLATINUM"

    final available = widget.card.limiteCredito - widget.consumption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La Tarjeta Física (UI) Interactiva
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Hero(
              tag: 'card_hero_${widget.card.id}',
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0, end: _xRotation),
                  builder: (context, valX, _) {
                    return TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      tween: Tween<double>(begin: 0, end: _yRotation),
                      builder: (context, valY, _) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(valX)
                            ..rotateY(valY),
                          alignment: FractionalOffset.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [bankData.primaryColor, bankData.secondaryColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: bankData.primaryColor.withOpacity(0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Textura decorativa
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
                                // Days remaining badge (si existe)
                                if (widget.daysRemaining != null)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Text(
                                        '⌛ ${widget.daysRemaining} días',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Contenido de la Tarjeta
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
                                          if (widget.daysRemaining == null)
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
                                      // Bottom: Nombre y indicador de tap
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Ver gastos',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  }
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Información debajo de la tarjeta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        bankData.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Eliminar tarjeta',
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
              Text(
                '•••• ${widget.card.nombreTarjeta}',
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
                  Text(widget.currencyFormat.format(widget.card.limiteCredito), style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Disponible:', style: GoogleFonts.inter(color: Colors.green.shade400, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(widget.currencyFormat.format(available > 0 ? available : 0), style: GoogleFonts.inter(color: Colors.green.shade400, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
