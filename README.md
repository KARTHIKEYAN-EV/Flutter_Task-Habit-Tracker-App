Task & Habit Tracker
A comprehensive Flutter application for tracking tasks, building habits, journaling, and earning rewards through a gamified experience.

Features
🔐 Authentication
Google Sign-In integration

Anonymous guest mode

Secure Firebase authentication

📊 Dashboard
Daily inspirational quotes

Progress tracking with visual indicators

Today's tasks overview

Habit completion status

User level and points system

✅ Task Management
Create, edit, and delete tasks

Set due dates and descriptions

Mark tasks as complete

Receive points for completed tasks

🔄 Habit Tracking
Create habits with custom targets (e.g., 21 days)

Track daily completion

Visual progress indicators

Earn points for maintaining streaks

📔 Digital Diary
Mood tracking (1-5 scale with emojis)

Journal entries with timestamps

Emotional well-being monitoring

Earn points for consistent journaling

🏆 Gamification System
Points System: Earn points for completing tasks (10 pts), habits (5 pts), and journal entries (5 pts)

Level Progression:

Bronze (0-199 pts)

Silver (200-499 pts)

Gold (500-999 pts)

Diamond (1000+ pts)

Achievements: Unlock badges for reaching milestones

Streaks: Maintain daily consistency for bonus rewards

👤 User Profile
Personal statistics dashboard

Achievement showcase

Account management

Data persistence (except for guest accounts)

Technology Stack
Frontend: Flutter with Material Design

Backend: Firebase (Firestore, Authentication)

Notifications: Flutter Local Notifications

State Management: Built-in Flutter state management with StreamBuilder

Date Handling: Intl package

Time Zones: Timezone package for scheduling

Installation
Prerequisites
Flutter SDK (latest version)

Firebase project setup

Google Sign-In configured for Android/iOS

Setup Steps
Clone the repository

bash
git clone <repository-url>
cd task-habit-tracker
Add Firebase Configuration

Create a new Firebase project

Add Android and iOS apps to your Firebase project

Download google-services.json (Android) and GoogleService-Info.plist (iOS)

Place these files in the appropriate directories

Enable Authentication Methods

In Firebase Console, enable Google Sign-In

Enable Anonymous authentication

Install Dependencies

bash
flutter pub get
Run the Application

bash
flutter run
Firebase Setup Guide
1. Create Firebase Project
Go to Firebase Console

Click "Add project" and follow the setup wizard

2. Configure Authentication
In your Firebase project, go to Authentication → Sign-in method

Enable "Google" and "Anonymous" sign-in providers

3. Configure Firestore Database
Go to Firestore Database → Create database

Start in test mode (for development) or production mode

4. Add Android App
In Project settings → General → Your apps

Click Android icon and follow setup instructions

Download google-services.json and place in android/app/ directory

5. Add iOS App (if developing for iOS)
Similar to Android setup but for iOS platform

Download GoogleService-Info.plist and add to Xcode project

Usage
Getting Started
Launch the app and sign in with Google or continue as guest

Note: Guest accounts have temporary data storage

Start by adding tasks or habits from their respective tabs

Earning Points
Complete a task: +10 points

Record a habit: +5 points daily

Write a journal entry: +5 points

Complete a habit streak: +50 points bonus

Level up: Achievement unlocked

Maintaining Streaks
The app tracks consecutive days of activity

Longer streaks earn bonus rewards and achievements

Breaking a streak resets the counter

Project Structure
text
lib/
├── main.dart              # App entry point, Firebase initialization
├── auth_wrapper.dart     # Authentication state management
├── login_page.dart       # Sign-in UI with Google and anonymous options
├── home_page.dart        # Main app structure with navigation
├── dashboard_page.dart   # Overview of tasks, habits, and inspiration
├── tasks_page.dart       # Task management functionality
├── habits_page.dart      # Habit tracking system
├── diary_page.dart       # Journal and mood tracking
├── profile_page.dart     # User profile and statistics
└── models/               # Data models (Task, Habit, DiaryEntry)
Data Models
Task Model
dart
class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
}
Habit Model
dart
class Habit {
  String id;
  String title;
  String description;
  int targetDays;
  int completedDays;
  List<DateTime> completedDates;
}
Diary Entry Model
dart
class DiaryEntry {
  String id;
  String title;
  String content;
  DateTime date;
  int mood; // 1-5 scale
}
Customization
Themes
Modify ThemeData in main.dart to customize the app's appearance:

Primary color scheme

Font family

Visual density

Notifications
Configure local notifications in the initialization section:

Android notification icons

iOS permission settings

Notification handling logic

Gamification Parameters
Adjust points and levels in _updateUserPoints() method:

Point values for different actions

Level thresholds

Achievement criteria

Troubleshooting
Common Issues
Firebase Initialization Error

Check Firebase configuration files are properly placed

Verify package names match between Flutter and Firebase projects

Google Sign-In Not Working

Ensure SHA-1 fingerprints are added to Firebase project

Verify OAuth consent screen is configured

Notification Permissions

On iOS, request permissions explicitly

On Android, ensure proper notification channels

Guest Account Limitations

Data is ephemeral and tied to device installation

Encourage users to create accounts for data persistence

Contributing
Fork the repository

Create a feature branch

Make your changes

Add tests if applicable

Submit a pull request

License
This project is licensed under the MIT License - see the LICENSE file for details.

Support
For support or questions, please create an issue in the GitHub repository or contact the development team.

Future Enhancements
Cloud synchronization across devices

Social features and sharing

Advanced analytics and insights

Custom notification scheduling

Export functionality for data

Additional authentication providers

Offline capability

Voice input for journal entries

Integration with health apps

Advanced habit analytics

Note: This application is designed for personal productivity and well-being tracking. For clinical mental health support, please consult professional healthcare providers.
