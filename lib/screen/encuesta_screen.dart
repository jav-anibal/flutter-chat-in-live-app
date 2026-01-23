import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/widgets/barra_votacion.dart';

class EncuestaScreen extends StatefulWidget {
  const EncuestaScreen({super.key});

  @override
  State<EncuestaScreen> createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {

  final Stream<DocumentSnapshot> _encuestaStream =
      FirebaseFirestore.instance.collection("encuestas").doc("lenguajes").snapshots();

  @override
  Widget build(BuildContext context) {

    // Creando un stream -> para crearse dinámicamente usando el argumento recibido
    final String encuestaId = ModalRoute.of(context)!.settings.arguments as String;


    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.indigo,
        title: const Text(
          "GUIA DE LENGUAJES",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),

        // Aqui es donde devolvemos pero dinámicamente por el ID
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
            .collection("encuestas")
            .doc(encuestaId) // -> El id pasando automáticamente
            .snapshots(),


          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Algo salió mal'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }


            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;

            data.remove("total_votos");
            int totalVotos = data.values.fold(0, (sum, value) => sum + (value as int));
            List<MapEntry<String, dynamic>> lenguajes = data.entries.toList();

            return ListView(
              children: lenguajes.map((entry) {
                return BarraVotacion(
                  label: entry.key,
                  votos: entry.value as int,
                  total: totalVotos,
                  color: Colors.indigo,
                  onTap: () {
                    FirebaseFirestore.instance
                        .collection("encuestas")
                        .doc("lenguajes")
                        .update({entry.key: FieldValue.increment(1)});
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
