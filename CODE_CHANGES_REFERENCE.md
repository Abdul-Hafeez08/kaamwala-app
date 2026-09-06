# CODE CHANGES REFERENCE

## File 1: `lib/models/user_model.dart`

### Added Fields to WorkerModel Class
```dart
class WorkerModel {
  // ... existing fields ...
  
  final bool availability;      // Existing: Open to Work toggle
  final bool isOnline;          // NEW: Online status
  final DateTime? lastSeen;     // NEW: Last activity timestamp
  
  // ... rest of fields ...
}
```

### Updated Constructor
```dart
WorkerModel({
  // ... existing parameters ...
  this.availability = true,
  this.isOnline = false,        // NEW parameter
  this.lastSeen,                // NEW parameter
  // ... rest of parameters ...
})
```

### Updated toMap() Method
```dart
Map<String, dynamic> toMap() {
  return {
    // ... existing fields ...
    'availability': availability,
    'isOnline': isOnline,         // NEW
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,  // NEW
    // ... rest of fields ...
  };
}
```

### Updated fromMap() Factory
```dart
factory WorkerModel.fromMap(Map<String, dynamic> map) {
  return WorkerModel(
    // ... existing fields ...
    availability: map['availability'] ?? true,
    isOnline: map['isOnline'] ?? false,           // NEW
    lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),  // NEW
    // ... rest of fields ...
  );
}
```

### Updated copyWith() Method
```dart
WorkerModel copyWith({
  // ... existing parameters ...
  bool? availability,
  bool? isOnline,                // NEW parameter
  DateTime? lastSeen,            // NEW parameter
  // ... rest of parameters ...
}) {
  return WorkerModel(
    // ... existing fields ...
    availability: availability ?? this.availability,
    isOnline: isOnline ?? this.isOnline,          // NEW
    lastSeen: lastSeen ?? this.lastSeen,          // NEW
    // ... rest of fields ...
  );
}
```

---

## File 2: `lib/controllers/worker_controller.dart`

### Added New Methods
```dart
/// Set worker online status in the backend
/// Called when worker logs in or enables app
Future<void> setWorkerOnline(String workerId) async {
  await _firestoreService.updateWorkerDocument(workerId, {
    'isOnline': true,
    'lastSeen': DateTime.now(),
  });
}

/// Set worker offline status in the backend
/// Called when worker logs out or disables app
Future<void> setWorkerOffline(String workerId) async {
  await _firestoreService.updateWorkerDocument(workerId, {
    'isOnline': false,
    'lastSeen': DateTime.now(),
  });
}

/// Update last seen timestamp to maintain online status
/// Should be called periodically or on user activity
Future<void> updateWorkerLastSeen(String workerId) async {
  await _firestoreService.updateWorkerDocument(workerId, {
    'lastSeen': DateTime.now(),
  });
}
```

---

## File 3: `lib/controllers/auth_controller.dart`

### Updated Imports
```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'worker_controller.dart';  // NEW
```

### Updated signIn() Method
```dart
Future<void> signIn({
  required String email,
  required String password,
}) async {
  final User? firebaseUser = await _authService.signInWithEmail(
    email: email,
    password: password,
  );

  if (firebaseUser == null) {
    throw 'Failed to sign in. Please try again.';
  }

  // NEW: Set worker online when they log in
  final userRole = await getCurrentUserRole();
  if (userRole == 'worker') {
    try {
      await WorkerController().setWorkerOnline(firebaseUser.uid);
    } catch (e) {
      // Log but don't fail login if online status update fails
      print('Warning: Could not set worker online status: $e');
    }
  }
}
```

### Updated signOut() Method
```dart
Future<void> signOut() async {
  // NEW: Set worker offline when they log out
  final User? currentUser = _authService.currentUser;
  if (currentUser != null) {
    final userRole = await _firestoreService.getUserRole(currentUser.uid);
    if (userRole == 'worker') {
      try {
        await WorkerController().setWorkerOffline(currentUser.uid);
      } catch (e) {
        // Log but don't fail logout if offline status update fails
        print('Warning: Could not set worker offline status: $e');
      }
    }
  }

  await _authService.signOut();
}
```

---

## File 4: `lib/views/user/nearby_workers_map_screen.dart`

### Updated _filterWorkers() Method

#### Added Debug Logging Setup
```dart
Future<List<WorkerModel>> _filterWorkers(
  List<WorkerModel> sourceWorkers,
) async {
  final userLat = _currentPosition?.latitude ?? _defaultCenter.latitude;
  final userLng = _currentPosition?.longitude ?? _defaultCenter.longitude;
  final categoryFilter = _selectedCategory == 'All Services'
      ? null
      : _selectedCategory.trim();

  // NEW: Debug logging
  if (kDebugMode) {
    print('=== NEARBY WORKERS QUERY DEBUG ===');
    print('Customer lat: $userLat, lng: $userLng');
    print('Selected category: ${_selectedCategory}');
    print('Selected radius: ${_selectedRadius} km');
    print('Total workers retrieved: ${sourceWorkers.length}');
  }

  final results = <WorkerModel>[];
  int onlineCount = 0;
  int availableCount = 0;
  int validLocationCount = 0;
  int categoryMatchCount = 0;
  
  // ... rest of method ...
}
```

