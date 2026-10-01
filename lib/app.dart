import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/design.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_controller.dart';
import 'core/outbox/outbox.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/session/idle_guard.dart';
import 'core/design/motion/page_transitions.dart';

class AumluxApp extends ConsumerStatefulWidget {
  const AumluxApp({super.key});

  @override
  ConsumerState<AumluxApp> createState() => _AumluxAppState();
}

class _AumluxAppState extends ConsumerState<AumluxApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app is the most common moment signal has returned.
    if (state == AppLifecycleState.resumed) {
      ref.read(outboxProvider.notifier).process();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the outbox alive app-wide without rebuilding on every change.
    ref.listen(outboxProvider, (_, __) {});
    ref.watch(pushControllerProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AumLux',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(locale: locale).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: AppPageTransition(),
          TargetPlatform.iOS: AppPageTransition(),
        }),
      ),
      builder: (context, child) => IdleGuard(child: child ?? const SizedBox.shrink()),
    );
  }
}
