import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetailOverlay extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onClose;

  const EventDetailOverlay({
    super.key,
    required this.event,
    required this.onClose,
  });

  @override
  State<EventDetailOverlay> createState() => _EventDetailOverlayState();
}

class _EventDetailOverlayState extends State<EventDetailOverlay> {
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadEventImages();
  }

  Future<void> _loadEventImages() async {
    final eventId = widget.event['eventId'];
    if (eventId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('eventsImages')
          .select('path')
          .eq('eventId', eventId);

      final paths = (response as List).cast<Map<String, dynamic>>();
      final urls =
          paths.map((row) {
            final path = row['path'];
            final publicUrl = Supabase.instance.client.storage
                .from('events')
                .getPublicUrl(path);

            return publicUrl; // this is a string now
          }).toList();

      setState(() {
        _imageUrls = urls;
      });
    } catch (e) {
      debugPrint('Error loading event images: $e');
    }
  }

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
        (widget.event['eventTimeSlots'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

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
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onClose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.event['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (widget.event['eventAddress'] != null)
                    Text(
                      widget.event['eventAddress'],
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),

                  const SizedBox(height: 10),

                  if (widget.event['description'] != null)
                    Text(
                      widget.event['description'],
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
                  }),

                  if (_imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    // const Text(
                    //   'Images',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          _imageUrls.map((url) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
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
