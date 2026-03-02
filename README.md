# 🍽️ Smart Mess App

A **multi-tenant mess (dining hall) management system** built with **Flutter** and **Firebase**. The app streamlines daily operations for both mess administrators and members — from menu planning and attendance tracking to availability management, diet balance monitoring, and member approvals.

> **Platform:** Flutter (Dart) + Firebase (Auth, Cloud Firestore)

---

## ✨ Features

### 🔐 Authentication (Firebase Phone + OTP)
- Phone number authentication with OTP verification
- Role-based access control — **Admin** & **Client**
- Auto-login via splash screen with role-based routing
- New clients can skip mess selection during signup and join later

### 👨‍💼 Admin Panel

| Page | Feature | Description |
|------|---------|-------------|
| **Dashboard** | Quick Actions | Access to menu, availability, members & notifications |
| **Menu Management** | Daily Menus | Set/update morning & evening meal menus |
| **Availability List** | Meal Tracking | View available clients for each meal; generate attendance records |
| **Members Panel** | Member Mgmt | View all members, approve/remove, manage diet balances |
| **Client Detail** | Diet Allocation | Allocate diets to individual members (sends notification) |
| **Notifications** | Request Handling | Process approval & delete requests |

### 👤 Client Panel

| Page | Feature | Description |
|------|---------|-------------|
| **Home Hub** *(NEW)* | Central Landing | Shows joined mess, available messes to join, profile & notifications |
| **Mess Dashboard** | Mess View | Diet counter, today's menu, availability management |
| **Availability** | Meal Toggles | Toggle ON/OFF for meals (past 30 days view, next 7 days editable) |
| **Notifications** | Activity Feed | Diet allocation alerts, removal requests (accept/reject), status updates |
| **Profile** | Account Mgmt | View profile, change password, change phone number, logout |

### 🏠 Mess Management
- **Create a Mess** — Admins create a new mess group
- **Join a Mess** — Clients browse messes from the Home Hub and send join requests
- **Soft Removal** — Admin removal clears mess association; client retains account and can rejoin

---

## 🏗️ Project Structure

