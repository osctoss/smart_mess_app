import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/constants/enums.dart';
import '../../../models/mess_model.dart';
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
  DateTime? _messCreatedAt;

  StreamSubscription? _userSub;
  StreamSubscription? _messSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _availabilitySub;

  List<UserModel> _rawUsers = [];
  List<AvailabilityModel> _rawAvails = [];

  AvailabilityListController() {
    _initialize();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _messSub?.cancel();
    _usersSub?.cancel();
    _availabilitySub?.cancel();
    super.dispose();
  }

  void _initialize() {
    final user = _auth.currentUser;
    if (user != null) {
      _userSub?.cancel();
      _userSub = _firestoreService.documentStream(
        path: 'users/${user.uid}',
        builder: (data, id) => UserModel(
          uid: id,
          name: '', contactNumber: '', role: '', createdAt: DateTime.now(),
          messId: data['messId'],
        ),
      ).listen((userDoc) {
        _messId = userDoc.messId;

        if (_messId != null) {
          _messSub?.cancel();
          _messSub = _firestoreService.documentStream(
            path: 'messes/$_messId',
            builder: (data, id) => MessModel(
              messId: id,
              messName: data['messName'] ?? '',
              createdBy: data['createdBy'] ?? '',
              createdAt: data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
            ),
          ).listen((messDoc) {
            _messCreatedAt = messDoc.createdAt;
            _loadAvailability();
          });
        }
      });
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

  void _loadAvailability() {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
    // 1. Fetch ALL approved users for this mess (including admins filtered out later)
    _usersSub?.cancel();
    _usersSub = _firestoreService.collectionStream(
      path: 'users',
      queryBuilder: (query) => query.where('messId', isEqualTo: _messId)
                                    .where('approved', isEqualTo: true),
      builder: (data, id) => UserModel(
        uid: id,
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        role: data['role'] ?? '',
        rollNumber: data['rollNumber'],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        messId: _messId,
        approved: true,
        permanentOff: data['permanentOff'] ?? false,
        morningOff: data['morningOff'] ?? false,
        eveningOff: data['eveningOff'] ?? false,
      ),
    ).listen((users) {
      _rawUsers = users;
      _recalculateState();
    });

    // 2. Fetch availability documents for this date/meal
    _availabilitySub?.cancel();
    _availabilitySub = _firestoreService.collectionStream(
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
    ).listen((docs) {
      _rawAvails = docs;
      _recalculateState();
    });
  }

  void _recalculateState() {
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final messCreatedDay = _messCreatedAt == null
        ? null
        : DateTime(
            _messCreatedAt!.year,
            _messCreatedAt!.month,
            _messCreatedAt!.day,
          );

    // Keep only CLIENTs who had actually joined by the selected date
    _allMembers = _rawUsers.where((u) {
      if (u.role != 'CLIENT') return false;

      final userCreatedDay = DateTime(
        u.createdAt.year,
        u.createdAt.month,
        u.createdAt.day,
      );

      if (messCreatedDay != null && selectedDay.isBefore(messCreatedDay)) {
        return false;
      }

      return !selectedDay.isBefore(userCreatedDay);
    }).toList();

    // Build the OFF set: permanent off + meal-specific off + availability doc OFF
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
    for (final doc in _rawAvails) {
      if (doc.status == 'OFF') {
        _offUids.add(doc.uid);
      } else if (doc.status == 'ON') {
        _offUids.remove(doc.uid); // They marked ON, override settings
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
