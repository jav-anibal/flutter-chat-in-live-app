import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WelcomeEncuestasScreen extends StatefulWidget {
  const WelcomeEncuestasScreen({super.key});

  @override
  State<WelcomeEncuestasScreen> createState() => _WelcomeEncuestasScreenState();
}

class _WelcomeEncuestasScreenState extends State<WelcomeEncuestasScreen> {
  final Stream<QuerySnapshot> _encuestaStream = FirebaseFirestore.instance
      .collection("encuestas")
      .snapshots();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("HOME - ENCUESTAS")),
      body: StreamBuilder(
        stream: _encuestaStream,
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(docs[index].id),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.pushNamed(context, '/encuesta',arguments: docs[index].id);
                        // recuperar-ID n el builder apuntar al otro arguemnto
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),

      // Botón para crear nueva encuesta
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/crear_encuesta');
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
