import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'events_section/event_detailed_overlay.dart';

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  final _client = Supabase.instance.client;
  final Map<String, int> _priorityOrder = {'A': 0, 'B': 1, 'C': 2, 'D': 3};

  bool _loading = true;
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDate = {};
  final int _daysToLoad = 60;

  Map<String, dynamic>? _selectedEvent;

  late final DateTime _startOfToday = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    _fetchAllEvents();
  }

  Future<void> _fetchAllEvents() async {
    final endOfRange = _startOfToday.add(Duration(days: _daysToLoad - 1));

    final eventDatesRes = await _client
        .from('eventsDates')
        .select('''
          eventDateId,
          eventStartDate,
          eventEndDate,
          eventId,
          events (
            eventId,
            title,
            description,
            eventAddress,
            eventAddedDate,
            userId,
            users (
              priority
            )
          )
        ''')
        .lte('eventStartDate', endOfRange.toIso8601String())
        .gte('eventStartDate', _startOfToday.toIso8601String());

    final Map<String, Map<String, dynamic>> groupedEvents = {};
    final Map<DateTime, List<Map<String, dynamic>>> tempEventsByDate = {};

    for (final dynamic rawEntry in eventDatesRes) {
      final entry = Map<String, dynamic>.from(rawEntry);
      final start = DateTime.parse(entry['eventStartDate']);
      final end = DateTime.parse(entry['eventEndDate']);
      final event = Map<String, dynamic>.from(entry['events'] ?? {});
      if (event.isEmpty) continue;

      final user = event['users'] ?? {};
      final priority = user['priority'] ?? 'D';
      final eventId = event['eventId'].toString();
      final dateKey = DateTime(start.year, start.month, start.day);

      final baseEvent = {
        ...event,
        'priority': priority,
        'eventTimeSlots': <Map<String, dynamic>>[],
      };

      if (!groupedEvents.containsKey(eventId)) {
        groupedEvents[eventId] = Map<String, dynamic>.from(baseEvent);
      }

      (groupedEvents[eventId]!['eventTimeSlots'] as List<Map<String, dynamic>>)
          .add({
            'eventStartDate': entry['eventStartDate'],
            'eventEndDate': entry['eventEndDate'],
          });

      tempEventsByDate.putIfAbsent(dateKey, () => []);
      if (!tempEventsByDate[dateKey]!.contains(groupedEvents[eventId])) {
        tempEventsByDate[dateKey]!.add(groupedEvents[eventId]!);
      }
    }

    for (final date in tempEventsByDate.keys) {
      tempEventsByDate[date]!.sort((a, b) {
        final prioA = _priorityOrder[a['priority']] ?? 999;
        final prioB = _priorityOrder[b['priority']] ?? 999;
        if (prioA != prioB) return prioA.compareTo(prioB);

        final addedA = DateTime.tryParse(a['eventAddedDate'] ?? '');
        final addedB = DateTime.tryParse(b['eventAddedDate'] ?? '');
        return _compareNullableDates(addedA, addedB);
      });
    }

    setState(() {
      _eventsByDate = tempEventsByDate;
      _loading = false;
    });
  }

  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  String _dateLabel(DateTime date) {
    final today = _startOfToday;
    final dayDiff = date.difference(today).inDays;

    if (dayDiff == 0) return 'Today';
    if (dayDiff == 1) return 'Tomorrow';
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalPages = (_daysToLoad / 3).ceil();

    return Stack(
      children: [
        PageView.builder(
          itemCount: totalPages,
          itemBuilder: (context, pageIndex) {
            final pageDates = List.generate(
              3,
              (i) => _startOfToday.add(Duration(days: pageIndex * 3 + i)),
            );

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:
                      pageDates.map((date) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              _dateLabel(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children:
                        pageDates.map((date) {
                          final events = _eventsByDate[date] ?? [];
                          return Expanded(
                            child: ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                final event = events[index];
                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _selectedEvent = event,
                                      ),
                                  child: Card(
                                    margin: const EdgeInsets.all(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        '${event['title'] ?? 'No Title'}',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          },
        ),

        if (_selectedEvent != null)
          EventDetailOverlay(
            event: _selectedEvent!,
            onClose: () => setState(() => _selectedEvent = null),
          ),
      ],
    );
  }
}
