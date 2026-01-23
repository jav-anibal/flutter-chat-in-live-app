# PROYECTO PRACTICA: Lista de Tareas con Firebase

## Objetivo

Crear una app de lista de tareas (TODO List) para practicar:
- QuerySnapshot (listar todas las tareas)
- DocumentSnapshot (ver detalle de una tarea)
- Crear tareas
- Actualizar tareas (marcar completada)
- Eliminar tareas

---

## PASO 0: Crear el Proyecto

### 0.1 Crear proyecto Flutter

```bash
flutter create todo_firebase_practica
cd todo_firebase_practica
```

### 0.2 Agregar dependencias

Edita `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.8.1
  cloud_firestore: ^5.6.0
```

Luego ejecuta:

```bash
flutter pub get
```

### 0.3 Configurar Firebase

```bash
# Instalar FlutterFire CLI (solo una vez)
dart pub global activate flutterfire_cli

# Configurar Firebase (te pedira seleccionar proyecto)
flutterfire configure
```

### 0.4 Crear estructura en Firestore

Ve a la consola de Firebase (https://console.firebase.google.com):

1. Selecciona tu proyecto
2. Ve a Firestore Database
3. Crea una coleccion llamada `tareas`
4. Agrega un documento de prueba:

```
Coleccion: tareas
    |
    +-- Documento (ID automatico)
            |
            +-- titulo: "Mi primera tarea"
            +-- completada: false
            +-- fecha: (timestamp actual)
```

---

## PASO 1: Configurar main.dart

### Ejercicio 1.1: Inicializar Firebase

Crea el archivo `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Pantallas (las crearemos despues)
import 'screens/lista_tareas_screen.dart';
import 'screens/detalle_tarea_screen.dart';
import 'screens/crear_tarea_screen.dart';

Future<void> main() async {
  // PASO 1: Preparar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // PASO 2: Conectar con Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // PASO 3: Lanzar app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Firebase Practica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // Ruta inicial
      initialRoute: '/',

      // Mapa de rutas
      routes: {
        '/': (context) => const ListaTareasScreen(),
        '/detalle': (context) => const DetalleTareaScreen(),
        '/crear': (context) => const CrearTareaScreen(),
      },
    );
  }
}
```

### Que practicamos aqui?

- Inicializacion de Firebase con async/await
- Sistema de rutas de Flutter
- Estructura basica de una app

---

## PASO 2: Listar Tareas (QuerySnapshot)

### Ejercicio 2.1: Crear pantalla de lista

Crea la carpeta `lib/screens/` y el archivo `lib/screens/lista_tareas_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({super.key});

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen> {

  // ============================================================
  // CONCEPTO CLAVE: Stream de QuerySnapshot
  // ============================================================
  // Escuchamos TODA la coleccion "tareas"
  // Esto devuelve un QuerySnapshot (multiples documentos)
  // ============================================================
  final Stream<QuerySnapshot> _tareasStream =
      FirebaseFirestore.instance
          .collection('tareas')
          .orderBy('fecha', descending: true)  // Mas recientes primero
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ============================================================
      // CONCEPTO CLAVE: StreamBuilder con QuerySnapshot
      // ============================================================
      body: StreamBuilder<QuerySnapshot>(
        stream: _tareasStream,
        builder: (context, snapshot) {

          // ESTADO 1: Error
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar tareas'),
            );
          }

          // ESTADO 2: Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ESTADO 3: Datos listos
          // ============================================================
          // CONCEPTO CLAVE: Extraer documentos de QuerySnapshot
          // ============================================================
          // snapshot.data = QuerySnapshot
          // snapshot.data!.docs = Lista de DocumentSnapshot
          // ============================================================
          final docs = snapshot.data!.docs;

          // Si no hay tareas
          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay tareas. Crea una!'),
            );
          }

          // Mostrar lista de tareas
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              // ============================================================
              // CONCEPTO CLAVE: Acceder a datos de cada documento
              // ============================================================
              // docs[index] = DocumentSnapshot individual
              // docs[index].id = ID del documento
              // docs[index].data() = Map con los campos
              // ============================================================
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String titulo = data['titulo'] ?? 'Sin titulo';
              final bool completada = data['completada'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  // Icono segun estado
                  leading: Icon(
                    completada ? Icons.check_circle : Icons.circle_outlined,
                    color: completada ? Colors.green : Colors.grey,
                  ),

                  // Titulo de la tarea
                  title: Text(
                    titulo,
                    style: TextStyle(
                      decoration: completada
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),

                  // Navegar al detalle
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // ============================================================
                    // CONCEPTO CLAVE: Pasar ID a otra pantalla
                    // ============================================================
                    Navigator.pushNamed(
                      context,
                      '/detalle',
                      arguments: doc.id,  // Pasamos el ID del documento
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // Boton para crear nueva tarea
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/crear');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Que practicamos aqui?

| Concepto | Linea | Explicacion |
|----------|-------|-------------|
| Stream de coleccion | 20-24 | `.collection('tareas').snapshots()` devuelve Stream |
| QuerySnapshot | 30 | El tipo de datos cuando escuchas una coleccion |
| Estados del snapshot | 33-47 | hasError, waiting, datos listos |
| Extraer docs | 54 | `snapshot.data!.docs` es la lista de documentos |
| Acceder a datos | 69-72 | `doc.data()` devuelve Map con campos |
| Pasar argumentos | 96 | `arguments: doc.id` pasa datos a otra pantalla |

---

## PASO 3: Ver Detalle de Tarea (DocumentSnapshot)

### Ejercicio 3.1: Crear pantalla de detalle

Crea `lib/screens/detalle_tarea_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetalleTareaScreen extends StatefulWidget {
  const DetalleTareaScreen({super.key});

  @override
  State<DetalleTareaScreen> createState() => _DetalleTareaScreenState();
}

class _DetalleTareaScreenState extends State<DetalleTareaScreen> {

  @override
  Widget build(BuildContext context) {

    // ============================================================
    // CONCEPTO CLAVE: Recibir argumentos de navegacion
    // ============================================================
    final String tareaId = ModalRoute.of(context)!.settings.arguments as String;

    // ============================================================
    // CONCEPTO CLAVE: Stream de DocumentSnapshot
    // ============================================================
    // Escuchamos UN SOLO documento especifico
    // Usamos el ID que recibimos de la pantalla anterior
    // Esto devuelve un DocumentSnapshot (un solo documento)
    // ============================================================
    final Stream<DocumentSnapshot> _tareaStream =
        FirebaseFirestore.instance
            .collection('tareas')
            .doc(tareaId)  // <-- ID DINAMICO, no hardcodeado!
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Tarea'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // ============================================================
      // CONCEPTO CLAVE: StreamBuilder con DocumentSnapshot
      // ============================================================
      body: StreamBuilder<DocumentSnapshot>(
        stream: _tareaStream,
        builder: (context, snapshot) {

          // ESTADO 1: Error
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tarea'));
          }

          // ESTADO 2: Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Verificar que el documento existe
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Tarea no encontrada'));
          }

          // ESTADO 3: Datos listos
          // ============================================================
          // CONCEPTO CLAVE: Extraer datos de DocumentSnapshot
          // ============================================================
          // snapshot.data = DocumentSnapshot (NO hay .docs!)
          // snapshot.data!.data() = Map con los campos
          // snapshot.data!.id = ID del documento
          // ============================================================
          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String titulo = data['titulo'] ?? 'Sin titulo';
          final bool completada = data['completada'] ?? false;
          final Timestamp? fecha = data['fecha'] as Timestamp?;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Mostrar ID del documento
                Text(
                  'ID: $tareaId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 16),

                // Titulo
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Estado
                Row(
                  children: [
                    const Text('Estado: ', style: TextStyle(fontSize: 16)),
                    Chip(
                      label: Text(completada ? 'Completada' : 'Pendiente'),
                      backgroundColor: completada ? Colors.green[100] : Colors.orange[100],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Fecha
                if (fecha != null)
                  Text(
                    'Creada: ${fecha.toDate().toString().substring(0, 16)}',
                    style: const TextStyle(color: Colors.grey),
                  ),

                const SizedBox(height: 32),

                // ============================================================
                // CONCEPTO CLAVE: Actualizar documento (UPDATE)
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(completada ? Icons.undo : Icons.check),
                    label: Text(completada ? 'Marcar Pendiente' : 'Marcar Completada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: completada ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // ============================================================
                      // .update() solo modifica campos especificos
                      // No borra los demas campos del documento
                      // ============================================================
                      FirebaseFirestore.instance
                          .collection('tareas')
                          .doc(tareaId)
                          .update({
                            'completada': !completada,  // Invertir estado
                          });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // CONCEPTO CLAVE: Eliminar documento (DELETE)
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar Tarea'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Mostrar dialogo de confirmacion
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar tarea?'),
                          content: const Text('Esta accion no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                // ============================================================
                                // .delete() elimina el documento completo
                                // ============================================================
                                FirebaseFirestore.instance
                                    .collection('tareas')
                                    .doc(tareaId)
                                    .delete();

                                // Cerrar dialogo y volver a la lista
                                Navigator.pop(context);  // Cerrar dialogo
                                Navigator.pop(context);  // Volver a lista
                              },
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### Que practicamos aqui?

| Concepto | Linea | Explicacion |
|----------|-------|-------------|
| Recibir argumentos | 19 | `ModalRoute.of(context)!.settings.arguments` |
| Stream de documento | 28-31 | `.doc(tareaId).snapshots()` para UN documento |
| DocumentSnapshot | 44 | El tipo cuando escuchas un documento |
| Extraer datos | 69 | `snapshot.data!.data()` devuelve Map (NO .docs!) |
| UPDATE | 126-130 | `.update({campo: valor})` modifica campos |
| DELETE | 156-159 | `.delete()` elimina el documento |

### DIFERENCIA CLAVE: QuerySnapshot vs DocumentSnapshot

```
LISTA DE TAREAS (QuerySnapshot)           DETALLE DE TAREA (DocumentSnapshot)
===============================           ==================================

.collection('tareas').snapshots()         .collection('tareas').doc(id).snapshots()
            |                                         |
            v                                         v
      QuerySnapshot                            DocumentSnapshot
            |                                         |
   snapshot.data!.docs                         snapshot.data!.data()
            |                                         |
   [Doc1, Doc2, Doc3]                          {titulo: "...", completada: false}
            |                                         |
   docs[0].data()                              Acceso directo a los campos
```

---

## PASO 4: Crear Nueva Tarea (CREATE)

### Ejercicio 4.1: Crear pantalla de creacion

Crea `lib/screens/crear_tarea_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrearTareaScreen extends StatefulWidget {
  const CrearTareaScreen({super.key});

  @override
  State<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends State<CrearTareaScreen> {

  // Controlador para el campo de texto
  final TextEditingController _tituloController = TextEditingController();

  // Estado de carga
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  // ============================================================
  // CONCEPTO CLAVE: Crear documento (CREATE)
  // ============================================================
  Future<void> _crearTarea() async {
    // Validar que hay texto
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un titulo para la tarea')),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _guardando = true;
    });

    try {
      // ============================================================
      // .add() crea un documento con ID AUTOMATICO
      // Firestore genera un ID unico como "abc123xyz789"
      // ============================================================
      await FirebaseFirestore.instance.collection('tareas').add({
        'titulo': titulo,
        'completada': false,
        'fecha': FieldValue.serverTimestamp(),  // Hora del servidor
      });

      // Volver a la lista
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('Nueva Tarea'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Titulo de la tarea:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Campo de texto
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                hintText: 'Ej: Comprar leche',
                border: OutlineInputBorder(),
              ),
              // Permitir crear con Enter
              onSubmitted: (_) => _crearTarea(),
            ),

            const SizedBox(height: 24),

            // Boton crear
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _crearTarea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear Tarea', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // NOTA EDUCATIVA: Diferencia entre .add() y .set()
            // ============================================================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nota: .add() vs .set()',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '.add({...}) --> ID automatico\n'
                    '.doc("miId").set({...}) --> ID personalizado',
                    style: TextStyle(fontFamily: 'monospace'),
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
```

### Que practicamos aqui?

| Concepto | Linea | Explicacion |
|----------|-------|-------------|
| .add() | 46-50 | Crea documento con ID automatico |
| FieldValue.serverTimestamp() | 50 | Usa hora del servidor (no del dispositivo) |
| async/await | 27, 46 | Esperar operacion asincrona |
| try/catch | 43-67 | Manejar errores |

---

## PASO 5: Ejercicios Extra (Practica Adicional)

### Ejercicio 5.1: Agregar descripcion a las tareas

**Objetivo:** Modificar el proyecto para que las tareas tengan titulo Y descripcion.

**Pasos:**
1. En `crear_tarea_screen.dart`, agregar otro TextField para descripcion
2. Al crear, agregar campo `'descripcion': descripcionController.text`
3. En `detalle_tarea_screen.dart`, mostrar la descripcion

### Ejercicio 5.2: Filtrar tareas

**Objetivo:** Agregar botones para filtrar: Todas / Pendientes / Completadas

**Pista - Queries con filtros:**

```dart
// Todas las tareas
.collection('tareas').snapshots()

// Solo pendientes
.collection('tareas').where('completada', isEqualTo: false).snapshots()

// Solo completadas
.collection('tareas').where('completada', isEqualTo: true).snapshots()
```

### Ejercicio 5.3: Contador de tareas

**Objetivo:** Mostrar en el AppBar cuantas tareas hay (total y completadas)

**Pista:**

```dart
final docs = snapshot.data!.docs;
final total = docs.length;
final completadas = docs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return data['completada'] == true;
}).length;

// Mostrar: "Tareas (3/5)" --> 3 completadas de 5 total
```

### Ejercicio 5.4: Editar titulo de tarea

**Objetivo:** Permitir editar el titulo de una tarea existente

**Pista:**

```dart
// Mostrar dialogo con TextField
// Al confirmar:
FirebaseFirestore.instance
    .collection('tareas')
    .doc(tareaId)
    .update({'titulo': nuevoTitulo});
```

### Ejercicio 5.5: Subcategorias (Subcolecciones)

**Objetivo:** Agregar subtareas a cada tarea (coleccion dentro de documento)

**Estructura en Firestore:**

```
tareas/
  |
  +-- tarea1/
  |       |
  |       +-- titulo: "Proyecto Flutter"
  |       +-- completada: false
  |       |
  |       +-- subtareas/  <-- SUBCOLECCION
  |               |
  |               +-- sub1/
  |               |     +-- titulo: "Disenar UI"
  |               |     +-- completada: true
  |               |
  |               +-- sub2/
  |                     +-- titulo: "Conectar Firebase"
  |                     +-- completada: false
```

**Pista - Acceder a subcoleccion:**

```dart
FirebaseFirestore.instance
    .collection('tareas')
    .doc(tareaId)
    .collection('subtareas')  // <-- Subcoleccion
    .snapshots();
```

---

## RESUMEN: Cheat Sheet

### Tipos de Snapshot

```dart
// COLECCION -> QuerySnapshot
Stream<QuerySnapshot> = .collection('x').snapshots();
// Acceder: snapshot.data!.docs[0].data()

// DOCUMENTO -> DocumentSnapshot
Stream<DocumentSnapshot> = .collection('x').doc('id').snapshots();
// Acceder: snapshot.data!.data()
```

### Operaciones CRUD

```dart
// CREATE (ID automatico)
.collection('x').add({campo: valor});

// CREATE (ID personalizado)
.collection('x').doc('miId').set({campo: valor});

// READ (una vez)
.collection('x').doc('id').get();

// READ (tiempo real)
.collection('x').doc('id').snapshots();

// UPDATE
.collection('x').doc('id').update({campo: nuevoValor});

// DELETE
.collection('x').doc('id').delete();
```

### Pasar datos entre pantallas

```dart
// ENVIAR
Navigator.pushNamed(context, '/ruta', arguments: dato);

// RECIBIR
final dato = ModalRoute.of(context)!.settings.arguments;
```

### StreamBuilder

```dart
StreamBuilder<TIPO>(
  stream: miStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) return Error();
    if (snapshot.connectionState == ConnectionState.waiting) return Loading();

    // Usar datos
    final data = snapshot.data!;
    return MiWidget(data);
  },
);
```

---

## Estructura Final del Proyecto

```
todo_firebase_practica/
    |
    +-- lib/
    |     |
    |     +-- main.dart
    |     |
    |     +-- firebase_options.dart (generado)
    |     |
    |     +-- screens/
    |           |
    |           +-- lista_tareas_screen.dart    (QuerySnapshot)
    |           +-- detalle_tarea_screen.dart   (DocumentSnapshot)
    |           +-- crear_tarea_screen.dart     (CREATE)
    |
    +-- pubspec.yaml
```

---

## Checklist de Aprendizaje

Marca cada concepto cuando lo entiendas:

- [ ] Diferencia entre Coleccion y Documento
- [ ] QuerySnapshot: cuando se usa y como extraer datos
- [ ] DocumentSnapshot: cuando se usa y como extraer datos
- [ ] Stream vs Future (snapshots vs get)
- [ ] StreamBuilder y sus estados (error, waiting, datos)
- [ ] CREATE con .add() (ID automatico)
- [ ] CREATE con .set() (ID personalizado)
- [ ] READ con .get() (una vez)
- [ ] READ con .snapshots() (tiempo real)
- [ ] UPDATE con .update()
- [ ] DELETE con .delete()
- [ ] Pasar argumentos con Navigator
- [ ] Recibir argumentos con ModalRoute

---

Proyecto de practica creado para aprender Firebase + Flutter.
Sigue los pasos en orden y completa los ejercicios extra para dominar los conceptos!
