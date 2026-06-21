import 'package:flutter/foundation.dart';

import 'checker.dart';

/// The circle — the people watching over someone (#18, PRD §3D). This is social
/// state, kept deliberately coarse: a checker can see WHO else is on the list and
/// roughly who's nearest, but never a raw live location. Proximity is a bucket,
/// not coordinates.

/// Rough proximity bucket — never raw location (privacy by architecture).
enum Proximity { nearby, sameCity, far }

extension ProximityCopy on Proximity {
  /// Display label for the roster.
  String get label => switch (this) {
    Proximity.nearby => 'Nearby',
    Proximity.sameCity => 'In the city',
    Proximity.far => 'Further away',
  };

  /// Sort order — nearest first.
  int get rank => switch (this) {
    Proximity.nearby => 0,
    Proximity.sameCity => 1,
    Proximity.far => 2,
  };
}

class CircleMember {
  const CircleMember({
    required this.id,
    required this.name,
    required this.reach,
    required this.proximity,
  });

  final String id;
  final String name;

  /// From the handshake (#17): can they physically go check, or call only?
  final CheckerReach reach;
  final Proximity proximity;

  /// "Within driving distance" = can physically reach the person.
  bool get canReachFast => reach == CheckerReach.canGoInPerson;
}

/// An immutable view of the circle with the honest-coverage maths.
class Circle {
  const Circle(this.members);

  final List<CircleMember> members;

  /// Roster ordered nearest-first (then by name for stability).
  List<CircleMember> get byProximity {
    final list = [...members];
    list.sort((a, b) {
      final r = a.proximity.rank.compareTo(b.proximity.rank);
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    return list;
  }

  int get total => members.length;
  int get canReachFastCount => members.where((m) => m.canReachFast).length;

  /// Safe coverage = at least two checkers AND at least one who can physically
  /// reach the person. Anything less is a gap the owner MUST see.
  bool get isSafe => total >= 2 && canReachFastCount >= 1;

  /// Honest coverage note, or null when coverage is safe. Silent gaps are the
  /// lethal failure (PRD §3D), so a degraded circle always has something to say.
  String? get coverageNote {
    if (isSafe) return null;
    if (total == 0) {
      return 'No one is watching over you yet. Add the people you trust.';
    }
    final plural = total == 1 ? 'checker' : 'checkers';
    if (canReachFastCount == 0) {
      return 'You now have $total $plural, but no one close enough to come over. '
          'Add someone nearby.';
    }
    // One checker, and they can reach you — still no backup.
    return 'You now have just one checker. Add another so there’s always backup.';
  }
}

/// Mutable holder for the circle. A resignation updates it immediately and
/// notifies listeners — so owner-visible coverage can never lag behind reality.
class CircleStore extends ChangeNotifier {
  CircleStore(List<CircleMember> members) : _members = [...members];

  final List<CircleMember> _members;
  CircleMember? _lastResigned;
  int? _lastResignedIndex;

  Circle get circle => Circle(_members);

  /// A checker steps down. Kept (with its original position) so it can be undone
  /// gracefully and restored exactly where it was.
  void resign(String id) {
    final idx = _members.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    _lastResignedIndex = idx;
    _lastResigned = _members.removeAt(idx);
    notifyListeners();
  }

  /// Undo the most recent resignation, restoring the member at its original
  /// index so insertion order isn't silently corrupted.
  void undoLastResign() {
    final m = _lastResigned;
    final idx = _lastResignedIndex;
    if (m == null || idx == null) return;
    _members.insert(idx.clamp(0, _members.length), m);
    _lastResigned = null;
    _lastResignedIndex = null;
    notifyListeners();
  }

  bool get canUndo => _lastResigned != null;
}

/// Demo roster for the scaffold: 3 watching, 1 within driving distance — matches
/// the honest-coverage home's default. Replaced by real circle data later.
List<CircleMember> demoCircleMembers() => const [
  CircleMember(
    id: 'maria',
    name: 'Maria',
    reach: CheckerReach.canGoInPerson,
    proximity: Proximity.nearby,
  ),
  CircleMember(
    id: 'tom',
    name: 'Tom',
    reach: CheckerReach.callOnly,
    proximity: Proximity.sameCity,
  ),
  CircleMember(
    id: 'priya',
    name: 'Priya',
    reach: CheckerReach.callOnly,
    proximity: Proximity.far,
  ),
];
