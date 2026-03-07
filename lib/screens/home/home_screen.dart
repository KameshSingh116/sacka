import '../society/society_radius_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../profile/profile_screen.dart';
import '../../models/tool_model.dart';
import '../../widgets/tool_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/animated_page.dart';
import '../../widgets/skeleton_tool_card.dart';
import '../inventory/add_item_screen.dart';
import '../society/join_node_screen.dart';
import '../cart/cart_screen.dart';
import '../../services/cart_service.dart';

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
          title: const Text('ShaCa', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.dark_mode_outlined),
              onPressed: widget.onToggleTheme,
            ),
            // 👥 Community Node
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SocietyRadiusScreen(),
                  ),
                );
              },
            ),
            // 🛒 CART ICON WITH BADGE
            Consumer<CartService>(
              builder: (context, cart, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartScreen(onToggleTheme: widget.onToggleTheme),
                          ),
                        );
                      },
                    ),
                    if (cart.items.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(onToggleTheme: widget.onToggleTheme),
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
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
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
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (_, __) =>
                const SkeletonToolCard(),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
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