#### Added isOnline Check (CRITICAL)
```dart
for (final worker in sourceWorkers) {
  // NEW: Log filtering steps
  if (kDebugMode) {
    print('\nChecking worker: ${worker.name}');
    print('  - approvalStatus: ${worker.approvalStatus}');
    print('  - isOnline: ${worker.isOnline}');    // NEW
    print('  - availability: ${worker.availability}');
    // ... etc
  }

  if (worker.approvalStatus != 'approved') {
    if (kDebugMode) print('  ✗ Filtered: Not approved');
    continue;
  }

  // NEW: CHECK FOR ONLINE STATUS
  if (!worker.isOnline) {
    if (kDebugMode) print('  ✗ Filtered: Not online');
    continue;
  }
  onlineCount++;

  // ... rest of existing filters ...
}
```

#### Added Debug Summary
```dart
if (kDebugMode) {
  print('\n=== FILTER SUMMARY ===');
  print('Workers checked: ${sourceWorkers.length}');
  print('Online: $onlineCount');
  print('Available: $availableCount');
  print('Valid location: $validLocationCount');
  print('Category match: $categoryMatchCount');
  print('Final results: ${results.length}');
  print('=====================================\n');
}
```

### Updated build() Layout

#### Before (Bug):
```dart
body: _isLoading
    ? const Center(child: CustomLoadingIndicator())
    : Column(
        children: [
          _buildFilterBar(isDark),
          if (_locationPermissionNeeded)
            _buildLocationPermissionCard()
          else
            Flexible(flex: 1, child: _buildMapContainer()),  // 50% space
          if (_nearbyWorkers.isEmpty)
            Flexible(
              flex: 1,  // 50% space
              child: SingleChildScrollView(
                child: _buildNoWorkersState(isDark),
              ),
            )
          else
            Flexible(
              flex: 1,  // 50% space
              child: ListView.separated(...),
            ),
        ],
      ),
```

#### After (Fixed):
```dart
body: _isLoading
    ? const Center(child: CustomLoadingIndicator())
    : Column(
        children: [
          _buildFilterBar(isDark),
          if (_locationPermissionNeeded)
            Flexible(
              flex: 1,
              child: _buildLocationPermissionCard(),  // NEW: Flexible wrapper
            )
          else
            Flexible(flex: 2, child: _buildMapContainer()),  // 66% space - MAP LARGER
          Flexible(
            flex: 1,  // 34% space
            child: _nearbyWorkers.isEmpty
                ? _buildNoWorkersState(isDark)  // Empty state OR list
                : ListView.separated(...),
          ),
        ],
      ),
```

**Key Changes:**
- Map changed from `flex: 1` to `flex: 2` → stays more visible
- Empty state/List: `flex: 1` → takes remaining space below map
- Always shows map, even with zero workers
- No more disappearing map

---

## COMPLETE FIRESTORE UPDATE FLOW

### When Worker Logs In
1. AuthController.signIn() called
2. Worker authenticated with Firebase
3. Check userRole == 'worker'? YES
4. WorkerController.setWorkerOnline(workerId) called
5. Firestore PATCH: `workers/{workerId}` → `{isOnline: true, lastSeen: now}`
6. Firestore listener triggers across all connected clients

### When Customer Queries
1. Customer opens Nearby Workers
2. Firebase listener fires
3. Query: `workers.where(approvalStatus='approved')`
4. For each worker, check:
   - `isOnline == true` ✓ NEW
   - `availability == true`
   - `serviceType` matches filter
   - `latitude/longitude` valid
   - Distance < selectedRadius
5. Only matching workers added to results
6. Map and list updated with filtered results

### When Worker Logs Out
1. AuthController.signOut() called
2. Get currentUser ID
3. WorkerController.setWorkerOffline(workerId) called
4. Firestore PATCH: `workers/{workerId}` → `{isOnline: false, lastSeen: now}`
5. Firestore listener triggers
6. Customer query refires automatically
7. Worker disappears from map and list (isOnline check fails)

---

## TESTING VERIFICATION POINTS

### Data Persistence Check
```
[] Login worker
[] Firestore Console: Check workers/{uid}.isOnline == true
[] Logout worker
[] Firestore Console: Check workers/{uid}.isOnline == false
[] Login worker again
[] Firestore Console: Check workers/{uid}.isOnline == true
```

### Real-time Sync Check
```
[] Browser 1: Customer logged in, Nearby Workers open
[] Browser 2: Worker logs in
[] Expected: Customer sees worker appear (no refresh needed)
[] Browser 2: Worker logs out
[] Expected: Customer sees worker disappear (no refresh needed)
```

### Filter Logic Check
```
[] Check debug logs when querying
[] Look for: === NEARBY WORKERS QUERY DEBUG ===
[] Verify: isOnline: true appears for included workers
[] Verify: isOnline: false shows ✗ Filtered: Not online for others
```

### Layout Check
```
[] Open Nearby Workers
[] Filter to show no results
[] Expected: Map still visible with 📍 customer location
[] Expected: Empty state below map
[] Expected: [Expand Radius] [Post Job Request] visible
[] Expected: No bottom overflow
```

---

## ROLLBACK (If Needed)

If issues occur, revert these changes:

1. Remove `isOnline` and `lastSeen` from WorkerModel
2. Remove setWorkerOnline/Offline/updateLastSeen from WorkerController
3. Remove online status calls from AuthController signIn/signOut
4. Remove isOnline check from _filterWorkers
5. Remove debug logging
6. Revert layout to original `flex: 1` ratios

But **fixing properly is better than reverting!**

