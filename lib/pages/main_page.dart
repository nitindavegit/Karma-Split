import 'package:flutter/material.dart';
import 'package:karma_split/pages/add_expense_page.dart';
import 'package:karma_split/pages/groups_page.dart';
import 'package:karma_split/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPage = 0;

  // Create pages with callbacks for navigation
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const GroupsPage(),
      AddExpensePage(onExpenseAdded: _navigateToGroups),
      const ProfilePage(),
    ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Expense"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
