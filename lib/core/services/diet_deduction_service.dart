import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';

class DietDeductionService {

  Future<void> performDailyDeduction(UserModel user) async {
    // Logic:
    // 1. Check if deduction already done for today? (Ideally store 'lastDeductionDate' in user or separate log)
    // For simplicity/demo: We will deduct on "Dashboard Load" if not done.
    // RISK: If user opens app multiple times, we need to be idempotent.
    
    // Better Approach for App-Side Logic:
    // Check 'dietBalances/{uid}.lastDeduction'. If < Today, run deduction.
    
    // Fetch Diet Balance
    final dietRef = FirebaseFirestore.instance.collection('dietBalances').doc(user.uid);
    final dietDoc = await dietRef.get();
    
    if (!dietDoc.exists) return;
    
    final lastDeduction = (dietDoc.data()?['lastDeduction'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastDeduction != null && lastDeduction.isAtSameMomentAs(today)) {
      // Already deducted today (simplified check, assumes deduction happens once per day for all meals or we track separately)
      // Real requirement: "For each meal... if ... remainingDiets--"
      // Complex to do robustly on client.
      return;
    }

    // Run Deduction for Today
    int deductionAmount = 0;
    
    // Check Availability for TODAY
    // 1. Permanent OFF?
    if (user.permanentOff) return;

    // 2. Fetch Availability for Morning / Evening
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Check Morning
    final morningAvailability = await _getAvailabilityStatus(user.messId!, user.uid, dateStr, 'MORNING');
    if (morningAvailability != 'OFF' && !user.morningOff) {
      deductionAmount++;
    }

    // Check Evening
    final eveningAvailability = await _getAvailabilityStatus(user.messId!, user.uid, dateStr, 'EVENING');
    if (eveningAvailability != 'OFF' && !user.eveningOff) {
        deductionAmount++;
    }

    if (deductionAmount > 0) {
      await dietRef.update({
        'remainingDiets': FieldValue.increment(-deductionAmount),
        'lastDeduction': Timestamp.fromDate(today), // Mark as done for today
      });
    }
  }

  Future<String> _getAvailabilityStatus(String messId, String uid, String date, String meal) async {
    final query = await FirebaseFirestore.instance.collection('availability')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .where('meal', isEqualTo: meal)
        .get();
    
    if (query.docs.isEmpty) return 'ON'; // Default to ON
    return query.docs.first.data()['status'] ?? 'ON';
  }
}
