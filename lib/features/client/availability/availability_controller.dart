import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';

class AvailabilityController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isMorningOn = true;
  bool get isMorningOn => _isMorningOn;
  
  bool _isEveningOn = true;
  bool get isEveningOn => _isEveningOn;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLockedMorning = false;
  bool get isLockedMorning => _isLockedMorning;

  bool _isLockedEvening = false;
  bool get isLockedEvening => _isLockedEvening;

  bool _isPermanentOff = false;
  bool get isPermanentOff => _isPermanentOff;

  String? _messId;

  AvailabilityController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestoreService.documentStream(
         path: 'users/${user.uid}',
         builder: (data, id) => UserModel(
            uid: id,
            name: '', contactNumber: '', role: '', createdAt: DateTime.now(),
            messId: data['messId'],
            permanentOff: data['permanentOff'] ?? false,
         ),
      ).first;
      _messId = userDoc.messId;
      _isPermanentOff = userDoc.permanentOff;
      await _loadAvailability(_selectedDate);
    } else {
       _isLoading = false;
       notifyListeners();
    }
  }

  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _loadAvailability(date);
  }

  Future<void> _loadAvailability(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check Locks (Strict 7 AM / 3 PM)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (date.isBefore(today)) {
         _isLockedMorning = true;
         _isLockedEvening = true;
      } else if (date.isAfter(today)) {
         _isLockedMorning = false;
         _isLockedEvening = false;
      } else {
         // Today
         _isLockedMorning = now.hour >= 7;
         _isLockedEvening = now.hour >= 15;
      }

      // 2. Fetch Status
      // Mock for now, ideal: query 'availability' collection
      if (_messId != null) {
          // Fetch logic...
      }
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePermanentOff(bool value) async {
     _isLoading = true;
     notifyListeners();
     try {
       final user = _auth.currentUser;
       if (user != null) {
          await _firestoreService.updateData(
             path: 'users/${user.uid}',
             data: {'permanentOff': value},
          );
          _isPermanentOff = value;
          // Also update local availability state if needed?
       }
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  Future<void> toggleMorning(bool value) async {
    if (_isLockedMorning) return;
    _isMorningOn = value;
    notifyListeners();
    // Update Firestore logic here
  }

  Future<void> toggleEvening(bool value) async {
    if (_isLockedEvening) return;
    _isEveningOn = value;
    notifyListeners();
    // Update Firestore logic here
  }
}
