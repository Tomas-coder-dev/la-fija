import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'tabs/cards_tab.dart';
import 'tabs/expenses_tab.dart';
import 'tabs/membership_tab.dart';
import 'tabs/analytics_tab.dart';
import '../widgets/modals/add_expense_modal.dart';
import '../widgets/modals/add_card_modal.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const CardsTab(),
    const ExpensesTab(),
    const MembershipTab(),
    const AnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.bottomNavigationBarTheme.backgroundColor?.withOpacity(0.85) ?? (isDark ? const Color(0xDD12121E) : const Color(0xDDFFFFFF)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(0.1),
                )
              ],
            ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey.withOpacity(0.3),
              hoverColor: Colors.grey.withOpacity(0.1),
              gap: 8,
              activeColor: theme.bottomNavigationBarTheme.selectedItemColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: isDark 
                  ? theme.bottomNavigationBarTheme.selectedItemColor!.withOpacity(0.1) 
                  : theme.bottomNavigationBarTheme.selectedItemColor!.withOpacity(0.1),
              color: theme.bottomNavigationBarTheme.unselectedItemColor,
              tabs: const [
                GButton(
                  icon: Icons.credit_card,
                  text: 'Tarjetas',
                ),
                GButton(
                  icon: Icons.receipt_long_rounded,
                  text: 'Gastos',
                ),
                GButton(
                  icon: Icons.star_border_rounded,
                  text: 'Membresía',
                ),
                GButton(
                  icon: Icons.bar_chart_rounded,
                  text: 'Resumen',
                ),
              ],
              selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                showAddCardModal(context);
              },
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tarjeta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                showAddExpenseModal(context);
              },
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }
}
