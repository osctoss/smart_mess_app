import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final reference = _db.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _db.doc(path);
    await reference.update(data);
  }

  Future<void> deleteData({required String path}) async {
    final reference = _db.doc(path);
    await reference.delete();
  }

  Stream<T> documentStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
  }) {
    final reference = _db.doc(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) => builder(snapshot.data()!, snapshot.id));
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T a, T b)? sort,
  }) {
    Query query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((snapshot) =>
              builder(snapshot.data() as Map<String, dynamic>, snapshot.id))
          .where((value) => value != null)
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Future<void> approveMemberAndAssignRollNumber(String messId, String uid) async {
    final messRef = _db.collection('messes').doc(messId);
    final userRef = _db.collection('users').doc(uid);
    final dietRef = _db.collection('dietBalances').doc(uid);

    await _db.runTransaction((transaction) async {
      final messDoc = await transaction.get(messRef);
      if (!messDoc.exists) return;

      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final bool wasApproved = userData['approved'] ?? false;

      final data = messDoc.data()!;
      final int currentRollNumber = data['lastRollNumber'] ?? 0;
      final int nextRollNumber = currentRollNumber + 1;

      transaction.update(messRef, {'lastRollNumber': nextRollNumber});
      transaction.update(userRef, {
        'approved': true,
        'role': 'CLIENT',
        'messId': messId,
        'rollNumber': nextRollNumber,
      });

      // Reset diet balance if this is a fresh approval for the mess.
      // E.g., user left previous mess and joins a new one.
      if (!wasApproved) {
        transaction.set(dietRef, {
          'uid': uid,
          'totalDiets': 0,
          'remainingDiets': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
