import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// PANTALLA CONFIGURACION ADMIN
class AdminConfiguracionScreen extends StatefulWidget {
  const AdminConfiguracionScreen({super.key});

  @override
  State<AdminConfiguracionScreen> createState() =>
      _AdminConfiguracionScreenState();
}

class _AdminConfiguracionScreenState extends State<AdminConfiguracionScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final configuracionRef =FirebaseFirestore.instance.collection('configuracion');

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final cargoController = TextEditingController();

  final nombreNegocioController = TextEditingController();
  final subtituloController = TextEditingController();

  File? logoSeleccionado;
  String logoActualUrl = "";

  File? fotoAdminSeleccionada;
  String fotoAdminUrl = "";


  final ImagePicker picker = ImagePicker();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  User? get usuarioActual => auth.currentUser;

  Future<void> seleccionarLogoNegocio() async {
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (imagen != null) {
      setState(() {
        logoSeleccionado = File(imagen.path);
      });
    }
  }

  Future<String> subirLogoNegocio() async {
    if (logoSeleccionado == null) return logoActualUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child("configuracion/logo_negocio.jpg");

    await ref.putFile(logoSeleccionado!);

    return await ref.getDownloadURL();
  }

  Future<void> guardarConfiguracionNegocio() async {
    final logoUrl = await subirLogoNegocio();
    
    await configuracionRef.doc('negocio').set({
      'nombreNegocio': nombreNegocioController.text.trim().isEmpty
          ? 'Inversiones Isabella'
          : nombreNegocioController.text.trim(),
      'subtitulo': subtituloController.text.trim().isEmpty
          ? 'Panel Administrativo'
          : subtituloController.text.trim(),
      'logoUrl': logoUrl,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configuración del negocio actualizada"),
        ),
      );
    }
  }

Future<void> seleccionarFotoAdmin() async {
  final XFile? imagen = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
  );

  if (imagen != null) {
    setState(() {
      fotoAdminSeleccionada = File(imagen.path);
    });
  }
}

Future<String> subirFotoAdmin() async {
  if (fotoAdminSeleccionada == null) return fotoAdminUrl;

  final ref = FirebaseStorage.instance
      .ref()
      .child("usuarios/${usuarioActual!.uid}.jpg");

  await ref.putFile(fotoAdminSeleccionada!);

  return await ref.getDownloadURL();
}


Future<void> actualizarDatosAdmin() async {
  if (usuarioActual == null) return;

  final fotoUrl = await subirFotoAdmin();

  await usuariosRef.doc(usuarioActual!.uid).set({
    'nombre': nombreController.text.trim(),
    'telefono': telefonoController.text.trim(),
    'cargo': cargoController.text.trim(),
    'correo': usuarioActual!.email,
    'rol': 'admin',
    'activo': true,
    'fotoUrl': fotoUrl,
    'fechaActualizacion': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Datos actualizados")),
  );
}

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Deseas cerrar sesión como administrador?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await auth.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  Widget campoTexto({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget infoCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    final DateTime fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year}";
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    cargoController.dispose();
    nombreNegocioController.dispose();
    subtituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usuarioActual == null) {
      return const Center(
        child: Text("No hay administrador autenticado"),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: usuariosRef.doc(usuarioActual!.uid).snapshots(),
        builder: (context, snapshotAdmin) {
          if (!snapshotAdmin.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> dataAdmin = {};

          if (snapshotAdmin.data!.exists) {
  dataAdmin = snapshotAdmin.data!.data() as Map<String, dynamic>;

  nombreController.text = dataAdmin['nombre'] ?? '';
  telefonoController.text = dataAdmin['telefono'] ?? '';
  cargoController.text = dataAdmin['cargo'] ?? 'Administrador';

  fotoAdminUrl = dataAdmin['fotoUrl'] ?? "";
} else {
  nombreController.text = usuarioActual!.displayName ?? '';
  telefonoController.text = '';
  cargoController.text = 'Administrador';

  fotoAdminUrl = "";
}

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configuración",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Administra la información del negocio y del usuario administrador.",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 22),

                const Text(
                  "Datos del negocio",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<DocumentSnapshot>(
                  stream: configuracionRef.doc('negocio').snapshots(),
                  builder: (context, snapshotNegocio) {
                    if (snapshotNegocio.hasData &&
                        snapshotNegocio.data!.exists) {
                      final data =
                          snapshotNegocio.data!.data() as Map<String, dynamic>;

                      nombreNegocioController.text =
                          data['nombreNegocio'] ?? 'Inversiones Isabella';

                      subtituloController.text =
                          data['subtitulo'] ?? 'Panel Administrativo';

                      logoActualUrl = data['logoUrl'] ?? '';
                    } else {
                      nombreNegocioController.text = 'Inversiones Isabella';
                      subtituloController.text = 'Panel Administrativo';
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: seleccionarLogoNegocio,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  primaryColor.withOpacity(0.12),
                              backgroundImage: logoSeleccionado != null
                                  ? FileImage(logoSeleccionado!)
                                  : logoActualUrl.isNotEmpty
                                      ? NetworkImage(logoActualUrl)
                                          as ImageProvider
                                      : null,
                              child: logoSeleccionado == null &&
                                      logoActualUrl.isEmpty
                                  ? Icon(
                                      Icons.add_a_photo,
                                      color: primaryColor,
                                      size: 38,
                                    )
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Toca la imagen para cambiar el logo",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          campoTexto(
                            label: "Nombre del negocio",
                            icon: Icons.store,
                            controller: nombreNegocioController,
                          ),

                          const SizedBox(height: 12),

                          campoTexto(
                            label: "Subtítulo del panel",
                            icon: Icons.dashboard,
                            controller: subtituloController,
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: guardarConfiguracionNegocio,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text(
                                "Guardar datos del negocio",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Datos del administrador",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Center(
  child: GestureDetector(
    onTap: seleccionarFotoAdmin,
    child: CircleAvatar(
      radius: 50,
      backgroundColor: primaryColor.withValues(alpha: 0.12),
      backgroundImage: fotoAdminSeleccionada != null
          ? FileImage(fotoAdminSeleccionada!)
          : fotoAdminUrl.isNotEmpty
              ? NetworkImage(fotoAdminUrl) as ImageProvider
              : null,
      child: fotoAdminSeleccionada == null && fotoAdminUrl.isEmpty
          ? Icon(
              Icons.add_a_photo,
              color: primaryColor,
              size: 35,
            )
          : null,
    ),
  ),

),
                ),

                const SizedBox(height: 22),

                infoCard(
                  titulo: "Correo administrador",
                  valor: usuarioActual!.email ?? 'Sin correo',
                  icono: Icons.email,
                  color: Colors.blue,
                ),

                infoCard(
                  titulo: "Rol del usuario",
                  valor: dataAdmin['rol'] ?? 'admin',
                  icono: Icons.verified_user,
                  color: Colors.green,
                ),

                infoCard(
                  titulo: "Fecha de registro",
                  valor: formatearFecha(dataAdmin['fechaRegistro']),
                  icono: Icons.calendar_month,
                  color: Colors.orange,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Nombre del administrador",
                  icon: Icons.person,
                  controller: nombreController,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Teléfono",
                  icon: Icons.phone,
                  controller: telefonoController,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Cargo",
                  icon: Icons.badge,
                  controller: cargoController,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: actualizarDatosAdmin,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "Guardar cambios del administrador",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: cerrarSesion,
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
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