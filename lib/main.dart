import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('es_PE', null);
  
  await Hive.initFlutter();
  await Hive.openBox('offline_cache');

  await Supabase.initialize(
    url: 'https://cobiksksbjjzjydjvjul.supabase.co',
    anonKey: 'sb_publishable_GGoc1nzgX8ANDvADaJ28LQ_w1R5VdvG',
  );

  runApp(const ProviderScope(child: LaFijaApp()));
}

class LaFijaApp extends StatelessWidget {
  const LaFijaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Fija',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Will adapt to device settings
      home: const _AuthGate(),
    );
  }
}

/// Widget que escucha el estado de autenticación de Supabase
/// y enruta al LoginScreen o DashboardScreen según corresponda.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Mientras carga el primer estado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D1A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          );
        }

        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const MainLayout();
        }

        return const LoginScreen();
      },
    );
  }
}
