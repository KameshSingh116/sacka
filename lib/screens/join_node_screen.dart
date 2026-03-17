import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinNodeScreen extends StatefulWidget {
  const JoinNodeScreen({super.key});

  @override
  State<JoinNodeScreen> createState() => _JoinNodeScreenState();
}

class _JoinNodeScreenState extends State<JoinNodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  // ----------------------------------------------------------------
  // 1. JOIN EXISTING SOCIETY (The 5km Geofence Check)
  // ----------------------------------------------------------------
  Future<void> _verifyAndJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage("Please enter a society code.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      DocumentSnapshot societyDoc = await FirebaseFirestore.instance.collection('societies').doc(code).get();

      if (!societyDoc.exists) {
        _showMessage("Invalid Society Code. Please check and try again.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final data = societyDoc.data() as Map<String, dynamic>;
      double distanceInMeters = Geolocator.distanceBetween(
          userPos.latitude, userPos.longitude, data['latitude'], data['longitude']
      );

      if (distanceInMeters <= 5000) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'societyCode': code,
          'societyName': data['name'],
          'isVerified': true,
        }, SetOptions(merge: true));

        _showMessage("Successfully joined ${data['name']}!", Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        _showMessage("You are ${(distanceInMeters / 1000).toStringAsFixed(1)}km away. You must be within 5km.", Colors.red);
      }
    } catch (e) {
      _showMessage("Error verifying location. Ensure GPS is on.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------------
  // 2. CREATE A NEW SOCIETY (Automatically grabs your GPS!)
  // ----------------------------------------------------------------
  // ----------------------------------------------------------------
  // 2. CREATE A NEW SOCIETY (With Duplicate Protection)
  // ----------------------------------------------------------------
  // ----------------------------------------------------------------
  // 2. CREATE A NEW SOCIETY (With Strict Duplicate Protection)
  // ----------------------------------------------------------------
  // ----------------------------------------------------------------
  // 2. CREATE A NEW SOCIETY (With Geographic & Name Overlap Protection)
  // ----------------------------------------------------------------
  Future<void> _createNewSociety() async {
    setState(() => _isLoading = true);

    try {
      // 📍 1. Grab their GPS Location FIRST
      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }
      Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 🛑 2. NEW: GEO-FENCE CHECK! Are they already standing in an existing society?
      QuerySnapshot allSocieties = await FirebaseFirestore.instance.collection('societies').get();

      bool societyNearby = false;
      String nearbySocietyName = "";
      String nearbySocietyCode = "";

      for (var doc in allSocieties.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          double dist = Geolocator.distanceBetween(
              userPos.latitude, userPos.longitude,
              data['latitude'], data['longitude']
          );

          // Check if there is already a society within 1000 meters (1km)
          if (dist <= 1000) {
            societyNearby = true;
            nearbySocietyName = data['name'];
            nearbySocietyCode = doc.id;
            break; // Stop looking, we found one!
          }
        }
      }

      // If they are standing in an existing society zone, stop them!
      if (societyNearby) {
        if (!mounted) return;
        _showMessage("Society '$nearbySocietyName' already exists here! We've entered the code for you to join.", Colors.orange);
        setState(() {
          _codeController.text = nearbySocietyCode;
        });
        return; // 🛑 Stop the rest of the function!
      }

      // ✅ 3. If the area is clear, NOW we ask them for a name
      if (!mounted) return;
      final TextEditingController nameController = TextEditingController();
      String? societyName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Register New Society'),
          content: TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: "e.g., Greenvale Apartments"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (societyName == null || societyName.isEmpty) return;

      // 🛑 4. Strict Duplicate Name Check
      var existingSocietyNameCheck = await FirebaseFirestore.instance
          .collection('societies')
          .where('name', isEqualTo: societyName)
          .get();

      if (existingSocietyNameCheck.docs.isNotEmpty) {
        _showMessage("This society name is already registered somewhere else! Please pick a unique name.", Colors.red);
        return;
      }

      // 5. Generate Code & Save to Firebase
      String prefix = societyName.replaceAll(' ', '').toUpperCase();
      if (prefix.length > 4) prefix = prefix.substring(0, 4);
      String newCode = "$prefix-${Random().nextInt(9000) + 1000}";

      await FirebaseFirestore.instance.collection('societies').doc(newCode).set({
        'name': societyName,
        'latitude': userPos.latitude,
        'longitude': userPos.longitude,
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
      });

      _showMessage("Created $societyName! Your code is $newCode", Colors.green);

      setState(() {
        _codeController.text = newCode;
      });

    } catch (e) {
      _showMessage("Failed to create society: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Helper for GPS Permissions
  Future<LocationPermission> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showMessage("GPS permission is required.", Colors.red);
      }
    }
    return permission;
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Society Node')),
      // 🛠️ FIX: Wrapped the body in a Center and SingleChildScrollView!
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 80, color: Color(0xFFFF8C00)),
              const SizedBox(height: 24),
              const Text(
                "Enter your Society Code to unlock renting and lending.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Society Code (e.g., GREEN-1234)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                  onPressed: _isLoading ? null : _verifyAndJoin,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Location & Join', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading ? null : _createNewSociety,
                child: const Text("Don't see your society? Register it here.", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}