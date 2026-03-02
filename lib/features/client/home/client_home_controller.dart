import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/user_model.dart';
import '../../../models/mess_model.dart';

class ClientHomeController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  UserModel? get user => _user;

  MessModel? _joinedMess;
  MessModel? get joinedMess => _joinedMess;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _userSubscription;

  ClientHomeController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Listen to user doc for real-time updates (e.g. after approval)
      _userSubscription = _firestoreService.documentStream(
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
      ).listen(
        (userModel) async {
          _user = userModel;

          // Fetch joined mess details if user has a messId
          if (userModel.messId != null && userModel.messId!.isNotEmpty) {
            try {
              _joinedMess = await _firestoreService.documentStream(
                path: 'messes/${userModel.messId}',
                builder: (data, id) => MessModel(
                  messId: id,
                  messName: data['messName'] ?? '',
                  createdBy: data['createdBy'] ?? '',
                  createdAt: (data['createdAt'] as Timestamp).toDate(),
                ),
              ).first;
            } catch (e) {
              _joinedMess = null;
            }
          } else {
            _joinedMess = null;
          }

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

  /// Stream of all messes (excluding the one user already joined)
  Stream<List<MessModel>> get messesStream => _firestoreService.collectionStream(
    path: 'messes',
    builder: (data, id) => MessModel(
      messId: id,
      messName: data['messName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    ),
  );

  Future<void> joinMess(BuildContext context, MessModel mess) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Update user doc with messId and pending approval
      await _firestoreService.updateData(
        path: 'users/${user.uid}',
        data: {
          'messId': mess.messId,
          'approved': false,
        },
      );

      // Send approval request to admin
      await _notificationService.sendNotification(
        messId: mess.messId,
        type: NotificationType.approvalRequest,
        fromUid: user.uid,
        toUid: mess.createdBy,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent! Waiting for admin approval.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    }
  }

  void refresh() {
    _joinedMess = null;
    _initialize();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
