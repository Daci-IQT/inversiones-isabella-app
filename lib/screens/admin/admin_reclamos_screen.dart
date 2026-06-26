

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

///PANTALLA RECLAMOS ADMIN
/////////////////////////////////

class AdminReclamosScreen extends StatefulWidget {
  const AdminReclamosScreen({super.key});

  @override
  State<AdminReclamosScreen> createState() => _AdminReclamosScreenState();
}

class _AdminReclamosScreenState extends State<AdminReclamosScreen> {
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final buscadorController = TextEditingController();
  final respuestaController = TextEditingController();

  String textoBusqueda = "";
  String estadoFiltro = "todos";

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final List<String> estados = [
    "pendiente",
    "en_revision",
    "respondido",
    "cerrado",
  ];

  Future<void> cambiarEstadoReclamo(
    String reclamoId,
    String nuevoEstado,
  ) async {
    await reclamosRef.doc(reclamoId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reclamo actualizado a $nuevoEstado")),
      );
    }
  }

  Future<void> responderReclamo(String reclamoId) async {
    if (respuestaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese una respuesta para el cliente")),
      );
      return;
    }

    await reclamosRef.doc(reclamoId).update({
      'respuestaAdmin': respuestaController.text.trim(),
      'estado': 'respondido',
      'fechaRespuesta': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    respuestaController.clear();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Respuesta enviada correctamente")),
      );
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "en_revision":
        return Colors.blue;
      case "respondido":
        return Colors.green;
      case "cerrado":
        return Colors.grey;
      default:
        return Colors.black45;
    }
  }

  Color colorTipo(String tipo) {
    switch (tipo) {
      case "reclamo":
        return Colors.red;
      case "sugerencia":
        return Colors.purple;
      default:
        return primaryColor;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case "en_revision":
        return "EN REVISIÓN";
      default:
        return estado.toUpperCase();
    }
  }

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    final DateTime fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year} "
        "${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}";
  }

  Widget etiquetaEstado(String estado) {
    final color = colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        textoEstado(estado),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget etiquetaTipo(String tipo) {
    final color = colorTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filtrosReclamos() {
    return Column(
      children: [
        TextField(
          controller: buscadorController,
          onChanged: (value) {
            setState(() {
              textoBusqueda = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Buscar por cliente, correo, asunto o descripción...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: buscadorController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      buscadorController.clear();
                      setState(() {
                        textoBusqueda = "";
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: estadoFiltro,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Filtrar por estado",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "todos",
              child: Text("Todos los reclamos"),
            ),
            DropdownMenuItem(
              value: "pendiente",
              child: Text("Pendientes"),
            ),
            DropdownMenuItem(
              value: "en_revision",
              child: Text("En revisión"),
            ),
            DropdownMenuItem(
              value: "respondido",
              child: Text("Respondidos"),
            ),
            DropdownMenuItem(
              value: "cerrado",
              child: Text("Cerrados"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              estadoFiltro = value ?? "todos";
            });
          },
        ),
      ],
    );
  }

  void mostrarDetalleReclamo({
    required String reclamoId,
    required Map<String, dynamic> reclamo,
  }) {
    final estadoActual = reclamo['estado'] ?? 'pendiente';
    final respuestaActual = reclamo['respuestaAdmin'] ?? '';

    respuestaController.text = respuestaActual;

    showDialog(
      context: context,
      builder: (_) {
        String estadoTemporal = estadoActual;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Detalle del reclamo",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              respuestaController.clear();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                etiquetaTipo(reclamo['tipo'] ?? 'reclamo'),
                                etiquetaEstado(estadoTemporal),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Text(
                              reclamo['asunto'] ?? 'Sin asunto',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Cliente: ${reclamo['clienteNombre'] ?? 'Sin nombre'}",
                            ),
                            Text(
                              "Correo: ${reclamo['clienteCorreo'] ?? 'Sin correo'}",
                            ),
                            Text(
                              "Fecha: ${formatearFecha(reclamo['fechaRegistro'])}",
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "Descripción",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                reclamo['descripcion'] ?? 'Sin descripción',
                              ),
                            ),

                            const SizedBox(height: 18),

                            DropdownButtonFormField<String>(
                              initialValue: estadoTemporal,
                              decoration: const InputDecoration(
                                labelText: "Cambiar estado",
                                border: OutlineInputBorder(),
                              ),
                              items: estados.map((estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(textoEstado(estado)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  estadoTemporal = value ?? estadoTemporal;
                                });
                              },
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "Respuesta del administrador",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              controller: respuestaController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText:
                                    "Escribe aquí la respuesta para el cliente...",
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (reclamo['fechaRespuesta'] != null)
                              Text(
                                "Fecha de respuesta: ${formatearFecha(reclamo['fechaRespuesta'])}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              respuestaController.clear();
                              Navigator.pop(context);
                            },
                            child: const Text("Cerrar"),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () async {
                              await cambiarEstadoReclamo(
                                reclamoId,
                                estadoTemporal,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Guardar estado",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () => responderReclamo(reclamoId),
                            child: const Text(
                              "Responder",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget reclamoCard({
    required String reclamoId,
    required Map<String, dynamic> reclamo,
  }) {
    final estado = reclamo['estado'] ?? 'pendiente';
    final tipo = reclamo['tipo'] ?? 'reclamo';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: colorTipo(tipo).withValues(alpha: 0.12),
          child: Icon(
            tipo == "sugerencia" ? Icons.lightbulb : Icons.report_problem,
            color: colorTipo(tipo),
          ),
        ),
        title: Text(
          reclamo['asunto'] ?? 'Sin asunto',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Cliente: ${reclamo['clienteNombre'] ?? 'Sin nombre'}"),
            Text("Correo: ${reclamo['clienteCorreo'] ?? 'Sin correo'}"),
            Text("Fecha: ${formatearFecha(reclamo['fechaRegistro'])}"),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                etiquetaTipo(tipo),
                etiquetaEstado(estado),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "detalle") {
              mostrarDetalleReclamo(
                reclamoId: reclamoId,
                reclamo: reclamo,
              );
            }

            if (value.startsWith("estado_")) {
              final nuevoEstado = value.replaceFirst("estado_", "");
              cambiarEstadoReclamo(reclamoId, nuevoEstado);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "detalle",
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Ver detalle"),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...estados.map(
              (estado) => PopupMenuItem(
                value: "estado_$estado",
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: colorEstado(estado),
                    ),
                    const SizedBox(width: 8),
                    Text("Marcar ${textoEstado(estado)}"),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          mostrarDetalleReclamo(
            reclamoId: reclamoId,
            reclamo: reclamo,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    buscadorController.dispose();
    respuestaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Reclamos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Visualiza, responde y actualiza el estado de reclamos y sugerencias.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 18),

            filtrosReclamos(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: reclamosRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar reclamos"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay reclamos registrados"),
                    );
                  }

                  final reclamosFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final clienteNombre =
                        (data['clienteNombre'] ?? '').toString().toLowerCase();

                    final clienteCorreo =
                        (data['clienteCorreo'] ?? '').toString().toLowerCase();

                    final asunto =
                        (data['asunto'] ?? '').toString().toLowerCase();

                    final descripcion =
                        (data['descripcion'] ?? '').toString().toLowerCase();

                    final estado = data['estado'] ?? 'pendiente';

                    final coincideBusqueda =
                        clienteNombre.contains(textoBusqueda) ||
                            clienteCorreo.contains(textoBusqueda) ||
                            asunto.contains(textoBusqueda) ||
                            descripcion.contains(textoBusqueda);

                    final coincideEstado =
                        estadoFiltro == "todos" ? true : estado == estadoFiltro;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  if (reclamosFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron reclamos"),
                    );
                  }

                  return ListView(
                    children: reclamosFiltrados.map((doc) {
                      final reclamo = doc.data() as Map<String, dynamic>;

                      return reclamoCard(
                        reclamoId: doc.id,
                        reclamo: reclamo,
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