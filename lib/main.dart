import 'package:expt/audio_test.dart';
import 'package:expt/home.dart';
import 'package:expt/practice.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  final app = App();
  runApp(app);
}

class App extends StatelessWidget {
  App({super.key});

  final router = GoRouter(
    // パス
    initialLocation: '/a',
    routes: [
      GoRoute(
        path: '/a',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/b',
        builder: (context, state) => const TestPage(),
      ),
      GoRoute(
        path: '/c',
        builder: (context, state) => const PracticePage(),
      ),
    ]
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}