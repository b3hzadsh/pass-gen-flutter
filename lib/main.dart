import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:pass_generator/bloc/generate_password/generate_password_bloc.dart';
import 'package:pass_generator/pages/login_page.dart';
import 'package:pass_generator/providers/secret_provider.dart'
    show SecretProvider;
import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider, Provider;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pass_generator/pages/auth_check_page.dart' show AuthCheckScreen;

final supabase = Supabase.instance.client;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SecretProvider()),
        // BlocProvider(create: (context) => PassGenBloc()),
        Provider<PassGenBloc>(
          create: (_) => PassGenBloc(),
          // dispose: (_, bloc) => bloc.dispose(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // handle auth state changes here
      print('Auth event: $event');
      print('Session: $session');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pass Generator',
      home: StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final session = snapshot.data?.session;

          if (session != null) {
            return const AuthCheckScreen();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
