import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // All approved members for this mess
  List<UserModel> _allMembers = [];
  List<UserModel> get allMembers => _allMembers;

  // Set of UIDs that are OFF (meal-specific or permanentOff)
  Set<String> _offUids = {};
  Set<String> get offUids => _offUids;

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

  /// Check if a given user is available (not off)
  bool isUserAvailable(String uid) => !_offUids.contains(uid);

  /// Count of available members
  int get availableCount => _allMembers.where((u) => isUserAvailable(u.uid)).length;

  Future<void> _loadAvailability() async {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // 1. Fetch ALL approved users for this mess (including admins filtered out later)
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

      // Keep only CLIENTs
      _allMembers = users.where((u) => u.role == 'CLIENT').toList();

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

      // 3. Build the OFF set: permanent off + meal-specific off + availability doc OFF
      _offUids = {};
      
      for (final user in _allMembers) {
        // Permanent off
        if (user.permanentOff) {
          _offUids.add(user.uid);
          continue;
        }
        // Per-meal off from user profile
        if (_selectedMeal == MealType.morning && user.morningOff) {
          _offUids.add(user.uid);
          continue;
        }
        if (_selectedMeal == MealType.evening && user.eveningOff) {
          _offUids.add(user.uid);
          continue;
        }
      }

      // From availability collection
      for (final doc in availabilityDocs) {
        if (doc.status == 'OFF') {
          _offUids.add(doc.uid);
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
