
# 💰 Karma Split

> **A social expense tracker with a karma point system.**  
> Track expenses, split bills, and earn karma points for your contributions.

![Topics](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Topics](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Topics](https://img.shields.io/badge/Riverpod-2D3748?style=for-the-badge&logo=riverpod&logoColor=white)
![Topics](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

<p align="center">
  <img src="assets/images/AppLogo.png" alt="Karma Split" width="150"/>
</p>

<p align="center">
  <a href="https://youtube.com/shorts/WbNIxsJ654g?feature=share">🎥 <b>Watch Demo Video</b></a>
  &nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;
  <a href="https://drive.google.com/file/d/1mEwKz-GiBTw2rJaJjYL_B7I4axXcJWEj/view?usp=sharing">📥 <b>Download APK</b></a>
</p>


---

## ✨ Features

### 👥 Group Management
- **Create & Join Groups**: Easily create expense groups for trips, apartments, or friend circles
- **Member Management**: Add/remove members, track their contributions
- **Group Settings**: Configure group details and preferences

### 💸 Expense Tracking
- **Add Expenses**: Record expenses with descriptions, amounts, and proof images
- **Proof Images**: Attach photos as proof for each expense
- **Smart Splitting**: Split bills equally or by specific amounts
- **Tag People**: Assign expenses to specific group members

### 📊 Karma Points System
- **Karma Score**: Earn karma points for spending money on the group
- **Leaderboards**: Compete with friends on who contributes most
- **Medals & Rankings**: Visual rankings with gold, silver, bronze medals
- **Real-time Updates**: Karma scores update automatically

---

## 🔒 Demo Credentials & Limits

**Note:** To prevent abuse, this app has a global daily limit of **10 OTP requests**.

### ⚠️ If OTP Limit Exceeds
If you see the "Limit Reached" message, please use the following **Demo Credentials** to access the app in "View Only" mode:

| 📱 Phone Number | 🔑 OTP |
|----------------|---------|
| **7233665588** | **625285** |

### Other Limits
*   **Daily Expenses**: Max 10 expenses per user per day.

---

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point & Firebase initialization
├── models/                   # Data models
│   ├── expense.dart         # Expense model with properties
│   ├── group.dart           # Group model with members
│   ├── groupmember.dart     # Group member model
│   └── user.dart            # User profile model
├── pages/                    # App screens
│   ├── auth_choice_page.dart      # Login/Signup choice
│   ├── login_page.dart            # Login screen
│   ├── signup_page.dart           # Registration screen
│   ├── main_page.dart             # Main navigation
│   ├── groups_page.dart           # Groups list
│   ├── add_group_page.dart        # Create group
│   ├── group_detail_page.dart     # Group expenses & details
│   ├── add_expense_page.dart      # Add new expense
│   └── profile_page.dart          # User profile & stats
├── providers/                # State management (Riverpod)
│   └── group_providers.dart  # Group data providers
├── theme/                    # App theming
│   └── app_theme.dart        # Theme configuration
├── utils/                    # Utility functions
│   ├── karma_calculator.dart     # Karma point calculations
│   ├── leaderboard_utils.dart    # Leaderboard sorting
│   ├── number_formatter.dart     # Number formatting
│   └── image_compressor.dart     # Image compression
└── widgets/                  # Reusable UI components
    ├── group_card.dart           # Group preview card
    ├── expense_card.dart         # Expense display
    ├── leaderboard_card.dart     # Leaderboard entry
    ├── stat_card.dart            # Statistics display
    ├── proof_image.dart          # Expense proof image
    └── ...
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.8+ |
| **Language** | Dart |
| **Backend** | Firebase (Firestore, Auth, Storage) |
| **State Management** | Riverpod |
| **Authentication** | Firebase Auth |
| **Database** | Cloud Firestore |
| **Storage** | Firebase Storage (images) |
| **Analytics** | Firebase Analytics |
| **Crash Reporting** | Firebase Crashlytics |
| **Image Handling** | image_picker, flutter_image_compressor |
| **Camera** | camera |
| **Permissions** | permission_handler |

---

## 📦 Dependencies

### Core
- `flutter` - UI framework
- `firebase_core` - Firebase initialization
- `flutter_riverpod` - State management
- `intl` - Internationalization & formatting

### Firebase Services
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `firebase_analytics` - Analytics
- `firebase_crashlytics` - Crash reporting

### Media & Camera
- `image_picker` - Image selection
- `camera` - Camera capture
- `flutter_image_compress` - Image compression
- `cloudinary_flutter` - Cloud image hosting

### Utilities
- `permission_handler` - Runtime permissions
- `shared_preferences` - Local storage
- `uuid` - Unique ID generation
- `http` - HTTP requests
- `flutter_dotenv` - Environment variables

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Firebase project set up
- Dart SDK 3.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/karma_split.git
   cd karma_split
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add Android and iOS apps
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Set up Storage bucket

4. **Configure environment**
   ```bash
   # Create .env file
   cp .env.example .env
   # Add your Firebase config keys
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 App Screens

| Screen | Description |
|--------|-------------|
| **Auth Choice** | Choose between login and signup |
| **Login** | Email/password authentication |
| **Signup** | Create new account |
| **Groups** | List of all your groups |
| **Group Detail** | Expenses, members, and karma leaderboard |
| **Add Expense** | Record new expense with proof |
| **Profile** | User stats and karma points |

---

## 🎯 Karma System Explained

The karma point system rewards members who contribute financially to the group:

- **Earning Karma**: Each ₹1 spent earns 1 karma point
- **Leaderboard**: Members ranked by total karma earned
- **Medals**: Top 3 get gold 🥇, silver 🥈, bronze 🥉 medals
- **Reset**: Karma resets monthly for fresh competition

---

## 🔧 Configuration

### App Version
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# major.minor.patch+buildNumber
```

### App Name
Change app name in:
- `android/app/src/main/AndroidManifest.xml` (`android:label`)
- `ios/Runner/Info.plist` (`CFBundleDisplayName`)

### Theme Colors
Modify in `lib/theme/app_theme.dart`:
```dart
static const Color primary = Color(0xFF6200EE);
static const Color secondary = Color(0xFF03DAC6);
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Creator

**Nitin Dave**

- GitHub: [Nitin Dave](https://github.com/nitindavegit)
- Email: nitindave2111@gmail.com

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - UI toolkit
- [Firebase](https://firebase.google.com) - Backend services
- [Riverpod](https://riverpod.dev) - State management
- [Icons8](https://icons8.com) - App icons

---

<div align="center">
  Made with ❤️ by Nitin Dave
</div>
