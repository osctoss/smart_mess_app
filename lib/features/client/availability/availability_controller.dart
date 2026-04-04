import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/availability_model.dart';

class AvailabilityController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int editableFutureDays = 7;

  final Map<String, bool> _savedAvailability = {};
  final Map<String, bool> _draftAvailability = {};

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isLockedMorning = false;
  bool get isLockedMorning => _isLockedMorning;

  bool _isLockedEvening = false;
  bool get isLockedEvening => _isLockedEvening;

  bool _savedPermanentOff = false;
  bool? _draftPermanentOff;
  bool get isPermanentOff => _draftPermanentOff ?? _savedPermanentOff;

  bool get isMorningOn => _availabilityValueFor(_selectedDate, 'MORNING');
  bool get isEveningOn => _availabilityValueFor(_selectedDate, 'EVENING');

  bool get hasUnsavedChanges {
    final hasPermanentOffChange =
        _draftPermanentOff != null && _draftPermanentOff != _savedPermanentOff;
    return hasPermanentOffChange || _draftAvailability.isNotEmpty;
  }

  String? _messId;

  AvailabilityController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
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
              permanentOff: data['permanentOff'] ?? false,
            ),
          )
          .first;

      _messId = userDoc.messId;
      _savedPermanentOff = userDoc.permanentOff;
      await _loadAvailability(_selectedDate);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _loadAvailability(date);
  }

  DateTime get lastEditableDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(const Duration(days: editableFutureDays));
  }

  bool isBeyondEditableRange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.isAfter(lastEditableDate);
  }

  String _availabilityDocId(String uid, String dateStr, String meal) {
    return '${uid}_${dateStr}_$meal';
  }

  String _availabilityKey(DateTime date, String meal) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${dateStr}_$meal';
  }

  bool _availabilityValueFor(DateTime date, String meal) {
    final key = _availabilityKey(date, meal);
    return _draftAvailability[key] ?? _savedAvailability[key] ?? true;
  }

  Future<void> _loadAvailability(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(date.year, date.month, date.day);

      if (selectedDay.isBefore(today)) {
        _isLockedMorning = true;
        _isLockedEvening = true;
      } else if (isBeyondEditableRange(selectedDay)) {
        _isLockedMorning = true;
        _isLockedEvening = true;
      } else if (selectedDay.isAfter(today)) {
        _isLockedMorning = false;
        _isLockedEvening = false;
      } else {
        _isLockedMorning = now.hour >= 7;
        _isLockedEvening = now.hour >= 15;
      }

      final user = _auth.currentUser;
      if (_messId == null || user == null) {
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      await _loadMealAvailability(user.uid, dateStr, 'MORNING');
      await _loadMealAvailability(user.uid, dateStr, 'EVENING');
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMealAvailability(
    String uid,
    String dateStr,
    String meal,
  ) async {
    final docId = _availabilityDocId(uid, dateStr, meal);
    final key = '${dateStr}_$meal';

    try {
      final doc = await _firestoreService
          .documentStream(
            path: 'availability/$docId',
            builder: (data, id) => AvailabilityModel(
              uid: data['uid'] ?? '',
              messId: data['messId'] ?? '',
              date: data['date'] ?? '',
              meal: data['meal'] ?? '',
              status: data['status'] ?? 'ON',
            ),
          )
          .first;
      _savedAvailability[key] = doc.status != 'OFF';
    } catch (_) {
      _savedAvailability[key] = true;
    }
  }

  void togglePermanentOff(bool value) {
    _draftPermanentOff = value;
    if (_draftPermanentOff == _savedPermanentOff) {
      _draftPermanentOff = null;
    }
    notifyListeners();
  }

  void toggleMorning(bool value) {
    if (_isLockedMorning) return;
    _setDraftAvailability(_selectedDate, 'MORNING', value);
  }

  void toggleEvening(bool value) {
    if (_isLockedEvening) return;
    _setDraftAvailability(_selectedDate, 'EVENING', value);
  }

  void _setDraftAvailability(DateTime date, String meal, bool value) {
    final key = _availabilityKey(date, meal);
    final savedValue = _savedAvailability[key] ?? true;

    if (value == savedValue) {
      _draftAvailability.remove(key);
    } else {
      _draftAvailability[key] = value;
    }

    notifyListeners();
  }

  Future<bool> saveChanges() async {
    if (!hasUnsavedChanges || _isSaving) {
      return true;
    }

    final user = _auth.currentUser;
    if (user == null || _messId == null) {
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      if (_draftPermanentOff != null &&
          _draftPermanentOff != _savedPermanentOff) {
        await _firestoreService.updateData(
          path: 'users/${user.uid}',
          data: {'permanentOff': _draftPermanentOff},
        );
        _savedPermanentOff = _draftPermanentOff!;
        _draftPermanentOff = null;
      }

      final draftEntries = _draftAvailability.entries.toList();
      for (final entry in draftEntries) {
        final parts = entry.key.split('_');
        final dateStr = parts[0];
        final meal = parts[1];
        final docId = _availabilityDocId(user.uid, dateStr, meal);

        await _firestoreService.setData(
          path: 'availability/$docId',
          data: {
            'uid': user.uid,
            'messId': _messId,
            'date': dateStr,
            'meal': meal,
            'status': entry.value ? 'ON' : 'OFF',
          },
        );

        _savedAvailability[entry.key] = entry.value;
        _draftAvailability.remove(entry.key);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving availability: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
