import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../screens/tool_detail_screen.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final int index;

  const ToolCard({
    super.key,
    required this.tool,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ToolDetailScreen(tool: tool),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3, // 🛠️ Adds a subtle shadow to pop off the background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 🛠️ Stretches image to card edges
                  children: [
                    // 🖼️ IMAGE AREA: Now uses Expanded!
                    Expanded(
                      child: Hero(
                        tag: tool.imageAsset,
                        child: Image.asset(
                          tool.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    // 📄 CONTENT AREA: Takes only the space it naturally needs at the bottom.
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 🛠️ Prevents text area from expanding vertically
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1, // 🛠️ Overflow protection
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tool.category,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1, // 🛠️ Overflow protection
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${tool.pricePerDay}/hr',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                            maxLines: 1, // 🛠️ Overflow protection
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}