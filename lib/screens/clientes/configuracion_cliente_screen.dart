import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// CONFIGURACIÓN CLIENTE
////////////////////////////////////////////

class ConfiguracionClienteScreen extends StatefulWidget {
  final String uid;

  const ConfiguracionClienteScreen({
    super.key,
    required this.uid,
  });

  @override
  State<ConfiguracionClienteScreen> createState() =>
      _ConfiguracionClienteScreenState();
}

class _ConfiguracionClienteScreenState
    extends State<ConfiguracionClienteScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String region = 'Perú';
  String idioma = 'Español';
  String moneda = 'PEN - Sol peruano';

  Future<void> guardarConfiguracion() async {
    await FirebaseFirestore.instance.collection('usuarios').doc(widget.uid).set({
      'configuracion': {
        'region': region,
        'idioma': idioma,
        'moneda': moneda,
      },
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configuración guardada")),
    );
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            value: region,
            decoration: const InputDecoration(
              labelText: "Región",
              prefixIcon: Icon(Icons.public),
              border: OutlineInputBorder(),
            ),
            items: ['Perú', 'Colombia', 'Ecuador', 'Chile']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => region = value!),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: idioma,
            decoration: const InputDecoration(
              labelText: "Idioma",
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            items: ['Español', 'Inglés']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => idioma = value!),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: moneda,
            decoration: const InputDecoration(
              labelText: "Moneda",
              prefixIcon: Icon(Icons.payments),
              border: OutlineInputBorder(),
            ),
            items: ['PEN - Sol peruano', 'USD - Dólar']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => moneda = value!),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: guardarConfiguracion,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              "Guardar configuración",
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}