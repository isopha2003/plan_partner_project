import 'package:flutter/material.dart';
import 'package:planner_app/presentation/screens/calendar_screen.dart';
import 'package:planner_app/presentation/screens/stats_screen.dart';
import 'package:planner_app/presentation/screens/timer_screen.dart';

/// Root scaffold that hosts the three main tabs via a bottom NavigationBar.
/// IndexedStack keeps each tab's widget tree (and scroll position) alive
/// while switching between tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          CalendarScreen(),
          TimerScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: '타이머',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '통계',
          ),
        ],
      ),
    );
  }
}
