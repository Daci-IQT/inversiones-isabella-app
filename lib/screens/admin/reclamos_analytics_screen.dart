import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReclamosAnalyticsScreen extends StatelessWidget {
  const ReclamosAnalyticsScreen({super.key});

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "en_revision":
        return Colors.blue;
      case "resuelto":
      case "resueltos":
        return Colors.green;
      case "rechazado":
      case "rechazados":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData iconoEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Icons.pending_actions;
      case "en_revision":
        return Icons.search;
      case "resuelto":
      case "resueltos":
        return Icons.check_circle;
      case "rechazado":
      case "rechazados":
        return Icons.cancel;
      default:
        return Icons.report_problem;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return "Pendiente";
      case "en_revision":
        return "En revisión";
      case "resuelto":
      case "resueltos":
        return "Resuelto";
      case "rechazado":
      case "rechazados":
        return "Rechazado";
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Análisis de Reclamos"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reclamosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar reclamos"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reclamos = snapshot.data!.docs;

          int pendientes = 0;
          int enRevision = 0;
          int resueltos = 0;
          int rechazados = 0;

          for (final doc in reclamos) {
            final data = doc.data() as Map<String, dynamic>;
            final estado = (data['estado'] ?? 'pendiente').toString();

            if (estado == "pendiente") {
              pendientes++;
            } else if (estado == "en_revision") {
              enRevision++;
            } else if (estado == "resuelto" || estado == "resueltos") {
              resueltos++;
            } else if (estado == "rechazado" || estado == "rechazados") {
              rechazados++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    resumenCard(
                      "Total",
                      reclamos.length.toString(),
                      Icons.report_problem,
                      Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Pendientes",
                      pendientes.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    resumenCard(
                      "En revisión",
                      enRevision.toString(),
                      Icons.search,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Resueltos",
                      resueltos.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                estadosReclamosCard(
                  pendientes: pendientes,
                  enRevision: enRevision,
                  resueltos: resueltos,
                  rechazados: rechazados,
                ),
                const SizedBox(height: 12),
                reclamosRecientesCard(reclamos),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget resumenCard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget estadosReclamosCard({
    required int pendientes,
    required int enRevision,
    required int resueltos,
    required int rechazados,
  }) {
    final estados = {
      "pendiente": pendientes,
      "en_revision": enRevision,
      "resuelto": resueltos,
      "rechazado": rechazados,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text(
                "Reclamos por estado",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...estados.entries.map((entry) {
            final color = colorEstado(entry.key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      iconoEstado(entry.key),
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(textoEstado(entry.key))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget reclamosRecientesCard(List<QueryDocumentSnapshot> reclamos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                "Reclamos recientes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reclamos.isEmpty) const Text("No hay reclamos registrados"),
          ...reclamos.take(8).map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final titulo = data['titulo'] ??
                data['motivo'] ??
                data['descripcion'] ??
                'Reclamo';
            final cliente = data['clienteNombre'] ?? data['usuarioNombre'] ?? 'Cliente';
            final estado = (data['estado'] ?? 'pendiente').toString();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorEstado(estado).withValues(alpha: 0.12),
                child: Icon(
                  iconoEstado(estado),
                  color: colorEstado(estado),
                ),
              ),
              title: Text(
                titulo.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(cliente.toString()),
              trailing: Text(
                textoEstado(estado),
                style: TextStyle(
                  color: colorEstado(estado),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}