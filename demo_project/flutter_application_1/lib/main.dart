import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
  
  
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
      
        print("Notification response received: ${response.payload}");
      },
    );
    print("Notifications initialized successfully");
  } catch (e) {
    print("Failed to initialize notifications: $e");
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task & Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage();
          }
          return HomePage();
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Try to sign in silently first to avoid UI pop-ups if already signed in
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If silent sign-in fails, try with UI
      googleUser ??= await _googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
            
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = 
            await _auth.signInWithCredential(credential);
            
        print("Signed in with Google as: ${userCredential.user?.displayName}");
      } else {
        print("Google sign-in canceled by user");
      }
    } catch (e) {
      print("Google sign-in error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      print("Signed in anonymously: ${userCredential.user?.uid}");
    } catch (e) {
      print("Anonymous sign-in error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Hero(
                    tag: 'app_logo',
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.task_alt,
                        size: 100,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Task & Habit Tracker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'You have to dream before your dreams can come true',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Google Sign-In Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Use a built-in icon instead of a network image
                        Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Guest Sign-In Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _isLoading ? null : _signInAnonymously,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.blue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUserLevel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // User level related variables
  int _userPoints = 0;
  String _userLevel = 'Bronze';
  int _streakCount = 0;
  List<String> _achievements = [];

  Future<void> _loadUserLevel() async {
    if (currentUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data();
          if (userData != null) {
            setState(() {
              _userPoints = userData['points'] ?? 0;
              _userLevel = userData['level'] ?? 'Bronze';
              _streakCount = userData['streakCount'] ?? 0;
              // Safely convert to List<String>
              _achievements = (userData['achievements'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ?? [];
            });
          }
        } else {
          // Create new user document with default values
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .set({
            'points': 0,
            'level': 'Bronze',
            'streakCount': 0,
            'achievements': [],
            'email': currentUser!.email ?? 'anonymous@guest.com',
            'displayName': currentUser!.displayName ?? 'Guest',
            'photoURL': currentUser!.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data. Please try again.')),
        );
      }
    }
  }

  Future<void> _updateUserPoints(int points) async {
    if (currentUser != null) {
      try {
        setState(() {
          _userPoints += points;
        });
        
        // Update level based on points
        String newLevel = 'Bronze';
        if (_userPoints >= 1000)
          newLevel = 'Diamond';
        else if (_userPoints >= 500)
          newLevel = 'Gold';
        else if (_userPoints >= 200)
          newLevel = 'Silver';
        
        if (newLevel != _userLevel) {
          setState(() {
            _userLevel = newLevel;
          });
          
          if (!_achievements.contains('Reached $newLevel Level')) {
            setState(() {
              _achievements.add('Reached $newLevel Level');
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Congratulations! You\'ve reached $newLevel level!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({
          'points': _userPoints,
          'level': _userLevel,
          'achievements': _achievements,
        });
        
        print('Points updated successfully: $_userPoints');
      } catch (e) {
        print('Error updating user points: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update points. Please try again.')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task & Habit Tracker'),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  '$_userLevel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_userPoints pts',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          DashboardPage(
            onPointsEarned: _updateUserPoints,
            streakCount: _streakCount,
            userLevel: _userLevel,
          ),
          TasksPage(onPointsEarned: _updateUserPoints),
          HabitsPage(onPointsEarned: _updateUserPoints),
          DiaryPage(onPointsEarned: _updateUserPoints),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Define Task data model
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

// Define Habit data model
class Habit {
  final String id;
  final String title;
  final String description;
  final int targetDays;
  int completedDays;
  List<DateTime> completedDates;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    this.completedDays = 0,
    List<DateTime>? completedDates,
  }) : this.completedDates = completedDates ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDays': targetDays,
      'completedDays': completedDays,
      'completedDates': completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetDays: map['targetDays'],
      completedDays: map['completedDays'] ?? 0,
      completedDates: (map['completedDates'] as List<dynamic>?)?.map(
        (date) => DateTime.fromMillisecondsSinceEpoch(date)
      ).toList() ?? [],
    );
  }

  double get progress => completedDays / targetDays;
}

// Define Diary Entry data model
class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final int mood; // 1-5 scale

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.millisecondsSinceEpoch,
      'mood': mood,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      mood: map['mood'],
    );
  }
}

class DashboardPage extends StatelessWidget {
  final Function(int) onPointsEarned;
  final int streakCount;
  final String userLevel;
  
  DashboardPage({
    required this.onPointsEarned, 
    required this.streakCount,
    required this.userLevel,
  });

  final List<String> _quotes = [
    "Dream, dream, dream. Dreams transform into thoughts and thoughts result in action.",
    "You have to dream before your dreams can come true.",
    "Don't take rest after your first victory because if you fail in second, more lips are waiting to say that your first victory was just luck.",
    "If you fail, never give up because FAIL means First Attempt In Learning.",
    "Excellence is a continuous process and not an accident.",
  ];

  String _getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Level Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Level: $userLevel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete tasks and maintain habits to earn points and level up!',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => onPointsEarned(5),
                    child: Text('Earn 5 Points (Testing)'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Quote Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Inspiration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getRandomQuote(),
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Streak Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, 
                      color: Colors.orange, size: 40),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '$streakCount days',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          Text(
            'Today\'s Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          
          // Tasks Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('tasks')
                .where('dueDate', isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch - 86400000)
                .where('isCompleted', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No tasks for today. Add tasks from the Tasks tab!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }
              
              return Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length > 3 ? 3 : snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Icon(Icons.check_box_outline_blank),
                      title: Text(data['title']),
                      subtitle: Text('Due: ${DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(data['dueDate']))}'),
                      trailing: IconButton(
                        icon: Icon(Icons.check_circle_outline),
                        onPressed: () async {
                          // Complete task
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('tasks')
                              .doc(data['id'])
                              .update({'isCompleted': true});
                          
                          // Award points
                          onPointsEarned(10);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task completed! +10 points')),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          SizedBox(height: 20),
          Text(
            'Habits Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          
          // Habits Stream
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('habits')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No habits tracked yet. Add habits from the Habits tab!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }
              
              return Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length > 3 ? 3 : snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    var habit = Habit.fromMap(data);
                    
                    // Check if already completed today
                    bool completedToday = false;
                    if (habit.completedDates.isNotEmpty) {
                      final today = DateTime.now();
                      completedToday = habit.completedDates.any((date) => 
                        date.year == today.year && 
                        date.month == today.month && 
                        date.day == today.day
                      );
                    }
                    
                    return ListTile(
                      leading: Icon(Icons.loop),
                      title: Text(habit.title),
                      subtitle: LinearProgressIndicator(value: habit.progress),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(habit.progress * 100).toInt()}%'),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              completedToday ? Icons.check_circle : Icons.add_circle_outline,
                              color: completedToday ? Colors.green : null,
                            ),
                            onPressed: completedToday ? null : () async {
                              // Update habit progress
                              habit.completedDays++;
                              habit.completedDates.add(DateTime.now());
                              
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('habits')
                                  .doc(habit.id)
                                  .update({
                                'completedDays': habit.completedDays,
                                'completedDates': habit.completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
                              });
                              
                              // Award points
                              onPointsEarned(5);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Habit recorded! +5 points')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  final Function(int) onPointsEarned;
  
  TasksPage({required this.onPointsEarned});
  
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _addTask() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Create a unique ID
      final taskId = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc()
          .id;
      
      final task = Task(
        id: taskId,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
      );
      
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc(taskId)
            .set(task.toMap());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task added successfully!')),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = DateTime.now();
        });
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Due Date: ${DateFormat('MMM d, y').format(_selectedDate)}'),
                    Spacer(),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: Text('Add Task'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('tasks')
            .orderBy('dueDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 100, color: Colors.blue.withOpacity(0.5)),
                  SizedBox(height: 20),
                  Text(
                    'No Tasks Yet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add your first task by tapping the button below',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          // Group tasks by status (incomplete first, then completed)
          final incompleteTasks = snapshot.data!.docs
              .where((doc) => !(doc.data() as Map<String, dynamic>)['isCompleted'])
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
              
          final completedTasks = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['isCompleted'])
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Text(
                'Pending Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (incompleteTasks.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No pending tasks. Great job!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...incompleteTasks.map((task) => _buildTaskCard(task)),
              
              SizedBox(height: 20),
              Text(
                'Completed Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (completedTasks.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No completed tasks yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...completedTasks.map((task) => _buildTaskCard(task)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Task',
      ),
    );
  }
  
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return;
            
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('tasks')
                .doc(task.id)
                .update({'isCompleted': value});
                
            if (value == true) {
              // Award points when task is completed
              widget.onPointsEarned(10);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task completed! +10 points')),
              );
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
            Text(
              'Due: ${DateFormat('MMM d, y').format(task.dueDate)}',
              style: TextStyle(
                color: task.isCompleted 
                    ? Colors.grey 
                    : task.dueDate.isBefore(DateTime.now()) 
                        ? Colors.red 
                        : null,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return;
            
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('tasks')
                  .doc(task.id)
                  .delete();
                  
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task deleted')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete task: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}

class HabitsPage extends StatefulWidget {
  final Function(int) onPointsEarned;
  
  HabitsPage({required this.onPointsEarned});
  
  @override
  _HabitsPageState createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _targetDays = 21; // Default 21 days to form a habit
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _addHabit() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Create a unique ID
      final habitId = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('habits')
          .doc()
          .id;
      
      final habit = Habit(
        id: habitId,
        title: _titleController.text,
        description: _descriptionController.text,
        targetDays: _targetDays,
      );
      
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('habits')
            .doc(habitId)
            .set(habit.toMap());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Habit added successfully!')),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _targetDays = 21;
        });
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add habit: $e')),
        );
      }
    }
  }
  
  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Habit'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Habit Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Target Days: $_targetDays'),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (_targetDays > 1) _targetDays--;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _targetDays++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addHabit,
            child: Text('Add Habit'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('habits')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 100, color: Colors.blue.withOpacity(0.5)),
                  SizedBox(height: 20),
                  Text(
                    'No Habits Yet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add your first habit by tapping the button below',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          final habits = snapshot.data!.docs
              .map((doc) => Habit.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Text(
                'Your Habits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...habits.map((habit) => _buildHabitCard(habit)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Habit',
      ),
    );
  }
  
  Widget _buildHabitCard(Habit habit) {
    // Check if already completed today
    bool completedToday = false;
    if (habit.completedDates.isNotEmpty) {
      final today = DateTime.now();
      completedToday = habit.completedDates.any((date) => 
        date.year == today.year && 
        date.month == today.month && 
        date.day == today.day
      );
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (habit.description.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(habit.description),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;
                    
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('habits')
                          .doc(habit.id)
                          .delete();
                          
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Habit deleted')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete habit: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: habit.progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${habit.completedDays}/${habit.targetDays} days'),
                Text('${(habit.progress * 100).toInt()}%'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: completedToday ? null : () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;
                
                try {
                  // Update habit progress
                  habit.completedDays++;
                  habit.completedDates.add(DateTime.now());
                  
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('habits')
                      .doc(habit.id)
                      .update({
                    'completedDays': habit.completedDays,
                    'completedDates': habit.completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
                  });
                  
                  // Award points
                  widget.onPointsEarned(5);
                  
                  // Check if habit is completed
                  if (habit.completedDays >= habit.targetDays) {
                    widget.onPointsEarned(50); // Bonus for completing the habit
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Congratulations! Habit completed! +55 points'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Progress recorded! +5 points')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update habit: $e')),
                  );
                }
              },
              icon: Icon(completedToday ? Icons.check : Icons.add),
              label: Text(completedToday ? 'Completed Today' : 'Mark Done Today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: completedToday ? Colors.green : null,
                disabledBackgroundColor: Colors.green.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryPage extends StatefulWidget {
  final Function(int) onPointsEarned;
  
  DiaryPage({required this.onPointsEarned});
  
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _selectedMood = 3; // Default mood (1-5 scale)
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _addDiaryEntry() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Create a unique ID
      final entryId = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('diary')
          .doc()
          .id;
      
      final entry = DiaryEntry(
        id: entryId,
        title: _titleController.text,
        content: _contentController.text,
        date: DateTime.now(),
        mood: _selectedMood,
      );
      
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('diary')
            .doc(entryId)
            .set(entry.toMap());
        
        // Award points for adding diary entry
        widget.onPointsEarned(5);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Diary entry added! +5 points')),
        );
        
        // Clear form
        _titleController.clear();
        _contentController.clear();
        setState(() {
          _selectedMood = 3;
        });
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add diary entry: $e')),
        );
      }
    }
  }
  
  void _showAddDiaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Diary Entry'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Journal Entry',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some content';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text('How are you feeling today?'),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final mood = index + 1;
                    final icon = [
                      Icons.sentiment_very_dissatisfied,
                      Icons.sentiment_dissatisfied,
                      Icons.sentiment_neutral,
                      Icons.sentiment_satisfied,
                      Icons.sentiment_very_satisfied,
                    ][index];
                    
                    return IconButton(
                      icon: Icon(
                        icon,
                        color: _selectedMood == mood 
                            ? Colors.blue
                            : Colors.grey,
                        size: _selectedMood == mood ? 36 : 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addDiaryEntry,
            child: Text('Save Entry'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('diary')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 100, color: Colors.blue.withOpacity(0.5)),
                  SizedBox(height: 20),
                  Text(
                    'No Diary Entries Yet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Start journaling by tapping the button below',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          final entries = snapshot.data!.docs
              .map((doc) => DiaryEntry.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Text(
                'Your Journal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...entries.map((entry) => _buildDiaryCard(entry)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiaryDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Entry',
      ),
    );
  }
  
  Widget _buildDiaryCard(DiaryEntry entry) {
    final icons = [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];
    
    final moodIcon = icons[entry.mood - 1];
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y').format(entry.date),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(moodIcon, color: Colors.blue),
              ],
            ),
            SizedBox(height: 8),
            Text(
              entry.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(entry.content),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Delete'),
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;
                    
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('diary')
                          .doc(entry.id)
                          .delete();
                          
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Diary entry deleted')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete entry: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = user?.isAnonymous ?? true;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: user?.photoURL != null 
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Icon(Icons.person, size: 50, color: Colors.blue)
                : null,
          ),
          SizedBox(height: 20),
          Text(
            user?.displayName ?? 'Guest User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.email ?? 'Anonymous User',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 30),
          
          // User statistics from Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              if (userData == null) {
                return SizedBox();
              }
              
              final level = userData['level'] ?? 'Bronze';
              final points = userData['points'] ?? 0;
              final streakCount = userData['streakCount'] ?? 0;
              final achievements = (userData['achievements'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ?? [];
              
              return Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildStatRow('Level', level),
                          _buildStatRow('Points', '$points pts'),
                          _buildStatRow('Current Streak', '$streakCount days'),
                          
                          SizedBox(height: 16),
                          Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (achievements.isEmpty)
                            Text(
                              'No achievements yet. Keep going!',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            Column(
                              children: achievements
                                  .map((achievement) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.emoji_events, color: Colors.amber),
                                        SizedBox(width: 8),
                                        Text(achievement),
                                      ],
                                    ),
                                  ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              );
            },
          ),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.blue),
                    title: Text('Account Settings'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account settings would go here')),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.blue),
                    title: Text('App Settings'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('App settings would go here')),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.help, color: Colors.blue),
                    title: Text('Help & Support'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Help & support would go here')),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Sign Out'),
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        // Will automatically navigate to login due to AuthWrapper
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error signing out: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          if (isAnonymous)
            Card(
              elevation: 4,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'You\'re signed in as a guest',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your data will be lost when you sign out. Create an account to save your progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upgrade account functionality would go here')),
                        );
                      },
                      child: Text('Create Account'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
