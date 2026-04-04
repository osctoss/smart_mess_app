import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/mess_model.dart';
import '../../../core/routes/app_routes.dart';

class AdminHomeController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _userSubscription;

  AdminHomeController() {
    _initialize();
  }

  void _initialize() {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _userSubscription?.cancel();
      _userSubscription = _firestoreService.documentStream(
        path: 'users/${currentUser.uid}',
        builder: (data, id) => UserModel(
          uid: id,
          name: data['name'] ?? '',
          contactNumber: data['contactNumber'] ?? '',
          role: data['role'] ?? '',
          messId: data['messId'],
          approved: data['approved'] ?? false,
          createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
        ),
      ).listen(
        (userModel) {
          _user = userModel;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Failed to load user data: $e';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<MessModel>> get messesStream {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    
    return _firestoreService.collectionStream(
      path: 'messes',
      queryBuilder: (query) => query.where('createdBy', isEqualTo: currentUser.uid).orderBy('createdAt', descending: false),
      builder: (data, id) => MessModel(
        messId: id,
        messName: data['messName'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      ),
    );
  }

  Future<void> selectMess(BuildContext context, MessModel mess) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Update the user's active messId
      await _firestoreService.updateData(
        path: 'users/${currentUser.uid}',
        data: {'messId': mess.messId},
      );

      if (!context.mounted) return;
      Navigator.pushNamed(context, AppRoutes.adminDashboard);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enter mess: $e')),
      );
    }
  }

  void refresh() {
    _initialize();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
