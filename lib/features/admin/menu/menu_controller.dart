import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/menu_model.dart';
import '../../../models/user_model.dart';

class MenuManagementController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController morningController = TextEditingController();
  final TextEditingController eveningController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

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
          _loadMenu(_selectedDate);
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

  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _loadMenu(date);
  }

  void _loadMenu(DateTime date) {
    if (_messId == null) return;
    
    _isLoading = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final menuId = '${_messId}_$dateStr';

    _menuSub?.cancel();
    _menuSub = _firestoreService.documentStream(
      path: 'menus/$menuId',
      builder: (data, id) => MenuModel(
        messId: data['messId'] ?? '',
        date: data['date'] ?? '',
        morningMenu: data['morningMenu'] ?? '',
        eveningMenu: data['eveningMenu'] ?? '',
        updatedBy: '',
      ),
    ).listen((menu) {
      // Only update if not actively typing or just initialize
      if (morningController.text != menu.morningMenu) {
         morningController.text = menu.morningMenu;
      }
      if (eveningController.text != menu.eveningMenu) {
         eveningController.text = menu.eveningMenu;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      // Menu not found for this date
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
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final menuId = '${_messId}_$dateStr';
      final currentUser = _auth.currentUser;

      await _firestoreService.setData(
        path: 'menus/$menuId',
        data: {
          'messId': _messId,
          'date': dateStr,
          'morningMenu': morningController.text.trim(),
          'eveningMenu': eveningController.text.trim(),
          'updatedBy': currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
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
