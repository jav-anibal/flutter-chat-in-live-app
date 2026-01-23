# GUIA: Creación de Encuestas en Firebase

## Indice

1. [Objetivo](#1-objetivo)
2. [Estructura de Datos en Firestore](#2-estructura-de-datos-en-firestore)
3. [Flujo Completo](#3-flujo-completo)
4. [Código Explicado Línea por Línea](#4-código-explicado-línea-por-línea)
5. [Diferencia entre .add() y .set()](#5-diferencia-entre-add-y-set)
6. [Cómo se Ve en Tiempo Real](#6-cómo-se-ve-en-tiempo-real)
7. [Errores Comunes](#7-errores-comunes)

---

## 1. Objetivo

Crear una encuesta significa:
1. El usuario escribe un nombre (ej: "peliculas")
2. El usuario agrega opciones (ej: "Acción", "Comedia", "Terror")
3. Se crea un documento en Firestore
4. Todos los usuarios pueden ver y votar en esa encuesta

---

## 2. Estructura de Datos en Firestore

### Antes de crear la encuesta

```
Firestore
    |
    +-- encuestas (colección)
            |
            +-- lenguajes (documento existente)
                    +-- Python: 25
                    +-- JavaScript: 18
                    +-- Dart: 12
```

### Después de crear la encuesta "peliculas"

```
Firestore
    |
    +-- encuestas (colección)
            |
            +-- lenguajes (documento existente)
            |       +-- Python: 25
            |       +-- JavaScript: 18
            |       +-- Dart: 12
            |
            +-- peliculas (DOCUMENTO NUEVO)
                    +-- Acción: 0
                    +-- Comedia: 0
                    +-- Terror: 0
```

### Anatomía del documento

```
+--------------------------------------------------+
|  DOCUMENTO: peliculas                            |
|  (ID del documento = nombre de la encuesta)      |
+--------------------------------------------------+
|                                                  |
|  CAMPOS (opciones de la encuesta):               |
|                                                  |
|    "Acción"   : 0    <-- tipo: number (int)      |
|    "Comedia"  : 0    <-- tipo: number (int)      |
|    "Terror"   : 0    <-- tipo: number (int)      |
|                                                  |
|  Cada campo es una opción con su contador de     |
|  votos inicializado en 0                         |
|                                                  |
+--------------------------------------------------+
```

---

## 3. Flujo Completo

### Diagrama Visual

```
+-------------------+
|      USUARIO      |
+-------------------+
         |
         | 1. Abre la app
         v
+-------------------+
| WelcomeEncuestas  |
| Screen            |
|                   |
| - lenguajes  -->  |
| - colores    -->  |
|                   |
|        [+]        |  <-- 2. Toca el botón (+)
+-------------------+
         |
         | Navigator.pushNamed('/crear_encuesta')
         v
+-------------------+
| CrearEncuesta     |
| Screen            |
|                   |
| Nombre: [peliculas]        <-- 3. Escribe nombre
|                   |
| Opción 1: [Acción]         <-- 4. Escribe opciones
| Opción 2: [Comedia]        |
| Opción 3: [Terror]         |
|                   |
| [+ Agregar opción]|
|                   |
| [Crear Encuesta]  |  <-- 5. Toca "Crear"
+-------------------+
         |
         | 6. Se ejecuta _crearEncuesta()
         v
+-------------------+
|     FIREBASE      |
|     FIRESTORE     |
|                   |
| .collection()     |
| .doc("peliculas") |  <-- 7. Crea documento con ID "peliculas"
| .set({            |
|   "Acción": 0,    |  <-- 8. Guarda las opciones con valor 0
|   "Comedia": 0,   |
|   "Terror": 0     |
| })                |
+-------------------+
         |
         | 9. Firestore confirma éxito
         v
+-------------------+
| CrearEncuesta     |
| Screen            |
|                   |
| "Encuesta creada!"|  <-- 10. Muestra mensaje
|                   |
| Navigator.pop()   |  <-- 11. Vuelve a la lista
+-------------------+
         |
         v
+-------------------+
| WelcomeEncuestas  |
| Screen            |
|                   |
| - lenguajes  -->  |
| - colores    -->  |
| - peliculas  -->  |  <-- 12. ¡Nueva encuesta aparece!
|                   |
|        [+]        |
+-------------------+
         |
         | El Stream detectó el cambio automáticamente
         | porque usamos .snapshots() (tiempo real)
         v
+-------------------+
|  TODOS LOS OTROS  |
|     USUARIOS      |
|                   |
| También ven la    |  <-- 13. Sincronización en tiempo real
| nueva encuesta    |
| "peliculas"       |
+-------------------+
```

---

## 4. Código Explicado Línea por Línea

### 4.1 Los Controladores

```dart
// Controlador para el nombre de la encuesta
final TextEditingController _nombreEncuestaController = TextEditingController();

// Lista de controladores para las opciones (mínimo 2)
final List<TextEditingController> _opcionesControllers = [
  TextEditingController(),  // Opción 1
  TextEditingController(),  // Opción 2
];
```

**¿Qué es un TextEditingController?**

```
+-------------------------------------------+
|  TextField                                |
|  +-------------------------------------+  |
|  | El usuario escribe aquí...          |  |
|  +-------------------------------------+  |
+-------------------------------------------+
         |
         | El controlador "escucha" lo que escribe
         v
+-------------------------------------------+
|  TextEditingController                    |
|                                           |
|  .text = "lo que escribió el usuario"     |
|  .clear() = borra el contenido            |
|  .dispose() = libera memoria              |
+-------------------------------------------+
```

### 4.2 Agregar Nueva Opción

```dart
void _agregarOpcion() {
  setState(() {
    _opcionesControllers.add(TextEditingController());
  });
}
```

**¿Qué hace este código?**

```
ANTES de tocar "Agregar opción":
+---------------------------+
| _opcionesControllers      |
|                           |
| [0] TextEditingController |  --> Opción 1
| [1] TextEditingController |  --> Opción 2
+---------------------------+

Usuario toca [+ Agregar opción]
         |
         v

DESPUÉS de tocar "Agregar opción":
+---------------------------+
| _opcionesControllers      |
|                           |
| [0] TextEditingController |  --> Opción 1
| [1] TextEditingController |  --> Opción 2
| [2] TextEditingController |  --> Opción 3 (NUEVA)
+---------------------------+

setState() hace que Flutter redibuje la pantalla
y aparezca el nuevo campo de texto
```

### 4.3 Eliminar una Opción

```dart
void _eliminarOpcion(int index) {
  if (_opcionesControllers.length > 2) {  // Mínimo 2 opciones
    setState(() {
      _opcionesControllers[index].dispose();  // Liberar memoria
      _opcionesControllers.removeAt(index);   // Eliminar de la lista
    });
  }
}
```

**¿Por qué mínimo 2?**

Una encuesta con menos de 2 opciones no tiene sentido:
- 0 opciones = no hay nada que votar
- 1 opción = no hay elección

### 4.4 La Función Principal: _crearEncuesta()

```dart
Future<void> _crearEncuesta() async {
```

**¿Por qué `Future<void>` y `async`?**

```
Operaciones SÍNCRONAS (inmediatas):
  int x = 5;           // Instantáneo
  String s = "hola";   // Instantáneo

Operaciones ASÍNCRONAS (toman tiempo):
  Guardar en Firestore  // Requiere internet, puede tardar
  Leer un archivo       // Acceso a disco
  Llamar a una API      // Red

async/await = "espera a que termine antes de continuar"
```

### 4.5 Obtener y Limpiar el Nombre

```dart
final nombre = _nombreEncuestaController.text.trim().toLowerCase().replaceAll(' ', '_');
```

**Paso a paso:**

```
Usuario escribe: "  Mis Peliculas Favoritas  "
                          |
                          v
.text -----------------> "  Mis Peliculas Favoritas  "
                          |
                          v
.trim() ---------------> "Mis Peliculas Favoritas"     (quita espacios al inicio/final)
                          |
                          v
.toLowerCase() --------> "mis peliculas favoritas"     (todo minúsculas)
                          |
                          v
.replaceAll(' ', '_') -> "mis_peliculas_favoritas"     (espacios por guiones bajos)

Resultado final: "mis_peliculas_favoritas"

Esto será el ID del documento en Firestore
```

### 4.6 Construir el Mapa de Opciones

```dart
final Map<String, int> opciones = {};

for (var controller in _opcionesControllers) {
  final opcion = controller.text.trim();
  if (opcion.isNotEmpty) {
    opciones[opcion] = 0;  // Cada opción inicia con 0 votos
  }
}
```

**Visualización:**

```
_opcionesControllers:
  [0].text = "Acción"
  [1].text = "Comedia"
  [2].text = "Terror"

         |
         | for loop
         v

Iteración 1: opcion = "Acción"
             opciones["Acción"] = 0
             opciones = {"Acción": 0}

Iteración 2: opcion = "Comedia"
             opciones["Comedia"] = 0
             opciones = {"Acción": 0, "Comedia": 0}

Iteración 3: opcion = "Terror"
             opciones["Terror"] = 0
             opciones = {"Acción": 0, "Comedia": 0, "Terror": 0}

Resultado final:
+---------------------------+
| opciones (Map)            |
|                           |
| "Acción"  : 0             |
| "Comedia" : 0             |
| "Terror"  : 0             |
+---------------------------+
```

### 4.7 Guardar en Firestore

```dart
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc(nombre)
    .set(opciones);
```

**Desglose:**

```
FirebaseFirestore.instance
         |
         | Conexión a tu base de datos Firestore
         v
.collection('encuestas')
         |
         | Accede a la colección "encuestas"
         | (si no existe, se crea automáticamente)
         v
.doc(nombre)
         |
         | nombre = "peliculas"
         | Accede/crea el documento con ID "peliculas"
         v
.set(opciones)
         |
         | opciones = {"Acción": 0, "Comedia": 0, "Terror": 0}
         | Guarda estos datos en el documento
         v
await
         |
         | ESPERA a que Firestore confirme que se guardó
         | (puede tardar milisegundos o segundos según la red)
         v
¡Documento creado!
```

**Resultado en Firestore:**

```
encuestas/
    |
    +-- peliculas/
            |
            +-- Acción: 0
            +-- Comedia: 0
            +-- Terror: 0
```

---

## 5. Diferencia entre .add() y .set()

### .add() - ID Automático

```dart
await FirebaseFirestore.instance
    .collection('mensajes')
    .add({
      'texto': 'Hola mundo',
      'fecha': FieldValue.serverTimestamp(),
    });
```

**Resultado:**

```
mensajes/
    |
    +-- abc123xyz789/     <-- ID generado por Firestore (aleatorio)
            |
            +-- texto: "Hola mundo"
            +-- fecha: Timestamp(...)
```

**Cuándo usar .add():**
- Cuando NO te importa el ID
- Mensajes de chat
- Comentarios
- Logs

### .set() - ID Personalizado

```dart
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('peliculas')     <-- TÚ defines el ID
    .set({
      'Acción': 0,
      'Comedia': 0,
    });
```

**Resultado:**

```
encuestas/
    |
    +-- peliculas/     <-- ID que TÚ elegiste
            |
            +-- Acción: 0
            +-- Comedia: 0
```

**Cuándo usar .set():**
- Cuando el ID tiene significado (nombre de encuesta, username, etc.)
- Cuando quieres poder acceder al documento fácilmente después
- Configuración de usuario (users/userId)

### Tabla Comparativa

```
+------------------+----------------------------------+----------------------------------+
|                  |           .add()                 |            .set()                |
+------------------+----------------------------------+----------------------------------+
| ID               | Automático (Firestore lo genera) | Personalizado (tú lo defines)    |
+------------------+----------------------------------+----------------------------------+
| Sintaxis         | .collection('x').add({...})      | .collection('x').doc('id')       |
|                  |                                  |     .set({...})                  |
+------------------+----------------------------------+----------------------------------+
| Si el doc existe | Siempre crea uno nuevo           | SOBRESCRIBE el documento         |
+------------------+----------------------------------+----------------------------------+
| Ejemplo de ID    | "Xk9mPqR2nLwYz"                  | "peliculas", "user_123"          |
+------------------+----------------------------------+----------------------------------+
| Uso típico       | Mensajes, comentarios, logs      | Usuarios, configuración,         |
|                  |                                  | encuestas con nombre             |
+------------------+----------------------------------+----------------------------------+
```

### CUIDADO con .set()

```dart
// Documento existente:
// peliculas: {Acción: 50, Comedia: 30, Terror: 20}

await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('peliculas')
    .set({
      'Romance': 0,  // Solo esto
    });

// RESULTADO: Se BORRA todo lo anterior!
// peliculas: {Romance: 0}
// ¡Acción, Comedia y Terror fueron eliminados!
```

**Solución - Usar merge:**

```dart
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc('peliculas')
    .set({
      'Romance': 0,
    }, SetOptions(merge: true));  // <-- merge: true

// RESULTADO: Se AÑADE sin borrar
// peliculas: {Acción: 50, Comedia: 30, Terror: 20, Romance: 0}
```

---

## 6. Cómo se Ve en Tiempo Real

### El Poder de los Streams

En `WelcomeEncuestasScreen` tenemos:

```dart
final Stream<QuerySnapshot> _encuestaStream = FirebaseFirestore.instance
    .collection("encuestas")
    .snapshots();
```

### Secuencia de Eventos

```
TIEMPO ────────────────────────────────────────────────────────────────►

Usuario A                    Firestore                    Usuario B
---------                    ---------                    ---------
    |                            |                            |
    | 1. Crea encuesta           |                            |
    |    "peliculas"             |                            |
    |--------------------------► |                            |
    |                            |                            |
    |                            | 2. Documento               |
    |                            |    guardado                |
    |                            |                            |
    |                            | 3. Stream emite            |
    |                            |    nuevo QuerySnapshot     |
    |                            |                            |
    | ◄--------------------------|----------------------------►
    |                            |                            |
    | 4. StreamBuilder           |            4. StreamBuilder|
    |    detecta cambio          |               detecta cambio
    |                            |                            |
    | 5. Lista se                |            5. Lista se     |
    |    actualiza               |               actualiza    |
    |                            |                            |
    | Muestra:                   |            Muestra:        |
    | - lenguajes                |            - lenguajes     |
    | - colores                  |            - colores       |
    | - peliculas ← NUEVO        |            - peliculas ← NUEVO
    |                            |                            |

¡Todo esto pasa en MILISEGUNDOS!
Sin que nadie refresque la página.
```

### Diagrama del Stream

```
+------------------+
|    FIRESTORE     |
|    (nube)        |
+------------------+
         |
         | .snapshots() crea una conexión permanente
         |
         v
+------------------+
|     STREAM       |
|                  |
| Escucha cambios  |
| 24/7             |
+------------------+
         |
         | Cada vez que hay un cambio...
         |
         v
+------------------+
|  StreamBuilder   |
|                  |
| builder: (ctx,   |
|   snapshot) {    |
|   // se ejecuta  |
|   // de nuevo    |
| }                |
+------------------+
         |
         v
+------------------+
|     WIDGET       |
|                  |
| Se redibuja con  |
| los nuevos datos |
+------------------+
```

---

## 7. Errores Comunes

### Error 1: Nombre vacío

```dart
// Usuario no escribe nada y toca "Crear"

if (nombre.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Escribe un nombre para la encuesta')),
  );
  return;  // Salir de la función, no crear nada
}
```

### Error 2: Menos de 2 opciones

```dart
// Usuario solo escribe 1 opción (o ninguna)

if (opciones.length < 2) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Agrega al menos 2 opciones')),
  );
  return;
}
```

### Error 3: Sobrescribir encuesta existente

```
Usuario A crea: "peliculas" con Acción, Comedia, Terror
   ... pasa el tiempo, la gente vota...
Usuario B crea: "peliculas" con Romance, Drama

¡PROBLEMA! .set() sobrescribe todo.
La encuesta original con sus votos se PIERDE.
```

**Solución: Verificar si existe antes de crear**

```dart
// Verificar si ya existe
final docRef = FirebaseFirestore.instance.collection('encuestas').doc(nombre);
final docSnap = await docRef.get();

if (docSnap.exists) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ya existe una encuesta llamada "$nombre"')),
  );
  return;
}

// Si no existe, crear
await docRef.set(opciones);
```

### Error 4: No liberar controladores

```dart
// INCORRECTO - Fuga de memoria
@override
void dispose() {
  // No hacer nada... ❌
  super.dispose();
}

// CORRECTO - Liberar recursos
@override
void dispose() {
  _nombreEncuestaController.dispose();
  for (var controller in _opcionesControllers) {
    controller.dispose();
  }
  super.dispose();
}
```

### Error 5: No manejar errores de red

```dart
// INCORRECTO - Si falla la red, la app crashea
await FirebaseFirestore.instance
    .collection('encuestas')
    .doc(nombre)
    .set(opciones);

// CORRECTO - Manejar errores
try {
  await FirebaseFirestore.instance
      .collection('encuestas')
      .doc(nombre)
      .set(opciones);

  // Éxito
  Navigator.pop(context);

} catch (e) {
  // Error (sin internet, permisos, etc.)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

## Resumen: Checklist de Creación

```
[ ] 1. Usuario escribe nombre de encuesta
[ ] 2. Usuario agrega opciones (mínimo 2)
[ ] 3. Validar que nombre no esté vacío
[ ] 4. Validar que haya al menos 2 opciones
[ ] 5. (Opcional) Verificar que no exista una encuesta con ese nombre
[ ] 6. Construir mapa: {opcion1: 0, opcion2: 0, ...}
[ ] 7. Guardar con .doc(nombre).set(mapa)
[ ] 8. Manejar errores con try/catch
[ ] 9. Mostrar mensaje de éxito
[ ] 10. Volver a la lista (Navigator.pop)
[ ] 11. La lista se actualiza sola (Stream)
```

---

## Código Completo Final

Ver archivo: `lib/screen/crear_encuesta_screen.dart`

---

Documento creado para entender el proceso de creación de encuestas.
Fecha: Enero 2026
