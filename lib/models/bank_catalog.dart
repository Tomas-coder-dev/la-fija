import 'package:flutter/material.dart';

class BankData {
  final String name;
  final String logoUrl;
  final String assetPath;
  final Color textColor;

  const BankData({
    required this.name,
    required this.logoUrl,
    required this.assetPath,
    this.textColor = Colors.white,
  });
}

class BankCatalog {
  static final List<BankData> banks = [
    // BCP
    BankData(
      name: 'BCP Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      assetPath: 'assets/cards/bcp_clasica.png',
    ),
    BankData(
      name: 'BCP Oro',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      assetPath: 'assets/cards/bcp_oro.png',
      textColor: Colors.black87,
    ),
    BankData(
      name: 'BCP Signature/Black',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png',
      assetPath: 'assets/cards/bcp_black.png',
    ),
    
    // BBVA
    BankData(
      name: 'BBVA Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png',
      assetPath: 'assets/cards/bbva_clasica.png',
    ),
    BankData(
      name: 'BBVA Black',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png',
      assetPath: 'assets/cards/bbva_black.png',
    ),

    // Interbank
    BankData(
      name: 'Interbank Clásica',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png',
      assetPath: 'assets/cards/interbank_clasica.png',
    ),
    BankData(
      name: 'Interbank Black/Platinum',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png',
      assetPath: 'assets/cards/interbank_black.png',
    ),

    // Scotiabank
    BankData(
      name: 'Scotiabank',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Scotiabank_Logo.svg/512px-Scotiabank_Logo.svg.png',
      assetPath: 'assets/cards/scotiabank.png',
    ),

    // Tarjetas de Tiendas (CMR / Ripley)
    BankData(
      name: 'CMR Falabella',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Logo_Falabella.svg/512px-Logo_Falabella.svg.png',
      assetPath: 'assets/cards/cmr.png',
    ),
    BankData(
      name: 'Banco Ripley',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Ripley_Peru_Logo.svg/512px-Ripley_Peru_Logo.svg.png',
      assetPath: 'assets/cards/ripley.png',
    ),
    
    // Diners Club / Premium genérica
    BankData(
      name: 'Diners Club',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Diners_Club_Logo3.svg/512px-Diners_Club_Logo3.svg.png',
      assetPath: 'assets/cards/diners.png',
      textColor: Colors.black87,
    ),
    BankData(
      name: 'Otra / Genérica',
      logoUrl: 'https://cdn-icons-png.flaticon.com/512/628/628522.png',
      assetPath: 'assets/cards/generica.png',
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
