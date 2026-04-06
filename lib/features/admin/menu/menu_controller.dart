import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';

class MenuManagementController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController morningController = TextEditingController();
  final TextEditingController eveningController = TextEditingController();

  int _selectedWeekday = DateTime.now().weekday;
  int get selectedWeekday => _selectedWeekday;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _messId;
  StreamSubscription? _userSub;
  StreamSubscription? _menuSub;

  MenuManagementController() {
    _initialize();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _menuSub?.cancel();
    morningController.dispose();
    eveningController.dispose();
    super.dispose();
  }

  void _initialize() {
    _isLoading = true;
    notifyListeners();
    try {
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
          _loadMenu(_selectedWeekday);
        }, onError: (e) {
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onWeekdaySelected(int weekday) {
    _selectedWeekday = weekday;
    _loadMenu(weekday);
  }

  void _loadMenu(int weekday) {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    _menuSub?.cancel();
    _menuSub = _firestoreService.documentStream(
      path: 'weekly_menus/$_messId',
      builder: (data, id) => data,
    ).listen((menuData) {
      final dayData = menuData[weekday.toString()] as Map<String, dynamic>? ?? {};
      final morningMenu = dayData['morning'] as String? ?? '';
      final eveningMenu = dayData['evening'] as String? ?? '';

      // Only update if not actively typing or just initialize
      if (morningController.text != morningMenu) {
         morningController.text = morningMenu;
      }
      if (eveningController.text != eveningMenu) {
         eveningController.text = eveningMenu;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      morningController.text = '';
      eveningController.text = '';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> saveMenu(BuildContext context) async {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;

      await _firestoreService.setData(
        path: 'weekly_menus/$_messId',
        data: {
          _selectedWeekday.toString(): {
            'morning': morningController.text.trim(),
            'evening': eveningController.text.trim(),
            'updatedBy': currentUser?.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        },
        merge: true,
      );
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu Updated')));
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
