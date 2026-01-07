# 💫 Karma Split

<div align="center">

![Karma Split](https://img.shields.io/badge/Karma-Split-purple?style=for-the-badge&logo=flutter&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue?style=flat-square&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?style=flat-square&logo=firebase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8.1-blue?style=flat-square&logo=dart&logoColor=white)

**A Gamified Expense Splitting App that Makes Managing Group Finances Fun! 🎯**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📱 About Karma Split

Karma Split revolutionizes the way groups manage shared expenses by combining practical expense tracking with an engaging gamification system. Instead of just splitting bills, users earn "karma points" based on their spending behavior, creating a fun competitive environment that encourages fair participation and transparency.

### 🌟 What Makes It Special?

- **🎮 Gamified Experience**: Earn karma points for paying expenses, lose points when you owe money
- **🏆 Leaderboards**: Compete with friends and group members for the top spot
- **🏅 Achievement System**: Unlock medals and badges for your accomplishments
- **📸 Photo Proof**: Upload receipt images for transparency and verification
- **⚡ Real-time Updates**: See expenses and rankings update instantly across all devices
- **👥 Smart Group Management**: Create, join, and manage expense groups effortlessly

---

## 🚀 Features

### 💰 Core Expense Management
- **Add Expenses**: Simple form-based expense entry with amount, description, and proof image
- **Smart Splitting**: Automatically calculate equal shares among group members
- **Photo Verification**: Upload receipt images using camera or gallery
- **Real-time Sync**: All expenses sync instantly across group members

### 🎯 Gamification System
- **Karma Points**: Dynamic scoring system based on spending patterns
- **Positive Karma**: Earn points when you pay for group expenses
- **Negative Karma**: Lose points when you owe money to others
- **Rankings**: See your position within groups and overall leaderboard
- **Top Contributors**: Track who's been most generous in each group

### 🏅 Achievement & Recognition
- **Medal System**: First, Second, Third, Fourth, and Fifth place medals
- **Leaderboard Cards**: Beautiful profile cards with rankings and points
- **Top Contributor Badges**: Special recognition for group leaders
- **Visual Rewards**: Custom medal images and achievement displays

### 👥 Group Features
- **Create Groups**: Set up expense groups with custom names and images
- **Member Management**: Add/remove members, track group statistics
- **Group Leaderboards**: See rankings within each specific group
- **Activity Tracking**: Monitor group spending patterns and trends

### 🔐 Security & Authentication
- **Phone Authentication**: Secure login using phone numbers
- **Firebase Security**: Enterprise-grade security with Firebase Auth
- **Data Privacy**: All personal and financial data protected

---

## 🛠️ Technology Stack

### Frontend
- **Flutter 3.8.1**: Modern, cross-platform UI framework
- **Dart**: Type-safe programming language
- **Material Design**: Beautiful, consistent UI components
- **Riverpod**: State management for reactive programming

### Backend & Services
- **Firebase Authentication**: Phone-based user authentication
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Storage**: Secure file and image storage
- **Firebase Analytics**: Usage tracking and insights
- **Firebase Crashlytics**: Error monitoring and crash reporting

### External Integrations
- **Cloudinary**: Advanced image storage and optimization
- **HTTP**: RESTful API communication
- **Image Picker**: Camera and gallery integration

---

## 📦 Installation

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Firebase project setup
- Cloudinary account for image storage

### Setup Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/karma_split.git
   cd karma_split
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Phone provider)
   - Enable Cloud Firestore
   - Enable Firebase Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in appropriate platform directories

