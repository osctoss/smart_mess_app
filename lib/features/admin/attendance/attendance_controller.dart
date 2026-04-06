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
import '../../../models/attendance_model.dart';

class AttendanceController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  MealType _selectedMeal = MealType.morning;
  MealType get selectedMeal => _selectedMeal;

  List<UserModel> _availableMembers = [];
  List<UserModel> get availableMembers => _availableMembers;

  final Map<String, bool> _savedAttendance = {};
  final Map<String, bool> _draftAttendance = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isAttendanceEditable = false;
  bool get isAttendanceEditable => _isAttendanceEditable;

  String? _attendanceWindowMessage;
  String? get attendanceWindowMessage => _attendanceWindowMessage;

  String? _messId;
  DateTime? _messCreatedAt;

  StreamSubscription? _userSub;
  StreamSubscription? _messSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _availSub;
  StreamSubscription? _recordsSub;

  List<UserModel> _rawUsers = [];
  List<AvailabilityModel> _rawAvails = [];
  List<AttendanceRecord> _rawRecords = [];

  AttendanceController() {
    _initialize();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _messSub?.cancel();
    _usersSub?.cancel();
    _availSub?.cancel();
    _recordsSub?.cancel();
    super.dispose();
  }

  int get presentCount {
    return _availableMembers
        .where((user) => _draftAttendance[user.uid] ?? false)
        .length;
  }

  bool get hasUnsavedChanges {
    if (_draftAttendance.length != _savedAttendance.length) {
      return true;
    }
    for (final entry in _draftAttendance.entries) {
      if ((_savedAttendance[entry.key] ?? false) != entry.value) {
        return true;
      }
    }
    for (final entry in _savedAttendance.entries) {
      if ((_draftAttendance[entry.key] ?? false) != entry.value) {
        return true;
      }
    }
    return false;
  }

  void _initialize() {
    final user = _auth.currentUser;
    if (user != null) {
      _userSub?.cancel();
      _userSub = _firestoreService
          .documentStream(
            path: 'users/${user.uid}',
            builder: (data, id) => UserModel(
              uid: id,
              name: '',
              contactNumber: '',
              role: '',
              createdAt: DateTime.now(),
              messId: data['messId'],
            ),
          )
          .listen((userDoc) {
        _messId = userDoc.messId;
        if (_messId != null) {
          _messSub?.cancel();
          _messSub = _firestoreService
              .documentStream(
                path: 'messes/$_messId',
                builder: (data, id) => MessModel(
                  messId: id,
                  messName: data['messName'] ?? '',
                  createdBy: data['createdBy'] ?? '',
                  createdAt: data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now(),
                ),
              )
              .listen((messDoc) {
            _messCreatedAt = messDoc.createdAt;
            _loadAttendance();
          });
        }
      });
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

  bool isMarkedPresent(String uid) {
    return _draftAttendance[uid] ?? false;
  }

  void toggleAttendance(String uid, bool value) {
    if (!_isAttendanceEditable) return;
    _draftAttendance[uid] = value;
    notifyListeners();
  }

  void _loadAttendance() {
    if (_messId == null) return;

    _isLoading = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    _computeAttendanceWindow();

    _usersSub?.cancel();
    _usersSub = _firestoreService
        .collectionStream(
          path: 'users',
          queryBuilder: (query) => query
              .where('messId', isEqualTo: _messId)
              .where('approved', isEqualTo: true),
          builder: (data, id) => UserModel(
            uid: id,
            name: data['name'] ?? '',
            contactNumber: data['contactNumber'] ?? '',
            role: data['role'] ?? '',
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            messId: _messId,
            rollNumber: data['rollNumber'],
            approved: true,
            permanentOff: data['permanentOff'] ?? false,
            morningOff: data['morningOff'] ?? false,
            eveningOff: data['eveningOff'] ?? false,
          ),
          sort: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        )
        .listen((users) {
      _rawUsers = users;
      _recalculateState();
    });

    _availSub?.cancel();
    _availSub = _firestoreService
        .collectionStream(
          path: 'availability',
          queryBuilder: (query) => query
              .where('messId', isEqualTo: _messId)
              .where('date', isEqualTo: dateStr)
              .where(
                'meal',
                isEqualTo: _selectedMeal == MealType.morning
                    ? 'MORNING'
                    : 'EVENING',
              ),
          builder: (data, id) => AvailabilityModel(
            uid: data['uid'],
            messId: data['messId'],
            date: data['date'],
            meal: data['meal'],
            status: data['status'],
          ),
        )
        .listen((docs) {
      _rawAvails = docs;
      _recalculateState();
    });

    final attendanceId = _attendanceDocId;
    _recordsSub?.cancel();
    _recordsSub = _firestoreService
        .collectionStream(
          path: 'attendance/$attendanceId/records',
          builder: (data, id) => AttendanceRecord(
            uid: id,
            name: data['name'] ?? '',
            present: data['present'] ?? false,
          ),
        )
        .listen((records) {
      _rawRecords = records;
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

    final clientUsers = _rawUsers.where((u) {
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

    for (final doc in _rawAvails) {
      if (doc.status == 'OFF') {
        offUids.add(doc.uid);
      } else if (doc.status == 'ON') {
        offUids.remove(doc.uid); // They explicitly marked ON, override settings
      }
    }

    _availableMembers = clientUsers.where((u) => !offUids.contains(u.uid)).toList();

    for (final record in _rawRecords) {
      _savedAttendance[record.uid] = record.present;
    }

    // Set _draftAttendance to _savedAttendance for missing keys
    for (final user in _availableMembers) {
      if (!_draftAttendance.containsKey(user.uid)) {
         _draftAttendance[user.uid] = _savedAttendance[user.uid] ?? false;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  String get _attendanceDocId {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final meal = _selectedMeal == MealType.morning ? 'MORNING' : 'EVENING';
    return '${_messId}_${dateStr}_$meal';
  }

  void _computeAttendanceWindow() {
    final now = DateTime.now();
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (_selectedMeal == MealType.morning) {
      final start = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        7,
      );
      final end = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        15,
      );

      _isAttendanceEditable =
          !now.isBefore(start) && now.isBefore(end);
      _attendanceWindowMessage = _isAttendanceEditable
          ? 'Morning attendance can be marked until 3:00 PM.'
          : 'Morning attendance is editable only from 7:00 AM to 3:00 PM on that date.';
      return;
    }

    final start = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      15,
    );
    final end = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day + 1,
      7,
    );

    _isAttendanceEditable =
        !now.isBefore(start) && now.isBefore(end);
    _attendanceWindowMessage = _isAttendanceEditable
        ? 'Evening attendance can be marked until 7:00 AM tomorrow.'
        : 'Evening attendance is editable only from 3:00 PM to 7:00 AM the next day.';
  }

  Future<bool> saveAttendance() async {
    if (_isSaving || _messId == null) {
      return false;
    }

    if (!hasUnsavedChanges) {
      return true;
    }

    if (!_isAttendanceEditable) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final meal = _selectedMeal == MealType.morning ? 'MORNING' : 'EVENING';
      final attendanceId = _attendanceDocId;

      await _firestoreService.setData(
        path: 'attendance/$attendanceId',
        data: {
          'messId': _messId,
          'date': dateStr,
          'meal': meal,
          'presentCount': presentCount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        merge: true,
      );

      for (final user in _availableMembers) {
        final present = _draftAttendance[user.uid] ?? false;
        await _firestoreService.setData(
          path: 'attendance/$attendanceId/records/${user.uid}',
          data: {
            'uid': user.uid,
            'name': user.name,
            'present': present,
          },
          merge: true,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
