import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import 'add_task_screen.dart';
import 'ai_assistant_screen.dart';
import 'cor_scanner_screen.dart';
import 'dashboard_screen.dart';
import 'planner_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';

class AutoSchedShell extends StatefulWidget {
  const AutoSchedShell({super.key});

  @override
  State<AutoSchedShell> createState() => _AutoSchedShellState();
}

class _AutoSchedShellState extends State<AutoSchedShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    PlannerScreen(),
    CorScannerScreen(),
    TasksScreen(),
    AiAssistantScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Planner'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: AppScope.of(context).activeClassSchedules.isNotEmpty,
              label: Text('${AppScope.of(context).activeClassSchedules.length}'),
              child: const Icon(Icons.document_scanner_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: AppScope.of(context).activeClassSchedules.isNotEmpty,
              label: Text('${AppScope.of(context).activeClassSchedules.length}'),
              child: const Icon(Icons.document_scanner_rounded),
            ),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('${AppScope.of(context).pendingTaskCount}'),
              isLabelVisible: AppScope.of(context).pendingTaskCount > 0,
              child: const Icon(Icons.checklist_rounded),
            ),
            selectedIcon: Badge(
              label: Text('${AppScope.of(context).pendingTaskCount}'),
              isLabelVisible: AppScope.of(context).pendingTaskCount > 0,
              child: const Icon(Icons.task_alt_rounded),
            ),
            label: 'Tasks',
          ),
          const NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'AI'),
          const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
