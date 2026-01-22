import 'package:flutter/material.dart';

class WelcomeEncuestasScreen extends StatefulWidget {
  const WelcomeEncuestasScreen({super.key});

  @override
  State<WelcomeEncuestasScreen> createState() => _WelcomeEncuestasScreenState();
}

class _WelcomeEncuestasScreenState extends State<WelcomeEncuestasScreen> {
  final List<String> categorias = [
    "LENGUAJES",
    "COLORES",
    "COMIDA",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("ENCUESTAS")),

      body: ListView.builder(
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categorias[index], style: TextStyle(fontSize: 16)),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  Navigator.pushNamed(context, '/encuesta');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
