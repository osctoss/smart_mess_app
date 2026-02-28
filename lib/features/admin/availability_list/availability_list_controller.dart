import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/user_model.dart';
import '../../../models/availability_model.dart';

class AvailabilityListController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  MealType _selectedMeal = MealType.morning;
  MealType get selectedMeal => _selectedMeal;

  List<UserModel> _availableUsers = [];
  List<UserModel> get availableUsers => _availableUsers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _messId;

  AvailabilityListController() {
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
      await _loadAvailability();
    }
  }

  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _loadAvailability();
  }

  void setMealType(MealType? meal) {
    if (meal != null) {
      _selectedMeal = meal;
      _loadAvailability();
    }
  }

  Future<void> _loadAvailability() async {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // 1. Fetch all approved users for this mess
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
        ),
      ).first;

      // 2. Filter users based on Availability Collection
      // This is inefficient (N+1 reads or large read), but with NoSQL structure `availability/{uid_date_meal}`:
      // We can iterate users and check their availability doc.
      // Better: Query `availability` collection for this mess_date_meal and get UIDs.
      // Then filter users list.
      
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

      final offUids = availabilityDocs.where((doc) => doc.status == 'OFF').map((doc) => doc.uid).toSet();

      // Also need to check 'Permanent OFF' from user profile if stored there (User model needs update if using that)
      // Assuming 'Permanent OFF' logic updates the daily availability or is a separate flag.
      // User prompt said "Permanent OFF: users/{uid}.permanentOff = true".
      // I should add `permanentOff` to UserModel.
      
      
      _availableUsers = users.where((user) {
        // Mocking permanentOff check as false for now if not in model
        // bool isPermanentOff = user.permanentOff; // Now available in model
        bool isOffForMeal = offUids.contains(user.uid);
        
        return !isOffForMeal && !user.permanentOff;
      }).toList();

      // Create Retention / Snapshot Logic
      // "Create attendance document. Delete older beyond 3."
      // Since this is a "List View", maybe we shouldn't create a snapshot every time we View?
      // But specs say "PAGE 7b – ADMIN AVAILABILITY LIST ... Create attendance doc."
      // Let's assume hitting this page "Finalizes" or "Checks" attendance.
      // To avoid duplicate docs for same meal/date, we check existence.
      
      final attendanceId = '${_messId}_${dateStr}_${_selectedMeal == MealType.morning ? "MORNING" : "EVENING"}';
      final attendanceRef = FirebaseFirestore.instance.collection('attendance').doc(attendanceId);
      final attendanceDoc = await attendanceRef.get();
      
      if (!attendanceDoc.exists) {
         await attendanceRef.set({
           'messId': _messId,
           'date': dateStr,
           'meal': _selectedMeal == MealType.morning ? 'MORNING' : 'EVENING',
           'createdAt': FieldValue.serverTimestamp(),
         });
         
         // Clean up older docs
         final allAttendance = await _firestoreService.collectionStream(
            path: 'attendance',
            queryBuilder: (query) => query.where('messId', isEqualTo: _messId).orderBy('createdAt', descending: true),
            builder: (data, id) => id, // Just IDs
         ).first;
         
         if (allAttendance.length > 3) {
            for (var i = 3; i < allAttendance.length; i++) {
               await _firestoreService.deleteData(path: 'attendance/${allAttendance[i]}');
            }
         }
      }
      
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
