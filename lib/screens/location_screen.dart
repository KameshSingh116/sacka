import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Renders the map
import 'package:latlong2/latlong.dart';      // Handles coordinates
import 'package:geolocator/geolocator.dart'; // Gets GPS
import '../services/location_service.dart';
import 'home_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();

  // 📍 CONFIGURATION: KOCHI TARGET
  final LatLng targetLocation = const LatLng(10.0492293, 76.3314411);
  final double allowedRadiusMeters = 5000; // 5 KM Zone

  LatLng? _userLocation;
  bool _isLoading = true;
  bool _isInsideZone = false;
  String _statusMessage = "Locating you...";
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      // 1. Get accurate GPS position
      Position position = await _locationService.getCurrentLocation();
      print("📍 MY CURRENT LOCATION: ${position.latitude}, ${position.longitude}"); // <--- ADD THIS
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      // 2. Calculate Distance
      double distance = const Distance().as(
          LengthUnit.Meter,
          userLatLng,
          targetLocation
      );

      // 3. Determine if inside/outside
      setState(() {
        _userLocation = userLatLng;
        _isLoading = false;

        if (distance <= allowedRadiusMeters) {
          _isInsideZone = true;
          _statusMessage = "✅ Valid! You are inside the zone.";
        } else {
          _isInsideZone = false;
          _statusMessage = "❌ Outside Zone (${(distance/1000).toStringAsFixed(1)}km away)";
        }
      });

      // Move map to show both points
      if (_userLocation != null) {
        _mapController.move(_userLocation!, 13);
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: ${e.toString()}";
      });
    }
  }

  void _enterApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // -------------------------------------------
          // 1. THE MAP LAYER (Background)
          // -------------------------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: targetLocation, // Start at Community Center
              initialZoom: 13.0,
            ),
            children: [
              // A. The Map Tiles (OpenStreetMap Style)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.shaca',
              ),

              // B. The "Allowed Zone" Circle (Blue)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: targetLocation,
                    color: Colors.blue.withOpacity(0.2), // Light Blue fill
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                    useRadiusInMeter: true,
                    radius: allowedRadiusMeters, // 5000 meters
                  ),
                ],
              ),

              // C. The User's Marker (Red Pin)
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // -------------------------------------------
          // 2. THE STATUS CARD (Overlay at Bottom)
          // -------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(
                    _isLoading ? Icons.radar : (_isInsideZone ? Icons.check_circle : Icons.cancel),
                    color: _isLoading ? Colors.blue : (_isInsideZone ? Colors.green : Colors.red),
                    size: 40,
                  ),
                  const SizedBox(height: 10),

                  // Text
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Button (Only enabled if success)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isInsideZone && !_isLoading) ? _enterApp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isInsideZone ? const Color(0xFFFF8C00) : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Enter ShaCa"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}