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
      body: Center(
        child: GestureDetector(
           onTap: (){
             Navigator.push(context,
                 MaterialPageRoute(builder: (_) => HomeScreen())
             );
           },
          child: const Text('Trees Screen'),
        ),
      ),
    );
  }
}