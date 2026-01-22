import 'package:flutter/material.dart';

class WelcomeEncuestasScreen extends StatefulWidget {
  const WelcomeEncuestasScreen({super.key});

  @override
  State<WelcomeEncuestasScreen> createState() => _WelcomeEncuestasScreenState();
}

class _WelcomeEncuestasScreenState extends State<WelcomeEncuestasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("ENCUESTAS")),

      body: Column(
        children: [
          Container(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushNamed(context, '/encuesta');
                  },
                ),
                Text("LENGUAJES", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
