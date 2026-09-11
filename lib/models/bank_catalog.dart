import 'package:flutter/material.dart';

class BankData {
  final String name;
  final String logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String network;
  
  // Metas de Membresía por defecto
  final double defaultMembershipFee;
  final String defaultExemptionType; // 'monthly_average' o 'monthly_purchase'
  final double defaultExemptionTarget;

  const BankData({
    required this.name,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.network,
    this.defaultMembershipFee = 0.0,
    this.defaultExemptionType = 'monthly_average',
    this.defaultExemptionTarget = 0.0,
  });
}

class BankCatalog {
  // URLs de logos (puedes cambiarlas más adelante si encuentras mejores)
  static const _bcpLogo = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Logo_BCP.svg/512px-Logo_BCP.svg.png';
  static const _cmrLogo = 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Logo_Falabella.svg/512px-Logo_Falabella.svg.png';
  static const _bbvaLogo = 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/BBVA_2019_logo.svg/512px-BBVA_2019_logo.svg.png';
  static const _interbankLogo = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Interbank_logo.svg/512px-Interbank_logo.svg.png';

  // Imagen por defecto temporal hasta que pongas las tuyas
  static const _placeholderImg = 'https://images.unsplash.com/photo-1620202685797-2856c80521ce?q=80&w=600&auto=format&fit=crop';

