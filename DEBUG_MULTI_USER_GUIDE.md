# Multi-User Data Synchronization Debugging Guide

## ROOT CAUSES IDENTIFIED & FIXED

### 1. **MISSING ONLINE STATUS FIELD** ✓
**Problem:** The `WorkerModel` had no `isOnline` field to track if a worker was actually online.
- Only had `availability` (Open to Work toggle)
- No way to know if worker was logged in

**Fixed:** Added to `WorkerModel`:
```dart
final bool isOnline;        // Online status in real-time
final DateTime? lastSeen;   // Last activity timestamp
```

### 2. **NO ONLINE STATUS UPDATES** ✓
**Problem:** Workers couldn't set their online status in the database.
- No method to mark workers online when they log in
- No method to mark workers offline when they log out

**Fixed:** Added to `WorkerController`:
```dart
Future<void> setWorkerOnline(String workerId)      // Call on login
Future<void> setWorkerOffline(String workerId)     // Call on logout
Future<void> updateWorkerLastSeen(String workerId) // Call on activity
```

### 3. **FILTERING DIDN'T CHECK ONLINE STATUS** ✓
**Problem:** The query filtered by `availability` but never checked `isOnline`.
- Customer could see offline workers
- Multi-user sync broken

**Fixed:** Updated `_filterWorkers()` in `NearbyWorkersMapScreen` to:
1. Check `worker.isOnline == true`
2. Added comprehensive debug logging to trace filtering

### 4. **MAP DISAPPEARED WITH NO WORKERS** ✓
**Problem:** Empty state replaced the map, so customer couldn't see their location.

**Fixed:** Restructured layout:
- Map: `Flexible(flex: 2)` - always visible
- Empty state/List: `Flexible(flex: 1)` - below map

---

## IMPLEMENTATION CHECKLIST

### STEP 1: Hook Online Status to Authentication

**Location:** `lib/services/firebase_auth_service.dart` or `lib/controllers/auth_controller.dart`

When worker logs in:
```dart
Future<void> loginWorker(String email, String password) async {
  // ... existing login code ...
  
  // Mark worker online
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await WorkerController().setWorkerOnline(currentUser.uid);
  }
}
```

When worker logs out:
```dart
Future<void> logoutWorker() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await WorkerController().setWorkerOffline(currentUser.uid);
  }
  
  // ... existing logout code ...
}
```

### STEP 2: Ensure Worker Account Has Location

**Location:** Worker profile creation/update screen

When worker submits profile:
1. Request location permission
2. Get current location via `LocationService`
3. Save latitude/longitude to Firestore

```dart
final position = await LocationService().getCurrentPosition();
await WorkerController().submitWorkerProfile(
  // ... other fields ...
  latitude: position.latitude,
  longitude: position.longitude,
);
```

### STEP 3: Verify Service Category Names Match

**Problem:** Database might store "Plumber" but query looks for "plumber"

**Check in Firestore Console:**
1. Go to `workers` collection
2. Look at actual `serviceType` values
3. Ensure they match exactly (case-sensitive comparison or normalize)

### STEP 4: Enable Debug Logging

Debug logs are now active in the filtering logic:

```
=== NEARBY WORKERS QUERY DEBUG ===
Customer lat: ..., lng: ...
Selected category: Plumber
Selected radius: 100 km
Total workers retrieved: X

Checking worker: John (Plumber)
  - approvalStatus: approved
  - isOnline: true          ← KEY FIELD
  - availability: true      ← Open to Work
  - serviceType: Plumber
  - location: lat=31.5, lng=74.3
  - Distance: 25.50 km
  ✓ INCLUDED in results

=== FILTER SUMMARY ===
Workers checked: 5
Online: 2
Available: 2
Valid location: 2
Plumbers: 1
Final results: 1
```

---

## TESTING PROCEDURE

### Setup: Two Real Accounts

**Account A - Customer:**
- Role: `user`
- Can see nearby workers

**Account B - Plumber:**
- Role: `worker`
- Service: `Plumber`
- Approval Status: `approved`

### Test 1: Worker Offline → Online Transition

```
BROWSER 1 (Customer):
- Nearby Workers
- Filter: Plumber
- Radius: 100 km
- Result: No plumbers (Worker is offline)

BROWSER 2 (Worker):
- Login as plumber
- Expected: setWorkerOnline() called
- Firestore: isOnline = true

BROWSER 1 (Refresh):
- Expected: Plumber appears on map + list
- Actual: [CHECK DEBUG LOGS]
```

### Test 2: Verify Data Flow

Open DevTools console in Browser 1 and look for:

```
=== NEARBY WORKERS QUERY DEBUG ===
Total workers retrieved: 1

Checking worker: Plumber Name
  - approvalStatus: approved        ✓
  - isOnline: true                  ✓ KEY
  - availability: true              ✓ Open to Work
  - serviceType: Plumber            ✓ Matches filter
  - location: lat=31.5, lng=74.3    ✓ Valid
  - Distance: 25.50 km              ✓ < 100 km

=== FILTER SUMMARY ===
Workers checked: 1
Online: 1                            ✓
Available: 1                         ✓
Valid location: 1                    ✓
Plumbers: 1                          ✓
Final results: 1
✓ INCLUDED in results
```

