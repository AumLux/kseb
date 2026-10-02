import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../application/session_controller.dart';
import '../domain/login_rate_limiter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _limiter = LoginRateLimiter();
  StreamSubscription<int>? _cooldownSub;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cooldownSub = _limiter.cooldownStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cooldownSub?.cancel();
    _limiter.dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _reasonMessage(AppLocalizations l10n, SessionState s) {
    if (s is! SessionSignedOut) return null;
    return switch (s.reason) {
      'not_active' => l10n.loginInactive,
      'no_profile' => l10n.loginNoProfile,
      'idle' => l10n.loginIdleSignedOut,
      'network' => l10n.errorNetwork,
      _ => null,
    };
  }

  Future<void> _submit() async {
    if (_busy || _limiter.isInCooldown) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(_identifier.text, _password.text);
      _limiter.reset();
    } catch (e) {
      final failure = AppFailure.from(e);
      if (failure.code == 'invalid_credentials') _limiter.recordFailure();
      if (mounted) {
        setState(() => _error = failureMessage(context.l10n, failure));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showForgot() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.loginForgotTitle, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.loginForgotBody, style: AppTypography.body),
              const SizedBox(height: AppSpacing.xl),
              AppButton.secondary(
                label: l10n.commonClose,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = _reasonMessage(l10n, ref.watch(sessionProvider));
    final message = _error ?? reason;
    final cooling = _limiter.isInCooldown;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Brand mesh washes the top of the screen; the form floats over white.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: GradientMesh(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FadeSlideIn(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: BrandMark(size: 60),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FadeSlideIn(
                            index: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.loginTitle,
                                  style: AppTypography.display,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.loginSubtitle,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AnimatedSize(
                            duration: AppMotion.base,
                            curve: AppMotion.curve,
                            alignment: Alignment.topCenter,
                            child: message == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.lg,
                                    ),
                                    child: _ErrorBanner(message: message),
                                  ),
                          ),
                          AppTextField(
                            label: l10n.loginIdentifierLabel,
                            hint: l10n.loginIdentifierHint,
                            controller: _identifier,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.loginIdentifierRequired
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: l10n.loginPasswordLabel,
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.loginPasswordRequired
                                : null,
                            suffix: IconButton(
                              tooltip: _obscure
                                  ? l10n.loginShowPassword
                                  : l10n.loginHidePassword,
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: cooling
                                ? l10n.loginCooldown(_limiter.remainingSeconds)
                                : l10n.loginSubmit,
                            loading: _busy,
                            expand: true,
                            onPressed: cooling ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: AppButton.tertiary(
                              label: l10n.loginForgot,
                              onPressed: _showForgot,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: AppSizes.iconMd,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.label.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
