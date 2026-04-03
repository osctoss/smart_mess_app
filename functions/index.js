const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;
const TIME_ZONE = "Asia/Kolkata";
const SIGNUP_LIMIT_PER_HOUR = 20;
const OTP_LIMIT_PER_HOUR = 2;

exports.processDietDeductions = onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: TIME_ZONE,
    region: "asia-south1",
  },
  async () => {
    const now = new Date();
    const dueMeals = getDueMeals(now);

    if (dueMeals.length === 0) {
      logger.info("No meal slots are due for processing.");
      return;
    }

    const userSnapshots = await db
      .collection("users")
      .where("role", "==", "CLIENT")
      .where("approved", "==", true)
      .get();

    logger.info("Starting diet deduction run.", {
      users: userSnapshots.size,
      meals: dueMeals,
    });

    for (const mealSlot of dueMeals) {
      for (const userDoc of userSnapshots.docs) {
        const userData = userDoc.data();
        if (!userData.messId) {
          continue;
        }

        await processMealForUser({
          userRef: userDoc.ref,
          userData,
          mealSlot,
        });
      }
    }
  },
);

exports.createUserProfile = onCall(
  {
    region: "asia-south1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in to complete signup.");
    }

    const {uid, name, contactNumber, role} = request.data || {};
    if (!uid || !name || !contactNumber || !role) {
      throw new HttpsError("invalid-argument", "Missing required signup data.");
    }

    if (uid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You can only create your own profile.");
    }

    if (!["ADMIN", "CLIENT"].includes(role)) {
      throw new HttpsError("invalid-argument", "Invalid user role.");
    }

    const userRef = db.collection("users").doc(uid);
    const oneHourAgo = Timestamp.fromDate(new Date(Date.now() - 60 * 60 * 1000));
    const recentSignupQuery = db.collection("users").where("createdAt", ">=", oneHourAgo);

    const [existingUserSnap, recentSignupCountSnap] = await Promise.all([
      userRef.get(),
      recentSignupQuery.count().get(),
    ]);

    if (existingUserSnap.exists) {
      throw new HttpsError("already-exists", "An account with this phone number already exists. Please login instead.");
    }

    const recentSignupCount = recentSignupCountSnap.data().count || 0;
    if (recentSignupCount >= SIGNUP_LIMIT_PER_HOUR) {
      throw new HttpsError(
        "resource-exhausted",
        "Signup limit reached. Please try again after some time.",
      );
    }

    await userRef.set({
      uid,
      name,
      contactNumber,
      role,
      messId: null,
      approved: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {success: true};
  },
);

exports.reserveOtpRequest = onCall(
  {
    region: "asia-south1",
  },
  async (request) => {
    const {deviceId, phoneNumber} = request.data || {};
    if (!deviceId || !phoneNumber) {
      throw new HttpsError("invalid-argument", "Missing OTP request data.");
    }

    const oneHourAgo = Timestamp.fromDate(new Date(Date.now() - 60 * 60 * 1000));
    const recentOtpQuery = db
      .collection("otpRequests")
      .where("deviceId", "==", deviceId)
      .where("createdAt", ">=", oneHourAgo);

    const recentOtpCountSnap = await recentOtpQuery.count().get();
    const recentOtpCount = recentOtpCountSnap.data().count || 0;

    if (recentOtpCount >= OTP_LIMIT_PER_HOUR) {
      throw new HttpsError(
        "resource-exhausted",
        "OTP limit reached for this device. Try again after some time.",
      );
    }

    await db.collection("otpRequests").add({
      deviceId,
      phoneNumber,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {success: true};
  },
);

function getDueMeals(now) {
  const slots = [];
  const zonedNow = getZonedDateParts(now);
  const today = new Date(Date.UTC(zonedNow.year, zonedNow.month - 1, zonedNow.day));
  const yesterday = new Date(today);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const minutesNow = zonedNow.hour * 60 + zonedNow.minute;

  const candidates = [
    {
      date: formatDateUtc(yesterday),
      meal: "EVENING",
      startsAtMinutes: 0,
    },
    {
      date: formatDateUtc(today),
      meal: "MORNING",
      startsAtMinutes: 7 * 60,
    },
    {
      date: formatDateUtc(today),
      meal: "EVENING",
      startsAtMinutes: 15 * 60,
    },
  ];

  for (const candidate of candidates) {
    if (minutesNow >= candidate.startsAtMinutes) {
      slots.push(candidate);
    }
  }

  return slots;
}

async function processMealForUser({userRef, userData, mealSlot}) {
  const uid = userRef.id;
  const dietRef = db.collection("dietBalances").doc(uid);
  const markerRef = db
    .collection("dietDeductionRuns")
    .doc(`${uid}_${mealSlot.date}_${mealSlot.meal}`);
  const availabilityRef = db
    .collection("availability")
    .doc(`${uid}_${mealSlot.date}_${mealSlot.meal}`);

  await db.runTransaction(async (transaction) => {
    const [dietSnap, markerSnap, availabilitySnap, freshUserSnap] = await Promise.all([
      transaction.get(dietRef),
      transaction.get(markerRef),
      transaction.get(availabilityRef),
      transaction.get(userRef),
    ]);

    if (markerSnap.exists) {
      return;
    }

    if (!dietSnap.exists) {
      transaction.set(markerRef, {
        uid,
        messId: userData.messId,
        date: mealSlot.date,
        meal: mealSlot.meal,
        deducted: false,
        skippedReason: "missing_diet_balance",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const dietData = dietSnap.data() || {};
    const remainingDiets = Number(dietData.remainingDiets || 0);
    if (remainingDiets <= 0) {
      transaction.set(markerRef, {
        uid,
        messId: userData.messId,
        date: mealSlot.date,
        meal: mealSlot.meal,
        deducted: false,
        skippedReason: "no_remaining_diets",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const freshUserData = freshUserSnap.data() || {};
    const availabilityStatus = availabilitySnap.exists
      ? availabilitySnap.data().status || "ON"
      : "ON";

    const shouldSkip = freshUserData.permanentOff === true ||
      (mealSlot.meal === "MORNING" && freshUserData.morningOff === true) ||
      (mealSlot.meal === "EVENING" && freshUserData.eveningOff === true) ||
      availabilityStatus === "OFF";

    if (shouldSkip) {
      transaction.set(markerRef, {
        uid,
        messId: userData.messId,
        date: mealSlot.date,
        meal: mealSlot.meal,
        deducted: false,
        skippedReason: availabilityStatus === "OFF" ? "availability_off" : "user_off",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.update(dietRef, {
      remainingDiets: remainingDiets - 1,
      lastUpdated: FieldValue.serverTimestamp(),
      lastDeduction: Timestamp.fromDate(new Date()),
    });

    transaction.set(markerRef, {
      uid,
      messId: userData.messId,
      date: mealSlot.date,
      meal: mealSlot.meal,
      deducted: true,
      deductionAmount: 1,
      remainingBefore: remainingDiets,
      remainingAfter: remainingDiets - 1,
      processedAt: FieldValue.serverTimestamp(),
    });
  });
}

function formatDateUtc(date) {
  const year = date.getUTCFullYear();
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function getZonedDateParts(date) {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });

  const parts = formatter.formatToParts(date);
  const values = {};
  for (const part of parts) {
    if (part.type !== "literal") {
      values[part.type] = Number(part.value);
    }
  }

  return {
    year: values.year,
    month: values.month,
    day: values.day,
    hour: values.hour,
    minute: values.minute,
  };
}
