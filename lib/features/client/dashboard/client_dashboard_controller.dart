import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/mess_model.dart';
import '../../../models/menu_model.dart';
import '../../../models/diet_balance_model.dart';

class ClientDashboardController with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  UserModel? get user => _user;
  
  MessModel? _mess;
  MessModel? get mess => _mess;

  DietBalanceModel? _dietBalance;
  DietBalanceModel? get dietBalance => _dietBalance;

  MenuModel? _todayMenu;
  MenuModel? get todayMenu => _todayMenu;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _userSub;
  StreamSubscription? _messSub;
  StreamSubscription? _dietSub;
  StreamSubscription? _menuSub;

  ClientDashboardController() {
    _loadData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _messSub?.cancel();
    _dietSub?.cancel();
    _menuSub?.cancel();
    super.dispose();
  }

  void _loadData() {
    _isLoading = true;
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _userSub?.cancel();
    _userSub = _firestoreService.documentStream(
      path: 'users/${currentUser.uid}',
      builder: (data, id) => UserModel(
        uid: id,
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        role: data['role'] ?? '',
        messId: data['messId'],
        approved: data['approved'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
    ).listen((userDoc) {
      _user = userDoc;
      _isLoading = false;
      notifyListeners();

      if (_user?.messId != null) {
        _listenToMessData();
      }
    }, onError: (e) {
      debugPrint('Error loading user: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToMessData() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _user?.messId == null) return;

    // 2. Fetch Mess Data
    _messSub?.cancel();
    _messSub = _firestoreService.documentStream(
      path: 'messes/${_user!.messId}',
      builder: (data, id) => MessModel(
        messId: id,
        messName: data['messName'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
    ).listen((messDoc) {
      _mess = messDoc;
      notifyListeners();
    });

    // 3. Fetch Diet Balance
    _dietSub?.cancel();
    _dietSub = _firestoreService.documentStream(
      path: 'dietBalances/${currentUser.uid}',
      builder: (data, id) => DietBalanceModel(
        uid: id,
        totalDiets: data['totalDiets'] ?? 0,
        remainingDiets: data['remainingDiets'] ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
    ).listen((dietDoc) {
      _dietBalance = dietDoc;
      notifyListeners();
    }, onError: (_) {
      _dietBalance = DietBalanceModel(
        uid: currentUser.uid, 
        totalDiets: 0, 
        remainingDiets: 0, 
        lastUpdated: DateTime.now()
      );
      notifyListeners();
    });

    // 4. Fetch Today's Menu
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final menuId = '${_user!.messId}_$today';
    
    _menuSub?.cancel();
    _menuSub = _firestoreService.documentStream(
      path: 'menus/$menuId',
      builder: (data, id) => MenuModel(
        messId: _user!.messId!,
        date: today,
        morningMenu: data['morningMenu'] ?? 'Not Set',
        eveningMenu: data['eveningMenu'] ?? 'Not Set',
        updatedBy: data['updatedBy'] ?? '',
      ),
    ).listen((menuDoc) {
      _todayMenu = menuDoc;
      notifyListeners();
    }, onError: (_) {
      _todayMenu = null;
      notifyListeners();
    });
  }

  void refresh() {
    // Streams handle real-time updates, but we can restart them if forced
    _loadData();
  }
}
