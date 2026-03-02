import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/user_model.dart';
import '../../../models/availability_model.dart';

class AttendanceController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  MealType _selectedMeal = MealType.morning;
  MealType get selectedMeal => _selectedMeal;

  // Only available members (green-dot users)
  List<UserModel> _availableMembers = [];
  List<UserModel> get availableMembers => _availableMembers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _messId;

  AttendanceController() {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestoreService.documentStream(
        path: 'users/${user.uid}',
        builder: (data, id) => UserModel(
          uid: id,
          name: '', contactNumber: '', role: '', createdAt: DateTime.now(),
          messId: data['messId'],
        ),
      ).first;
      _messId = userDoc.messId;
      await _loadAttendance();
    }
  }

  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _loadAttendance();
  }

  void setMealType(MealType? meal) {
    if (meal != null) {
      _selectedMeal = meal;
      _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    if (_messId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 1. Fetch all approved CLIENT users for this mess
      final users = await _firestoreService.collectionStream(
        path: 'users',
        queryBuilder: (query) => query.where('messId', isEqualTo: _messId)
                                      .where('approved', isEqualTo: true),
        builder: (data, id) => UserModel(
          uid: id,
          name: data['name'] ?? '',
          contactNumber: data['contactNumber'] ?? '',
          role: data['role'] ?? '',
          createdAt: DateTime.now(),
          messId: _messId,
          approved: true,
          permanentOff: data['permanentOff'] ?? false,
          morningOff: data['morningOff'] ?? false,
          eveningOff: data['eveningOff'] ?? false,
        ),
      ).first;

      final clientUsers = users.where((u) => u.role == 'CLIENT').toList();

      // 2. Fetch availability documents for this date/meal
      final availabilityDocs = await _firestoreService.collectionStream(
        path: 'availability',
        queryBuilder: (query) => query.where('messId', isEqualTo: _messId)
                                      .where('date', isEqualTo: dateStr)
                                      .where('meal', isEqualTo: _selectedMeal == MealType.morning ? 'MORNING' : 'EVENING'),
        builder: (data, id) => AvailabilityModel(
           uid: data['uid'],
           messId: data['messId'],
           date: data['date'],
           meal: data['meal'],
           status: data['status'],
        ),
      ).first;

      // 3. Build OFF set
      final offUids = <String>{};
      
      for (final user in clientUsers) {
        if (user.permanentOff) {
          offUids.add(user.uid);
          continue;
        }
        if (_selectedMeal == MealType.morning && user.morningOff) {
          offUids.add(user.uid);
          continue;
        }
        if (_selectedMeal == MealType.evening && user.eveningOff) {
          offUids.add(user.uid);
          continue;
        }
      }

      for (final doc in availabilityDocs) {
        if (doc.status == 'OFF') {
          offUids.add(doc.uid);
        }
      }

      // 4. Only keep available members
      _availableMembers = clientUsers.where((u) => !offUids.contains(u.uid)).toList();

      // 5. Create attendance snapshot (if not exists)
      final attendanceId = '${_messId}_${dateStr}_${_selectedMeal == MealType.morning ? "MORNING" : "EVENING"}';
      final attendanceRef = FirebaseFirestore.instance.collection('attendance').doc(attendanceId);
      final attendanceDoc = await attendanceRef.get();
      
      if (!attendanceDoc.exists) {
         await attendanceRef.set({
           'messId': _messId,
           'date': dateStr,
           'meal': _selectedMeal == MealType.morning ? 'MORNING' : 'EVENING',
           'presentCount': _availableMembers.length,
           'createdAt': FieldValue.serverTimestamp(),
         });
         
         // Clean up older docs (keep only 3 latest)
         final allAttendance = await _firestoreService.collectionStream(
            path: 'attendance',
            queryBuilder: (query) => query.where('messId', isEqualTo: _messId).orderBy('createdAt', descending: true),
            builder: (data, id) => id,
         ).first;
         
         if (allAttendance.length > 3) {
            for (var i = 3; i < allAttendance.length; i++) {
               await _firestoreService.deleteData(path: 'attendance/${allAttendance[i]}');
            }
         }
      }

    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
