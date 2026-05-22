import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:go_router/go_router.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';
import 'pages/home_page.dart';
import 'pages/people_list_page.dart';
import 'pages/person_detail_page.dart';
import 'pages/person_form_page.dart';
import 'pages/settings_page.dart';
import 'pages/account_page.dart';
import 'pages/places_list_page.dart';
import 'pages/place_detail_page.dart';
import 'pages/place_form_page.dart';
import 'pages/memories_list_page.dart';
import 'pages/memory_detail_page.dart';
import 'pages/memory_form_page.dart';
import 'pages/calendar_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/account',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AccountPage(),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic);
            return ScaleTransition(
              alignment: Alignment.topRight,
              scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
              child: child,
            );
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/people',
              builder: (_, __) => const PeopleListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const PersonFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) =>
                      PersonDetailPage(personId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (_, state) =>
                          PersonFormPage(personId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/places',
              builder: (_, __) => const PlacesListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const PlaceFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) =>
                      PlaceDetailPage(placeId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (_, state) =>
                          PlaceFormPage(placeId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/memories',
              builder: (_, __) => const MemoriesListPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const MemoryFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) =>
                      MemoryDetailPage(memoryId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (_, state) =>
                          MemoryFormPage(memoryId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (_, __) => const CalendarPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsPage()),
          ]),
        ],
      ),
    ],
  );
});

class LifeLogApp extends ConsumerStatefulWidget {
  const LifeLogApp({super.key});

  @override
  ConsumerState<LifeLogApp> createState() => _LifeLogAppState();
}

class _LifeLogAppState extends ConsumerState<LifeLogApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await loadPersistedPreferences(ref);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final colors = ref.watch(appColorsProvider);
    final router = ref.watch(routerProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        _rememberDynamicSchemes(ref, lightDynamic, darkDynamic);
        final theme = AppTheme.build(colors, isDark: isDark);

        if (!_ready) {
          return MaterialApp(
            title: 'LifeLog',
            debugShowCheckedModeBanner: false,
            theme: theme,
            builder: _systemUiBuilder(isDark),
            home: GradientBackground(
              colors: colors,
              isDark: isDark,
              child: const Scaffold(
                  body: Center(child: CircularProgressIndicator())),
            ),
          );
        }

        return MaterialApp.router(
          title: 'LifeLog',
          debugShowCheckedModeBanner: false,
          theme: theme,
          builder: _systemUiBuilder(isDark),
          routerConfig: router,
        );
      },
    );
  }
}

void _rememberDynamicSchemes(
  WidgetRef ref,
  ColorScheme? lightDynamic,
  ColorScheme? darkDynamic,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.read(dynamicLightColorSchemeProvider) != lightDynamic) {
      ref.read(dynamicLightColorSchemeProvider.notifier).state = lightDynamic;
    }
    if (ref.read(dynamicDarkColorSchemeProvider) != darkDynamic) {
      ref.read(dynamicDarkColorSchemeProvider.notifier).state = darkDynamic;
    }
  });
}

TransitionBuilder _systemUiBuilder(bool isDark) {
  return (context, child) {
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent.withAlpha(1),
        systemNavigationBarContrastEnforced: false,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  };
}

class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final colors = ref.watch(appColorsProvider);

    return GradientBackground(
      colors: colors,
      isDark: isDark,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: GlassBottomNav(
          currentIndex: navigationShell.currentIndex,
          colors: colors,
          onTap: (index) {
            navigationShell.goBranch(index,
                initialLocation: index == navigationShell.currentIndex);
          },
        ),
      ),
    );
  }
}
