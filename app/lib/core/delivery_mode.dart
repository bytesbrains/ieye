/// The two delivery modes (PRD §5). The detection brain is shared; only the
/// trigger sink swaps. The honest promise differs at this leaf, and the
/// difference is load-bearing:
///   - Easy depends on iEye's servers existing — it may promise REACH, never
///     "inevitable".
///   - Sovereign delivery never touches a server (can't be stopped) — but the
///     fact and timing of check-ins are public and permanent on-chain (#264).
enum DeliveryMode { easy, sovereign }

extension DeliveryModeCopy on DeliveryMode {
  String get title => switch (this) {
    DeliveryMode.easy => 'Easy mode',
    DeliveryMode.sovereign => 'Sovereign mode',
  };

  /// The mode-specific honest promise shown at the comprehension gate. Easy must
  /// NEVER claim inevitability; Sovereign must state the on-chain reality.
  String get honestPromise => switch (this) {
    DeliveryMode.easy =>
      'iEye will fan out across every channel that reaches the people you chose '
          '— a notification, a message, a phone call. It depends on iEye’s servers '
          'being there, so we promise the effort to reach them, never that you’ll '
          'be reached no matter what.',
    DeliveryMode.sovereign =>
      'Delivery never touches a server and cannot be switched off — but the fact '
          'and timing of your check-ins become public and permanent on a public '
          'blockchain. It is coming later; for now, iEye uses Easy mode.',
  };
}
