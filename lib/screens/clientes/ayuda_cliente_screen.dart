import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AYUDA: DEVOLUCIONES Y REEMBOLSOS
////////////////////////////////////////////

class AyudaClienteScreen extends StatefulWidget {
  const AyudaClienteScreen({super.key});

  @override
  State<AyudaClienteScreen> createState() => _AyudaClienteScreenState();
}

class _AyudaClienteScreenState extends State<AyudaClienteScreen> {
  final motivoController = TextEditingController();
  final detalleController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  Future<void> enviarSolicitud() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection('solicitudes_ayuda').add({
      'uidCliente': user.uid,
      'correo': user.email,
      'tipo': 'Devolución o reembolso',
      'motivo': motivoController.text.trim(),
      'detalle': detalleController.text.trim(),
      'estado': 'pendiente',
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Solicitud enviada correctamente")),
    );

    motivoController.clear();
    detalleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            "Devoluciones y reembolsos",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: "Motivo",
              prefixIcon: Icon(Icons.help_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: detalleController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Detalle de la solicitud",
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: enviarSolicitud,
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text(
              "Enviar solicitud",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}