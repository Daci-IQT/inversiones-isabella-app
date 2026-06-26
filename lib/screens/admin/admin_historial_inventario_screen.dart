import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHistorialInventarioScreen extends StatelessWidget {
  const AdminHistorialInventarioScreen({super.key});

  Color colorMovimiento(String tipo) {
    switch (tipo) {
      case "crear":
        return Colors.green;
      case "editar":
        return Colors.blue;
      case "stock":
        return Colors.orange;
      case "duplicar":
        return Colors.purple;
      case "activar":
        return Colors.teal;
      case "inactivar":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData iconoMovimiento(String tipo) {
    switch (tipo) {
      case "crear":
        return Icons.add_circle;
      case "editar":
        return Icons.edit;
      case "stock":
        return Icons.inventory;
      case "duplicar":
        return Icons.copy;
      case "activar":
        return Icons.visibility;
      case "inactivar":
        return Icons.visibility_off;
      default:
        return Icons.history;
    }
  }

  String formatearFecha(dynamic fecha) {
    if (fecha == null) return "Sin fecha";

    final date = (fecha as Timestamp).toDate();

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('movimientos_inventario')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar historial"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movimientos = snapshot.data!.docs;

          if (movimientos.isEmpty) {
            return const Center(
              child: Text("Aún no hay movimientos de inventario"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final data = movimientos[index].data() as Map<String, dynamic>;

              final tipo = data['tipo'] ?? '';
              final color = colorMovimiento(tipo);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        iconoMovimiento(tipo),
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['productoNombre'] ?? 'Producto',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['descripcion'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Usuario: ${data['usuarioNombre'] ?? 'Administrador'}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatearFecha(data['fecha']),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}