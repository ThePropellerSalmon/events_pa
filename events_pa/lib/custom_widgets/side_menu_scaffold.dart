import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideMenuScaffold extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSectionOpenOrClick;

  const SideMenuScaffold({
    super.key,
    required this.child,
    this.onSectionOpenOrClick,
  });

  @override
  SideMenuScaffoldState createState() => SideMenuScaffoldState();
}

class SideMenuScaffoldState extends State<SideMenuScaffold> {
  String? _activeSection;

  void _toggleSection(String section) {
    widget.onSectionOpenOrClick?.call(); // close map popups first
    setState(() {
      _activeSection = (_activeSection == section) ? null : section;
    });
  }

  void clearSection({bool closePopup = true}) {
    if (closePopup) {
      widget.onSectionOpenOrClick?.call(); // close map popups first
    }
    setState(() {
      _activeSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: clearSection, // clicking anywhere clears sections + popups
        child: Row(
          children: [
            Container(
              width: 40,
              color: Colors.grey.shade200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.person_outline_outlined),
                    onPressed: () {
                      widget.onSectionOpenOrClick?.call();
                      context.go('/account');
                    },
                    tooltip: 'Account',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _toggleSection('search'),
                    tooltip: 'Search',
                  ),
                  IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: () => _toggleSection('events'),
                    tooltip: 'Events',
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _toggleSection('calendar'),
                    tooltip: 'Calendar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_location_outlined),
                    onPressed: () => _toggleSection('hobbies'),
                    tooltip: 'Hobbies',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  widget.child,
                  if (_activeSection != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 300,
                        color: Colors.white.withOpacity(0.9),
                        padding: const EdgeInsets.all(16),
                        child: _buildSectionContent(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'search':
        return const Text('Search Section Content');
      case 'events':
        return const Text('Events Section Content');
      case 'calendar':
        return const Text('Calendar Section Content');
      case 'hobbies':
        return const Text('Hobbies Section Content');
      default:
        return const SizedBox.shrink();
    }
  }
}
