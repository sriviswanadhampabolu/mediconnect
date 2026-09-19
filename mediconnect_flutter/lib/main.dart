import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localization.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/triage_provider.dart';
import 'providers/pharmacy_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/owner_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediConnectApp());
}

class MediConnectApp extends StatelessWidget {
  const MediConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocalization()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TriageProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<AppLocalization>(
        builder: (context, localization, _) {
          return MaterialApp(
            title: 'MediConnect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // First screen: asks for role & credentials
                if (!auth.isLoggedIn) {
                  return const AuthScreen();
                }

                // Role-based navigation: Owner vs Customer
                if (auth.isOwner) {
                  return const OwnerDashboardScreen();
                }

                return const HomeScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
