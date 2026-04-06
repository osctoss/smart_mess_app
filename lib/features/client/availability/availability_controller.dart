import 'dart:async';
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
  bool get isGlobalPermanentOff => _draftPermanentOff ?? _savedPermanentOff;

  bool _savedMorningOff = false;
  bool? _draftMorningOff;
  bool get isPermanentMorningOff => _draftMorningOff ?? _savedMorningOff;

  bool _savedEveningOff = false;
  bool? _draftEveningOff;
  bool get isPermanentEveningOff => _draftEveningOff ?? _savedEveningOff;

  bool get isMorningOn => _availabilityValueFor(_selectedDate, 'MORNING');
  bool get isEveningOn => _availabilityValueFor(_selectedDate, 'EVENING');

  bool get hasUnsavedChanges {
    final hasGlobalOffChange = _draftPermanentOff != null && _draftPermanentOff != _savedPermanentOff;
    final hasMorningOffChange = _draftMorningOff != null && _draftMorningOff != _savedMorningOff;
    final hasEveningOffChange = _draftEveningOff != null && _draftEveningOff != _savedEveningOff;
    
    return hasGlobalOffChange || hasMorningOffChange || hasEveningOffChange || _draftAvailability.isNotEmpty;
  }

  String? _messId;

  StreamSubscription? _userSub;
  StreamSubscription? _morningSub;
  StreamSubscription? _eveningSub;

  AvailabilityController() {
    _initialize();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _morningSub?.cancel();
    _eveningSub?.cancel();
    super.dispose();
  }

  void _initialize() {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
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
              permanentOff: data['permanentOff'] ?? false,
              morningOff: data['morningOff'] ?? false,
              eveningOff: data['eveningOff'] ?? false,
            ),
          )
          .listen((userDoc) {
        _messId = userDoc.messId;
        _savedPermanentOff = userDoc.permanentOff;
        _savedMorningOff = userDoc.morningOff;
        _savedEveningOff = userDoc.eveningOff;
        _loadAvailability(_selectedDate);
      }, onError: (_) {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
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
    
    // Draft always has highest priority (user just toggled in this session)
    if (_draftAvailability.containsKey(key)) return _draftAvailability[key]!;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    // For today and future dates, permanent off takes priority over old saved data
    if (!selectedDay.isBefore(today)) {
      if (isGlobalPermanentOff) return false;
      if (meal == 'MORNING' && isPermanentMorningOff) return false;
      if (meal == 'EVENING' && isPermanentEveningOff) return false;
    }
    
    // For past dates (or when permanent off is not active), use saved data
    if (_savedAvailability.containsKey(key)) return _savedAvailability[key]!;
    
    return true; // ON by default
  }

  void _loadAvailability(DateTime date) {
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
        _isLoading = false;
        notifyListeners();
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      _morningSub?.cancel();
      _morningSub = _listenMealAvailability(user.uid, dateStr, 'MORNING');

      _eveningSub?.cancel();
      _eveningSub = _listenMealAvailability(user.uid, dateStr, 'EVENING');
    } catch (e) {
      debugPrint('Error loading availability: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  StreamSubscription<AvailabilityModel> _listenMealAvailability(
    String uid,
    String dateStr,
    String meal,
  ) {
    final docId = _availabilityDocId(uid, dateStr, meal);
    final key = '${dateStr}_$meal';

    return _firestoreService
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
        .listen((doc) {
      _savedAvailability[key] = doc.status != 'OFF';
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      // Don't set _savedAvailability here — let _availabilityValueFor
      // fall through to the permanent off checks instead of defaulting to ON.
      _savedAvailability.remove(key);
      _isLoading = false;
      notifyListeners();
    });
  }

  void togglePermanentOff(bool value) {
    _draftPermanentOff = value;
    if (_draftPermanentOff == _savedPermanentOff) {
      _draftPermanentOff = null;
    }
    notifyListeners();
  }

  void togglePermanentMorningOff(bool value) {
    _draftMorningOff = value;
    if (_draftMorningOff == _savedMorningOff) {
      _draftMorningOff = null;
    }
    notifyListeners();
  }

  void togglePermanentEveningOff(bool value) {
    _draftEveningOff = value;
    if (_draftEveningOff == _savedEveningOff) {
      _draftEveningOff = null;
    }
    notifyListeners();
  }

  void toggleMorning(bool value) {
    if (_isLockedMorning || isGlobalPermanentOff || isPermanentMorningOff) return;
    _setDraftAvailability(_selectedDate, 'MORNING', value);
  }

  void toggleEvening(bool value) {
    if (_isLockedEvening || isGlobalPermanentOff || isPermanentEveningOff) return;
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
      final updates = <String, dynamic>{};
      
      if (_draftPermanentOff != null && _draftPermanentOff != _savedPermanentOff) {
        updates['permanentOff'] = _draftPermanentOff;
      }
      if (_draftMorningOff != null && _draftMorningOff != _savedMorningOff) {
        updates['morningOff'] = _draftMorningOff;
      }
      if (_draftEveningOff != null && _draftEveningOff != _savedEveningOff) {
        updates['eveningOff'] = _draftEveningOff;
      }

      if (updates.isNotEmpty) {
        await _firestoreService.updateData(
          path: 'users/${user.uid}',
          data: updates,
        );
        
        if (updates.containsKey('permanentOff')) {
          _savedPermanentOff = _draftPermanentOff!;
          _draftPermanentOff = null;
        }
        if (updates.containsKey('morningOff')) {
          _savedMorningOff = _draftMorningOff!;
          _draftMorningOff = null;
        }
        if (updates.containsKey('eveningOff')) {
          _savedEveningOff = _draftEveningOff!;
          _draftEveningOff = null;
        }
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