4. **Setup Cloudinary**
   - Create account at [Cloudinary](https://cloudinary.com)
   - Create upload preset for expense images
   - Add environment variables to `.env` file:
     ```
     CLOUDINARY_CLOUD_NAME=your_cloud_name
     CLOUDINARY_UPLOAD_PRESET=your_upload_preset
     CLOUDINARY_FOLDER=karma_split_expenses
     ```

5. **Run the App**
   ```bash
   flutter run
   ```

---

## 📱 Usage

### Getting Started
1. **Sign Up**: Authenticate using your phone number
2. **Create Profile**: Set your username and profile picture
3. **Create Group**: Start a new expense group or join existing ones
4. **Add Expenses**: Record shared expenses with photos and descriptions
5. **Track Karma**: Watch your karma points and rankings grow!

### Adding an Expense
1. Navigate to the "Add Expense" tab
2. Select the group for the expense
3. Enter amount and description
4. Take or upload a photo of the receipt
5. Tag people who need to split the cost
6. Submit and watch karma points update automatically

### Understanding Karma Points
- **Positive Points**: Earned when you pay for group expenses
- **Negative Points**: Accumulated when you owe money to others
- **Calculation**: Based on the difference between what you pay and your equal share
- **Real-time Updates**: Points update immediately after expense submission

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── expense.dart         # Expense data structure
│   ├── group.dart           # Group data structure
│   ├── groupmember.dart     # Group member data
│   └── user.dart            # User data structure
├── pages/                   # Screen widgets
│   ├── main_page.dart       # Main navigation
│   ├── add_expense_page.dart # Expense creation
│   ├── groups_page.dart     # Groups overview
│   ├── group_detail_page.dart # Individual group view
│   ├── profile_page.dart    # User profile
│   ├── login_page.dart      # Authentication
│   └── signup_page.dart     # User registration
├── providers/               # State management
│   └── group_providers.dart # Group state providers
├── utils/                   # Utility functions
│   ├── karma_calculator.dart # Karma point calculations
│   └── leaderboard_utils.dart # Ranking utilities
├── widgets/                 # Reusable UI components
│   ├── leaderboard_card.dart # Leaderboard display
│   ├── group_card.dart      # Group summary cards
│   ├── amount_spent.dart    # Amount input widget
│   ├── description.dart     # Description input
│   ├── proof_image.dart     # Image upload widget
│   ├── select_group.dart    # Group selection
│   └── tag_people_card.dart # People tagging
└── theme/                   # App theming
    └── app_theme.dart       # Color schemes and styles
```

### Key Components

#### Data Models
- **Expense**: Represents individual expense entries with amount, description, creator, and karma points
- **Group**: Manages group information including members, total karma, and top contributor
- **User**: Stores user profile information and authentication details
- **GroupMember**: Tracks individual member statistics within groups

#### State Management
- **Riverpod Providers**: Reactive state management for groups, expenses, and user data
- **Stream Builders**: Real-time updates from Firebase Firestore
- **State Notifiers**: Complex state logic for expense addition and group management

#### Utility Functions
- **KarmaCalculator**: Handles karma point calculations across multiple groups
- **LeaderboardUtils**: Manages user rankings and leaderboard generation
- **ImageHandler**: Processes image uploads to Cloudinary

---

## 🎨 UI/UX Features

### Design System
- **Material Design 3**: Modern, accessible design principles
- **Custom Color Scheme**: Purple-themed palette for premium feel
- **Responsive Layout**: Optimized for various screen sizes
- **Smooth Animations**: Fluid transitions and micro-interactions

### User Experience
- **Intuitive Navigation**: Bottom tab bar for main sections
- **Progressive Disclosure**: Step-by-step expense creation process
- **Real-time Feedback**: Immediate visual feedback for all actions
- **Error Handling**: Comprehensive error messages and recovery options

### Accessibility
- **Screen Reader Support**: Proper semantic markup and labels
- **High Contrast**: Readable color combinations
- **Touch Targets**: Appropriately sized interactive elements
- **Keyboard Navigation**: Full keyboard accessibility

---

## 🔧 Development

### Code Quality
- **Flutter Lints**: Enforced coding standards and best practices
- **Type Safety**: Strong typing throughout the codebase
- **Error Handling**: Comprehensive try-catch blocks and user feedback
- **Logging**: Detailed debug logs for troubleshooting

### Performance Optimizations
- **Lazy Loading**: Efficient data loading for large expense lists
- **Image Optimization**: Compressed and cached images
- **Firestore Queries**: Optimized database queries with indexes
- **State Management**: Minimal rebuilds with Riverpod

### Testing Strategy
- **Unit Tests**: Core business logic and utility functions
- **Widget Tests**: UI component behavior verification
- **Integration Tests**: End-to-end user workflows
- **Firebase Tests**: Mock Firebase services for testing

---

## 📊 Features Deep Dive

### Karma Point System
The karma point system is the heart of Karma Split's gamification:

```dart
// Karma calculation formula
final totalAmount = expense.amount;
final numberOfPeople = taggedPeople.length + 1; // +1 for payer
final equalShare = totalAmount / numberOfPeople;
final netContribution = totalAmount - equalShare;
final creatorKarmaPoints = netContribution;
```

### Real-time Leaderboards
- **Group Rankings**: Live updates within each expense group
- **Global Rankings**: Overall user rankings across all groups
- **Top Contributor Tracking**: Automatic detection and display of group leaders
- **Medal System**: Visual rewards for top performers

### Image Management
- **Camera Integration**: Direct photo capture from app
- **Gallery Selection**: Choose existing photos from device
- **Cloudinary Upload**: Secure cloud storage with optimization
- **Image Validation**: Size and format verification

---

## 🚀 Future Enhancements

### Planned Features
- **Expense Categories**: Organize expenses by type (food, transport, entertainment)
- **Settlement Reminders**: Automated notifications for outstanding balances
- **Currency Support**: Multiple currency handling for international groups
- **Export Data**: CSV/PDF export for expense tracking
- **Dark Mode**: System-wide dark theme support

### Advanced Features
- **AI Receipt Scanning**: OCR technology for automatic expense entry
- **Predictive Analytics**: Spending pattern analysis and recommendations
- **Integration APIs**: Connect with banking and payment apps
- **Multi-language Support**: Internationalization for global users

---

## 🤝 Contributing

We welcome contributions to Karma Split! Here's how you can help:

### Ways to Contribute
- **Bug Reports**: Submit issues for bugs or unexpected behavior
- **Feature Requests**: Suggest new features or improvements
- **Code Contributions**: Submit pull requests for fixes or enhancements
- **Documentation**: Improve code documentation and user guides
- **Testing**: Help test new features and report issues

### Development Guidelines
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Flutter and Dart style guides
- Write meaningful commit messages
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass before submitting

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Firebase**: For the robust backend infrastructure
- **Cloudinary**: For reliable image storage and processing
- **Material Design**: For the comprehensive design system
- **Open Source Community**: For the countless libraries and tools

---

## 📞 Support

Need help or have questions? Here's how to reach us:

- **Issues**: [GitHub Issues](https://github.com/yourusername/karma_split/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/karma_split/discussions)
- **Email**: support@karmasplit.com
- **Documentation**: [Wiki](https://github.com/yourusername/karma_split/wiki)

---

<div align="center">

**Made with ❤️ by the Nitin Dave**

[⬆ Back to Top](#-karma-split)

</div>
