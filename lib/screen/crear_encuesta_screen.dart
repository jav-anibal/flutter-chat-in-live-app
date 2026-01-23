import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrearEncuestaScreen extends StatefulWidget {
  const CrearEncuestaScreen({super.key});

  @override
  State<CrearEncuestaScreen> createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {

  // Controlador para el nombre de la encuesta
  final TextEditingController _nombreEncuestaController = TextEditingController();

  // Lista de controladores para las opciones (mínimo 2)
  final List<TextEditingController> _opcionesControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Estado de carga
  bool _guardando = false;

  @override
  void dispose() {
    _nombreEncuestaController.dispose();
    for (var controller in _opcionesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // Agregar campo para nueva opción
  // ============================================================
  void _agregarOpcion() {
    setState(() {
      _opcionesControllers.add(TextEditingController());
    });
  }

  // ============================================================
  // Eliminar una opción (mínimo 2)
  // ============================================================
  void _eliminarOpcion(int index) {
    if (_opcionesControllers.length > 2) {
      setState(() {
        _opcionesControllers[index].dispose();
        _opcionesControllers.removeAt(index);
      });
    }
  }

  // ============================================================
  // CREAR ENCUESTA EN FIRESTORE
  // ============================================================
  Future<void> _crearEncuesta() async {
    // Obtener nombre (sin espacios, minúsculas)
    final nombre = _nombreEncuestaController.text.trim().toLowerCase().replaceAll(' ', '_');

    // Validar nombre
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre para la encuesta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ============================================================
    // Construir mapa de opciones: {opcion: 0, opcion2: 0, ...}
    // ============================================================
    final Map<String, int> opciones = {};

    for (var controller in _opcionesControllers) {
      final opcion = controller.text.trim();
      if (opcion.isNotEmpty) {
        opciones[opcion] = 0;  // Cada opción inicia con 0 votos
      }
    }

    // Validar mínimo 2 opciones
    if (opciones.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos 2 opciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _guardando = true;
    });

    try {
      // ============================================================
      // CONCEPTO CLAVE: .doc(nombre).set(datos)
      // ============================================================
      // - .doc(nombre) = El ID del documento será el nombre
      // - .set(opciones) = Los datos serán {opcion1: 0, opcion2: 0}
      //
      // Ejemplo resultado en Firestore:
      // encuestas/
      //     +-- comidas_favoritas
      //             +-- Pizza: 0
      //             +-- Tacos: 0
      //             +-- Sushi: 0
      // ============================================================
      await FirebaseFirestore.instance
          .collection('encuestas')
          .doc(nombre)
          .set(opciones);

      // Mostrar éxito y volver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encuesta "$nombre" creada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Encuesta'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ============================================================
            // NOMBRE DE LA ENCUESTA
            // ============================================================
            const Text(
              'Nombre de la encuesta:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreEncuestaController,
              decoration: const InputDecoration(
                hintText: 'Ej: comidas_favoritas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.poll),
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Este será el ID del documento en Firestore',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // OPCIONES DE LA ENCUESTA
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Opciones:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_opcionesControllers.length} opciones',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de campos para opciones
            ...List.generate(_opcionesControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Campo de texto
                    Expanded(
                      child: TextField(
                        controller: _opcionesControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Opción ${index + 1}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.check_circle_outline),
                        ),
                      ),
                    ),

                    // Botón eliminar (solo si hay más de 2)
                    if (_opcionesControllers.length > 2)
                      IconButton(
                        onPressed: () => _eliminarOpcion(index),
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                      ),
                  ],
                ),
              );
            }),

            // Botón agregar opción
            TextButton.icon(
              onPressed: _agregarOpcion,
              icon: const Icon(Icons.add_circle),
              label: const Text('Agregar opción'),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // BOTÓN CREAR
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _crearEncuesta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Crear Encuesta'),
              ),
            ),

            const SizedBox(height: 24),

            // ============================================================
            // NOTA EDUCATIVA
            // ============================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cómo funciona:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. El nombre será el ID del documento\n'
                    '2. Cada opción será un campo con valor 0\n'
                    '3. Al votar, se incrementa el valor con +1\n'
                    '4. Todos los usuarios verán la encuesta en tiempo real',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