```
smart_mess_app/
│
├── android/                          # Android platform files
├── ios/                              # iOS platform files
├── web/ | macos/ | windows/ | linux/ # Other platform targets
│
├── lib/
│   ├── main.dart                     # App entry point (Firebase init)
│   ├── app.dart                      # MaterialApp configuration
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart       # Color palette
│   │   │   ├── app_strings.dart      # Static strings
│   │   │   └── enums.dart            # UserRole, MealType, NotificationType, etc.
│   │   │
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Light theme definition
│   │   │
│   │   ├── utils/
│   │   │   └── validators.dart       # Input validation
│   │   │
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Phone auth + OTP + password linking
│   │   │   ├── firestore_service.dart     # Firestore CRUD + streams
│   │   │   ├── notification_service.dart  # Create notifications in Firestore
│   │   │   └── diet_deduction_service.dart # Daily diet deduction logic
│   │   │
│   │   └── routes/
│   │       └── app_routes.dart        # Route constants + route generator
│   │
│   ├── models/
│   │   ├── user_model.dart            # User profile + role + mess info
│   │   ├── mess_model.dart            # Mess group data
│   │   ├── menu_model.dart            # Daily menu (morning/evening)
│   │   ├── diet_balance_model.dart    # Total & remaining diets
│   │   ├── availability_model.dart    # Per-meal availability status
│   │   ├── attendance_model.dart      # Attendance record
│   │   └── notification_model.dart    # Notification with type, status, message
│   │
│   ├── repositories/                  # Data access layer (abstract interfaces)
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── mess_repository.dart
│   │   ├── diet_repository.dart
│   │   ├── menu_repository.dart
│   │   ├── availability_repository.dart
│   │   ├── attendance_repository.dart
│   │   └── notification_repository.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── splash/               # Splash → auto-route by role
│       │   ├── login/                # Phone login
│       │   ├── signup/               # Registration + OTP
│       │   ├── otp/                  # OTP verification screen
│       │   ├── create_mess/          # Admin: create new mess
│       │   └── select_mess/          # Legacy: join mess (now via Home Hub)
│       │
│       ├── client/
│       │   ├── home/                 # ★ Home Hub — central landing page
│       │   ├── dashboard/            # Mess-specific: diet counter, menu, status
│       │   ├── availability/         # Meal availability toggles
│       │   ├── notifications/        # Notification feed with actions
│       │   └── profile/              # Profile, change password/phone
│       │
│       ├── admin/
│       │   ├── dashboard/            # Admin home with quick actions
│       │   ├── menu/                 # Set daily menus
│       │   ├── availability_list/    # View available members
│       │   ├── attendance/           # Record & view attendance
│       │   ├── members/              # Member list + client detail + diet allocation
│       │   └── notifications/        # Process approval/delete requests
│       │
│       └── shared_widgets/
│           ├── custom_button.dart
│           └── custom_text_field.dart
│
├── pubspec.yaml                      # Dependencies
└── README.md
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter (Dart SDK ^3.10.8) |
| **Backend** | Firebase (Auth + Cloud Firestore) |
| **Auth** | Firebase Phone Authentication (OTP) |
| **State Management** | Provider |
| **Calendar** | table_calendar |
| **Local Storage** | shared_preferences |
| **Utilities** | intl (date formatting), uuid (ID generation) |

---

## 🗄️ Firestore Data Model

All data is scoped by `messId` to ensure multi-tenant isolation.

### `messes/{messId}`
| Field | Type | Description |
|-------|------|-------------|
| `messName` | string | Unique name per admin |
| `createdBy` | uid | Admin who created it |
| `createdAt` | timestamp | Creation time |

### `users/{uid}`
| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name |
| `contactNumber` | string | Phone number |
| `role` | `"ADMIN"` \| `"CLIENT"` | User role |
| `messId` | string \| null | Associated mess (null if not joined) |
| `approved` | boolean | Admin approval status |
| `permanentOff` | boolean | Permanently opt out of meals |
| `morningOff` | boolean | Morning meal opt-out |
| `eveningOff` | boolean | Evening meal opt-out |
| `createdAt` | timestamp | Registration time |

### `dietBalances/{uid}`
| Field | Type | Description |
|-------|------|-------------|
| `totalDiets` | number | Total allocated diets |
| `remainingDiets` | number | Remaining (never < 0) |
| `lastUpdated` | timestamp | Last modification time |

### `menus/{messId_date}`
| Field | Type | Description |
|-------|------|-------------|
| `messId` | string | Mess reference |
| `date` | string | `YYYY-MM-DD` |
| `morningMenu` | string | Morning meal items |
| `eveningMenu` | string | Evening meal items |
| `updatedBy` | uid | Admin who updated |
| `updatedAt` | timestamp | Update time |

### `availability/{uid_date_meal}`
| Field | Type | Description |
|-------|------|-------------|
| `uid` | string | User reference |
| `messId` | string | Mess reference |
| `date` | string | `YYYY-MM-DD` |
| `meal` | `"MORNING"` \| `"EVENING"` | Meal type |
| `status` | `"ON"` \| `"OFF"` | Availability |
| `locked` | boolean | Past cutoff = locked |

### `notifications/{notificationId}`
| Field | Type | Description |
|-------|------|-------------|
| `messId` | string | Mess reference |
| `type` | `"APPROVAL_REQUEST"` \| `"DELETE_REQUEST"` \| `"DIET_ALLOCATED"` \| `"ACCOUNT_DELETED"` | Notification type |
| `fromUid` / `toUid` | uid | Sender / receiver |
| `status` | `"PENDING"` \| `"ACCEPTED"` \| `"REJECTED"` | Current status |
| `message` | string (optional) | Human-readable detail (e.g. "30 diets added") |
| `createdAt` | timestamp | Request time |

### `attendance/{messId_date_meal}` + subcollection `records/{uid}`
| Field | Type | Description |
|-------|------|-------------|
| `messId` | string | Mess reference |
| `date` | string | `YYYY-MM-DD` |
| `meal` | string | Meal type |
| `records/{uid}.present` | boolean | Attendance status |

> 📌 **Retention rule:** Only the latest **3 attendance documents** per mess are retained.

### 🔗 Firestore Composite Indexes Required

| Collection | Fields | Order |
|------------|--------|-------|
| `notifications` | `toUid` (Asc) + `createdAt` (Desc) | Client notifications query |
| `notifications` | `toUid` (Asc) + `status` (Asc) + `createdAt` (Desc) | Admin notifications query |

> Create these indexes via the Firebase Console or by clicking the link in the debug console error.

---

## 🔄 User Flow

### Signup & Login
```
Signup → OTP Verification → Login Page
Login → Splash → Route by Role
├── Admin (no mess)  → Create Mess → Login
├── Admin (has mess)  → Admin Dashboard
└── Client (any)      → Client Home Hub
```

### Client Home Hub (Central Landing)
```
Client Home Hub
├── Has Mess + Approved  → Tap to open Mess Dashboard
├── Has Mess + Pending   → Shows "Waiting for approval"
├── No Mess              → Browse & join from available list
├── Notifications icon   → Notification feed
└── Profile icon         → Profile management
```

### Notification Types

| Type | Trigger | Displayed To | Actions |
|------|---------|-------------|---------|
| `APPROVAL_REQUEST` | Client joins mess | Admin | Approve / Reject |
| `DIET_ALLOCATED` | Admin adds diets | Client | Informational (shows amount) |
| `DELETE_REQUEST` | Admin removes client (diet > 0) | Client | Accept / Reject |
| `ACCOUNT_DELETED` | Admin removes client (diet = 0) | Client | Informational |

### Member Removal Flow
```
Admin clicks Delete
├── Client has 0 remaining diets
│   ├── Send ACCOUNT_DELETED notification
│   ├── Clear messId & approved (soft-delete)
│   └── Delete dietBalances
│
└── Client has remaining diets > 0
    ├── Send DELETE_REQUEST notification
    └── Client decides:
        ├── Accept → Clear messId, delete dietBalances → Home Hub
        └── Reject → Stay in mess
