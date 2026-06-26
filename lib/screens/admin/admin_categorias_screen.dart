
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/// PANTALLA CATEGORIA ADMIN
////////////////////////////////////////////////////////


class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  final categoriasRef = FirebaseFirestore.instance.collection('categorias');

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
  }

  Future<void> guardarCategoria({String? categoriaId}) async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingrese el nombre de la categoría"),
        ),
      );
      return;
    }

    final data = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    if (categoriaId == null) {
      await categoriasRef.add({
        ...data,
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    } else {
      await categoriasRef.doc(categoriaId).update(data);
    }

    limpiarCampos();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoriaId == null
                ? "Categoría registrada correctamente"
                : "Categoría actualizada correctamente",
          ),
        ),
      );
    }
  }

  Future<void> cambiarEstadoCategoria({
    required String categoriaId,
    required bool estadoActual,
  }) async {
    await categoriasRef.doc(categoriaId).update({
      'activo': !estadoActual,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estadoActual
                ? "Categoría inhabilitada correctamente"
                : "Categoría habilitada correctamente",
          ),
        ),
      );
    }
  }

  void mostrarFormularioCategoria({
    String? categoriaId,
    Map<String, dynamic>? categoria,
  }) {
    if (categoria != null) {
      nombreController.text = categoria['nombre'] ?? '';
      descripcionController.text = categoria['descripcion'] ?? '';
    } else {
      limpiarCampos();
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            categoriaId == null ? "Nueva Categoría" : "Editar Categoría",
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre de categoría *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                limpiarCampos();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () => guardarCategoria(categoriaId: categoriaId),
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => mostrarFormularioCategoria(),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Categorías",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Administra categorías activas e inactivas sin eliminar datos del sistema.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: categoriasRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar categorías"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay categorías registradas"),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final bool activo = data['activo'] ?? true;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),

                          leading: CircleAvatar(
                            backgroundColor: activo
                                ? primaryColor.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.20),
                            child: Icon(
                              activo
                                  ? Icons.category
                                  : Icons.category_outlined,
                              color: activo ? primaryColor : Colors.grey,
                            ),
                          ),

                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['nombre'] ?? 'Sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: activo
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: activo
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  activo ? "Activa" : "Inactiva",
                                  style: TextStyle(
                                    color:
                                        activo ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data['descripcion'] == null ||
                                      data['descripcion'].toString().isEmpty
                                  ? "Sin descripción"
                                  : data['descripcion'],
                              style: TextStyle(
                                color: activo
                                    ? Colors.grey[700]
                                    : Colors.grey,
                              ),
                            ),
                          ),

                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "editar") {
                                mostrarFormularioCategoria(
                                  categoriaId: doc.id,
                                  categoria: data,
                                );
                              }

                              if (value == "estado") {
                                cambiarEstadoCategoria(
                                  categoriaId: doc.id,
                                  estadoActual: activo,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "editar",
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text("Editar"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: "estado",
                                child: Row(
                                  children: [
                                    Icon(
                                      activo
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: activo
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      activo
                                          ? "Inhabilitar"
                                          : "Habilitar",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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