import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'custom_widgets/image_upload.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _manualDatesSelected = true;
  List<File> _uploadedImages = [];
  List<Map<String, dynamic>> _manualDates = [];

  void _handleImageChange(List<File> images) {
    setState(() {
      _uploadedImages = images;
    });
  }

  Future<void> _pickManualDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (endTime == null) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _manualDates.add({
        'date': selectedDate,
        'startTime': startTime,
        'endTime': endTime,
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final label = _labelController.text.trim();
      final street = _streetController.text.trim();
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      final images = _uploadedImages;

      try {
        final supabase = Supabase.instance.client;

        final eventInsert =
            await supabase
                .from('events')
                .insert({
                  'title': title,
                  'description': description,
                  'label': label,
                  'street': street,
                  'city': city,
                  'postal_code': postalCode,
                  'image_count': images.length,
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select('eventId')
                .single();

        final eventId = eventInsert['eventId'];

        if (_manualDatesSelected) {
          for (final slot in _manualDates) {
            final date = slot['date'] as DateTime;
            final start = slot['startTime'] as TimeOfDay;
            final end = slot['endTime'] as TimeOfDay;

            final eventStart = DateTime(
              date.year,
              date.month,
              date.day,
              start.hour,
              start.minute,
            );
            final eventEnd = DateTime(
              date.year,
              date.month,
              date.day,
              end.hour,
              end.minute,
            );

            await supabase.from('eventsDates').insert({
              'eventId': eventId,
              'eventStartDate': eventStart.toIso8601String(),
              'eventEndDate': eventEnd.toIso8601String(),
            });
          }
        }

        setState(() {
          _uploadedImages.clear();
          _manualDates.clear();
          _formKey.currentState!.reset();
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event submitted successfully!')),
        );
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        flexibleSpace: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Go to Map'),
                onPressed: () => context.push('/events_map'),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 1000,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label for address *',
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Street *'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City *'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code * (e.g. E1T 2W2)',
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(7),
                    _CanadianPostalCodeFormatter(),
                  ],
                  validator: (value) {
                    final regex = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d\$');
                    if (value == null || value.isEmpty) return 'Required';
                    if (!regex.hasMatch(value)) return 'Invalid postal code';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Upload up to 3 images (max 5MB each):'),
                const SizedBox(height: 8),
                ImageUploadWidget(
                  initialImages: _uploadedImages,
                  onImagesChanged: _handleImageChange,
                ),
                const SizedBox(height: 32),
                const Text('Date Options:', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Manual Dates'),
                        value: true,
                        groupValue: _manualDatesSelected,
                        onChanged:
                            (val) =>
                                setState(() => _manualDatesSelected = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Recurring Schedule'),
                        value: false,
                        groupValue: _manualDatesSelected,
                        onChanged:
                            (val) =>
                                setState(() => _manualDatesSelected = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _manualDatesSelected
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickManualDate,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Add Time Slot'),
                        ),
                        const SizedBox(height: 12),
                        if (_manualDates.isEmpty)
                          const Text('No time slots added yet.'),
                        ..._manualDates.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final date = item['date'] as DateTime;
                          final start = item['startTime'] as TimeOfDay;
                          final end = item['endTime'] as TimeOfDay;

                          return ListTile(
                            title: Text(
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} | ${start.format(context)} - ${end.format(context)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () =>
                                      setState(() => _manualDates.removeAt(i)),
                            ),
                          );
                        }),
                      ],
                    )
                    : const Placeholder(fallbackHeight: 100),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CanadianPostalCodeFormatter extends TextInputFormatter {
  static final _letterRegex = RegExp(r'[A-Za-z]');
  static final _digitRegex = RegExp(r'\d');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newTextRaw = newValue.text.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();

    for (int i = 0; i < newTextRaw.length && buffer.length < 6; i++) {
      final pos = buffer.length;
      final char = newTextRaw[i];
      bool isValid =
          (pos == 0 || pos == 2 || pos == 4) && _letterRegex.hasMatch(char) ||
          (pos == 1 || pos == 3 || pos == 5) && _digitRegex.hasMatch(char);
      if (isValid) buffer.write(char);
    }

    String formatted = buffer.toString();
    if (formatted.length > 3) {
      formatted = formatted.substring(0, 3) + ' ' + formatted.substring(3);
    }

    int cursorPos = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}
