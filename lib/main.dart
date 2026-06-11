import 'package:flutter/material.dart';
import 'package:hydration_app/screens/sign_up_screen.dart';

import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'theme/app_colors.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydration_app/services/notification_services.dart';

import 'models/user_profile.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gysjshfvkbocjmhfgawp.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5c2pzaGZ2a2JvY2ptaGZnYXdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODQxMjUsImV4cCI6MjA5NTQ2MDEyNX0.VgGcuinb0nMQlR8gp-qskzIxSmuUB-CnmX4TvXcJq_Q',
  );

  await NotificationService.init();

  final plugin = FlutterLocalNotificationsPlugin();

  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await android?.requestNotificationsPermission();

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
  String _screen = 'login';

  Future<void> _onLogin() async {
    setState(() => _screen = 'loading');
    try {final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _screen = 'login');
      return;

      }
    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id, name, age, weight, daily_goal')
        .eq('id', userId)
        .maybeSingle();
      // final existing = await Supabase.instance.client
      //     .from('profiles')
      //     .select('id')
      //     .eq('id', userId)
      //     .maybeSingle();

      // if (existing != null) {
      //   _profile.skipOnboarding();
      //   setState(() => _screen = 'app');
      // }
    if (existing != null) {
      _profile.completeOnboarding(
        name: existing['name'] ?? '',
        age: existing['age'] ?? 0,
        weightKg: (existing['weight'] ?? 0).toDouble(),
      );

      setState(() => _screen = 'app');
    } else {
        setState(() => _screen = 'onboarding');
      }
    } catch (_) {
      setState(() => _screen = 'onboarding');
    }
  }

  void _onGoToRegister() => setState(() => _screen = 'register');

  void _onRegister()     => setState(() => _screen = 'onboarding');
  void _onBackToLogin()  => setState(() => _screen = 'login');

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case 'login':
        return LoginScreen(
          onLogin:        _onLogin,
          onGoToRegister: _onGoToRegister,
        );

      case 'register':
        return RegisterScreen(
          onRegister:  _onRegister,
          onGoToLogin: _onBackToLogin,
        );

      case 'loading':
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

      case 'onboarding':
        return ListenableBuilder(
          listenable: _profile,
          builder: (context, _) {
            if (_profile.onboarded) return AppShell(profile: _profile);
            return OnboardingScreen(
              profile:    _profile,
              onComplete: () {},
            );
          },
        );

      default: // 'app'
        return AppShell(profile: _profile);
    }
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
      backgroundColor: AppColors.background,
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

