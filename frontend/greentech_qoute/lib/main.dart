import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/services/api_client.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/quote_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GreentechQuoteApp());
}

class GreentechQuoteApp extends StatelessWidget {
  const GreentechQuoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Greentech Quote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppStartupPage(),
      ),
    );
  }
}

class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key});

  @override
  State<AppStartupPage> createState() => _AppStartupPageState();
}

class _AppStartupPageState extends State<AppStartupPage> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await ApiClient().initialize();
      await context.read<AuthProvider>().initialize();
    } catch (e, stackTrace) {
      debugPrint('❌ App initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashPage();
        }

        if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        }

        final auth = context.watch<AuthProvider>();

        if (!auth.isLoggedIn) {
          return const LoginPage();
        }

        return const QuoteListPage();
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading app...'),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String error;

  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AppStartupPage()),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
