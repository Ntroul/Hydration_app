import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'theme/app_colors.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_profile.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gysjshfvkbocjmhfgawp.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5c2pzaGZ2a2JvY2ptaGZnYXdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODQxMjUsImV4cCI6MjA5NTQ2MDEyNX0.VgGcuinb0nMQlR8gp-qskzIxSmuUB-CnmX4TvXcJq_Q',
  );

  runApp(const MyApp());
}

final _profile = UserProfile();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydration Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          surface: AppColors.surface,
          primary: AppColors.primary,
          onSurface: AppColors.text,
        ),
      ),
      home: const _RootRouter(),
    );
  }
}


class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _loggedIn = false;

  void _onLogin() => setState(() => _loggedIn = true);
  void _onGoToRegister() => setState(() => _loggedIn = true);

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(
        onLogin:        _onLogin,
        onGoToRegister: _onGoToRegister,
      );
    }
    return ListenableBuilder(
      listenable: _profile,
      builder: (context, _) {
        if (!_profile.onboarded) {
          return OnboardingScreen(
            profile:    _profile,
            onComplete: () {},
          );
        }

        return AppShell(profile: _profile);
      },
    );
  }
}

class AppShell extends StatefulWidget {

  final UserProfile profile;
  const AppShell({super.key, required this.profile});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const HistoryScreen(),
      SettingsScreen(profile: widget.profile),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}