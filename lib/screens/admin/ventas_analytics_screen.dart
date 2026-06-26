import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasAnalyticsScreen extends StatelessWidget {
  const VentasAnalyticsScreen({super.key});

  double obtenerTotal(Map<String, dynamic> data) {
    return double.tryParse((data['total'] ?? 0).toString()) ?? 0;
  }

  bool esEntregado(Map<String, dynamic> data) {
    return data['estado'] == 'entregado';
  }

  @override
  Widget build(BuildContext context) {
    final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Análisis de Ventas"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pedidosRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          double ventasTotales = 0;
          int pedidosEntregados = 0;
          int pedidosCancelados = 0;
          int pedidosPendientes = 0;

          for (final doc in pedidos) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['estado'] == 'entregado') {
              ventasTotales += obtenerTotal(data);
              pedidosEntregados++;
            }

            if (data['estado'] == 'cancelado') {
              pedidosCancelados++;
            }

            if (data['estado'] == 'pendiente') {
              pedidosPendientes++;
            }
          }

          final ticketPromedio = pedidosEntregados > 0
              ? ventasTotales / pedidosEntregados
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    resumenCard(
                      "Ventas",
                      "S/ ${ventasTotales.toStringAsFixed(2)}",
                      Icons.payments,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Entregados",
                      pedidosEntregados.toString(),
                      Icons.check_circle,
                      Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    resumenCard(
                      "Pendientes",
                      pedidosPendientes.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Cancelados",
                      pedidosCancelados.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_bag,
                        color: Colors.purple,
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "S/ ${ticketPromedio.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Text("Ticket promedio"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                ventasRecientesCard(pedidos),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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

  Widget ventasRecientesCard(List<QueryDocumentSnapshot> pedidos) {
    final entregados = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['estado'] == 'entregado';
    }).toList();

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
              Icon(Icons.receipt_long, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Ventas recientes",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (entregados.isEmpty)
            const Text("No hay ventas entregadas todavía"),

          ...entregados.take(8).map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final cliente = data['clienteNombre'] ?? 'Cliente';
            final total = double.tryParse((data['total'] ?? 0).toString()) ?? 0;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.check, color: Colors.green),
              ),
              title: Text(
                cliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("Pedido #${doc.id.substring(0, 6).toUpperCase()}"),
              trailing: Text(
                "S/ ${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}