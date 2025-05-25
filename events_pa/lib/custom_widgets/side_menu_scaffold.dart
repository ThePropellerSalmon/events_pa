import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideMenuScaffold extends StatelessWidget {
  final Widget child;

  const SideMenuScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 40,
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.person_outline_outlined),
                  onPressed: () => context.go('/account'),
                  tooltip: 'Account',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.go('/account'),
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () => context.go('/account'),
                  tooltip: 'Events',
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => context.go('/account'),
                  tooltip: 'Calendar',
                ),
                IconButton(
                  icon: const Icon(Icons.add_location_outlined),
                  onPressed: () => context.go('/account'),
                  tooltip: 'Hobbies',
                ),
              ],
            ),
          ),

          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}
