import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../application/session_controller.dart';
import '../domain/app_user.dart';

/// Used both for the forced first-login change and from More › Change
/// password. [voluntary] adds a back button and pops on success.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key, this.voluntary = false});

  final bool voluntary;

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).changePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.changePasswordDone)));
      if (widget.voluntary) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pw = _password.text;
    final lengthOk = pw.length >= 8;
    final mixOk = RegExp(r'[A-Za-z]').hasMatch(pw) && RegExp(r'[0-9]').hasMatch(pw);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.voluntary,
        title: Text(l10n.changePasswordTitle),
        actions: [
          if (!widget.voluntary)
            TextButton(
              onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              child: Text(l10n.moreSignOut),
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.changePasswordSubtitle, style: AppTypography.body),
                    const SizedBox(height: AppSpacing.xl),
                    if (_error != null) ...[
                      Text(_error!, style: AppTypography.label.copyWith(color: AppColors.danger)),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AppTextField(
                      label: l10n.changePasswordNew,
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      validator: (v) => passwordMeetsPolicy(v ?? '') ? null : l10n.errorWeakPassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Rule(ok: lengthOk, text: l10n.changePasswordRuleLength),
                    _Rule(ok: mixOk, text: l10n.changePasswordRuleMix),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.changePasswordConfirm,
                      controller: _confirm,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v == _password.text ? null : l10n.changePasswordMismatch,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.changePasswordSubmit,
                      loading: _busy,
                      expand: true,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.inkMute;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
