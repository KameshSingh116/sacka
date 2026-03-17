import 'package:flutter/material.dart';

class SkeletonToolCard extends StatelessWidget {
  const SkeletonToolCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 120,
            color: Colors.grey.shade300,
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: double.infinity),
                const SizedBox(height: 8),
                _bar(width: 80),
                const SizedBox(height: 12),
                _bar(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
