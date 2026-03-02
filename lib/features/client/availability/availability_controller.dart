import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/availability_model.dart';

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

  /// Helper to build the availability document ID
  String _availabilityDocId(String uid, String dateStr, String meal) {
    return '${uid}_${dateStr}_$meal';
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

      // 2. Fetch existing availability status from Firestore
      final user = _auth.currentUser;
      if (_messId != null && user != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        // Fetch morning availability
        final morningDocId = _availabilityDocId(user.uid, dateStr, 'MORNING');
        try {
          final morningDoc = await _firestoreService.documentStream(
            path: 'availability/$morningDocId',
            builder: (data, id) => AvailabilityModel(
              uid: data['uid'] ?? '',
              messId: data['messId'] ?? '',
              date: data['date'] ?? '',
              meal: data['meal'] ?? '',
              status: data['status'] ?? 'ON',
            ),
          ).first;
          _isMorningOn = morningDoc.status != 'OFF';
        } catch (e) {
          // Doc doesn't exist — default to ON
          _isMorningOn = true;
        }

        // Fetch evening availability
        final eveningDocId = _availabilityDocId(user.uid, dateStr, 'EVENING');
        try {
          final eveningDoc = await _firestoreService.documentStream(
            path: 'availability/$eveningDocId',
            builder: (data, id) => AvailabilityModel(
              uid: data['uid'] ?? '',
              messId: data['messId'] ?? '',
              date: data['date'] ?? '',
              meal: data['meal'] ?? '',
              status: data['status'] ?? 'ON',
            ),
          ).first;
          _isEveningOn = eveningDoc.status != 'OFF';
        } catch (e) {
          // Doc doesn't exist — default to ON
          _isEveningOn = true;
        }
      }
      
    } catch (e) {
      debugPrint('Error loading availability: $e');
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

    final user = _auth.currentUser;
    if (user == null || _messId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final docId = _availabilityDocId(user.uid, dateStr, 'MORNING');

    await _firestoreService.setData(
      path: 'availability/$docId',
      data: {
        'uid': user.uid,
        'messId': _messId,
        'date': dateStr,
        'meal': 'MORNING',
        'status': value ? 'ON' : 'OFF',
      },
    );
  }

  Future<void> toggleEvening(bool value) async {
    if (_isLockedEvening) return;
    _isEveningOn = value;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null || _messId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final docId = _availabilityDocId(user.uid, dateStr, 'EVENING');

    await _firestoreService.setData(
      path: 'availability/$docId',
      data: {
        'uid': user.uid,
        'messId': _messId,
        'date': dateStr,
        'meal': 'EVENING',
        'status': value ? 'ON' : 'OFF',
      },
    );
  }
}
