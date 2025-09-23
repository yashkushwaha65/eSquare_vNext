import 'package:flutter/material.dart';

class PostGateInScreen extends StatelessWidget {
  const PostGateInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post-Gate IN Survey")),
      body: const Center(child: Text("Post-Gate IN Survey Screen")),
    );
  }
}

class FinalOutScreen extends StatelessWidget {
  const FinalOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Final Out Confirmation")),
      body: const Center(child: Text("Final Out Confirmation Screen")),
    );
  }
}
