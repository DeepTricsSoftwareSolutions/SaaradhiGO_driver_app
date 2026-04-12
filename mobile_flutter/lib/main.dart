import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/ride/ride_provider.dart';
import 'features/ride/bloc/ride_bloc.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/verification_pending_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/active_trip_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/about_screen.dart';
import 'screens/register_screen.dart';
import 'screens/ride_request_screen.dart';
import 'screens/pickup_navigation_screen.dart';
import 'screens/start_ride_screen.dart';
import 'screens/live_trip_screen.dart';
import 'screens/end_trip_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only (mobile behaviour)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent (mobile look)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()..add(AuthCheckSession())),
        BlocProvider(create: (context) => RideBloc()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RideProvider()),
        ],
        child: const SaaradhiGoApp(),
      ),
    ),
  );
}

class SaaradhiGoApp extends StatelessWidget {
  const SaaradhiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaradhiGO Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Mobile viewport wrapper — constrains to phone width when running on web/desktop
      builder: (context, child) {
        return _MobileViewport(child: child!);
      },
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/verification': (context) => const VerificationPendingScreen(),
        '/earnings': (context) => const EarningsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/about': (context) => const AboutScreen(),
        '/active-trip': (context) => const ActiveTripScreen(),
        '/ride-request': (context) => const RideRequestScreen(),
        '/pickup-navigation': (context) => const PickupNavigationScreen(),
        '/start-ride': (context) => const StartRideScreen(),
        '/live-trip': (context) => const LiveTripScreen(),
        '/end-trip': (context) => const EndTripScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatScreen(riderId: args['riderId'], riderName: args['riderName']);
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => OtpScreen(
              phone: args['phone'],
              isRegistration: args['isRegistration'] ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}

/// Constrains the app to a mobile-sized viewport (max 430px wide) when
/// running on web or desktop. On real mobile devices this is a no-op.
class _MobileViewport extends StatelessWidget {
  final Widget child;
  const _MobileViewport({required this.child});

  @override
  Widget build(BuildContext context) {
    // On actual mobile the short side is always ≤ 430 dp, so skip wrapper
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 430) return child;

    // On web/desktop: center a phone-sized frame
    final size = MediaQuery.of(context).size;
    final mobileWidth = size.width < 430 ? size.width : 430.0;
    // Allow more height in the browser so nothing is cut off
    final mobileHeight = size.height < 900 ? size.height * 0.98 : 900.0;

    return Container(
      color: const Color(0xFF0F0F1A),
      alignment: Alignment.center,
      child: Container(
        width: mobileWidth,
        height: mobileHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(screenWidth <= 430 ? 0 : 44),
          border: Border.all(color: Colors.white12, width: screenWidth <= 430 ? 0 : 2),
          boxShadow: [
            if (screenWidth > 430)
              BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.1), blurRadius: 100),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth <= 430 ? 0 : 42),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(mobileWidth, mobileHeight),
              padding: screenWidth <= 430 
                  ? MediaQuery.of(context).padding 
                  : const EdgeInsets.only(top: 44, bottom: 34),
              viewPadding: screenWidth <= 430 
                  ? MediaQuery.of(context).viewPadding 
                  : const EdgeInsets.only(top: 44, bottom: 34),
              viewInsets: MediaQuery.of(context).viewInsets,
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.hasSeenSplash) {
          return const SplashScreen();
        }

        if (auth.token == null) {
          return const LoginScreen();
        }

        // Logic for which screen based on status
        final status = auth.user?['status'];
        if (status == 'PENDING') {
          return const OnboardingScreen();
        } else if (status == 'VERIFYING') {
          return const VerificationPendingScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}

