import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/domain/app_user.dart';
import 'idle_timeout_service.dart';

/// Signs out after inactivity — but only where it protects sensitive data:
/// on the web and for supervisors and above. Field staff on phones are not
/// timed out, because signing back in needs connectivity and would block
/// offline check-ins.
class IdleGuard extends ConsumerStatefulWidget {
  const IdleGuard({super.key, required this.child, this.timeoutMinutes = 15});

  final Widget child;
  final int timeoutMinutes;

  @override
  ConsumerState<IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends ConsumerState<IdleGuard> {
  final _service = IdleTimeoutService();

  bool _shouldGuard(AppUser? user) =>
      user != null && (kIsWeb || user.role.atLeast(AppRole.supervisor));

  void _sync(AppUser? user) {
    if (_shouldGuard(user)) {
      if (!_service.isRunning) {
        _service.start(
          timeoutMinutes: widget.timeoutMinutes,
          onTimeout: () => ref.read(sessionProvider.notifier).signOut(reason: 'idle'),
        );
      }
    } else {
      _service.stop();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    _sync(user);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _service.resetTimer(),
      child: widget.child,
    );
  }
}
