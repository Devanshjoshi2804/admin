import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:freight_flow_flutter/screens/dashboard_screen.dart';
import 'package:freight_flow_flutter/screens/trips_screen.dart';
import 'package:freight_flow_flutter/screens/trip_detail_screen.dart';
import 'package:freight_flow_flutter/screens/ftl_booking_screen.dart';
import 'package:freight_flow_flutter/screens/payments_screen.dart';
import 'package:freight_flow_flutter/screens/payment_detail_screen.dart';
import 'package:freight_flow_flutter/screens/clients_screen.dart';
import 'package:freight_flow_flutter/screens/client_form_screen.dart';
import 'package:freight_flow_flutter/screens/client_onboarding_screen.dart';
import 'package:freight_flow_flutter/screens/suppliers_screen.dart';
import 'package:freight_flow_flutter/screens/supplier_form_screen.dart';
import 'package:freight_flow_flutter/screens/supplier_onboarding_screen.dart';
import 'package:freight_flow_flutter/screens/vehicles_screen.dart';
import 'package:freight_flow_flutter/screens/vehicle_onboarding_screen.dart';
import 'package:freight_flow_flutter/screens/settings_screen.dart';
import 'package:freight_flow_flutter/screens/help_screen.dart';
import 'package:freight_flow_flutter/screens/payment_dashboard.dart';
import 'package:freight_flow_flutter/screens/debug_onboarding_screen.dart';
import 'package:freight_flow_flutter/screens/ultra_fast_dashboard_screen.dart';
import 'package:freight_flow_flutter/screens/ultra_fast_trips_screen.dart';
import 'package:freight_flow_flutter/api/api_service.dart';

// Setup router
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    // Ultra-fast dashboard route
    GoRoute(
      path: '/ultra-fast',
      builder: (context, state) => const UltraFastDashboardScreen(),
    ),
    // Ultra-fast trips route
    GoRoute(
      path: '/ultra-fast-trips',
      builder: (context, state) => const UltraFastTripsScreen(),
    ),
    GoRoute(
      path: '/trips',
      builder: (context, state) => const TripsScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const FTLBookingScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => TripDetailScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    // Add a redirect for /booking to maintain backward compatibility
    GoRoute(
      path: '/booking',
      redirect: (_, __) => '/trips/new',
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const PaymentDashboardScreen(),
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientsScreen(),
      routes: [
        GoRoute(
          path: 'onboarding',
          builder: (context, state) => const ClientOnboardingScreen(),
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) => const ClientFormScreen(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final clientId = state.pathParameters['id']!;
            return ClientFormScreen(clientId: clientId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/suppliers',
      builder: (context, state) => const SuppliersScreen(),
      routes: [
        GoRoute(
          path: 'onboarding',
          builder: (context, state) => const SupplierOnboardingScreen(),
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) => const SupplierFormScreen(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final supplierId = state.pathParameters['id']!;
            return SupplierFormScreen(supplierId: supplierId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/vehicles',
      builder: (context, state) => VehiclesScreen(),
      routes: [
        GoRoute(
          path: 'onboarding',
          builder: (context, state) => const VehicleOnboardingScreen(),
        ),
      ],
    ),
    // Remove duplicate /payments route
    GoRoute(
      path: '/payments/details',
      builder: (context, state) => const PaymentsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/debug',
      builder: (context, state) => const DebugOnboardingScreen(),
    ),
  ],
);

void main() {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
  
  // Initialize API service
  final apiService = ApiService();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Freight Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
