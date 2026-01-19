// WIDGET PERSONALIZADO PARA LAS BARRAS
import 'package:flutter/material.dart';

class BarraVotacion extends StatelessWidget {
  final String label;
  final int votos;
  final int total;
  final Color color;
  final VoidCallback onTap;

  const BarraVotacion({
    required this.label,
    required this.votos,
    required this.total,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Evitamos división por cero si es el primer voto
    double porcentaje = total == 0 ? 0 : votos / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: InkWell(
        onTap: onTap, // Al tocar, vota
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("$votos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 10),
              // La barra animada
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: porcentaje,
                  minHeight: 25,
                  backgroundColor: Colors.grey[200],
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}