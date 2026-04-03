import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/cashbook_provider.dart';
import 'providers/note_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInitializationWrapper());
}

class AppInitializationWrapper extends StatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  State<AppInitializationWrapper> createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase asynchronously
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Initialize notifications
      await NotificationService.init();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Continue anyway to prevent app from being stuck
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading screen while initializing
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A4FD1), Color(0xFF6B5CE6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Initializing...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // App is initialized, show the main app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CashbookProvider()),
        ChangeNotifierProxyProvider<CashbookProvider, TransactionProvider>(
          create: (context) => TransactionProvider(context.read<CashbookProvider>()),
          update: (context, cashbookProvider, previous) =>
              TransactionProvider(cashbookProvider),
        ),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const LifeManagerApp(),
    );
  }
}

class LifeManagerApp extends StatelessWidget {
  const LifeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AllInOneApp',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/auth': (_) => const AuthGate(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedUserId;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    final authProvider = context.read<AuthProvider>();
    authProvider.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid;
    _handleAuthState(userId);
  }

  void _handleAuthState(String? userId) {
    // User logged out
    if (userId == null) {
      if (_loadedUserId != null) {
        // Clear local state
        context.read<CashbookProvider>().reset();
        context.read<TodoProvider>().reset();
        context.read<NoteProvider>().reset();
        context.read<BudgetProvider>().reset();
      }
      _loadedUserId = null;
      _isSyncing = false;
      return;
    }

    // User logged in - load data from Firestore
    if (_loadedUserId == userId || _isSyncing) {
      return;
    }

    _loadedUserId = userId;
    _isSyncing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Load all data from Firestore for the logged-in user
        await Future.wait([
          context.read<CashbookProvider>().load(),
          context.read<TodoProvider>().load(),
          context.read<NoteProvider>().load(),
          context.read<BudgetProvider>().load(),
        ]);
      } catch (e) {
        debugPrint('Error loading data after login: $e');
      }

      if (!mounted) return;
      setState(() {
        _isSyncing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return const SignInScreen();
    }

    if (_isSyncing) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5A4FD1), Color(0xFF6B5CE6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Loading your data...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MainNavigationScreen();
  }
}
