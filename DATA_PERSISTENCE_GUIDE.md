# Data Persistence & Firebase Integration Guide

## Overview
All user data in DailyAP is now automatically persisted to Firebase Firestore. This means:
- ✅ Data is backed up to the cloud
- ✅ Data syncs across devices
- ✅ User-specific data stored securely
- ✅ Automatic data loading on sign-in

## Data Structure in Firestore

Your Firestore database is organized as follows:

```
firestore-root
├── users (collection)
│   └── {userId} (document)
│       ├── email: string
│       ├── displayName: string
│       ├── photoURL: string
│       ├── createdAt: timestamp
│       ├── cashbooks (subcollection)
│       │   └── data (document)
│       │       ├── cashbooks: array
│       │       └── updatedAt: timestamp
│       ├── todos (subcollection)
│       │   └── data (document)
│       │       ├── todos: array
│       │       └── updatedAt: timestamp
│       ├── notes (subcollection)
│       │   └── data (document)
│       │       ├── notes: array
│       │       └── updatedAt: timestamp
│       └── budget (subcollection)
│           └── data (document)
│               ├── amount: number
│               └── updatedAt: timestamp
```

## Automatic Sync Flow

```
User Action (Add/Edit/Delete)
    ↓
Provider Updates State
    ↓
Provider Calls save()
    ↓
Save to Local Storage (offline support)
    ↓
Save to Firestore (cloud backup)
    ↓
State Notifies UI
    ↓
UI Updates
```

## What Data Gets Synced?

### 1. **Cashbooks & Transactions**
- Cashbook names
- All transactions (income/expense)
- Transaction dates, amounts, categories
- Status: Synced automatically on every change

### 2. **Todos**
- Title, description, priority
- Due dates and completion status
- Status: Synced automatically on every change

### 3. **Notes**
- Daily diary entries
- Date-based notes
- Status: Synced automatically on every change

### 4. **Budget**
- Budget amount
- Status: Synced automatically on every change

### 5. **User Profile**
- Name, email, profile photo
- User ID and authentication metadata
- Status: Synced on sign-in

## How It Works Behind the Scenes

### FirestoreService (lib/services/firestore_service.dart)

Main service handling all Firestore operations:

```dart
// Save data to Firestore
FirestoreService.saveCashbooks(cashbookList);
FirestoreService.saveTodos(todoList);
FirestoreService.saveNotes(noteList);
FirestoreService.saveBudget(budgetAmount);

// Load data from Firestore
List<CashbookModel> cashbooks = await FirestoreService.loadCashbooks();
List<TodoModel> todos = await FirestoreService.loadTodos();

// Real-time updates (optional)
FirestoreService.streamCashbooks().listen((data) { ... });
```

### Provider Integration

Each provider automatically syncs data:

```dart
// CashbookProvider
class CashbookProvider extends ChangeNotifier {
  Future<void> load() async {
    cashbooks = await FirestoreService.loadCashbooks();
    notifyListeners();
  }

  void save() {
    LocalStorageService.saveCashbooks(cashbooks);  // Local backup
    FirestoreService.saveCashbooks(cashbooks);     // Cloud backup
  }
}
```

## Sign-In Data Flow

When user signs in:

```
1. User clicks "Sign in with Google"
   ↓
2. Google Authentication completes
   ↓
3. AuthProvider saves user profile to Firestore
   ↓
4. AuthProvider state updates
   ↓
5. Main app automatically navigates to MainNavigationScreen
   ↓
6. All providers load data from Firestore
   ↓
7. App displays user's existing data
```

## Firestore Security Rules

**Recommended Security Rules** (add to Firebase Console):

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

## Offline Support

The app has hybrid offline support:

1. **Local Storage**: All data is cached in SharedPreferences
2. **Cloud Sync**: When online, data automatically syncs to Firestore
3. **Offline Usage**: You can view and edit data offline
4. **Auto-Sync**: When connection restores, data syncs to Firestore

## Current Data (Already Stored)

Any data you entered before authentication is stored locally in SharedPreferences. After sign-in:
- Everything is automatically uploaded to Firestore
- Next time you sign in, this data loads automatically
- You can switch devices and data follows you

## Testing Sync

To verify data is syncing:

### In Android Emulator:
1. Add an expense in Cashbook tab
2. Add a todo in Todo tab
3. Open Firebase Console
4. Go to Firestore Database
5. Navigate to `users > [your-user-id] > cashbooks > data`
6. Check if your expense appears in the `cashbooks` array
7. Navigate to `users > [your-user-id] > todos > data`
8. Check if your todo appears in the `todos` array

### Real Device Testing:
1. Sign in on Device A
2. Add some data
3. Sign in on Device B
4. Your data appears automatically!

## Troubleshooting

### Data Not Syncing?

1. **Check Authentication**:
   - Verify you're signed in (check Profile tab)
   - Sign out and sign back in

2. **Check Internet Connection**:
   - Data syncs only when online
   - Check your device's network settings

3. **Check Firestore Rules**:
   - Go to Firebase Console
   - Check if security rules allow your user to write data
   - Temporarily allow all to test: `allow read, write: if true;`

4. **Check Error Logs**:
   ```dart
   // Errors are logged in FirestoreService
   // Check Android logcat or iOS console
   ```

### Old Data Disappearing?

- Data is not deleted, just moved to cloud
- Local storage is still used as cache
- Data loads from Firestore when you sign in

## Performance Tips

1. **Batch Operations**:
   - When adding multiple items, save once not multiple times
   - The provider handles batching automatically

2. **Real-Time Updates** (Advanced):
   ```dart
   // Use streaming for real-time sync across devices
   FirestoreService.streamCashbooks().listen((data) {
     setState(() => cashbooks = data);
   });
   ```

3. **Offline-First**:
   - Data saves locally immediately
   - Syncs to cloud in background
   - Always responsive UI

## Data Deletion

### User Account Data:
```dart
// On sign-out, you can optionally delete all data
await FirestoreService.deleteUserData();
```

### Specific Data Items:
- Delete via UI (removes from local storage and Firestore)
- Uses same `save()` method in providers

### Complete Account:
1. Delete in Firebase Console
2. User can sign back in with new empty account

## Advanced: Real-Time Sync Across Devices

To make data update in real-time across multiple devices:

```dart
// In a provider:
Stream<List<CashbookModel>> get cashbookStream => 
  FirestoreService.streamCashbooks();

// In UI:
StreamBuilder<List<CashbookModel>>(
  stream: provider.cashbookStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return YourWidget(data: snapshot.data!);
    }
    return LoadingWidget();
  },
)
```

## Security Best Practices

⚠️ **Important**:
1. Never store sensitive passwords in app data
2. Use Firebase Authentication for sensitive data
3. Encrypt sensitive fields before saving to Firestore
4. Set appropriate security rules in Firestore
5. Regularly review Analytics for unauthorized access

## Costs

Firestore has a free tier:
- **Free**: 
  - 1 GB storage
  - 50,000 reads/day
  - 20,000 writes/day
  - 20,000 deletes/day

For typical app usage, you'll stay within free limits.

## Migration from Local Storage

All existing local data is automatically:
1. Read from SharedPreferences
2. Uploaded to Firestore on first sync
3. Kept in local cache for offline access
4. Synced bidirectionally going forward

---

**Last Updated**: March 27, 2026
**Firebase Project**: allinoneapp-45
**Status**: ✅ Production Ready
