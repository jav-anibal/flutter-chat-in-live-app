import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screen/encuesta_screen.dart';
import 'package:flutter_chat_app/screen/welcome_encuestas_screen.dart';

import 'firebase_options.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeEncuestasScreen(),
        '/encuesta': (context) => const EncuestaScreen(),
      },


    );
  }
}

