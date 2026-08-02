import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../core/homescan/scanner.dart';
import '../../theme/ieye_theme.dart';
import '../../widgets/bytesbrains_badge.dart';
import 'auth_service.dart';
import 'speech_input.dart';
import 'support_repository.dart';
import 'support_request.dart';

/// Raise a request for professional help — a BytesBrains specialist closes what a
/// passive scan can only flag. Sign in with Google/Apple (no password, no typo'd
/// email), an opt-in toggle (off by default) to attach the scan, a callback
/// number and time, an optional note (with voice-to-text), and — only if the
/// user opts in — timezone + area.
///
/// Honest by construction: everything shared is on this screen and opt-in; the
/// home inventory travels only when the user says so, and nothing else leaves the
/// phone. All I/O is behind injected interfaces so the flow is fully testable.
class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({
    super.key,
    required this.auth,
    required this.repository,
    this.report,
    this.speech = const NoSpeechInput(),
  });

  final AuthService auth;
  final SupportRepository repository;

  /// The scan to (optionally) attach. Null when opened outside a scan.
  final ScanReport? report;
  final SpeechInput speech;

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  AuthUser? _user;
  bool _busy = false; // sign-in or submit in flight
  String? _error;

  // Form state.
  final _callback = TextEditingController();
  final _area = TextEditingController();
  final _note = TextEditingController();
  PreferredTime _time = PreferredTime.anytime;
  // Off by default: sharing the home inventory is a choice the user makes, never
  // a pre-checked box (matches SupportRequest's "opt-in, defaults to NOT shared").
  bool _shareFindings = false;
  bool _shareLocation = false;

  // Speech.
  bool _speechReady = false;
  String _noteBeforeListen = '';

  String? _submittedId;

  @override
  void initState() {
    super.initState();
    _user = widget.auth.currentUser;
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await widget.speech.init();
    if (mounted) setState(() => _speechReady = ok);
  }

  @override
  void dispose() {
    // The promise on the tin: the mic listens only while this screen asks it to.
    // Leaving mid-dictation must end the platform speech session, not orphan it.
    widget.speech.stop();
    _callback.dispose();
    _area.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _signIn(Future<AuthUser?> Function() method) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await method();
      if (!mounted) return;
      setState(() => _user = user);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Sign-in didn’t complete. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleMic() async {
    if (widget.speech.isListening) {
      await widget.speech.stop();
      if (mounted) setState(() {});
      return;
    }
    // Each transcript replaces everything after this snapshot, so anything typed
    // while listening is overwritten — acceptable for a dictation session.
    _noteBeforeListen = _note.text.trim();
    await widget.speech.start(
      onText: (t) {
        // A transcript can land after the screen is gone (dispose stops the
        // engine, but a result may already be in flight).
        if (!mounted) return;
        _note.text = _noteBeforeListen.isEmpty ? t : '$_noteBeforeListen $t';
        _note.selection =
            TextSelection.collapsed(offset: _note.text.length);
        setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final user = _user;
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = DateTime.now();
    final req = SupportRequest(
      callbackNumber: _callback.text,
      preferredTime: _time,
      note: _note.text,
      shareFindings: _shareFindings && widget.report != null,
      findingsSummary: _shareFindings && widget.report != null
          ? summarizeReport(widget.report!)
          : null,
      shareLocation: _shareLocation,
      timezone: _shareLocation
          ? '${now.timeZoneName} (UTC${_offset(now.timeZoneOffset)})'
          : null,
      area: _shareLocation ? _area.text : null,
    );
    try {
      final id = await widget.repository.submit(user: user, request: req);
      if (!mounted) return;
      setState(() => _submittedId = id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'We couldn’t send it just now. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _offset(Duration d) {
    final sign = d.isNegative ? '-' : '+';
    final h = d.abs().inHours;
    final m = d.abs().inMinutes % 60;
    return '$sign$h:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: IEyeColors.paper,
        foregroundColor: IEyeColors.charcoal,
        elevation: 0,
        title: const Text(
          'Talk to a specialist',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _body(context),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_submittedId != null) {
      return _Sent(onDone: () => Navigator.of(context).pop());
    }
    if (_user == null) {
      return _SignIn(
        busy: _busy,
        error: _error,
        onGoogle: () => _signIn(widget.auth.signInWithGoogle),
        onApple: () => _signIn(widget.auth.signInWithApple),
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = _user!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A specialist will call you back',
          style: text.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'A BytesBrains specialist can go deeper than a passive scan and help you '
          'close what it found — safely, on a call at a time that suits you.',
          style: text.bodyLarge?.copyWith(color: IEyeColors.charcoalSoft),
        ),
        const SizedBox(height: 20),

        _SignedInChip(user: user, onSignOut: () async {
          await widget.auth.signOut();
          if (mounted) setState(() => _user = null);
        }),
        const SizedBox(height: 20),

        // Opt-in: attach the scan summary. Only when we have a report.
        if (widget.report != null) ...[
          _ShareFindingsTile(
            value: _shareFindings,
            report: widget.report!,
            onChanged: (v) => setState(() => _shareFindings = v),
          ),
          const SizedBox(height: 16),
        ],

        _FieldLabel('Callback number'),
        TextField(
          controller: _callback,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          decoration: _dec('A number we can reach you on'),
        ),
        const SizedBox(height: 20),

        _FieldLabel('Best time to call'),
        Wrap(
          spacing: 8,
          children: [
            for (final t in PreferredTime.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _time == t,
                onSelected: (_) => setState(() => _time = t),
                selectedColor: IEyeColors.amber.withValues(alpha: 0.30),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Opt-in: timezone + a typed area (never GPS), so the callback lands at a
        // sane local hour.
        _ShareLocationTile(
          value: _shareLocation,
          onChanged: (v) => setState(() => _shareLocation = v),
        ),
        if (_shareLocation) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _area,
            decoration: _dec('Area / city (optional)'),
          ),
        ],
        const SizedBox(height: 20),

        _FieldLabel('Anything you’d like us to know'),
        TextField(
          controller: _note,
          maxLines: 4,
          decoration: _dec('Type a note — or tap the mic to speak it').copyWith(
            suffixIcon: _speechReady
                ? IconButton(
                    icon: Icon(
                      widget.speech.isListening ? Icons.stop_circle : Icons.mic_none,
                      color: widget.speech.isListening
                          ? IEyeColors.amberDeep
                          : IEyeColors.tealDeep,
                    ),
                    tooltip: widget.speech.isListening
                        ? 'Stop'
                        : 'Speak your note',
                    onPressed: _toggleMic,
                  )
                : null,
          ),
        ),
        if (widget.speech.isListening) ...[
          const SizedBox(height: 6),
          Text(
            'Listening… tap the stop icon when you’re done.',
            style: text.bodyMedium?.copyWith(
              fontSize: 13,
              color: IEyeColors.amberDeep,
            ),
          ),
        ],
        const SizedBox(height: 24),

        if (_error != null) ...[
          Text(
            _error!,
            style: text.bodyMedium?.copyWith(color: IEyeColors.amberDeep),
          ),
          const SizedBox(height: 12),
        ],

        FilledButton.icon(
          onPressed:
              (_busy || !SupportRequest.isValidCallbackNumber(_callback.text))
                  ? null
                  : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Send my request'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 16),
        Text(
          'We only send what you chose on this screen. Nothing else — no scan '
          'details, no location — leaves your phone unless you turned it on.',
          style: text.bodyMedium?.copyWith(
            fontSize: 13,
            color: IEyeColors.charcoalMuted,
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: BytesBrainsBadge()),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: IEyeColors.paperDim,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: IEyeColors.charcoal,
      ),
    ),
  );
}

/// The sign-in gate — why we ask, then Google + Apple. No email field, on purpose.
class _SignIn extends StatelessWidget {
  const _SignIn({
    required this.busy,
    required this.error,
    required this.onGoogle,
    required this.onApple,
  });
  final bool busy;
  final String? error;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  /// Apple sign-in is native-only today: on Android it needs a web-flow Service
  /// ID we don't have yet (tied to the Apple Developer Program, #79). Better no
  /// button than one that can only fail.
  static bool get _appleAvailable =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.support_agent, color: IEyeColors.tealDeep, size: 44),
        const SizedBox(height: 18),
        Text(
          'Sign in so we can reach you',
          style: text.headlineSmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 12),
        Text(
          'We use your Google or Apple sign-in only to attach your name to this '
          'request — no password to remember, and no email to type wrong. You '
          'choose what else to share on the next screen.',
          style: text.bodyLarge?.copyWith(color: IEyeColors.charcoalSoft),
        ),
        const SizedBox(height: 28),
        if (error != null) ...[
          Text(error!, style: text.bodyMedium?.copyWith(color: IEyeColors.amberDeep)),
          const SizedBox(height: 12),
        ],
        _AuthButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          onPressed: busy ? null : onGoogle,
        ),
        if (_appleAvailable) ...[
          const SizedBox(height: 12),
          _AuthButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onPressed: busy ? null : onApple,
          ),
        ],
        if (busy) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 28),
        const Center(child: BytesBrainsBadge()),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24, color: IEyeColors.charcoal),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: IEyeColors.charcoal,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: IEyeColors.charcoalMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SignedInChip extends StatelessWidget {
  const _SignedInChip({required this.user, required this.onSignOut});
  final AuthUser user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final who = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!
        : (user.email ?? 'Signed in');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              color: IEyeColors.tealDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signed in as $who',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => onSignOut(),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

/// The opt-in to attach the scan, with a plain summary of exactly what goes.
class _ShareFindingsTile extends StatelessWidget {
  const _ShareFindingsTile({
    required this.value,
    required this.report,
    required this.onChanged,
  });
  final bool value;
  final ScanReport report;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Share my scan results with the specialist',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: IEyeColors.amber,
              ),
            ],
          ),
          Text(
            // Itemise what actually travels (see summarizeReport) — counts alone
            // would undersell it, and honest copy is the brand.
            value
                ? 'They’ll see a summary: ${report.deviceCount} devices, '
                    '${report.findingCount} findings '
                    '(${report.criticalCount} critical) — each flagged device’s '
                    'type, name, local network address and finding titles. No '
                    'passwords — the scan never had any.'
                : 'Off — they’ll only see your note. You can describe it in your '
                    'own words instead.',
            style: text.bodyMedium?.copyWith(
              fontSize: 13,
              color: IEyeColors.charcoalMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLocationTile extends StatelessWidget {
  const _ShareLocationTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: IEyeColors.paperDim,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Share my timezone and area',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: IEyeColors.amber,
              ),
            ],
          ),
          Text(
            'Optional — helps us call at a sensible local hour. Timezone only, '
            'plus an area if you type one. Never your exact location.',
            style: text.bodyMedium?.copyWith(
              fontSize: 13,
              color: IEyeColors.charcoalMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The confirmation after a successful submit.
class _Sent extends StatelessWidget {
  const _Sent({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: IEyeColors.tealDeep, size: 56),
          const SizedBox(height: 20),
          Text(
            'Request sent',
            style: text.headlineSmall?.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'A BytesBrains specialist will call you back at the time you chose. '
            'Nothing more leaves your phone.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: IEyeColors.charcoalSoft),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(minimumSize: const Size(160, 50)),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
