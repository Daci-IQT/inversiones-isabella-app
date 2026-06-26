import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
class AdminRepartidoresScreen extends StatefulWidget {
  const AdminRepartidoresScreen({super.key});

  @override
  State<AdminRepartidoresScreen> createState() =>
      _AdminRepartidoresScreenState();
}

class _AdminRepartidoresScreenState extends State<AdminRepartidoresScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final celularController = TextEditingController();
  final passwordController = TextEditingController();

  bool guardando = false;

  Future<void> registrarRepartidor() async {
    if (nombreController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa nombre, correo y contraseña")),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final adminApp = Firebase.app();
      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: adminApp.options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: correoController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': nombreController.text.trim(),
        'correo electrónico': correoController.text.trim(),
        'celular': celularController.text.trim(),
        'rol': 'repartidor',
        'estado': 'activo',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
      await secondaryApp.delete();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Repartidor registrado correctamente")),
      );

      nombreController.clear();
      correoController.clear();
      celularController.clear();
      passwordController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar repartidor: $e")),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

Widget resumenCalificacionRepartidor(String repartidorId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('calificaciones_repartidores')
        .where('repartidorId', isEqualTo: repartidorId)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Text(
          "Cargando calificación...",
          style: TextStyle(fontSize: 12),
        );
      }

      final docs = snapshot.data!.docs;

      if (docs.isEmpty) {
        return const Text(
          "Sin calificaciones todavía",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        );
      }

      double suma = 0;

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        suma += double.tryParse(data['calificacion'].toString()) ?? 0;
      }

      final promedio = suma / docs.length;

      return Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            promedio.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(
            "(${docs.length} calificaciones)",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    },
  );
}
  Future<void> cambiarEstadoRepartidor(String uid, String estadoActual) async {
    final nuevoEstado = estadoActual == 'activo' ? 'inactivo' : 'activo';

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }

void abrirDetalleCalificacionesRepartidor({
  required String repartidorId,
  required Map<String, dynamic> repartidor,
}) {
  final nombre = repartidor['nombre'] ?? 'Repartidor';
  final correo = repartidor['correo electrónico'] ?? repartidor['correo'] ?? '';
  final celular = repartidor['celular'] ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF5F6FA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.96,
        minChildSize: 0.55,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(18),
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(correo),
              Text("Celular: $celular"),

              const SizedBox(height: 18),

              const Text(
                "Calificaciones recibidas",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calificaciones_repartidores')
                    .where('repartidorId', isEqualTo: repartidorId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final calificaciones = snapshot.data!.docs;

                  if (calificaciones.isEmpty) {
                    return const Text("Este repartidor aún no tiene calificaciones.");
                  }

                  return Column(
                    children: calificaciones.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final calificacion =
                          int.tryParse(data['calificacion'].toString()) ?? 0;
                      final comentario = data['comentario'] ?? '';
                      final pedidoId = data['pedidoId'] ?? '';
                      final clienteCorreo = data['clienteCorreo'] ?? '';
                      final fecha = data['fecha'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < calificacion
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                                const Spacer(),
                                Text(
                                  pedidoId.toString().isNotEmpty
                                      ? "#${pedidoId.toString().substring(0, 6).toUpperCase()}"
                                      : "",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            if (comentario.toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(comentario),
                            ],

                            const SizedBox(height: 8),

                            Text(
                              "Cliente: $clienteCorreo",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),

                            Text(
                              "Fecha: ${formatearFecha(fecha)}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}
String formatearFecha(dynamic timestamp) {
  if (timestamp == null) return "Sin fecha";

  try {
    final fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year}";
  } catch (e) {
    return "Sin fecha";
  }
}
  void abrirFormularioRepartidor() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Agregar repartidor"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: "Correo"),
                ),
                TextField(
                  controller: celularController,
                  decoration: const InputDecoration(labelText: "Celular"),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña temporal",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: guardando ? null : registrarRepartidor,
              child: Text(
                guardando ? "Guardando..." : "Guardar",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget repartidorCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final nombre = data['nombre'] ?? 'Sin nombre';
    final correo = data['correo electrónico'] ?? data['correo'] ?? '';
    final celular = data['celular'] ?? '';
    final estado = data['estado'] ?? 'activo';

    final activo = estado == 'activo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activo ? Colors.green : Colors.grey,
          child: const Icon(Icons.delivery_dining, color: Colors.white),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(correo),
    Text("Celular: $celular"),
    Text("Estado: $estado"),
    const SizedBox(height: 4),
    resumenCalificacionRepartidor(doc.id),
  ],
),
        isThreeLine: false,
        trailing: Switch(
          value: activo,
          activeThumbColor: primaryColor,
          onChanged: (_) {
            cambiarEstadoRepartidor(doc.id, estado);
          },
        ),
      onTap: () {
  abrirDetalleCalificacionesRepartidor(
    repartidorId: doc.id,
    repartidor: data,
  );
},
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    celularController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: abrirFormularioRepartidor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Agregar",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Repartidores",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Registra, visualiza y activa repartidores.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'repartidor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar repartidores"),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final repartidores = snapshot.data!.docs;

                  if (repartidores.isEmpty) {
                    return const Center(
                      child: Text("No hay repartidores registrados"),
                    );
                  }

                  return ListView.builder(
                    itemCount: repartidores.length,
                    itemBuilder: (context, index) {
                      return repartidorCard(repartidores[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}