import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  final _client = Supabase.instance.client;

  List<List<Map<String, dynamic>>> _eventsByDay = [[], [], []];
  bool _loading = true;

  final Map<String, int> _priorityOrder = {'A': 0, 'B': 1, 'C': 2, 'D': 3};

  @override
  void initState() {
    super.initState();
    _fetchAllEvents();
  }

  Future<void> _fetchAllEvents() async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfAfterTomorrow = startOfToday
        .add(const Duration(days: 3))
        .subtract(const Duration(seconds: 1));
    final dateRange = List.generate(
      3,
      (i) => startOfToday.add(Duration(days: i)),
    );

    // Fetch all users with their subscriptionDate
    final usersRes = await _client
        .from('users')
        .select('userId, subscriptionDate');
    final users = (usersRes as List).cast<Map<String, dynamic>>();

    final userSubscriptionMap = {
      for (var u in users)
        u['userId']: _parseNullableDate(u['subscriptionDate']),
    };

    final eventsRes = await _client
        .from('events')
        .select()
        .lte(
          'eventStartDate',
          endOfAfterTomorrow.toIso8601String(),
        ) // Starts on or before 2 days later at 23:59:59
        .gte(
          'eventEndDate',
          startOfToday.toIso8601String(),
        ); // Ends on or after today at 00:00:00

    final events = (eventsRes as List).cast<Map<String, dynamic>>();

    List<List<Map<String, dynamic>>> tempEventsByDay = [[], [], []];

    for (int i = 0; i < 3; i++) {
      final currentDay = dateRange[i];
      final dailyEvents = <Map<String, dynamic>>[];

      for (var event in events) {
        final start = DateTime.parse(event['eventStartDate']);
        final end = DateTime.parse(event['eventEndDate']);

        if (!currentDay.isBefore(start) && !currentDay.isAfter(end)) {
          dailyEvents.add(event);
        }
      }

      dailyEvents.sort((a, b) {
        final prioA = _priorityOrder[a['priority']] ?? 999;
        final prioB = _priorityOrder[b['priority']] ?? 999;
        if (prioA != prioB) return prioA.compareTo(prioB);

        final startA = DateTime.parse(a['eventStartDate']);
        final startB = DateTime.parse(b['eventStartDate']);
        if (startA != startB) return startA.compareTo(startB);

        final subA = userSubscriptionMap[a['userId']];
        final subB = userSubscriptionMap[b['userId']];
        return _compareNullableDates(subA, subB);
      });

      tempEventsByDay[i] = dailyEvents;
    }

    setState(() {
      _eventsByDay = tempEventsByDay;
      _loading = false;
    });
  }

  DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // null is "latest"
    if (b == null) return -1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final labels = List.generate(3, (i) {
      final date = DateTime.now().add(Duration(days: i));
      return i == 0 ? 'Today' : '${date.month}/${date.day}';
    });

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  labels
                      .map(
                        (label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: List.generate(3, (i) {
                  final events = _eventsByDay[i];
                  return Expanded(
                    child: ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          margin: const EdgeInsets.all(6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${event['title'] ?? 'No Title'}'),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        );
  }
}
