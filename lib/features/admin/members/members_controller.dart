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

  MembersController() {
    _initialize();
  }

  Future<void> _initialize() async {
     _isLoading = true;
     notifyListeners();
     try {
       final user = _auth.currentUser;
       if (user == null) return;
       
       final userDoc = await _firestoreService.documentStream(
          path: 'users/${user.uid}',
          builder: (data, id) => UserModel(
            uid: id,
            name: '', contactNumber: '', role: '', createdAt: DateTime.now(),
            messId: data['messId'],
          ),
        ).first;
        _messId = userDoc.messId;
        
        await _fetchMembers();
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  Future<void> _fetchMembers() async {
    if (_messId == null) return;

    final users = await _firestoreService.collectionStream(
      path: 'users',
      queryBuilder: (query) => query.where('messId', isEqualTo: _messId),
      builder: (data, id) => UserModel(
        uid: id,
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        role: data['role'] ?? '', // Should be CLIENT usually
        messId: _messId,
        approved: data['approved'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      ),
    ).first;

    _members = users.where((u) => u.approved && u.role == 'CLIENT').toList();
    _pendingMembers = users.where((u) => !u.approved && u.role == 'CLIENT').toList();
    notifyListeners();
  }
  
  Future<void> removeMember(String uid) async {
    // Logic: If remainingDiets == 0 -> Delete instantly. Else -> Send delete request.
    
    try {
       // 1. Fetch Diet Balance
       final dietDoc = await _firestoreService.documentStream(
         path: 'dietBalances/$uid',
         builder: (data, id) => data['remainingDiets'] ?? 0,
       ).first; // This might throw if doc doesn't exist, handle gracefull

       final int remainingDiets = dietDoc is int ? dietDoc : 0;

       if (remainingDiets == 0) {
          // Delete Instantly
          await _firestoreService.deleteData(path: 'users/$uid');
          await _firestoreService.deleteData(path: 'dietBalances/$uid'); 
          // Also cleanup other docs? (attendance, etc. - maybe expensive, leave for now)
          await _fetchMembers();
          // SnackBar? Controller doesn't have context easily. notifyListeners can trigger UI.
       } else {
          // Send DELETE_REQUEST
          // Check if already sent?
          await _notificationService.sendNotification(
            messId: _messId!,
            type: NotificationType.deleteRequest, // Ensure Enum has this
            fromUid: _auth.currentUser!.uid,
            toUid: uid,
          );
       }
    } catch (e) {
       debugPrint('Error removing member: $e');
    }
  }

  Future<void> approveMember(String uid) async {
    await _firestoreService.updateData(
      path: 'users/$uid',
      data: {'approved': true},
    );
    await _fetchMembers();
  }
}
