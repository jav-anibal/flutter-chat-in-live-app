# GUIA COMPLETA: Flutter + Firebase Firestore

## Indice

1. [Conceptos Fundamentales](#1-conceptos-fundamentales)
2. [Estructura de Firestore](#2-estructura-de-firestore)
3. [QuerySnapshot vs DocumentSnapshot](#3-querysnapshot-vs-documentsnapshot)
4. [Conexion con Firebase](#4-conexion-con-firebase)
5. [Streams y Tiempo Real](#5-streams-y-tiempo-real)
6. [StreamBuilder Explicado](#6-streambuilder-explicado)
7. [Operaciones CRUD](#7-operaciones-crud)
8. [Flujo Completo del Proyecto](#8-flujo-completo-del-proyecto)
9. [Errores Comunes](#9-errores-comunes)

---

## 1. Conceptos Fundamentales

### Que es Firebase?

Firebase es una plataforma de Google que ofrece servicios backend para aplicaciones:
- **Firestore**: Base de datos NoSQL en tiempo real
- **Authentication**: Sistema de login (Google, email, etc.)
- **Storage**: Almacenamiento de archivos (imagenes, videos)
- **Y mas...**

### Que es Firestore?

Firestore es una base de datos **NoSQL** organizada en:

```
Base de Datos
    |
    +-- Coleccion (como una carpeta)
    |       |
    |       +-- Documento (como un archivo)
    |       |       |
    |       |       +-- Campos (datos dentro del archivo)
    |       |
    |       +-- Documento
    |               |
    |               +-- Campos
    |
    +-- Coleccion
            |
            +-- Documento
                    |
                    +-- Campos
```

### Ejemplo Real de Este Proyecto

```
Firestore (tu base de datos)
    |
    +-- encuestas (COLECCION)
    |       |
    |       +-- lenguajes (DOCUMENTO)
    |       |       |
    |       |       +-- Python: 25      (CAMPO)
    |       |       +-- JavaScript: 18  (CAMPO)
    |       |       +-- Dart: 12        (CAMPO)
    |       |
    |       +-- colores (DOCUMENTO)
    |               |
    |               +-- Rojo: 10        (CAMPO)
    |               +-- Azul: 15        (CAMPO)
    |
    +-- messages (COLECCION)
            |
            +-- abc123xyz (DOCUMENTO - ID automatico)
            |       |
            |       +-- sender: "Anibal"           (CAMPO)
            |       +-- text: "Hola mundo"         (CAMPO)
            |       +-- date: Timestamp(...)       (CAMPO)
            |
            +-- def456uvw (DOCUMENTO - ID automatico)
                    |
                    +-- sender: "Anibal"           (CAMPO)
                    +-- text: "Como estas?"        (CAMPO)
                    +-- date: Timestamp(...)       (CAMPO)
```

---

## 2. Estructura de Firestore

### Coleccion

Una coleccion es como una **carpeta** que contiene documentos.

```dart
// Acceder a una coleccion
FirebaseFirestore.instance.collection("encuestas")
FirebaseFirestore.instance.collection("messages")
```

**Reglas importantes:**
- Una coleccion SOLO puede contener documentos
- El nombre es un String (ej: "encuestas", "messages", "users")
- Si la coleccion no existe, se crea automaticamente al agregar el primer documento

### Documento

Un documento es como un **archivo** dentro de la carpeta.

```dart
// Acceder a un documento especifico
FirebaseFirestore.instance.collection("encuestas").doc("lenguajes")
FirebaseFirestore.instance.collection("messages").doc("abc123xyz")
```

**Caracteristicas:**
- Cada documento tiene un **ID unico** (puede ser personalizado o autogenerado)
- Contiene campos con datos (como un objeto JSON)
- Tamanio maximo: 1 MB

### Campo

Los campos son los **datos** dentro de un documento.

```dart
// Ejemplo de campos en un documento
{
  "sender": "Anibal",        // String
  "text": "Hola mundo",      // String
  "date": Timestamp(...),    // Timestamp
  "activo": true,            // Boolean
  "edad": 25,                // Number
  "tags": ["flutter", "dart"] // Array
}
```

---

## 3. QuerySnapshot vs DocumentSnapshot

### ESTA ES LA PARTE MAS IMPORTANTE DE ENTENDER

Cuando pides datos a Firestore, recibes un "Snapshot" (foto) de los datos.
Hay **DOS TIPOS** de snapshots segun lo que pidas:

```
+-------------------+----------------------------------+----------------------------------+
|                   |        QuerySnapshot             |       DocumentSnapshot           |
+-------------------+----------------------------------+----------------------------------+
| Que es?           | Foto de MULTIPLES documentos     | Foto de UN SOLO documento        |
+-------------------+----------------------------------+----------------------------------+
| Cuando se usa?    | Cuando pides una COLECCION       | Cuando pides UN DOCUMENTO        |
+-------------------+----------------------------------+----------------------------------+
| Codigo            | .collection("x").snapshots()     | .collection("x").doc("y")        |
|                   |                                  |     .snapshots()                 |
+-------------------+----------------------------------+----------------------------------+
| Que contiene?     | Lista de DocumentSnapshots       | Datos de un solo documento       |
+-------------------+----------------------------------+----------------------------------+
| Como acceder      | snapshot.docs (lista)            | snapshot.data() (mapa)           |
| a los datos?      | snapshot.docs[0].data()          |                                  |
+-------------------+----------------------------------+----------------------------------+
```

### QuerySnapshot - Obtener MULTIPLES Documentos

**Uso:** Cuando quieres TODOS los documentos de una coleccion (o varios filtrados).

```dart
// CODIGO
Stream<QuerySnapshot> stream = FirebaseFirestore.instance
    .collection("encuestas")  // <-- Solo coleccion, sin .doc()
    .snapshots();

// VISUALIZACION DE LO QUE RECIBES
QuerySnapshot {
    docs: [
        DocumentSnapshot { id: "lenguajes", data: {Python: 25, Dart: 12} },
        DocumentSnapshot { id: "colores", data: {Rojo: 10, Azul: 15} },
        DocumentSnapshot { id: "comida", data: {Pizza: 30, Tacos: 20} },
    ]
}
```

**Como extraer los datos:**

```dart
StreamBuilder<QuerySnapshot>(
  stream: stream,
  builder: (context, snapshot) {
    // snapshot.data es el QuerySnapshot
    // snapshot.data!.docs es la LISTA de documentos

    final List<QueryDocumentSnapshot> documentos = snapshot.data!.docs;

    // Recorrer cada documento
    for (var doc in documentos) {
      print(doc.id);              // "lenguajes", "colores", "comida"
      print(doc.data());          // {Python: 25, Dart: 12}
    }

    // O acceder por indice
    print(documentos[0].id);      // "lenguajes"
    print(documentos[0].data());  // {Python: 25, Dart: 12}

    return Widget(...);
  },
);
```

### DocumentSnapshot - Obtener UN SOLO Documento

**Uso:** Cuando quieres UN documento especifico y conoces su ID.

```dart
// CODIGO
Stream<DocumentSnapshot> stream = FirebaseFirestore.instance
    .collection("encuestas")
    .doc("lenguajes")  // <-- Especificas cual documento
    .snapshots();

// VISUALIZACION DE LO QUE RECIBES
DocumentSnapshot {
    id: "lenguajes",
    data: {
        Python: 25,
        JavaScript: 18,
        Dart: 12
    }
}
```

**Como extraer los datos:**

```dart
StreamBuilder<DocumentSnapshot>(
  stream: stream,
  builder: (context, snapshot) {
    // snapshot.data es el DocumentSnapshot directamente
    // NO hay .docs porque es UN solo documento

    final String id = snapshot.data!.id;  // "lenguajes"

    // .data() devuelve un Map con los campos
    final Map<String, dynamic> datos = snapshot.data!.data() as Map<String, dynamic>;

    print(datos["Python"]);     // 25
    print(datos["JavaScript"]); // 18
    print(datos["Dart"]);       // 12

    return Widget(...);
  },
);
```

### Comparacion Visual

```
QUERYSNAPSHOT (Coleccion completa)          DOCUMENTSNAPSHOT (Un documento)
================================            ================================

.collection("encuestas").snapshots()        .collection("encuestas").doc("lenguajes").snapshots()
         |                                               |
         v                                               v
+------------------+                        +------------------+
| QuerySnapshot    |                        | DocumentSnapshot |
|------------------|                        |------------------|
| .docs = [        |                        | .id = "lenguajes"|
|   DocSnap1,      |                        | .data() = {      |
|   DocSnap2,      |                        |   Python: 25,    |
|   DocSnap3       |                        |   Dart: 12       |
| ]                |                        | }                |
+------------------+                        +------------------+
         |                                               |
         v                                               v
Para acceder:                               Para acceder:
snapshot.data!.docs[0].data()               snapshot.data!.data()
snapshot.data!.docs[0].id                   snapshot.data!.id
```

---

## 4. Conexion con Firebase

### Paso 1: Archivo main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';  // Archivo generado por FlutterFire CLI

Future<void> main() async {
  // PASO 1: Preparar Flutter para operaciones asincronas
  WidgetsFlutterBinding.ensureInitialized();

  // PASO 2: Conectar con Firebase (ESPERAR a que termine)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // PASO 3: Lanzar la app (Firebase ya esta listo)
  runApp(const MyApp());
}
```

### Por que este orden es OBLIGATORIO?

```
1. WidgetsFlutterBinding.ensureInitialized()
   |
   +-- Prepara el motor de Flutter
   |
   +-- NECESARIO antes de cualquier operacion asincrona en main()
   |
   v
2. await Firebase.initializeApp(...)
   |
   +-- Conecta con los servidores de Firebase
   |
   +-- Lee la configuracion de firebase_options.dart
   |
   +-- ESPERA hasta que la conexion este lista
   |
   v
3. runApp(const MyApp())
   |
   +-- Ahora SI puedes usar Firestore en tu app
```

**Si no sigues este orden:**
- Sin `ensureInitialized()` --> Crash al iniciar
- Sin `await` --> La app intenta usar Firebase antes de conectar --> Crash

### Archivo firebase_options.dart

Este archivo contiene las **credenciales** de tu proyecto Firebase:

```dart
// Este archivo se genera automaticamente con: flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Detecta si es Android, iOS, Web, etc.
    // y devuelve la configuracion correcta
    return FirebaseOptions(
      apiKey: 'AIzaSy...',           // Clave API
      appId: '1:12345:android:abc',  // ID de la app
      projectId: 'mi-proyecto',       // ID del proyecto
      // ... mas configuracion
    );
  }
}
```

**IMPORTANTE:** Este archivo contiene claves sensibles. Por eso esta en `.gitignore`.

---

## 5. Streams y Tiempo Real

### Que es un Stream?

Un Stream es como un **rio de datos** que fluye constantemente:

```
FIRESTORE (nube)                          TU APP
+----------------+                        +----------------+
|                |   dato 1               |                |
|   Base de      | ------>                |   StreamBuilder|
|   Datos        |   dato 2               |                |
|                | ------>                |   Se actualiza |
|   (cambia)     |   dato 3               |   solo!        |
|                | ------>                |                |
+----------------+                        +----------------+
```

### Diferencia: get() vs snapshots()

```dart
// OPCION 1: get() - Pedir datos UNA VEZ
final snapshot = await FirebaseFirestore.instance
    .collection("encuestas")
    .get();  // <-- Pide datos y termina

// Problema: Si alguien vota, tu app NO se entera


// OPCION 2: snapshots() - Escuchar CONTINUAMENTE
final stream = FirebaseFirestore.instance
    .collection("encuestas")
    .snapshots();  // <-- Devuelve un Stream

// Ventaja: Cada vez que cambian los datos, tu app recibe la actualizacion
```

### Visualizacion del Flujo

```
TIEMPO -->

Usuario A vota          Usuario B vota          Usuario C vota
     |                       |                       |
     v                       v                       v
+--------+              +--------+              +--------+
|Python:5|  --------->  |Python:6|  --------->  |Python:7|
+--------+              +--------+              +--------+
     |                       |                       |
     | Stream emite          | Stream emite          | Stream emite
     | nuevo snapshot        | nuevo snapshot        | nuevo snapshot
     v                       v                       v
+----------+            +----------+            +----------+
| TU APP   |            | TU APP   |            | TU APP   |
| muestra 5|            | muestra 6|            | muestra 7|
+----------+            +----------+            +----------+

Todo esto pasa AUTOMATICAMENTE sin que el usuario refresque la pagina!
```

---

## 6. StreamBuilder Explicado

### Estructura Basica

```dart
StreamBuilder<TIPO_DE_SNAPSHOT>(
  stream: TU_STREAM,
  builder: (BuildContext context, AsyncSnapshot<TIPO> snapshot) {
    // Este codigo se ejecuta CADA VEZ que llegan nuevos datos
    return Widget(...);
  },
);
```

### Los Estados del Snapshot

```dart
builder: (context, snapshot) {

  // ESTADO 1: Error
  // Algo fallo (sin internet, permisos, etc.)
  if (snapshot.hasError) {
    return Text('Error: ${snapshot.error}');
  }

  // ESTADO 2: Esperando
  // Todavia no han llegado datos
  if (snapshot.connectionState == ConnectionState.waiting) {
    return CircularProgressIndicator();
  }

  // ESTADO 3: Datos listos
  // Aqui ya puedes usar snapshot.data
  final datos = snapshot.data!;
  return MostrarDatos(datos);
}
```

### Diagrama de Estados

```
App inicia
    |
    v
+-------------------+
| ConnectionState.  |     "Cargando..."
| waiting           | --> CircularProgressIndicator
+-------------------+
    |
    | (llegan datos)
    v
+-------------------+
| ConnectionState.  |     "Mostrando datos"
| active            | --> ListView con datos
+-------------------+
    |
    | (llegan MAS datos - alguien voto)
    v
+-------------------+
| ConnectionState.  |     "Actualizando automaticamente"
| active            | --> ListView actualizado
+-------------------+
    |
    | (error de red)
    v
+-------------------+
| hasError = true   |     "Algo salio mal"
|                   | --> Mensaje de error
+-------------------+
```

### Ejemplo Completo con QuerySnapshot

```dart
// En welcome_encuestas_screen.dart

// 1. Crear el Stream (escuchar la coleccion "encuestas")
final Stream<QuerySnapshot> _encuestaStream =
    FirebaseFirestore.instance
        .collection("encuestas")
        .snapshots();

// 2. Usar StreamBuilder
StreamBuilder<QuerySnapshot>(
  stream: _encuestaStream,
  builder: (context, snapshot) {

    // Manejar errores
    if (snapshot.hasError) {
      return Center(child: Text('Algo salio mal'));
    }

    // Manejar estado de carga
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    // EXITO: Extraer los documentos
    // snapshot.data = QuerySnapshot
    // snapshot.data!.docs = Lista de DocumentSnapshots
    final docs = snapshot.data!.docs;

    // Construir la lista
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        // docs[index] = un DocumentSnapshot individual
        // docs[index].id = ID del documento
        // docs[index].data() = datos del documento

        return ListTile(
          title: Text(docs[index].id),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/encuesta',
              arguments: docs[index].id,
            );
          },
        );
      },
    );
  },
);
```

### Ejemplo Completo con DocumentSnapshot

```dart
// En encuesta_screen.dart

// 1. Crear el Stream (escuchar UN documento especifico)
final Stream<DocumentSnapshot> _encuestaStream =
    FirebaseFirestore.instance
        .collection("encuestas")
        .doc("lenguajes")  // <-- Documento especifico
        .snapshots();

// 2. Usar StreamBuilder
StreamBuilder<DocumentSnapshot>(
  stream: _encuestaStream,
  builder: (context, snapshot) {

    if (snapshot.hasError) {
      return Center(child: Text('Algo salio mal'));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    // EXITO: Extraer los datos del documento
    // snapshot.data = DocumentSnapshot (NO hay .docs!)
    // snapshot.data!.data() = Map con los campos

    Map<String, dynamic> data =
        snapshot.data!.data() as Map<String, dynamic>;

    // data = { "Python": 25, "JavaScript": 18, "Dart": 12 }

    // Calcular total de votos
    int totalVotos = data.values.fold(0, (sum, val) => sum + (val as int));

    // Convertir a lista para iterar
    List<MapEntry<String, dynamic>> opciones = data.entries.toList();

    return ListView(
      children: opciones.map((entry) {
        // entry.key = "Python"
        // entry.value = 25
        return ListTile(
          title: Text(entry.key),
          trailing: Text('${entry.value} votos'),
        );
      }).toList(),
    );
  },
);
```

---

## 7. Operaciones CRUD

CRUD = Create, Read, Update, Delete (Crear, Leer, Actualizar, Eliminar)

### CREATE - Crear Documentos

```dart
// Opcion 1: ID automatico (Firestore genera un ID unico)
await FirebaseFirestore.instance
    .collection('messages')
    .add({
      'sender': 'Anibal',
      'text': 'Hola mundo',
      'date': FieldValue.serverTimestamp(),
    });
// Resultado: Se crea documento con ID como "abc123xyz789"


// Opcion 2: ID personalizado
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')  // <-- Tu defines el ID
    .set({
      'Python': 0,
      'JavaScript': 0,
      'Dart': 0,
    });
// Resultado: Se crea documento con ID "lenguajes"
```

### READ - Leer Documentos

```dart
// Opcion 1: Leer UNA vez (get)
final snapshot = await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .get();

Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;


// Opcion 2: Escuchar en tiempo real (snapshots)
FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .snapshots()
    .listen((snapshot) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      print('Datos actualizados: $data');
    });
```

### UPDATE - Actualizar Documentos

```dart
// Actualizar campos especificos (NO borra los demas)
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .update({
      'Python': 26,  // Cambia Python de 25 a 26
    });
// Resultado: { Python: 26, JavaScript: 18, Dart: 12 }


// Incrementar un valor (ATOMICO - seguro para multiples usuarios)
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .update({
      'Python': FieldValue.increment(1),  // Suma 1 al valor actual
    });


// Reemplazar TODO el documento (CUIDADO: borra campos no incluidos)
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .set({
      'Python': 100,
    });
// Resultado: { Python: 100 } -- JavaScript y Dart fueron BORRADOS!
```

### DELETE - Eliminar Documentos

```dart
// Eliminar un documento completo
await FirebaseFirestore.instance
    .collection('messages')
    .doc('abc123xyz')
    .delete();


// Eliminar un campo especifico (no el documento)
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('lenguajes')
    .update({
      'Dart': FieldValue.delete(),  // Solo elimina el campo Dart
    });
```

### Tabla Resumen CRUD

```
+------------+------------------+----------------------------------------+
| Operacion  | Metodo           | Ejemplo                                |
+------------+------------------+----------------------------------------+
| CREATE     | .add({})         | collection('x').add({campo: valor})    |
|            | .set({})         | collection('x').doc('id').set({...})   |
+------------+------------------+----------------------------------------+
| READ       | .get()           | collection('x').doc('id').get()        |
|            | .snapshots()     | collection('x').snapshots() [Stream]   |
+------------+------------------+----------------------------------------+
| UPDATE     | .update({})      | doc('id').update({campo: nuevoValor})  |
|            | FieldValue       | update({campo: FieldValue.increment(1)})|
+------------+------------------+----------------------------------------+
| DELETE     | .delete()        | doc('id').delete()                     |
|            | FieldValue       | update({campo: FieldValue.delete()})   |
+------------+------------------+----------------------------------------+
```

---

## 8. Flujo Completo del Proyecto

### Arquitectura General

```
+------------------------------------------------------------------+
|                           FIREBASE                                |
|  +------------------------+    +------------------------+         |
|  |     messages           |    |      encuestas         |         |
|  |  (Coleccion)           |    |  (Coleccion)           |         |
|  |                        |    |                        |         |
|  |  +------------------+  |    |  +------------------+  |         |
|  |  | abc123 (Doc)     |  |    |  | lenguajes (Doc)  |  |         |
|  |  | sender: "Anibal" |  |    |  | Python: 25       |  |         |
|  |  | text: "Hola"     |  |    |  | JavaScript: 18   |  |         |
|  |  | date: Timestamp  |  |    |  | Dart: 12         |  |         |
|  |  +------------------+  |    |  +------------------+  |         |
|  |                        |    |                        |         |
|  |  +------------------+  |    |  +------------------+  |         |
|  |  | def456 (Doc)     |  |    |  | colores (Doc)    |  |         |
|  |  | sender: "Anibal" |  |    |  | Rojo: 10         |  |         |
|  |  | text: "Adios"    |  |    |  | Azul: 15         |  |         |
|  |  | date: Timestamp  |  |    |  +------------------+  |         |
|  |  +------------------+  |    |                        |         |
|  +------------------------+    +------------------------+         |
+------------------------------------------------------------------+
              |                              |
              | Stream                       | Stream
              | QuerySnapshot                | QuerySnapshot / DocumentSnapshot
              |                              |
              v                              v
+------------------+              +-------------------------+
|   UsersList      |              | WelcomeEncuestasScreen  |
|   (Chat)         |              | (Lista de encuestas)    |
|                  |              |                         |
| - Ver mensajes   |              | - Ver todas las         |
| - Enviar mensaje |              |   encuestas             |
| - Eliminar msg   |              | - Navegar a una         |
+------------------+              +------------+------------+
                                               |
                                               | Navigator.pushNamed
                                               | arguments: "lenguajes"
                                               v
                                  +-------------------------+
                                  |    EncuestaScreen       |
                                  |    (Votacion)           |
                                  |                         |
                                  | - Ver opciones          |
                                  | - Votar                 |
                                  | - Ver resultados        |
                                  +-------------------------+
```

### Flujo de Navegacion

```
1. App Inicia
       |
       v
2. main.dart
   - Firebase.initializeApp()
   - runApp(MyApp)
       |
       v
3. MaterialApp
   - initialRoute: '/welcome'
   - routes: { '/welcome': ..., '/encuesta': ... }
       |
       v
4. WelcomeEncuestasScreen
   - Stream: collection("encuestas").snapshots()
   - Tipo: QuerySnapshot (multiples docs)
   - Muestra: Lista de encuestas
       |
       | Usuario toca una encuesta
       | Navigator.pushNamed('/encuesta', arguments: 'lenguajes')
       v
5. EncuestaScreen
   - Stream: collection("encuestas").doc("lenguajes").snapshots()
   - Tipo: DocumentSnapshot (un solo doc)
   - Muestra: Opciones de voto
       |
       | Usuario vota
       | .update({opcion: FieldValue.increment(1)})
       v
6. Firestore actualiza el documento
       |
       | Stream emite nuevo snapshot
       v
7. EncuestaScreen se reconstruye automaticamente
   - Muestra los nuevos votos
```

### Flujo de Datos Detallado

```
WELCOME ENCUESTAS SCREEN
========================

Firestore                    Stream                      Widget
--------                    --------                    --------
encuestas/                      |                           |
  lenguajes                     |                           |
  colores        ------>   QuerySnapshot   ------>    StreamBuilder
  comida                        |                           |
                                |                           v
                          .docs = [                   ListView.builder
                            DocSnap("lenguajes"),       - "lenguajes"
                            DocSnap("colores"),         - "colores"
                            DocSnap("comida")           - "comida"
                          ]


ENCUESTA SCREEN
===============

Firestore                    Stream                      Widget
--------                    --------                    --------
encuestas/                      |                           |
  lenguajes/                    |                           |
    Python: 25                  |                           |
    JavaScript: 18  ---->  DocumentSnapshot  ---->    StreamBuilder
    Dart: 12                    |                           |
                                |                           v
                          .data() = {                 ListView
                            Python: 25,                 - Python: 25
                            JavaScript: 18,             - JavaScript: 18
                            Dart: 12                    - Dart: 12
                          }
```

---

## 9. Errores Comunes

### Error 1: Import incorrecto de firebase_options.dart

```dart
// INCORRECTO - busca fuera de lib/
import '../firebase_options.dart';

// CORRECTO - busca dentro de lib/
import 'firebase_options.dart';
// o
import 'package:flutter_chat_app/firebase_options.dart';
```

### Error 2: No recibir argumentos en la navegacion

```dart
// En WelcomeEncuestasScreen - SE ENVIA el argumento
Navigator.pushNamed(context, '/encuesta', arguments: docs[index].id);

// En EncuestaScreen - NO SE RECIBE el argumento (ERROR!)
final Stream<DocumentSnapshot> _encuestaStream =
    FirebaseFirestore.instance.collection("encuestas").doc("lenguajes").snapshots();
    //                                                      ^^^^^^^^^^^
    //                                                      HARDCODEADO!

// SOLUCION: Recibir el argumento
@override
Widget build(BuildContext context) {
  // Obtener el argumento pasado
  final String encuestaId = ModalRoute.of(context)!.settings.arguments as String;

  // Usar el argumento dinamicamente
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection("encuestas")
        .doc(encuestaId)  // <-- DINAMICO
        .snapshots(),
    // ...
  );
}
```

### Error 3: Confundir QuerySnapshot con DocumentSnapshot

```dart
// Si usas .collection().snapshots() --> QuerySnapshot
StreamBuilder<QuerySnapshot>  // <-- Tipo correcto
  stream: collection("x").snapshots(),
  builder: (context, snapshot) {
    final docs = snapshot.data!.docs;  // <-- .docs porque son MULTIPLES
  }

// Si usas .collection().doc().snapshots() --> DocumentSnapshot
StreamBuilder<DocumentSnapshot>  // <-- Tipo correcto
  stream: collection("x").doc("y").snapshots(),
  builder: (context, snapshot) {
    final data = snapshot.data!.data();  // <-- .data() porque es UNO
  }
```

### Error 4: No esperar a Firebase

```dart
// INCORRECTO - Firebase no esta listo
void main() {
  Firebase.initializeApp();  // Falta await!
  runApp(MyApp());  // Crash!
}

// CORRECTO
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}
```

### Error 5: No manejar estados del snapshot

```dart
// INCORRECTO - Puede crashear
builder: (context, snapshot) {
  final data = snapshot.data!.data();  // Crash si aun esta cargando!
  return Text(data.toString());
}

// CORRECTO - Manejar todos los estados
builder: (context, snapshot) {
  if (snapshot.hasError) return Text('Error');
  if (snapshot.connectionState == ConnectionState.waiting) {
    return CircularProgressIndicator();
  }
  // Ahora si es seguro acceder a los datos
  final data = snapshot.data!.data();
  return Text(data.toString());
}
```

---

## Resumen Final

```
+------------------+---------------------------------------------------+
| Concepto         | Recuerda                                          |
+------------------+---------------------------------------------------+
| Coleccion        | Carpeta que contiene documentos                   |
| Documento        | Archivo con datos (campos)                        |
| QuerySnapshot    | Foto de MULTIPLES documentos (.docs)              |
| DocumentSnapshot | Foto de UN documento (.data())                    |
| Stream           | Rio de datos en tiempo real                       |
| StreamBuilder    | Widget que escucha un Stream y se reconstruye     |
| .snapshots()     | Devuelve Stream (tiempo real)                     |
| .get()           | Devuelve Future (una sola vez)                    |
| .add()           | Crear documento con ID automatico                 |
| .set()           | Crear/reemplazar documento con ID personalizado   |
| .update()        | Actualizar campos especificos                     |
| .delete()        | Eliminar documento                                |
+------------------+---------------------------------------------------+
```

---

Documento creado para el proyecto Flutter Chat App con Firebase.
Fecha: Enero 2026
