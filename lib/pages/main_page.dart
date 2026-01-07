import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karma_split/pages/add_expense_page.dart';
import 'package:karma_split/pages/groups_page.dart';
import 'package:karma_split/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentPage = 0;

  // Create pages with callbacks for navigation
  // Use late init to ensure pages are created only once
  late final List<Widget> _pages;

  // For press again to exit functionality
  DateTime? _lastBackPressTime;
  bool _showExitWarning = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      const GroupsPage(),
      AddExpensePage(onExpenseAdded: _navigateToGroups),
      const ProfilePage(),
    ];
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Exit the app completely when it goes to background
    // This ensures a fresh start when the app is opened again
    if (state == AppLifecycleState.paused) {
      // Use a delay to ensure the app has time to pause properly
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Try multiple methods to exit the app
          try {
            SystemNavigator.pop(animated: true);
          } catch (e) {
            // If SystemNavigator.pop() fails, try exit(0)
            exit(0);
          }
        }
      });
    }
  }

  void _navigateToGroups() {
    setState(() {
      _currentPage = 0; // Switch to Groups tab
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    // Check if this is the first back press or if it's been more than 2 seconds
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      // Show snackbar warning
      if (mounted) {
        setState(() {
          _showExitWarning = true;
        });
      }

      // Clear the warning after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showExitWarning = false;
          });
        }
      });

      return false; // Don't exit yet
    }

    // Second press within 2 seconds - exit the app
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Handle back press with "press again to exit" logic
        final shouldExit = await _onWillPop();
        if (shouldExit && mounted) {
          // Use exit(0) to exit the app properly on Android
          exit(0);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              _pages[_currentPage],
              // Exit warning overlay
              if (_showExitWarning)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Press back again to exit',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentPage,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Add Expense",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
