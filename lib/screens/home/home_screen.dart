import '../society/society_radius_screen.dart';
import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../../models/tool_model.dart';
import '../../widgets/tool_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/animated_page.dart';
import '../../widgets/skeleton_tool_card.dart';
import '../inventory/add_item_screen.dart';
import '../society/join_node_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  bool isLoading = true;

  final TextEditingController _searchController =
  TextEditingController();

  final categories = [
    'All',
    'Drills',
    'Ladders',
    'Gardening',
    'Electrical',
  ];

  final tools = [
    Tool(
      name: 'Bosch Drill',
      category: 'Drills',
      pricePerDay: 120,
      imageAsset: 'assets/images/drill.jpg',
    ),
    Tool(
      name: 'Foldable Ladder',
      category: 'Ladders',
      pricePerDay: 80,
      imageAsset: 'assets/images/ladder.jpg',
    ),
    Tool(
      name: 'Garden Tool Set',
      category: 'Gardening',
      pricePerDay: 60,
      imageAsset: 'assets/images/garderning.jpg',
    ),
    Tool(
      name: 'Electrical Toolkit',
      category: 'Electrical',
      pricePerDay: 90,
      imageAsset: 'assets/images/electrical.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // ⏳ Simulate API loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = tools.where((tool) {
      final matchesCategory =
          selectedCategory == 'All' ||
              tool.category == selectedCategory;

      final matchesSearch = tool.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase()) ||
          tool.category
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return AnimatedPage(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ShaCa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.groups),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SocietyRadiusScreen(),
                  ),
                );
              },
            ),


          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddItemScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            // 🔍 SEARCH
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() {
                    searchQuery = v;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),

            // 🏷️ CATEGORIES
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                children: categories
                    .map(
                      (c) => CategoryChip(
                    label: c,
                    selected: selectedCategory == c,
                    onTap: () {
                      setState(() {
                        selectedCategory = c;
                      });
                    },
                  ),
                )
                    .toList(),
              ),
            ),

            // 🦴 SKELETON OR GRID
            Expanded(
              child: isLoading
                  ? GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
                itemBuilder: (_, __) =>
                const SkeletonToolCard(),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return ToolCard(
                    tool: filtered[index],
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
