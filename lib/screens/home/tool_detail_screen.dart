import 'package:flutter/material.dart';
import '../../models/tool_model.dart';

class ToolDetailScreen extends StatelessWidget {
  final Tool tool;

  const ToolDetailScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tool.name),
      ),
      body: Column(
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

          // 📄 DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.category,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${tool.pricePerDay} per day',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Well-maintained tool available for rent within your society. '
                        'Easy pickup, flexible usage, and trusted neighbourhood sharing.',
                  ),
                  const Spacer(),

                  // 🔘 RENT CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Rent Now'),
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
