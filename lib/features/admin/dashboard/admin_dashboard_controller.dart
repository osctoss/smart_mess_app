import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/mess_model.dart';

class AdminDashboardController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MessModel? _mess;
  MessModel? get mess => _mess;

  int _totalMembers = 0;
  int get totalMembers => _totalMembers;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AdminDashboardController() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 1. Fetch Admin User to get Mess ID
      final userDoc = await _firestoreService.documentStream(
        path: 'users/${currentUser.uid}',
        builder: (data, id) => UserModel(
          uid: id,
          name: data['name'] ?? '',
          contactNumber: data['contactNumber'] ?? '',
          role: data['role'] ?? '',
          messId: data['messId'],
          approved: data['approved'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        ),
      ).first;

      if (userDoc.messId != null) {
        // 2. Fetch Mess Details
        final messDoc = await _firestoreService.documentStream(
          path: 'messes/${userDoc.messId}',
          builder: (data, id) => MessModel(
            messId: id,
            messName: data['messName'] ?? '',
            createdBy: data['createdBy'] ?? '',
            createdAt: (data['createdAt'] as Timestamp).toDate(),
          ),
        ).first;
        _mess = messDoc;

        // 3. Count Members using aggregate query (mocking with generic fetch for now)
        // Ideally use .count() aggregation
        final members = await _firestoreService.collectionStream(
          path: 'users',
          queryBuilder: (query) => query.where('messId', isEqualTo: userDoc.messId),
          builder: (data, id) => id,
        ).first;
        _totalMembers = members.length;
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
