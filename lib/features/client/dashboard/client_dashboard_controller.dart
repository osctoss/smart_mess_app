import 'package:flutter/material.dart';
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

  ClientDashboardController() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 1. Fetch User Data
      final userDoc = await _firestoreService.documentStream(
        path: 'users/${currentUser.uid}',
        builder: (data, id) => UserModel(
          uid: id,
          name: data['name'] ?? '',
          contactNumber: data['contactNumber'] ?? '',
          role: data['role'] ?? '',
          messId: data['messId'],
          approved: data['approved'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        ),
      ).first;
      _user = userDoc;

      if (_user?.messId != null) {
         // 2. Fetch Mess Data
         final messDoc = await _firestoreService.documentStream(
            path: 'messes/${_user!.messId}',
            builder: (data, id) => MessModel(
              messId: id,
              messName: data['messName'] ?? '',
              createdBy: data['createdBy'] ?? '',
              createdAt: (data['createdAt'] as Timestamp).toDate(),
            ),
         ).first;
         _mess = messDoc;

         // 3. Fetch Diet Balance
         // Note: Might need to create if not exists, but usually created on approval.
         // For now, stream it or fetch once.
         final dietDocStream = _firestoreService.documentStream(
           path: 'dietBalances/${currentUser.uid}',
           builder: (data, id) => DietBalanceModel(
             uid: id,
             totalDiets: data['totalDiets'] ?? 0,
             remainingDiets: data['remainingDiets'] ?? 0,
             lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
           ),
         );
         
         // Error handling for missing diet doc
         try {
            _dietBalance = await dietDocStream.first;
         } catch (e) {
            _dietBalance = DietBalanceModel(
              uid: currentUser.uid, 
              totalDiets: 0, 
              remainingDiets: 0, 
              lastUpdated: DateTime.now()
            );
         }

         // 4. Fetch Today's Menu
         final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
         final menuId = '${_user!.messId}_$today';
         
         try {
           final menuDoc = await _firestoreService.documentStream(
             path: 'menus/$menuId',
             builder: (data, id) => MenuModel(
               messId: _user!.messId!,
               date: today,
               morningMenu: data['morningMenu'] ?? 'Not Set',
               eveningMenu: data['eveningMenu'] ?? 'Not Set',
               updatedBy: data['updatedBy'] ?? '',
             ),
           ).first;
           _todayMenu = menuDoc;
         } catch (e) {
           _todayMenu = null; // No menu set
         }
      }
      
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    _loadData();
  }
}
