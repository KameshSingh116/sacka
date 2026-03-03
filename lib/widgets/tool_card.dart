import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../screens/home/tool_detail_screen.dart';

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
                    builder: (_) =>
                        ToolDetailScreen(tool: tool),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ HERO IMAGE
                    Hero(
                      tag: tool.imageAsset,
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: Image.asset(
                          tool.imageAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // 📄 CONTENT
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(tool.category),
                          const SizedBox(height: 8),
                          Text(
                            '₹${tool.pricePerDay}/hour',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
