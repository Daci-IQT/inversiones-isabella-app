import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MesaAyudaAdminScreen extends StatefulWidget {
  const MesaAyudaAdminScreen({super.key});

  @override
  State<MesaAyudaAdminScreen> createState() => _MesaAyudaAdminScreenState();
}

class _MesaAyudaAdminScreenState extends State<MesaAyudaAdminScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String filtroEstado = "todos";
  final buscarController = TextEditingController();
  String textoBusqueda = "";

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "en_revision":
        return Colors.blue;
      case "resuelto":
        return Colors.green;
      case "rechazado":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return "Pendiente";
      case "en_revision":
        return "En revisión";
      case "resuelto":
        return "Resuelto";
      case "rechazado":
        return "Rechazado";
      default:
        return estado;
    }
  }

  Future<void> responderSolicitud({
    required String solicitudId,
    required Map<String, dynamic> data,
  }) async {
    final respuestaController = TextEditingController(
      text: data['respuestaAdmin'] ?? '',
    );

    String estadoSeleccionado = data['estado'] ?? 'pendiente';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Responder solicitud"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: "Estado",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "pendiente",
                          child: Text("Pendiente"),
                        ),
                        DropdownMenuItem(
                          value: "en_revision",
                          child: Text("En revisión"),
                        ),
                        DropdownMenuItem(
                          value: "resuelto",
                          child: Text("Resuelto"),
                        ),
                        DropdownMenuItem(
                          value: "rechazado",
                          child: Text("Rechazado"),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          estadoSeleccionado = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: respuestaController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Respuesta al cliente",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Guardar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    await FirebaseFirestore.instance
        .collection('solicitudes_ayuda')
        .doc(solicitudId)
        .update({
      'estado': estadoSeleccionado,
      'respuestaAdmin': respuestaController.text.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Solicitud actualizada")),
    );
  }

Widget estadisticasSoporte() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('solicitudes_ayuda')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(height: 90);
      }

      final solicitudes = snapshot.data!.docs;

      int pendientes = 0;
      int revision = 0;
      int resueltos = 0;
      int rechazados = 0;

      for (final doc in solicitudes) {
        final data = doc.data() as Map<String, dynamic>;
        final estado = data['estado'] ?? 'pendiente';

        if (estado == 'pendiente') pendientes++;
        if (estado == 'en_revision') revision++;
        if (estado == 'resuelto') resueltos++;
        if (estado == 'rechazado') rechazados++;
      }

      return Row(
        children: [
          estadisticaCard(
            titulo: "Pend.",
            valor: pendientes.toString(),
            icono: Icons.pending_actions,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          estadisticaCard(
            titulo: "Revisión",
            valor: revision.toString(),
            icono: Icons.search,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          estadisticaCard(
            titulo: "Resueltos",
            valor: resueltos.toString(),
            icono: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          estadisticaCard(
            titulo: "Rechaz.",
            valor: rechazados.toString(),
            icono: Icons.cancel,
            color: Colors.red,
          ),
        ],
      );
    },
  );
}

Widget estadisticaCard({
  required String titulo,
  required String valor,
  required IconData icono,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    ),
  );
}


  Widget filtros() {
    return Column(
      children: [
        TextField(
          controller: buscarController,
          onChanged: (value) {
            setState(() {
              textoBusqueda = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Buscar por correo, tipo o motivo...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: filtroEstado,
          decoration: InputDecoration(
            labelText: "Filtrar por estado",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          items: const [
            DropdownMenuItem(value: "todos", child: Text("Todos")),
            DropdownMenuItem(value: "pendiente", child: Text("Pendiente")),
            DropdownMenuItem(value: "en_revision", child: Text("En revisión")),
            DropdownMenuItem(value: "resuelto", child: Text("Resuelto")),
            DropdownMenuItem(value: "rechazado", child: Text("Rechazado")),
          ],
          onChanged: (value) {
            setState(() {
              filtroEstado = value ?? "todos";
            });
          },
        ),
      ],
    );
  }

  Widget solicitudCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final correo = data['correo'] ?? 'Sin correo';
    final tipo = data['tipo'] ?? 'Solicitud';
    final motivo = data['motivo'] ?? '';
    final detalle = data['detalle'] ?? '';
    final estado = data['estado'] ?? 'pendiente';
    final respuesta = data['respuestaAdmin'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorEstado(estado).withValues(alpha: 0.12),
                child: Icon(
                  Icons.support_agent,
                  color: colorEstado(estado),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tipo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorEstado(estado).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  textoEstado(estado),
                  style: TextStyle(
                    color: colorEstado(estado),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            correo,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            motivo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            detalle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),

          if (respuesta.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Respuesta: $respuesta",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                responderSolicitud(
                  solicitudId: id,
                  data: data,
                );
              },
              icon: const Icon(Icons.reply, color: Colors.white),
              label: const Text(
                "Responder / Cambiar estado",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override

  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('solicitudes_ayuda')
        .orderBy('fechaRegistro', descending: true);

    if (filtroEstado != "todos") {
      query = FirebaseFirestore.instance
          .collection('solicitudes_ayuda')
          .where('estado', isEqualTo: filtroEstado)
          .orderBy('fechaRegistro', descending: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Mesa de Ayuda"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
  children: [
    estadisticasSoporte(),

    const SizedBox(height: 14),

    filtros(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar solicitudes"),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final solicitudes = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final correo =
                        (data['correo'] ?? '').toString().toLowerCase();
                    final tipo =
                        (data['tipo'] ?? '').toString().toLowerCase();
                    final motivo =
                        (data['motivo'] ?? '').toString().toLowerCase();
                    final detalle =
                        (data['detalle'] ?? '').toString().toLowerCase();

                    return correo.contains(textoBusqueda) ||
                        tipo.contains(textoBusqueda) ||
                        motivo.contains(textoBusqueda) ||
                        detalle.contains(textoBusqueda);
                  }).toList();

                  if (solicitudes.isEmpty) {
                    return const Center(
                      child: Text("No hay solicitudes registradas"),
                    );
                  }

                  return ListView.builder(
                    itemCount: solicitudes.length,
                    itemBuilder: (context, index) {
                      final doc = solicitudes[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return solicitudCard(
                        id: doc.id,
                        data: data,
                      );
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