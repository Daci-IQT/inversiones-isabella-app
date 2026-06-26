
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

/// EDITAR PERFIL CLIENTE
////////////////////////////////////////////

class EditarPerfilClienteScreen extends StatefulWidget {
  final String uid;

  const EditarPerfilClienteScreen({
    super.key,
    required this.uid,
  });

  @override
  State<EditarPerfilClienteScreen> createState() =>
      _EditarPerfilClienteScreenState();
}

class _EditarPerfilClienteScreenState extends State<EditarPerfilClienteScreen> {
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final FirebaseAuth auth = FirebaseAuth.instance;

  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String fotoUrl = '';
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final doc = await usuariosRef.doc(widget.uid).get();
    final user = auth.currentUser;

    if (doc.exists) {
      final data = doc.data()!;
      nombreController.text = data['nombre'] ?? '';
      emailController.text = data['correo'] ?? user?.email ?? '';
      telefonoController.text = data['telefono'] ?? '';
      fotoUrl = data['fotoUrl'] ?? '';
    } else {
      emailController.text = user?.email ?? '';
    }

    setState(() {});
  }

  Future<void> cambiarFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen == null) return;

    setState(() => cargando = true);

    final file = File(imagen.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('usuarios')
        .child(widget.uid)
        .child('perfil.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await usuariosRef.doc(widget.uid).set({
      'fotoUrl': url,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      fotoUrl = url;
      cargando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Foto actualizada correctamente")),
    );
  }

  Future<void> guardarPerfil() async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese su nombre")),
      );
      return;
    }

    await usuariosRef.doc(widget.uid).set({
      'nombre': nombreController.text.trim(),
      'correo': emailController.text.trim(),
      'telefono': telefonoController.text.trim(),
      'rol': 'cliente',
      'activo': true,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Perfil actualizado correctamente")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar perfil"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  backgroundImage:
                      fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                  child: fotoUrl.isEmpty
                      ? Icon(Icons.person, size: 60, color: primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: cargando ? null : cambiarFoto,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          campoTexto("Nombres", Icons.person, nombreController),
          campoTexto("Email", Icons.email, emailController),
          campoTexto("Celular", Icons.phone, telefonoController),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: guardarPerfil,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              "Guardar cambios",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget campoTexto(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}