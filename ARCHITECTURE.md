# DailyAP - System Architecture Overview

## Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     DailyAP Application                      │
└─────────────────────────────────────────────────────────────┘

                        ┌──────────────┐
                        │  User Signs  │
                        │   In with    │
                        │    Google    │
                        └──────┬───────┘
                               │
                    ┌──────────v──────────┐
                    │  Google OAuth Flow  │
                    │  (google_sign_in)   │
                    └──────────┬──────────┘
                               │
            ┌──────────────────v──────────────────┐
            │    Firebase Auth - signIn           │
            │    (firebase_auth)                  │
            └──────────────────┬──────────────────┘
                               │
            ┌──────────────────v──────────────────┐
            │   AuthProvider Updates State        │
            │   - User object populated           │
            │   - isAuthenticated = true          │
            └──────────────────┬──────────────────┘
                               │
        ┌──────────────────────v──────────────────────┐
        │  FirestoreService.updateUserProfile()      │
        │  - Saves user data to Firestore            │
        │  - Path: /users/{userId}                   │
        └──────────────────────┬──────────────────────┘
                               │
        ┌──────────────────────v──────────────────────┐
        │   Consumer Rebuilds Navigation              │
        │   - Shows MainNavigationScreen              │
        │   - Loads all providers                     │
        └──────────────────────┬──────────────────────┘
                               │
        ┌──────────────────────v──────────────────────┐
        │  All Providers Call load():                 │
        │  - CashbookProvider                         │
        │  - TodoProvider                             │
        │  - NoteProvider                             │
        │  - BudgetProvider                           │
        └──────────────────────┬──────────────────────┘
                               │
        ┌──────────────────────v──────────────────────┐
        │  Each Provider Calls:                       │
        │  FirestoreService.load[Data]()              │
        │  - Firestore returns user's data            │
        │  - Data is cached locally                   │
        │  - Provider state updated                   │
        └──────────────────────┬──────────────────────┘
                               │
            ┌──────────────────v──────────────────┐
            │   UI Renders with User's Data       │
            │   - Cashbooks display               │
            │   - Todos visible                   │
            │   - Budget shown                    │
            │   - Notes loaded                    │
            └──────────────────────────────────────┘
```

## Component Architecture

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                  │
├─────────────────────────────────────────────────┤
│ • SignInScreen                                  │
│ • ProfileScreen                                 │
│ • MainNavigationScreen                          │
│ • CashbookHomeScreen                            │
│ • TodoHomeScreen                                │
│ • CalendarScreen                                │
│ • AnalyticsScreen                               │
└──────────────────┬────────────────────────────┘
                   │
┌──────────────────v────────────────────────────┐
│           State Management Layer                │
├──────────────────────────────────────────────┤
│ • AuthProvider (Google Sign-In)               │
│ • CashbookProvider                            │
│ • TransactionProvider                         │
│ • TodoProvider                                 │
│ • NoteProvider                                 │
│ • BudgetProvider                               │
└──────────────────┬────────────────────────────┘
                   │
┌──────────────────v────────────────────────────┐
│         Data Access Layer (Services)            │
├──────────────────────────────────────────────┤
│ • FirestoreService ← Cloud Database (NEW)     │
│ • LocalStorageService ← Local Cache           │
│ • NotificationService                         │
│ • BackupService                                │
└──────────────────┬────────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
┌───v─────────────┐    ┌─────────v─────┐
│  Local Storage  │    │   Firebase    │
│  (SharedPrefs)  │    │  (Firestore)  │
├─────────────────┤    │               │
│ • Cashbooks     │    │ • Users       │
│ • Transactions  │    │ • Cashbooks   │
│ • Todos         │    │ • Todos       │
│ • Notes         │    │ • Notes       │
│ • Budget        │    │ • Budget      │
└─────────────────┘    │ • Profiles    │
                       └───────────────┘
```

## Data Sync Architecture

