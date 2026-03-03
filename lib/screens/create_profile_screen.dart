import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import 'home_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  bool _isLocating = false;

  // 📍 NEW: Stores the exact coordinates of the Pin they dropped on the map!
  LatLng? _pinnedLocation;

  // 🗺️ NEW: Opens the Full-Screen Map
  Future<void> _openMapPicker() async {
    setState(() => _isLocating = true);

    try {
      // Get live location so the map starts zoomed in on their actual city
      Position livePos = await _locationService.getCurrentLocation();

      if (!mounted) return;

      // Open the MapScreen and wait for them to hit "Confirm"
      final LatLng? selectedLocation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            initialLocation: LatLng(livePos.latitude, livePos.longitude),
          ),
        ),
      );

      // Save the pin they dropped!
      if (selectedLocation != null) {
        setState(() {
          _pinnedLocation = selectedLocation;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinnedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pin your home location on the map!"), backgroundColor: Colors.red),
      );
      return;
    }

    // ---------------------------------------------------------
    // 🛑 NEW: EXPLICIT CONSENT DIALOG
    // ---------------------------------------------------------
    bool? userConsented = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFFFF8C00)),
            SizedBox(width: 10),
            Text("Verify Location"),
          ],
        ),
        content: const Text(
          "ShaCa will now check your live GPS to see if you are currently standing at your pinned Home Base.\n\nThis ensures our community stays secure.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // User clicked Cancel
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // User clicked Agree
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
            ),
            child: const Text("Check My Location"),
          ),
        ],
      ),
    );

    // If they clicked Cancel or tapped outside the box, stop here.
    if (userConsented != true) return;

    // ---------------------------------------------------------
    // ✅ THEY AGREED! NOW WE DO THE LOCATION MATH
    // ---------------------------------------------------------
    setState(() => _isLoading = true);

    try {
      // 1. Get Live Phone Location (Now with their explicit permission!)
      Position livePosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // 2. The 100-Meter Math!
      double distanceInMeters = Geolocator.distanceBetween(
        _pinnedLocation!.latitude,
        _pinnedLocation!.longitude,
        livePosition.latitude,
        livePosition.longitude,
      );

      // 3. Determine Status
      String accountStatus = (distanceInMeters <= 100) ? 'verified' : 'guest';

      // 4. Save to Firebase
      await _dbService.saveUserProfile(
        name: _nameController.text.trim(),
        tower: _towerController.text.trim(),
        flatNo: _flatController.text.trim(),
        latitude: _pinnedLocation!.latitude,
        longitude: _pinnedLocation!.longitude,
        status: accountStatus,
      );

      if (!mounted) return;

      // 5. Show Smart Success Message
      if (accountStatus == 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile Verified! Welcome Home."), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Saved in Guest Mode. Open app at home to verify!"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // 6. Go to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool locationLocked = _pinnedLocation != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.maps_home_work_rounded, size: 80, color: Color(0xFFFF8C00)),
              const SizedBox(height: 20),

              Text("Welcome to ShaCa!", textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text("Let's anchor you to your neighborhood.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _towerController,
                      decoration: const InputDecoration(labelText: "Tower / Block", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _flatController,
                      decoration: const InputDecoration(labelText: "Flat No.", border: OutlineInputBorder(), prefixIcon: Icon(Icons.door_front_door)),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 📍 THE NEW MAP LAUNCHER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: locationLocked ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: locationLocked ? Colors.green : Colors.grey.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(locationLocked ? Icons.check_circle : Icons.map_rounded, color: locationLocked ? Colors.green : Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      locationLocked ? "Home Base Pinned!" : "Set Your Home Base",
                      style: TextStyle(fontWeight: FontWeight.bold, color: locationLocked ? Colors.green : Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locationLocked
                          ? "We will verify if you are currently inside this building."
                          : "Drop a pin on the map to claim your neighborhood.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    if (!locationLocked)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLocating ? null : _openMapPicker,
                          icon: _isLocating
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.pin_drop),
                          label: Text(_isLocating ? "Loading Map..." : "Open Map"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !locationLocked) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Profile & Verify"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 🗺️ FULL SCREEN MAP PICKER WIDGET (Built right into the same file!)
// =========================================================================
class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drag map to your house")),
      body: Stack(
        children: [
          // 1. The OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 16.0,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  setState(() => _currentCenter = position.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yourcompany.shaca',
              ),
            ],
          ),

          // 2. The Red Pin (Stays perfectly centered while they drag the map)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),

          // 3. Confirm Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _currentCenter); // Sends the pin back!
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Confirm Home Base", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}