```

### Full Flow Diagram

```mermaid
graph TD
    A[Splash Screen] -->|Not Authenticated| B[Login Page]
    A -->|Authenticated| C{Fetch Role}
    B --> D[Sign Up]
    D --> E[OTP Verification]
    E --> B
    C -->|Admin - no mess| F[Create Mess]
    C -->|Admin - has mess| G[Admin Dashboard]
    C -->|Client| H[Client Home Hub]
    F --> B
    H -->|Has mess + approved| I[Client Mess Dashboard]
    H -->|No mess| J[Browse & Join Mess]
    J -->|Join request sent| H
    G --> K[Menu / Members / Attendance / Notifications]
    K -->|Delete member diet=0| L[Soft-delete → Client returns to Home Hub]
    K -->|Delete member diet>0| M[Delete Request → Client Accept/Reject]
    K -->|Allocate diet| N[Diet Notification → Client]
```

---

## 🍽️ Diet Deduction Logic
For each meal, a diet is deducted if **all** conditions are met:
- `permanentOff == false`
- `mealOff == false` (morningOff / eveningOff)
- `availability.status != "OFF"`
- `remainingDiets > 0`

### ⏰ Time Restrictions
| Meal | Cutoff | After Cutoff |
|------|--------|--------------|
| Morning | **7:00 AM** | Locked (no toggle) |
| Evening | **3:00 PM** | Locked (no toggle) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.10.8)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- A Firebase project with **Phone Auth** & **Cloud Firestore** enabled

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/osctoss/smart_mess_app.git
   cd smart_mess_app
   ```

2. **Configure Firebase**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   - Enable **Phone Authentication** in Firebase Console
   - Enable **Cloud Firestore** in Firebase Console
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Create Firestore composite indexes** (see [Indexes Required](#-firestore-composite-indexes-required) section)

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔒 Security

### Firestore Rules
- All reads/writes are filtered by `messId`
- Clients cannot access data from other messes
- **Only Admin** can modify: menus, dietBalances, approvals
- **Only Client** can modify: their own availability & profile

### Gitignored Sensitive Files
| File | Reason |
|------|--------|
| `lib/firebase_options.dart` | Firebase API keys |
| `android/app/google-services.json` | Android Firebase config |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config |
| `.env` / `.env.*` | Environment variables |
| `*.jks` / `*.keystore` / `key.properties` | Signing keys |

> ⚠️ **Each developer must generate their own Firebase config files using `flutterfire configure`.**

---

## 🛡️ System Guarantees

- ✅ No negative diet balance
- ✅ No cross-mess data access
- ✅ Only 3 attendance logs retained per mess
- ✅ Approval required before client can access mess dashboard
- ✅ Permanent OFF overrides manual meal toggles
- ✅ Time-restricted availability edits enforced
- ✅ Soft-delete on member removal — clients can rejoin after being removed
- ✅ Real-time notifications for diet allocation, removal, and approvals

---

## 📄 License

This project is developed as part of an academic lab project.

---

<p align="center">Built with ❤️ using Flutter & Firebase</p>
