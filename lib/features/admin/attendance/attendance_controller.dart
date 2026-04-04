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

  AttendanceController() {
    _initialize();
  }

  int get presentCount {
    return _availableMembers
        .where((user) => _draftAttendance[user.uid] ?? _savedAttendance[user.uid] ?? false)
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

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestoreService
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
          .first;
      _messId = userDoc.messId;

      if (_messId != null) {
        final messDoc = await _firestoreService
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
            .first;
        _messCreatedAt = messDoc.createdAt;
      }

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

  bool isMarkedPresent(String uid) {
    return _draftAttendance[uid] ?? _savedAttendance[uid] ?? false;
  }

  void toggleAttendance(String uid, bool value) {
    if (!_isAttendanceEditable) return;
    _draftAttendance[uid] = value;
    notifyListeners();
  }

  Future<void> _loadAttendance() async {
    if (_messId == null) return;

    _isLoading = true;
    _draftAttendance.clear();
    _savedAttendance.clear();
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
      _computeAttendanceWindow();

      final users = await _firestoreService
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
              approved: true,
              permanentOff: data['permanentOff'] ?? false,
              morningOff: data['morningOff'] ?? false,
              eveningOff: data['eveningOff'] ?? false,
            ),
            sort: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          )
          .first;

      final clientUsers = users.where((u) {
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

      final availabilityDocs = await _firestoreService
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
          .first;

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

      _availableMembers = clientUsers.where((u) => !offUids.contains(u.uid)).toList();

      final attendanceId = _attendanceDocId;
      final savedRecords = await _firestoreService
          .collectionStream(
            path: 'attendance/$attendanceId/records',
            builder: (data, id) => AttendanceRecord(
              uid: id,
              name: data['name'] ?? '',
              present: data['present'] ?? false,
            ),
          )
          .first;

      final savedRecordMap = {
        for (final record in savedRecords) record.uid: record,
      };

      for (final user in _availableMembers) {
        final savedRecord = savedRecordMap[user.uid];
        _savedAttendance[user.uid] = savedRecord?.present ?? false;
        _draftAttendance[user.uid] = savedRecord?.present ?? false;
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        _savedAttendance[user.uid] = present;
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
