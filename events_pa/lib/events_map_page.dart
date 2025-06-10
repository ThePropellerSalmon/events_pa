import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class EventsMapPage extends StatefulWidget {
  final VoidCallback? onMapTap;
  final VoidCallback? onRequestClearMenu;
  const EventsMapPage({super.key, this.onMapTap, this.onRequestClearMenu});

  @override
  State<EventsMapPage> createState() => EventsMapPageState();
}

class EventsMapPageState extends State<EventsMapPage> {
  final TextEditingController _addressController = TextEditingController();
  LatLng? _searchedLocation;
  LatLng? _defaultPosition;

  String? _selectedMarkerId;

  void closePopup() {
    print('closePopup() called');
    setState(() {
      _selectedMarkerId = null;
    });
  }


  @override
  void initState() {
    super.initState();
    _loadDefaultPosition();
  }

  Future<void> _loadDefaultPosition() async {
    try {
      List<Location> locations =
          await locationFromAddress('Shippagan, New Brunswick, Canada');
      if (locations.isNotEmpty) {
        setState(() {
          _defaultPosition =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading default position: $e')),
      );
    }
  }

  Future<void> _searchAddress() async {
    try {
      List<Location> locations =
          await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _searchedLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding address: $e')),
      );
    }
  }

  void _onMarkerTap(String markerId) {
    
    print(_selectedMarkerId);
    widget.onRequestClearMenu?.call();

    print('Marker tapped: $markerId');
    setState(() {
      if (_selectedMarkerId == markerId) {
        print('Tapped same marker, closing popup');
        _selectedMarkerId = null;
      } else {
        print('Opening popup for marker $markerId');
        _selectedMarkerId = markerId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_defaultPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final markers = [
      {
        'id': 'default',
        'position': _defaultPosition!,
        'color': Colors.blue,
      },
      if (_searchedLocation != null)
        {
          'id': 'searched',
          'position': _searchedLocation!,
          'color': Colors.red,
        }
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Enter address...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchAddress,
                child: const Text('Search'),
              ),
            ],
          ),
        ),

        // DEBUG INFO BOX - show current popup status
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Debug: selectedMarkerId = ${_selectedMarkerId ?? "none"}\nPopup open = ${_selectedMarkerId != null}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _searchedLocation ?? _defaultPosition!,
              initialZoom: 12,
              minZoom: 6,
              maxZoom: 18,
              onTap: (_, __) {
                print('Map background tapped, close popup');
                widget.onMapTap?.call();
                closePopup();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: markers.map((marker) {
                  final isOpen = _selectedMarkerId == marker['id'];
                  return Marker(
                    width: 80,
                    height: isOpen ? 140 : 80,
                    point: marker['position'] as LatLng,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        print('Marker ${marker['id']} tapped');
                        _onMarkerTap(marker['id'] as String);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOpen)
                            GestureDetector(
                              onTap: () {
                                print('Popup content tapped - do nothing');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Event Details Here',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          Icon(Icons.location_pin,
                              color: marker['color'] as Color, size: 40),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
