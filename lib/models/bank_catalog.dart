import 'package:flutter/material.dart';

class BankData {
  final String name;
  final String logoUrl;
  final List<Color> backgroundColors;
  final Color textColor;

  const BankData({
    required this.name,
    required this.logoUrl,
    required this.backgroundColors,
    this.textColor = Colors.white,
  });
}

class BankCatalog {
  static final List<BankData> banks = [
    BankData(
      name: 'BCP',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      backgroundColors: [Colors.orange.shade800, Colors.orange.shade500],
    ),
    BankData(
      name: 'BBVA',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png',
      backgroundColors: [const Color(0xFF072146), const Color(0xFF1464A5)],
    ),
    BankData(
      name: 'Interbank',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png',
      backgroundColors: [const Color(0xFF009B3A), const Color(0xFF003876)],
    ),
    BankData(
      name: 'Scotiabank',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Scotiabank_Logo.svg/512px-Scotiabank_Logo.svg.png',
      backgroundColors: [const Color(0xFFED1B24), const Color(0xFFA10000)],
    ),
    BankData(
      name: 'Falabella',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Logo_Falabella.svg/512px-Logo_Falabella.svg.png',
      backgroundColors: [const Color(0xFFB1D235), const Color(0xFF4C9F38)],
    ),
    BankData(
      name: 'Ripley',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Ripley_Peru_Logo.svg/512px-Ripley_Peru_Logo.svg.png',
      backgroundColors: [const Color(0xFF2C2A29), const Color(0xFF111111)],
    ),
    BankData(
      name: 'Otro / Premium',
      logoUrl: 'https://cdn-icons-png.flaticon.com/512/628/628522.png',
      backgroundColors: [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)],
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
