import 'package:flutter/material.dart';
import 'dart:async';
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

  StreamSubscription? _userSub;
  StreamSubscription? _messSub;
  StreamSubscription? _membersSub;

  AdminDashboardController() {
    _loadData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _messSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }

  void _loadData() {
    _isLoading = true;
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 1. Fetch Admin User to get Mess ID
    _userSub?.cancel();
    _userSub = _firestoreService.documentStream(
      path: 'users/${currentUser.uid}',
      builder: (data, id) => UserModel(
        uid: id,
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        role: data['role'] ?? '',
        messId: data['messId'],
        approved: data['approved'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
    ).listen((userDoc) {
      if (userDoc.messId != null) {
        _listenToMessData(userDoc.messId!);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToMessData(String messId) {
    // 2. Fetch Mess Details
    _messSub?.cancel();
    _messSub = _firestoreService.documentStream(
      path: 'messes/$messId',
      builder: (data, id) => MessModel(
        messId: id,
        messName: data['messName'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
    ).listen((messDoc) {
      _mess = messDoc;
      _isLoading = false;
      notifyListeners();
    });

    // 3. Count Members
    _membersSub?.cancel();
    _membersSub = _firestoreService.collectionStream(
      path: 'users',
      queryBuilder: (query) => query.where('messId', isEqualTo: messId),
      builder: (data, id) => id,
    ).listen((members) {
      _totalMembers = members.length;
      notifyListeners();
    });
  }
}
