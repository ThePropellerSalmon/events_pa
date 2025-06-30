import 'package:flutter/material.dart';

class EventDetailOverlay extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onClose;

  const EventDetailOverlay({
    super.key,
    required this.event,
    required this.onClose,
  });

  String _formatDateRange(String start, String end) {
    final startDate = DateTime.parse(start);
    final endDate = DateTime.parse(end);

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return _formatDate(startDate);
    } else {
      return '${_formatDate(startDate)} to ${_formatDate(endDate)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(event['eventStartDate']);
    final end = DateTime.parse(event['eventEndDate']);

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

                  // Address
                  if (event['eventAddress'] != null)
                    Text(
                      event['eventAddress'],
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),

                  const SizedBox(height: 10),

                  // Description
                  if (event['description'] != null) Text(event['description']),

                  const SizedBox(height: 20),

                  // Date range
                  Text(
                    _formatDateRange(
                      event['eventStartDate'],
                      event['eventEndDate'],
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  // Time boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeBox(_formatTime(start)),
                      const Text('-'),
                      _buildTimeBox(_formatTime(end)),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(time, style: const TextStyle(fontSize: 16)),
    );
  }
}
