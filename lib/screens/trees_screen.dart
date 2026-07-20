import 'package:flutter/material.dart';

import 'home_screen.dart';

class TreesScreen extends StatefulWidget {
  const TreesScreen({super.key});

  @override
  State<TreesScreen> createState() => TreesScreenState();
}

class TreesScreenState extends State<TreesScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('Coming Soon'),
      ),
    );
  }
}