import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'support_request.dart';

/// Persists a [SupportRequest]. Behind an interface so the screen tests against a
/// fake; [FirestoreSupportRepository] is the real Firebase sink.
abstract interface class SupportRepository {
  /// Store the request for the signed-in [user]; returns the new record id.
  Future<String> submit({
    required AuthUser user,
    required SupportRequest request,
  });
}

/// Writes support requests to Firestore `support_requests`. Rules make this
/// collection client-write-only and owner-scoped (a client can create its own
/// request but never read the queue) — see firestore.rules. The scan summary is
/// included ONLY when the user opted to share it.
class FirestoreSupportRepository implements SupportRepository {
  FirestoreSupportRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<String> submit({
    required AuthUser user,
    required SupportRequest request,
  }) async {
    final doc = await _db.collection('support_requests').add({
      'userId': user.uid, // must equal request.auth.uid (enforced by rules)
      'userName': user.displayName,
      'userEmail': user.email,
      'callbackNumber': request.callbackNumber.trim(),
      'preferredTime': request.preferredTime.name,
      'shareFindings': request.shareFindings,
      if (request.shareFindings && request.findingsSummary != null)
        'findings': request.findingsSummary,
      'shareLocation': request.shareLocation,
      if (request.shareLocation && request.timezone != null)
        'timezone': request.timezone,
      if (request.shareLocation && (request.area?.trim().isNotEmpty ?? false))
        'area': request.area!.trim(),
      'note': request.note.trim(),
      'status': 'new',
      'source': 'ieye-secure',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
