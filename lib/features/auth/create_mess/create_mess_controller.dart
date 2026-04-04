import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/routes/app_routes.dart';

class CreateMessController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController messNameController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> createMess(BuildContext context) async {
    final messName = messNameController.text.trim();

    if (messName.isEmpty) {
      _errorMessage = 'Mess Name is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check maximum 3 messes
      final createdMessesSnapshot = await FirebaseFirestore.instance
          .collection('messes')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      
      if (createdMessesSnapshot.docs.length >= 3) {
        _errorMessage = 'Maximum of 3 messes allowed per admin';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final messId = const Uuid().v4();

      // 1. Create Mess Document
      await _firestoreService.setData(
        path: 'messes/$messId',
        data: {
          'messId': messId,
          'messName': messName,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // 2. Update User Document
      await _firestoreService.updateData(
        path: 'users/${user.uid}',
        data: {
          'messId': messId,
          // Admin is auto-approved for their own mess? Usually yes.
          'approved': true, 
        },
      );

      // 3. Navigate to Admin Home
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminHome, (route) => false);
      
    } catch (e) {
      _errorMessage = 'Failed to create mess: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
