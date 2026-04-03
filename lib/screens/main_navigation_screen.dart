import 'package:flutter/material.dart';

import 'cashbook/cashbook_home_screen.dart';
import 'cashbook/analytics_screen.dart';
import 'todo/todo_home_screen.dart';
import 'calendar/calendar_screen.dart'; // ✅ NEW
import 'profile_screen.dart'; // ✅ NEW

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int index = 0;

  final screens = const [
    CashbookHomeScreen(),
    AnalyticsScreen(),
    TodoHomeScreen(),
    CalendarScreen(), // ✅ REPLACED
    ProfileScreen(), // ✅ NEW
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,

        onTap: (i) {
          setState(() {
            index = i;
          });
        },

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5A4FD1),
        unselectedItemColor: Colors.grey,

        elevation: 12,
        selectedFontSize: 14,
        unselectedFontSize: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Cashbook",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Analytics",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Todo",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Diary", // ✅ UPDATED
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile", // ✅ NEW
          ),
        ],
      ),
    );
  }
}
