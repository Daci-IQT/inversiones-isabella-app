import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




/// 📊 DASHBOARD PRINCIPAL
////////////////////////////////////////////////////////

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final productosRef = FirebaseFirestore.instance.collection('productos');
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  Widget dashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: productosRef.snapshots(),
      builder: (context, productosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: pedidosRef.snapshots(),
          builder: (context, pedidosSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: usuariosRef.where('rol', isEqualTo: 'cliente').snapshots(),
              builder: (context, clientesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: reclamosRef.snapshots(),
                  builder: (context, reclamosSnapshot) {
                    if (!productosSnapshot.hasData ||
                        !pedidosSnapshot.hasData ||
                        !clientesSnapshot.hasData ||
                        !reclamosSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productos = productosSnapshot.data!.docs;
                    final pedidos = pedidosSnapshot.data!.docs;
                    final clientes = clientesSnapshot.data!.docs;
                    final reclamos = reclamosSnapshot.data!.docs;

                    final productosActivos = productos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['activo'] ?? true;
                    }).length;

                    final bajoStock = productos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final stock = data['stock'] ?? 0;
                      final activo = data['activo'] ?? true;
                      return activo == true && stock < 4;
                    }).length;

                    final pedidosPendientes = pedidos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['estado'] == 'pendiente';
                    }).length;

                    final reclamosPendientes = reclamos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final estado = data['estado'] ?? 'pendiente';
                      return estado == 'pendiente' || estado == 'en_revision';
                    }).length;

                    double ventasEntregadas = 0;

                    for (final doc in pedidos) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['estado'] == 'entregado') {
                        ventasEntregadas += (data['total'] ?? 0).toDouble();
                      }
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Panel de Administración",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Resumen general de Inversiones Isabella",
                            style: TextStyle(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 25),

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.25,
                            children: [
                              dashboardCard(
                                title: "Productos activos",
                                value: productosActivos.toString(),
                                icon: Icons.inventory_2,
                                color: Colors.blue,
                              ),
                              dashboardCard(
                                title: "Pedidos pendientes",
                                value: pedidosPendientes.toString(),
                                icon: Icons.shopping_cart,
                                color: Colors.orange,
                              ),
                              dashboardCard(
                                title: "Clientes",
                                value: clientes.length.toString(),
                                icon: Icons.people,
                                color: Colors.green,
                              ),
                              dashboardCard(
                                title: "Bajo stock",
                                value: bajoStock.toString(),
                                icon: Icons.warning,
                                color: Colors.red,
                              ),
                              dashboardCard(
                                title: "Reclamos pendientes",
                                value: reclamosPendientes.toString(),
                                icon: Icons.report_problem,
                                color: Colors.deepOrange,
                              ),
                              dashboardCard(
                                title: "Ventas entregadas",
                                value: "S/ ${ventasEntregadas.toStringAsFixed(2)}",
                                icon: Icons.payments,
                                color: primaryColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            "Alertas importantes",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (bajoStock > 0)
                            activityItem(
                              icon: Icons.warning,
                              title: "Productos con bajo stock",
                              subtitle:
                                  "$bajoStock producto(s) tienen stock menor a 4.",
                              color: Colors.red,
                            ),

                          if (pedidosPendientes > 0)
                            activityItem(
                              icon: Icons.receipt_long,
                              title: "Pedidos pendientes",
                              subtitle:
                                  "$pedidosPendientes pedido(s) necesitan atención.",
                              color: Colors.orange,
                            ),

                          if (reclamosPendientes > 0)
                            activityItem(
                              icon: Icons.report_problem,
                              title: "Reclamos por atender",
                              subtitle:
                                  "$reclamosPendientes reclamo(s) están pendientes o en revisión.",
                              color: Colors.deepOrange,
                            ),

                          if (bajoStock == 0 &&
                              pedidosPendientes == 0 &&
                              reclamosPendientes == 0)
                            activityItem(
                              icon: Icons.check_circle,
                              title: "Todo está en orden",
                              subtitle:
                                  "No hay alertas importantes por atender.",
                              color: Colors.green,
                            ),

                          const SizedBox(height: 20),

                          const Text(
                            "Resumen rápido",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          activityItem(
                            icon: Icons.inventory,
                            title: "Productos registrados",
                            subtitle:
                                "Tienes ${productos.length} producto(s) registrados en total.",
                            color: Colors.blue,
                          ),

                          activityItem(
                            icon: Icons.shopping_bag,
                            title: "Pedidos registrados",
                            subtitle:
                                "Tienes ${pedidos.length} pedido(s) registrados en el sistema.",
                            color: Colors.purple,
                          ),

                          activityItem(
                            icon: Icons.people,
                            title: "Clientes registrados",
                            subtitle:
                                "Tienes ${clientes.length} cliente(s) registrados.",
                            color: Colors.green,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}