```
┌──────────────────────────────────────────────────┐
│           User Takes Action in App               │
│         (Add expense, Todo, Note, etc.)          │
└────────────────────┬─────────────────────────────┘
                     │
                     v
            ┌────────────────┐
            │  Provider.add()│
            │  Provider.edit │
            │  Provider.save │
            └────────┬───────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         v                       v
    ┌─────────────┐        ┌──────────────┐
    │   LOCAL     │        │   FIRESTORE  │
    │  STORAGE    │        │              │
    │             │        │              │
    │ Stores Data │        │Stores Data   │
    │ Instantly ✓ │        │  in Cloud    │
    │ (Offline)   │        │  (Synced) ✓  │
    └─────────────┘        └──────────────┘
         │                       │
         └───────────┬───────────┘
                     │
                     v
            ┌────────────────┐
            │   Provider     │
            │ Notifies UI    │
            │ Listeners      │
            └────────┬───────┘
                     │
                     v
            ┌────────────────┐
            │  Consumer/     │
            │ StreamBuilder  │
            │  Rebuilds      │
            │   UI           │
            └────────────────┘
```

## Authentication Flow

```
┌─────────────────────────────────────────┐
│   SignInScreen Displayed                 │
│   (user not authenticated)               │
└────────────────┬────────────────────────┘
                 │
                 │ User taps Google/Gmail
                 │
                 v
┌─────────────────────────────────────────┐
│  AuthProvider.signInWithGoogle()         │
└────────────────┬────────────────────────┘
                 │
                 v
┌─────────────────────────────────────────┐
│  GoogleSignIn.signIn()                   │
│  Shows system OAuth dialog               │
└────────────────┬────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
    Cancelled         Authorized
         │                │
         │                v
         │   ┌──────────────────────┐
         │   │GoogleAuth.getAuth()  │
         │   │Retrieve tokens       │
         │   └──────────┬───────────┘
         │              │
         │              v
         │   ┌──────────────────────┐
         │   │FirebaseAuth.signIn   │
         │   │(with Google tokens)  │
         │   └──────────┬───────────┘
         │              │
         v              v
    ┌─────────────────────────┐
    │  AuthProvider Updates   │
    │  _user = new User       │
    │  _isLoading = false     │
    │  notifyListeners()      │
    └─────────┬───────────────┘
              │
              v
    ┌─────────────────────────┐
    │ SaveUserProfile to      │
    │ Firestore:              │
    │ /users/{uid}/           │
    │  email,name,photo       │
    └─────────┬───────────────┘
              │
              v
    ┌─────────────────────────┐
    │ Consumer Listens to     │
    │ AuthProvider            │
    │ isAuthenticated = true  │
    └─────────┬───────────────┘
              │
              v
    ┌─────────────────────────┐
    │ Navigation:             │
    │ SignInScreen →          │
    │ MainNavigationScreen    │
    └─────────────────────────┘
```

## Firestore Database Schema

```json
{
  "users": {
    "{userId}": {
      "email": "user@example.com",
      "displayName": "John Doe",
      "photoURL": "https://...",
      "uid": "abc123...",
      "createdAt": "2026-03-27T...",
      "cashbooks": {
        "data": {
          "cashbooks": [
            {
              "name": "Personal",
              "transactions": [
                {
                  "title": "Grocery",
                  "amount": 500.0,
                  "category": "Food",
                  "isIncome": false,
                  "date": "2026-03-27T..."
                }
              ]
            }
          ],
          "updatedAt": "2026-03-27T..."
        }
      },
      "todos": {
        "data": {
          "todos": [
            {
              "title": "Buy milk",
              "description": "2% milk",
              "isCompleted": false,
              "priority": "High",
              "dueDate": "2026-04-01T..."
            }
          ],
          "updatedAt": "2026-03-27T..."
        }
      },
      "notes": {
        "data": {
          "notes": [
            {
              "date": "2026-03-27",
              "text": "Had a great day today..."
            }
          ],
          "updatedAt": "2026-03-27T..."
        }
      },
      "budget": {
        "data": {
          "amount": 5000.0,
          "updatedAt": "2026-03-27T..."
        }
      }
    }
  }
}
```

