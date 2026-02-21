import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get Current Location (Auto-detect)
      Position position = await _locationService.getCurrentLocation();

      // 2. Save to Firebase
      await _dbService.saveUserProfile(
        name: _nameController.text.trim(),
        tower: _towerController.text.trim(),
        flatNo: _flatController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 3. Success! Go Home
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile Created Successfully!")),
      );

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
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_pin_circle_rounded, size: 80, color: Color(0xFFFF8C00)),
              const SizedBox(height: 20),

              Text(
                "Welcome to ShaCa!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                "Let's get you set up.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // NAME INPUT
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 16),

              // TOWER & FLAT ROW
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _towerController,
                      decoration: const InputDecoration(
                        labelText: "Tower / Block",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _flatController,
                      decoration: const InputDecoration(
                        labelText: "Flat No.",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.door_front_door),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // SAVE BUTTON
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50), // Slate Grey
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Profile & Location"),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "We will use your current location to verify you are inside the community.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}