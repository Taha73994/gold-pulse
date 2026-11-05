import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/about_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/ads_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/mentor_screen.dart';
import 'screens/more_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shops_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoldPulseRoot());
}

class GoldPulseRoot extends StatefulWidget {
  const GoldPulseRoot({super.key});

  @override
  State<GoldPulseRoot> createState() => _GoldPulseRootState();
}

class _GoldPulseRootState extends State<GoldPulseRoot> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return AppScope(
          state: _state,
          child: MaterialApp(
            title: _state.en ? 'Gold Pulse' : 'نبض الذهب',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _state.themeMode,
            locale: Locale(_state.en ? 'en' : 'ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: _state.en
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _state.ready ? const ShellScreen() : const SplashScreen(),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween(begin: 0.65, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: const GoldLogo(size: 78),
            ),
            const SizedBox(height: 18),
            Text(
              l.appName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.tagline,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                color: c.muted,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: c.surfaceAlt,
                  color: c.gold,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              l.copyright,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.5,
                color: c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _index = _initialIndex();

  static int _initialIndex() {
    final tab = Uri.base.queryParameters['tab'];
    switch (tab) {
      case 'market':
        return 1;
      case 'mentor':
        return 2;
      case 'shops':
        return 3;
      case 'more':
        return 4;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final screen = Uri.base.queryParameters['screen'];
    if (screen == null || screen.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => _screenFor(screen)));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند العودة للتطبيق: تحديث صامت دون أن يرى المستخدم أي مؤشر.
    if (state == AppLifecycleState.resumed && mounted) {
      AppScope.of(context).refreshAll(silent: true);
    }
  }

  Widget _screenFor(String screen) {
    switch (screen) {
      case 'calculator':
        return const CalculatorScreen();
      case 'currency':
        return const CurrencyScreen();
      case 'news':
        return const NewsScreen();
      case 'alerts':
        return const AlertsScreen();
      case 'ads':
        return const AdsScreen();
      case 'admin':
        return const AdminScreen();
      case 'settings':
        return const SettingsScreen();
      case 'about':
        return const AboutScreen();
      default:
        return const HomeScreen(onNavigate: _noop);
    }
  }

  static void _noop(int _) {}

  void _navigate(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    final pages = [
      HomeScreen(onNavigate: _navigate),
      const MarketScreen(),
      const MentorScreen(),
      const ShopsScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 820;
          if (!wide) return IndexedStack(index: _index, children: pages);
          return ColoredBox(
            color: c.bg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _navigate,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.candlestick_chart_outlined),
                  selectedIcon: const Icon(Icons.candlestick_chart_rounded),
                  label: l.navMarket,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.psychology_outlined),
                  selectedIcon: const Icon(Icons.psychology_rounded),
                  label: l.navMentor,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront_rounded),
                  label: l.navShops,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_view_outlined),
                  selectedIcon: const Icon(Icons.grid_view_rounded),
                  label: l.navMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
