import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'join_node_screen.dart';
import 'tool_detail_screen.dart';
import 'login_screen.dart';
import 'owner_dashboard_screen.dart';

class KHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const KHomeScreen({super.key, required this.onToggleTheme});

  @override
  State<KHomeScreen> createState() => _KHomeScreenState();
}

class _KHomeScreenState extends State<KHomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Drills', 'Ladders', 'Gardening', 'Electrical'];

  Future<Position>? _locationFuture;
  bool _isSettingHome = false;

  @override
  void initState() {
    super.initState();
    _locationFuture = Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    // 1. Grab where the phone is physically located right now
    Position currentPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final user = FirebaseAuth.instance.currentUser;

    // 2. GUEST FLOW: Just update the local feed, don't save anything!
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location updated! Showing tools near you."), backgroundColor: Colors.blue)
        );
      }
      return;
    }

    // 3. LOGGED-IN MEMBER FLOW: The Security Cross-Check
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;

        if (data.containsKey('homeLat') && data.containsKey('homeLng')) {
          double dbLat = data['homeLat'];
          double dbLng = data['homeLng'];

          double distanceInMeters = Geolocator.distanceBetween(
              currentPos.latitude, currentPos.longitude, dbLat, dbLng
          );

          if (!mounted) return;

          if (distanceInMeters <= 500) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Home verified! You are within 500m."), backgroundColor: Colors.green)
            );
          } else {
            // 🚀 CHANGED: No longer says renting is disabled!
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You are away from home. Remote booking enabled!"), backgroundColor: Colors.orange)
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please set your Home Location first!"), backgroundColor: Colors.orange)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to verify location cross-check."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _setHomeToCurrentLocation() async {
    setState(() => _isSettingHome = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _showToast("GPS permission is required to set your home base.");
          setState(() => _isSettingHome = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'homeLat': position.latitude,
        'homeLng': position.longitude,
      }, SetOptions(merge: true));

      _showToast("Home base locked in successfully!");
    } catch (e) {
      _showToast("Failed to get location. Make sure your GPS is turned on.");
    } finally {
      if (mounted) setState(() => _isSettingHome = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎧 Wrap the entire Scaffold in a StreamBuilder for real-time auth updates
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          return Scaffold(
            appBar: AppBar(
              title: const Text('ShaCa Community', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                if (user != null)
                  IconButton(
                      icon: const Icon(Icons.inbox),
                      tooltip: 'Incoming Requests',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OwnerDashboardScreen())
                        );
                      }
                  ),
                if (user != null)
                  IconButton(icon: const Icon(Icons.my_location), tooltip: 'Refresh GPS', onPressed: _refreshLocation),
                IconButton(icon: const Icon(Icons.brightness_6), onPressed: widget.onToggleTheme),
              ],
            ),
            body: Column(
              children: [
                // --- CATEGORY FILTER BAR ---
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = category);
                          },
                          selectedColor: const Color(0xFFFF8C00),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        ),
                      );
                    },
                  ),
                ),

                // --- DYNAMIC CONTENT AREA ---
                Expanded(child: _buildMainContent(user)),
              ],
            ),
          );
        }
    );
  }

  Widget _buildMainContent(User? user) {
    // 🛑 1. GUEST VIEW
    if (user == null) {
      return Column(
        children: [
          _buildInfoBanner("Browsing as Guest. Log in to rent tools nearby.", Icons.lock_open, "Log In", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          }),
          Expanded(child: _fetchAndBuildToolGrid(null)),
        ],
      );
    }

    // 🎧 Listen to User Profile for Home Coordinates and Society Code
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final homeLat = userData?['homeLat'];
        final homeLng = userData?['homeLng'];
        final societyCode = userData?['societyCode'] ?? '';

        // 🛑 2. HAS NO HOME LOCATION
        if (homeLat == null || homeLng == null) {
          return Column(
            children: [
              _isSettingHome
                  ? const LinearProgressIndicator(color: Color(0xFFFF8C00))
                  : _buildInfoBanner("You must be at home to lock your location.", Icons.add_location_alt, "Lock Location", _setHomeToCurrentLocation),
              Expanded(child: _fetchAndBuildToolGrid(null)),
            ],
          );
        }

        // 🛑 3. HAS HOME, BUT NO SOCIETY CODE
        if (societyCode.isEmpty) {
          return Column(
            children: [
              _buildInfoBanner(
                  "Join the community to unlock renting and lending nearby.",
                  Icons.people_outline,
                  "Join Community",
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinNodeScreen()))
              ),
              Expanded(child: _fetchAndBuildToolGrid(null)),
            ],
          );
        }

        // 🛰️ ALL DATA EXISTS: Check their physical GPS location!
        return FutureBuilder<Position>(
          future: _locationFuture,
          builder: (context, locSnapshot) {
            if (locSnapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const LinearProgressIndicator(color: Color(0xFFFF8C00)),
                  Expanded(child: _fetchAndBuildToolGrid(societyCode)),
                ],
              );
            }

            if (locSnapshot.hasError) {
              return Column(
                children: [
                  _buildInfoBanner("GPS Error. We cannot verify your location.", Icons.gps_off, "Retry", _refreshLocation),
                  Expanded(child: _fetchAndBuildToolGrid(societyCode)),
                ],
              );
            }

            final currentPos = locSnapshot.data!;
            double distanceInMeters = Geolocator.distanceBetween(
                currentPos.latitude, currentPos.longitude, homeLat, homeLng
            );

            // 🛑 4. AWAY FROM HOME (> 500 meters)
            if (distanceInMeters > 500) {
              return Column(
                children: [
                  // 🚀 CHANGED: Removed "Renting is disabled". Now it just reminds them handovers are local.
                  _buildInfoBanner("You are away from home. Handovers must happen at the society.", Icons.directions_car, "Refresh GPS", _refreshLocation),
                  Expanded(child: _fetchAndBuildToolGrid(societyCode)), // Grid is now fully interactive!
                ],
              );
            }

            // ✅ 5. FULLY VERIFIED & AT HOME!
            return _fetchAndBuildToolGrid(societyCode);
          },
        );
      },
    );
  }

  Widget _fetchAndBuildToolGrid(String? societyFilter) {
    // 🚀 Show everything! The calendar will handle the dates.
    Query query = FirebaseFirestore.instance.collection('tools');

    if (societyFilter != null && societyFilter.isNotEmpty) {
      query = query.where('societyCode', isEqualTo: societyFilter);
    }

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, toolSnapshot) {
        if (toolSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!toolSnapshot.hasData || toolSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text("No tools found", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        final tools = toolSnapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final toolDoc = tools[index];
            final toolData = toolDoc.data() as Map<String, dynamic>;
            return _buildToolCard(toolDoc.id, toolData);
          },
        );
      },
    );
  }

  Widget _buildToolCard(String toolId, Map<String, dynamic> tool) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolDetailScreen(
              toolId: toolId,
              toolData: tool,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      tool['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(tool['category'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFFFF8C00),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('₹${tool['pricePerDay']}/day',
                          style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),

            // 🛑 THE STATUS BADGE: Checks if it's currently with a borrower right now
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rentals')
                  .where('toolId', isEqualTo: toolId)
                  .where('status', isEqualTo: 'Active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  DateTime now = DateTime.now();
                  bool isCurrentlyBusy = snapshot.data!.docs.any((doc) {
                    DateTime start = (doc['startDate'] as Timestamp).toDate();
                    DateTime end = (doc['endDate'] as Timestamp).toDate();
                    return now.isAfter(start.subtract(const Duration(days: 1))) &&
                        now.isBefore(end.add(const Duration(days: 1)));
                  });

                  if (isCurrentlyBusy) {
                    return Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "RENTED",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text, IconData icon, String buttonText, VoidCallback onPressed) {
    return Container(
      color: const Color(0xFFFF8C00).withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C00)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPressed,
            child: Text(buttonText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}