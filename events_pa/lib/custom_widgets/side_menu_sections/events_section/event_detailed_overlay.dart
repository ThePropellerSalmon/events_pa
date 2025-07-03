import 'package:flutter/material.dart';

class EventDetailOverlay extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onClose;

  const EventDetailOverlay({
    super.key,
    required this.event,
    required this.onClose,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> timeSlots =
        (event['eventTimeSlots'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Sort by start time
    timeSlots.sort((a, b) {
      final startA =
          DateTime.tryParse(a['eventStartDate'] ?? '') ?? DateTime(2000);
      final startB =
          DateTime.tryParse(b['eventStartDate'] ?? '') ?? DateTime(2000);
      return startA.compareTo(startB);
    });

    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back arrow
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: onClose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (event['eventAddress'] != null)
                    Text(
                      event['eventAddress'],
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),

                  const SizedBox(height: 10),

                  if (event['description'] != null)
                    Text(
                      event['description'],
                      style: const TextStyle(fontSize: 16),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'Date & Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  ...timeSlots.map((slot) {
                    final start = DateTime.tryParse(
                      slot['eventStartDate'] ?? '',
                    );
                    final end = DateTime.tryParse(slot['eventEndDate'] ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(_formatDate(start ?? DateTime(2000))),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildTimeBox(_formatTime(start)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('-'),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildTimeBox(_formatTime(end)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(time, style: const TextStyle(fontSize: 13)),
    );
  }
}