  static final List<BankData> banks = [
    // BCP
    const BankData(name: 'BCP Light', logoUrl: _bcpLogo, primaryColor: Color(0xFFFF7A00), secondaryColor: Color(0xFFFFFFFF), accentColor: Color(0xFF0057A8), network: 'VISA', defaultMembershipFee: 0, defaultExemptionTarget: 0, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Clásica', logoUrl: _bcpLogo, primaryColor: Color(0xFF0057A8), secondaryColor: Color(0xFFFF6B00), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 80, defaultExemptionTarget: 50, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Oro', logoUrl: _bcpLogo, primaryColor: Color(0xFFC99700), secondaryColor: Color(0xFF003B70), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 170, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Platinum', logoUrl: _bcpLogo, primaryColor: Color(0xFF243447), secondaryColor: Color(0xFFFF7900), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 350, defaultExemptionTarget: 1200, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Signature', logoUrl: _bcpLogo, primaryColor: Color(0xFF102A43), secondaryColor: Color(0xFFD9A441), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 400, defaultExemptionTarget: 3500, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Infinite', logoUrl: _bcpLogo, primaryColor: Color(0xFF111111), secondaryColor: Color(0xFFD4AF37), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 450, defaultExemptionTarget: 4500, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP LATAM Pass', logoUrl: _bcpLogo, primaryColor: Color(0xFF0057A8), secondaryColor: Color(0xFFE31E24), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 80, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BCP Amex', logoUrl: _bcpLogo, primaryColor: Color(0xFF1C1C1C), secondaryColor: Color(0xFFD4AF37), accentColor: Color(0xFFFFFFFF), network: 'AMEX', defaultMembershipFee: 80, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_average'),

    // BBVA
    const BankData(name: 'BBVA Cero', logoUrl: _bbvaLogo, primaryColor: Color(0xFF072146), secondaryColor: Color(0xFF49C5E8), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 0, defaultExemptionTarget: 0, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Bfree', logoUrl: _bbvaLogo, primaryColor: Color(0xFF004481), secondaryColor: Color(0xFF2DCCCD), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 100, defaultExemptionTarget: 200, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Clásica', logoUrl: _bbvaLogo, primaryColor: Color(0xFF072146), secondaryColor: Color(0xFF1464A5), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 80, defaultExemptionTarget: 200, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Oro', logoUrl: _bbvaLogo, primaryColor: Color(0xFFC99700), secondaryColor: Color(0xFF003B70), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 170, defaultExemptionTarget: 200, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Platinum', logoUrl: _bbvaLogo, primaryColor: Color(0xFF072146), secondaryColor: Color(0xFFB8C7D9), accentColor: Color(0xFF49C5E8), network: 'VISA', defaultMembershipFee: 350, defaultExemptionTarget: 800, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Signature', logoUrl: _bbvaLogo, primaryColor: Color(0xFF061E3C), secondaryColor: Color(0xFF6EC6E8), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 400, defaultExemptionTarget: 2000, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Black', logoUrl: _bbvaLogo, primaryColor: Color(0xFF111827), secondaryColor: Color(0xFF4B5563), accentColor: Color(0xFFFFFFFF), network: 'MASTERCARD', defaultMembershipFee: 400, defaultExemptionTarget: 2000, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'BBVA Infinite', logoUrl: _bbvaLogo, primaryColor: Color(0xFF071D2B), secondaryColor: Color(0xFFB9C7D0), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 500, defaultExemptionTarget: 5000, defaultExemptionType: 'monthly_average'),

    // Interbank (1 consumo)
    const BankData(name: 'Interbank Clásica', logoUrl: _interbankLogo, primaryColor: Color(0xFF00A859), secondaryColor: Color(0xFFFFFFFF), accentColor: Color(0xFF003876), network: 'VISA', defaultMembershipFee: 60, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Interbank Oro', logoUrl: _interbankLogo, primaryColor: Color(0xFF00A859), secondaryColor: Color(0xFFD4AF37), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 170, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Interbank Platinum', logoUrl: _interbankLogo, primaryColor: Color(0xFF063B35), secondaryColor: Color(0xFF00A859), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 300, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Interbank Signature', logoUrl: _interbankLogo, primaryColor: Color(0xFF062E2A), secondaryColor: Color(0xFFA7D8D0), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 400, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Interbank Infinite', logoUrl: _interbankLogo, primaryColor: Color(0xFF101C24), secondaryColor: Color(0xFF00A859), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 500, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Interbank Mastercard', logoUrl: _interbankLogo, primaryColor: Color(0xFF151515), secondaryColor: Color(0xFFEB001B), accentColor: Color(0xFFFFFFFF), network: 'MASTERCARD', defaultMembershipFee: 60, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Amex Green', logoUrl: _interbankLogo, primaryColor: Color(0xFF0B5D3B), secondaryColor: Color(0xFFC9D6D0), accentColor: Color(0xFFFFFFFF), network: 'AMEX', defaultMembershipFee: 106, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Amex Gold', logoUrl: _interbankLogo, primaryColor: Color(0xFF191919), secondaryColor: Color(0xFFD4AF37), accentColor: Color(0xFFFFFFFF), network: 'AMEX', defaultMembershipFee: 199, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Amex Platinum', logoUrl: _interbankLogo, primaryColor: Color(0xFFC9CED3), secondaryColor: Color(0xFF263238), accentColor: Color(0xFFFFFFFF), network: 'AMEX', defaultMembershipFee: 300, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),
    const BankData(name: 'Amex Black', logoUrl: _interbankLogo, primaryColor: Color(0xFF080808), secondaryColor: Color(0xFFB8B8B8), accentColor: Color(0xFFFFFFFF), network: 'AMEX', defaultMembershipFee: 420, defaultExemptionTarget: 1, defaultExemptionType: 'monthly_purchase'),

    // CMR / Banco Falabella
    const BankData(name: 'CMR Básica', logoUrl: _cmrLogo, primaryColor: Color(0xFF00A859), secondaryColor: Color(0xFFFFFFFF), accentColor: Color(0xFF333333), network: 'VISA', defaultMembershipFee: 0, defaultExemptionTarget: 0, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'CMR Clásica', logoUrl: _cmrLogo, primaryColor: Color(0xFF008C45), secondaryColor: Color(0xFFFFFFFF), accentColor: Color(0xFF333333), network: 'VISA', defaultMembershipFee: 69, defaultExemptionTarget: 100, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'CMR Platinum', logoUrl: _cmrLogo, primaryColor: Color(0xFF063B2A), secondaryColor: Color(0xFF00A859), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 190, defaultExemptionTarget: 250, defaultExemptionType: 'monthly_average'),
    const BankData(name: 'CMR Signature', logoUrl: _cmrLogo, primaryColor: Color(0xFF111C18), secondaryColor: Color(0xFFA8D5C2), accentColor: Color(0xFFFFFFFF), network: 'VISA', defaultMembershipFee: 290, defaultExemptionTarget: 1000, defaultExemptionType: 'monthly_average'),
  ];

  /// Obtiene la información visual de un banco por su nombre.
  static BankData getBankData(String bankName) {
    return banks.firstWhere(
      (b) => b.name.toLowerCase() == bankName.toLowerCase(),
      orElse: () => banks.last, // 'Otro' por defecto
    );
  }
}
