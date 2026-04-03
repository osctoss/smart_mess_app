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

  SelectMessController() {
    _fetchMesses();
  }

  Future<void> _fetchMesses() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch all messes - optimize query later if needed
      _messes = await _firestoreService.collectionStream<MessModel>(
        path: 'messes',
        builder: (data, id) => MessModel(
          messId: id,
          messName: data['messName'] ?? 'Unknown',
          createdBy: data['createdBy'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        ),
      ).first; // Just take first batch for now
      // Stream subscription usually handled by StreamBuilder in UI, but here we fetch once for selection list
      // Creating a stream helper inside Controller or logic to fetch once:
      // Since firestore_service returns Stream, update this to listen or use Future if logic allows.
      // Modifying to use simple QuerySnapshot logic here would be easier, but sticking to service.
      
      // REFACTOR: Service only exposes stream. Let's use it as a stream.
    } catch (e) {
       // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Expose stream for UI
  Stream<List<MessModel>> get messesStream => _firestoreService.collectionStream(
    path: 'messes',
    builder: (data, id) => MessModel(
      messId: id,
      messName: data['messName'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: DateTime.now(), // Placeholder as timestamp conversion might vary
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
