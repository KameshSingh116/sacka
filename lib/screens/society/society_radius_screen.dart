import 'package:flutter/material.dart';
import 'join_node_screen.dart';

class SocietyRadiusScreen extends StatelessWidget {
  const SocietyRadiusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Node'),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🌐 Radius circle
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
              ),
            ),

            // 🏠 Your society (center)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                Theme.of(context).colorScheme.primary,
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 32,
              ),
            ),

            // 👤 Neighbour nodes (clickable)
            _node(
              context,
              offset: const Offset(0, -110),
            ),
            _node(
              context,
              offset: const Offset(100, 40),
            ),
            _node(
              context,
              offset: const Offset(-100, 40),
            ),
            _node(
              context,
              offset: const Offset(60, -80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _node(BuildContext context,
      {required Offset offset}) {
    return Transform.translate(
      offset: offset,
      child: GestureDetector(
        onTap: () {
          // 🔐 Prompt to join via society code
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const JoinNodeScreen(),
            ),
          );
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade400,
          ),
          child: const Icon(
            Icons.person,
            size: 20,
          ),
        ),
      ),
    );
  }
}
