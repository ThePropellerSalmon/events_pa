import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../custom_widgets/side_menu_sections/calendar.dart';
import '../custom_widgets/side_menu_sections/events.dart';
import '../custom_widgets/side_menu_sections/hobbies.dart';
import '../custom_widgets/side_menu_sections/search.dart';

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

class SectionConfig {
  final double width;
  final double height;
  final double offsetFromLeft;
  final double offsetFromTop;
  final Widget widget;

  const SectionConfig({
    required this.width,
    required this.height,
    required this.offsetFromLeft,
    required this.offsetFromTop,
    required this.widget,
  });
}

class SideMenuScaffoldState extends State<SideMenuScaffold> {
  String? _activeSection;

  final Map<String, SectionConfig> _sections = {
    'search': SectionConfig(
      width: 220,
      height: 300,
      offsetFromLeft: 60,
      offsetFromTop: 40,
      widget: const Search(),
    ),
    'events': SectionConfig(
      width: 240,
      height: 500,
      offsetFromLeft: 40,
      offsetFromTop: 70,
      widget: const Events(),
    ),
    'calendar': SectionConfig(
      width: 260,
      height: 300,
      offsetFromLeft: 80,
      offsetFromTop: 40,
      widget: const Calendar(),
    ),
    'hobbies': SectionConfig(
      width: 200,
      height: 250,
      offsetFromLeft: 100,
      offsetFromTop: 40,
      widget: const Hobbies(),
    ),
  };

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
    final section = _sections[_activeSection];

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
                  if (section != null)
                    Positioned(
                      top: section.offsetFromTop,
                      left: section.offsetFromLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {}, // absorb taps inside section
                        child: Container(
                          width: section.width,
                          height: section.height,
                          color: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.all(16),
                          child: section.widget,
                        ),
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
}
