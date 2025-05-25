import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class EventsMapPage extends StatefulWidget {
  const EventsMapPage({super.key});

  @override
  State<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends State<EventsMapPage> {
  final TextEditingController _addressController = TextEditingController();
  LatLng? _searchedLocation;
  LatLng? _defaultPosition;

  @override
  void initState() {
    super.initState();
    _loadDefaultPosition();
  }

  Future<void> _loadDefaultPosition() async {
    try {
      List<Location> locations = await locationFromAddress('Shippagan, New Brunswick, Canada');
      if (locations.isNotEmpty) {
        setState(() {
          _defaultPosition = LatLng(locations.first.latitude, locations.first.longitude);
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
      List<Location> locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        setState(() {
          _searchedLocation = LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding address: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_defaultPosition == null) {
      // While loading, show a simple spinner
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Events Map')),
      body: Column(
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
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _searchedLocation ?? _defaultPosition!,
                initialZoom: 12,
                minZoom: 2,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    if (_searchedLocation != null)
                      Marker(
                        width: 80,
                        height: 80,
                        point: _searchedLocation!,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      )
                    else
                      Marker(
                        width: 80,
                        height: 80,
                        point: _defaultPosition!,
                        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
