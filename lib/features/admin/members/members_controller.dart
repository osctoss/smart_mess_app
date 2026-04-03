import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/user_model.dart';

class MembersController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _members = [];
  List<UserModel> get members => _members;
  List<UserModel> _pendingMembers = [];
  List<UserModel> get pendingMembers => _pendingMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _messId;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _membersSubscription;

  MembersController() {
    _initialize();
  }

  Future<void> _initialize() async {
     _isLoading = true;
     notifyListeners();
     try {
       final user = _auth.currentUser;
       if (user == null) {
         _errorMessage = 'User not logged in';
         return;
       }
       
       final userDoc = await _firestoreService.documentStream(
          path: 'users/${user.uid}',
          builder: (data, id) => UserModel(
            uid: id,
            name: '', contactNumber: '', role: '', createdAt: DateTime.now(),
            messId: data['messId'],
          ),
        ).first;
        _messId = userDoc.messId;
        
        if (_messId == null) {
          _errorMessage = 'No mess assigned';
          return;
        }

        _listenToMembers();
     } catch (e) {
       _errorMessage = 'Failed to initialize: $e';
       debugPrint('MembersController init error: $e');
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  void _listenToMembers() {
    _membersSubscription?.cancel();
    _membersSubscription = _firestoreService.collectionStream(
      path: 'users',
      queryBuilder: (query) => query.where('messId', isEqualTo: _messId),
      builder: (data, id) => UserModel(
        uid: id,
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        role: data['role'] ?? '',
        messId: _messId,
        approved: data['approved'] ?? false,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      ),
    ).listen(
      (users) {
        _members = users.where((u) => u.approved && u.role == 'CLIENT').toList();
        _pendingMembers = users.where((u) => !u.approved && u.role == 'CLIENT').toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Failed to fetch members: $e';
        debugPrint('MembersController stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<String> removeMember(String uid) async {
    try {
       // Use direct Firestore get() to safely handle missing diet doc
       final dietSnapshot = await FirebaseFirestore.instance
           .collection('dietBalances')
           .doc(uid)
           .get();

       final int remainingDiets = dietSnapshot.exists
           ? (dietSnapshot.data()?['remainingDiets'] ?? 0)
           : 0;

       if (remainingDiets == 0) {
          // Send informational notification
          await _notificationService.sendNotification(
            messId: _messId!,
            type: NotificationType.accountDeleted,
            fromUid: _auth.currentUser!.uid,
            toUid: uid,
            message: 'You have been removed from the mess',
          );
          // Soft-delete: clear messId instead of deleting user doc
          await _firestoreService.updateData(
            path: 'users/$uid',
            data: {'messId': null, 'approved': false},
          );
          // Delete diet balance if it exists
          if (dietSnapshot.exists) {
            try {
              await _firestoreService.deleteData(path: 'dietBalances/$uid');
            } catch (_) {}
          }
          return 'Member removed successfully';
       } else {
          await _notificationService.sendNotification(
            messId: _messId!,
            type: NotificationType.deleteRequest,
            fromUid: _auth.currentUser!.uid,
            toUid: uid,
          );
          return 'Removal request sent';
       }
    } catch (e) {
       debugPrint('Error removing member: $e');
       rethrow;
    }
  }

  Future<void> approveMember(String uid) async {
    await _firestoreService.updateData(
      path: 'users/$uid',
      data: {'approved': true},
    );
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    super.dispose();
  }
}
