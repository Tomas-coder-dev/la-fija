import 'package:flutter/material.dart';

class BankData {
  final String name;
  final String logoUrl;
  final String cardImageUrl;
  final List<Color> fallbackColors;
  final Color textColor;

  const BankData({
    required this.name,
    required this.logoUrl,
    required this.cardImageUrl,
    required this.fallbackColors,
    this.textColor = Colors.white,
  });
}

class BankCatalog {
  static final List<BankData> banks = [
    // BCP
    BankData(
      name: 'BCP Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1605380582239-448f108d4b8e?q=80&w=600&auto=format&fit=crop', // Naranja abstracto
      fallbackColors: [Colors.orange.shade800, Colors.orange.shade500],
    ),
    BankData(
      name: 'BCP Oro',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1618501258602-5e197c36a617?q=80&w=600&auto=format&fit=crop', // Dorado abstracto
      fallbackColors: [const Color(0xFFD4AF37), const Color(0xFFF3E5AB)],
      textColor: Colors.black87,
    ),
    BankData(
      name: 'BCP Signature/Black',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1620202685797-2856c80521ce?q=80&w=600&auto=format&fit=crop', // Negro abstracto
      fallbackColors: [const Color(0xFF111111), const Color(0xFF2C2A29)],
    ),
    
    // BBVA
    BankData(
      name: 'BBVA Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=600&auto=format&fit=crop', // Azul abstracto
      fallbackColors: [const Color(0xFF072146), const Color(0xFF1464A5)],
    ),
    BankData(
      name: 'BBVA Black',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600&auto=format&fit=crop', // Azul oscuro
      fallbackColors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
    ),

    // Interbank
    BankData(
      name: 'Interbank Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=600&auto=format&fit=crop', // Verde abstracto
      fallbackColors: [const Color(0xFF009B3A), const Color(0xFF003876)],
    ),
    BankData(
      name: 'Interbank Black/Platinum',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1620202685797-2856c80521ce?q=80&w=600&auto=format&fit=crop', // Negro abstracto
      fallbackColors: [const Color(0xFF1C1C1C), const Color(0xFF383838)],
    ),

    // Scotiabank
    BankData(
      name: 'Scotiabank',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Scotiabank_Logo.svg/512px-Scotiabank_Logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?q=80&w=600&auto=format&fit=crop', // Rojo abstracto
      fallbackColors: [const Color(0xFFED1B24), const Color(0xFFA10000)],
    ),

    // Tarjetas de Tiendas (CMR / Ripley)
    BankData(
      name: 'CMR Falabella',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Logo_Falabella.svg/512px-Logo_Falabella.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1550684376-efcbd6e3f031?q=80&w=600&auto=format&fit=crop', // Verde lima abstracto
      fallbackColors: [const Color(0xFFB1D235), const Color(0xFF4C9F38)],
    ),
    BankData(
      name: 'Banco Ripley',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Ripley_Peru_Logo.svg/512px-Ripley_Peru_Logo.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600&auto=format&fit=crop', // Gris abstracto
      fallbackColors: [const Color(0xFF2C2A29), const Color(0xFF111111)],
    ),
    
    // Diners Club / Premium genérica
    BankData(
      name: 'Diners Club',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Diners_Club_Logo3.svg/512px-Diners_Club_Logo3.svg.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1620202685797-2856c80521ce?q=80&w=600&auto=format&fit=crop', // Gris claro abstracto
      fallbackColors: [const Color(0xFF9E9E9E), const Color(0xFFE0E0E0)],
      textColor: Colors.black87,
    ),
    BankData(
      name: 'Otra / Genérica',
      logoUrl: 'https://cdn-icons-png.flaticon.com/512/628/628522.png',
      cardImageUrl: 'https://images.unsplash.com/photo-1618501258602-5e197c36a617?q=80&w=600&auto=format&fit=crop', // Dorado abstracto
      fallbackColors: [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)],
    ),
  ];

  /// Obtiene la información visual de un banco por su nombre.
  static BankData getBankData(String bankName) {
    return banks.firstWhere(
      (b) => b.name.toLowerCase() == bankName.toLowerCase(),
      orElse: () => banks.last, // 'Otro' por defecto
    );
  }
}