## Provider Dependency Graph

```
AppRoot
├── AuthProvider
│   └── (Independent)
│
├── CashbookProvider
│   ├── FirestoreService
│   └── LocalStorageService
│
├── TransactionProvider
│   ├── CashbookProvider (dependent)
│   └── FirestoreService
│
├── TodoProvider
│   ├── FirestoreService
│   └── LocalStorageService
│
├── NoteProvider
│   ├── FirestoreService
│   └── LocalStorageService
│
└── BudgetProvider
    └── FirestoreService
```

## Error Handling Flow

```
┌──────────────────────────────────────┐
│  Operation (sign-in, add data, etc.)  │
└────────────────┬─────────────────────┘
                 │
         ┌───────v────────┐
         │ Try Operation  │
         └───────┬────────┘
                 │
         ┌───────┴────────┐
         │                │
      Success          Error
         │                │
         │                v
         │        ┌────────────────┐
         │        │Catch Exception │
         │        │ (Firebase or   │
         │        │  Network)      │
         │        └────────┬───────┘
         │                 │
         │                 v
         │        ┌────────────────┐
         │        │AuthProvider    │
         │        │._errorMessage  │
         │        │= error.message │
         │        └────────┬───────┘
         │                 │
         │                 v
         │        ┌────────────────┐
         │        │notifyListeners│
         │        │               │
         │        │(UI shows error│
         │        │ message)      │
         │        └────────────────┘
         │
         v
    ┌───────────────┐
    │Update State   │
    │Notify UI      │
    │Show Success   │
    └───────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────┐
│     Client (FlutiApp)               │
├─────────────────────────────────────┤
│ • Firebase Auth SDK                 │
│ • Encrypted local storage           │
│ • No hardcoded secrets              │
└──────────────┬──────────────────────┘
               │
      (HTTPS + SSL/TLS)
               │
        ┌──────v───────┐
        │ Google OAuth │
        │   Servers    │
        └──────┬───────┘
               │
        ┌──────v──────────────┐
        │  Firebase Backend   │
        │  • Authentication   │
        │  • Authorization    │
        │  • Encryption       │
        ├─────────────────────┤
        │  Firestore Rules:   │
        │  Only user can      │
        │  access their data  │
        └────────────────────┘
```

## Performance Optimization

```
┌──────────────────────────────────┐
│ Operation Trigger (Add expense)  │
└────────────┬─────────────────────┘
             │
             v
    ┌────────────────┐
    │ Save to LOCAL  │
    │ (Instant ✓)    │
    └────────┬───────┘
             │
             v
    ┌────────────────┐
    │ Notify UI      │
    │ (Instant ✓)    │
    │ show new item  │
    └────────┬───────┘
             │
             v
    ┌────────────────────────┐
    │ Background: Save to    │
    │ Firestore              │
    │ (Async, non-blocking)  │
    │ ✓ UI stays responsive  │
    └────────────────────────┘
```

## Multi-Device Sync

```
Device A                    Firestore              Device B
  │                            │                      │
  ├─ Add Transaction ──────────>│                      │
  │                            │                      │
  │                            ├─ Stream Update ──────>│
  │                            │                      │
  │                            │                      ├─ Refresh UI
  │                            │                      │
  │<─────── Stream Update ──────┤<──── Add Todo ───────┤
  │                            │                      │
  ├─ Refresh UI                │                      │
  │                            │                      │
  └────────────────────────────┴──────────────────────┘
         Both devices always in sync!
```

---

**Last Updated**: March 27, 2026
**Diagram Type**: System Architecture
**Status**: ✅ Complete & Production Ready
