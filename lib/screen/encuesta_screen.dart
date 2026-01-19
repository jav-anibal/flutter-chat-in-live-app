import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/widgets/barra_votacion.dart';

class EncuestaScreen extends StatefulWidget {
  const EncuestaScreen({super.key});

  @override
  State<EncuestaScreen> createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {
  final Stream<QuerySnapshot> _encuestaStream =
      FirebaseFirestore.instance.collection("encuesta").snapshots();

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _encuestaStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Algo salió mal'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Calcular total de votos
            int totalVotos = snapshot.data!.docs.fold(
              0,
              (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['votos'] as int? ?? 0),
            );

            return ListView(
              children: snapshot.data!.docs.map((document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                return BarraVotacion(
                  label: data['nombre'] ?? 'Sin nombre',
                  votos: data['votos'] ?? 0,
                  total: totalVotos,
                  color: Colors.indigo,
                  onTap: () {
                    // Incrementar voto en Firestore
                    document.reference.update({
                      'votos': FieldValue.increment(1),
                    });
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
