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

    // Fetch events in range
    final eventsRes = await _client
        .from('events')
        .select()
        .lte('eventStartDate', endOfRange.toIso8601String())
        .gte('eventEndDate', _startOfToday.toIso8601String());

    final events = (eventsRes as List).cast<Map<String, dynamic>>();

    // Group by day
    final Map<DateTime, List<Map<String, dynamic>>> tempEventsByDate = {};
    final allDates = List.generate(
      _daysToLoad,
      (i) => _startOfToday.add(Duration(days: i)),
    );

    for (final day in allDates) {
      final dailyEvents = <Map<String, dynamic>>[];

      for (var event in events) {
        final start = DateTime.parse(event['eventStartDate']);
        final end = DateTime.parse(event['eventEndDate']);

        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);

        if (!day.isBefore(startDate) && !day.isAfter(endDate)) {
          dailyEvents.add(event);
        }
      }

      dailyEvents.sort((a, b) {
        final prioA = _priorityOrder[a['priority']] ?? 999;
        final prioB = _priorityOrder[b['priority']] ?? 999;
        if (prioA != prioB) return prioA.compareTo(prioB);

        final addedA = DateTime.tryParse(a['eventAddedDate'] ?? '');
        final addedB = DateTime.tryParse(b['eventAddedDate'] ?? '');
        return _compareNullableDates(addedA, addedB);
      });

      tempEventsByDate[day] = dailyEvents;
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

  String _formatDateRange(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${_formatDate(startDate)}';
    } else {
      return '${_formatDate(startDate)} to ${_formatDate(endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return '[${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}]';
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(time, style: const TextStyle(fontSize: 16)),
    );
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

        // Event detail overlay
        if (_selectedEvent != null)
          EventDetailOverlay(
            event: _selectedEvent!,
            onClose: () => setState(() => _selectedEvent = null),
          ),
      ],
    );
  }
}
