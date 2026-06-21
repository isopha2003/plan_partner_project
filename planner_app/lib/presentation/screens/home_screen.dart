import 'package:flutter/material.dart';
import 'package:planner_app/presentation/screens/calendar_screen.dart';
import 'package:planner_app/presentation/screens/deadline_tasks_screen.dart';
import 'package:planner_app/presentation/screens/stats_screen.dart';
import 'package:planner_app/presentation/screens/timer_screen.dart';
import 'package:planner_app/presentation/screens/today_screen.dart';

/// Root scaffold — 5 tabs; "오늘" is the default landing tab.
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
          TodayScreen(),
          CalendarScreen(),
          TimerScreen(),
          StatsScreen(),
          DeadlineTasksScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: '오늘',
          ),
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
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: '할 일',
          ),
        ],
      ),
    );
  }
}