### Test 3: Worker Goes Offline

```
BROWSER 2 (Worker):
- Logout
- Expected: setWorkerOffline() called
- Firestore: isOnline = false

BROWSER 1 (Refresh):
- Expected: Plumber disappears
- Debug logs show: isOnline: false → Filtered out
```

### Test 4: Verify Map Always Visible

```
When: No workers found
Expected:
- Map still shows 📍 Customer location
- Empty state below map shows: "No plumbers available within 100 km"
- [Expand Radius] [Post Job Request] buttons visible
```

---

## DEBUGGING CHECKLIST

If plumber still doesn't appear:

- [ ] **1. Verify Worker is Online**
  - Firestore Console → workers collection
  - Find worker document
  - Check: `isOnline` = `true`
  - Check: `lastSeen` = recent timestamp

- [ ] **2. Verify Approval Status**
  - Firestore: `approvalStatus` = `approved`
  - Not pending/rejected

- [ ] **3. Verify Availability**
  - Firestore: `availability` = `true` (Open to Work toggle)
  - Not manually disabled

- [ ] **4. Verify Location**
  - Firestore: `latitude` and `longitude` are NOT 0.0
  - Has valid GPS coordinates

- [ ] **5. Verify Service Category**
  - Firestore: `serviceType` = `"Plumber"` (exact match, case-sensitive)
  - Check database for exact value
  - May need normalization if inconsistent

- [ ] **6. Verify Distance Calculation**
  - Check debug logs:
     - Customer location: `lat=X, lng=Y`
     - Worker location: `lat=A, lng=B`
     - Calculated distance: `D km`
     - Selected radius: `100 km`
  - Is `D < 100`?

- [ ] **7. Check Debug Logs**
  - Run test
  - Open browser console (F12)
  - Look for `=== NEARBY WORKERS QUERY DEBUG ===`
  - See exactly where worker is filtered out
  - Example: `✗ Filtered: Not online`

---

## CRITICAL CODE SECTIONS

### Worker Authentication (TODO: Implement)
Find where worker logs in and add:
```dart
await WorkerController().setWorkerOnline(workerId);
```

### Customer Query
Already implemented in:
- `nearby_workers_map_screen.dart`
- `_filterWorkers()` method
- Filters: isOnline ✓, availability ✓, category ✓, distance ✓

### Real-Time Sync
Existing Firestore listener:
```dart
_workersSubscription = _firestore
    .collection('workers')
    .snapshots()
    .listen((_) => _refreshLocationAndWorkers());
```

When worker's `isOnline` changes in Firestore:
1. Listener triggered
2. `_refreshLocationAndWorkers()` called
3. Customer sees update immediately

---

## MAP VISIBILITY FIX

### Before (Bug):
- Map: Flexible(flex: 1) - 50% space
- Empty state: Flexible(flex: 1) - 50% space
- Result: Map compressed, sometimes invisible

### After (Fixed):
- Map: Flexible(flex: 2) - 66% space
- Empty state: Flexible(flex: 1) - 34% space
- Result: Map prominent, always visible

---

## FIELD MAPPING REFERENCE

### WorkerModel Fields:

```dart
// Identity
workerId          → Firestore: workerId
name              → Firestore: name
email             → Firestore: email

// Status (CRITICAL FOR MULTI-USER)
isOnline          → Firestore: isOnline      (NEW ✓)
lastSeen          → Firestore: lastSeen      (NEW ✓)
availability      → Firestore: availability (Open to Work)
approvalStatus    → Firestore: approvalStatus

// Location (CRITICAL)
latitude          → Firestore: latitude
longitude         → Firestore: longitude
location          → Firestore: location (address string)

// Service
serviceType       → Firestore: serviceType
rating            → Firestore: rating
```

---

## NEXT ACTIONS

1. **Find worker login/logout code**
   - Add `setWorkerOnline()` call
   - Add `setWorkerOffline()` call

2. **Test with two real accounts**
   - Follow "TESTING PROCEDURE" above
   - Check debug logs

3. **If still broken:**
   - Enable logs in Firebase Console
   - Check Firestore for actual values
   - Verify category name consistency
   - Check location permissions on worker device

4. **Remove debug logging after verified:**
   - Comment out or remove `if (kDebugMode) print(...)` statements
   - Keep error logging for production

---

## FIRESTORE RULES (Optional Enhancement)

Consider adding Firestore rules to auto-expire online status:
```
// Mark offline if lastSeen > 15 minutes
```

For now, manual updates work via app logic.

---

## SUMMARY OF FIXES

| Issue | Root Cause | Solution | Status |
|-------|-----------|----------|--------|
| No online tracking | Missing `isOnline` field | Added to WorkerModel | ✓ Done |
| No status updates | No controller methods | Added setWorkerOnline/Offline | ✓ Done |
| Query doesn't filter online | Filter logic incomplete | Added isOnline check + debug logs | ✓ Done |
| Map disappeared | Layout using equal flex | Changed to flex 2:1 ratio | ✓ Done |
| No debugging visibility | Silent failures | Added comprehensive console logs | ✓ Done |

---

**Next Step:** Integrate `setWorkerOnline()` call into your worker authentication flow.
