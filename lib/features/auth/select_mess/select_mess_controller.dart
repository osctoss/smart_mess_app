import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/mess_model.dart';
import '../../../core/routes/app_routes.dart';

class SelectMessController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MessModel> _messes = [];
  List<MessModel> get messes => _messes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _messesSub;

  SelectMessController() {
    _fetchMesses();
  }

  @override
  void dispose() {
    _messesSub?.cancel();
    super.dispose();
  }

  void _fetchMesses() {
    _isLoading = true;
    notifyListeners();
    
    _messesSub?.cancel();
    _messesSub = _firestoreService.collectionStream<MessModel>(
      path: 'messes',
      builder: (data, id) => MessModel(
        messId: id,
        messName: data['messName'] ?? 'Unknown',
        createdBy: data['createdBy'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      ),
    ).listen((fetchedMesses) {
      _messes = fetchedMesses;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Failed to load messes: $e';
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Expose stream for UI
  Stream<List<MessModel>> get messesStream => _firestoreService.collectionStream(
    path: 'messes',
    builder: (data, id) => MessModel(
      messId: id,
      messName: data['messName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    ),
  );

  Future<void> joinMess(BuildContext context, MessModel mess) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Update User
      await _firestoreService.updateData(
        path: 'users/${user.uid}',
        data: {
          'messId': mess.messId,
          'approved': false,
        },
      );

      // 2. Send Notification to Admin
      await _notificationService.sendNotification(
        messId: mess.messId,
        type: NotificationType.approvalRequest,
        fromUid: user.uid,
        toUid: mess.createdBy, // Admin UID
      );

      // 3. Navigate to Login or Wait Screen
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      
    } catch (e) {
      _errorMessage = 'Failed to join mess: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
