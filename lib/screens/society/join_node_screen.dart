import 'package:flutter/material.dart';

class JoinNodeScreen extends StatelessWidget {
  const JoinNodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Society Node')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Enter society code'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Society Code'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
