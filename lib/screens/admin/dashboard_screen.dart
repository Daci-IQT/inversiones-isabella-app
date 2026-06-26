import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventario_analytics_screen.dart';
import 'ventas_analytics_screen.dart';
import 'pedidos_analytics_screen.dart';
import 'clientes_analytics_screen.dart';
import 'delivery_analytics_screen.dart';
import 'reclamos_analytics_screen.dart';


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
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: Colors.grey[500],
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
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
            backgroundColor: color.withValues(alpha: 0.12),
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

  final stock = int.tryParse(data['stock'].toString()) ?? 0;
  final stockMinimo =
      int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;
  final activo = data['activo'] ?? true;

  return activo == true && stock > 0 && stock <= stockMinimo;
}).length;

final productosAgotados = productos.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  final stock = int.tryParse(data['stock'].toString()) ?? 0;
  final activo = data['activo'] ?? true;

  return activo == true && stock <= 0;
}).length;

double valorInventario = 0;

for (final doc in productos) {
  final data = doc.data() as Map<String, dynamic>;

  final stock = int.tryParse(data['stock'].toString()) ?? 0;
  final precio = double.tryParse(data['precio'].toString()) ?? 0;
  final activo = data['activo'] ?? true;

  if (activo) {
    valorInventario += stock * precio;
  }
}
                    final pedidosPendientes = pedidos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['estado'] == 'pendiente';
                    }).length;

                    final reclamosPendientes = reclamos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final estado = data['estado'] ?? 'pendiente';
                      return estado == 'pendiente' || estado == 'en_revision';
                    }).length;
                    final deliveryPendientes = pedidos.where((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return (data['metodoEntrega'] ?? '') == 'delivery' &&
      (data['estadoEntrega'] ?? '') == 'asignado';
}).length;

final deliveryEnCamino = pedidos.where((doc) {
  final data = doc.data() as Map<String, dynamic>;
  return (data['metodoEntrega'] ?? '') == 'delivery' &&
      (data['estadoEntrega'] ?? '') == 'en_camino';
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
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  childAspectRatio: 1.20,
  children: [
    dashboardCard(
      title: "Delivery",
      value: deliveryPendientes.toString(),
      subtitle: "$deliveryEnCamino en camino",
      icon: Icons.local_shipping,
      color: Colors.blue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DeliveryAnalyticsScreen(),
          ),
        );
      },
    ),

    dashboardCard(
      title: "Pedidos",
      value: pedidosPendientes.toString(),
      subtitle: "Pendientes por atender",
      icon: Icons.shopping_cart,
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PedidosAnalyticsScreen(),
          ),
        );
      },
    ),

    dashboardCard(
      title: "Clientes",
      value: clientes.length.toString(),
      subtitle: "Clientes registrados",
      icon: Icons.people,
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClientesAnalyticsScreen(),
          ),
        );
      },
    ),

    dashboardCard(
      title: "Bajo stock",
      value: bajoStock.toString(),
      subtitle: "Necesitan reposición",
      icon: Icons.warning,
      color: Colors.amber,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventarioAnalyticsScreen(),
          ),
        );
      },
    ),

    dashboardCard(
      title: "Reclamos",
      value: reclamosPendientes.toString(),
      subtitle: "Pendientes o en revisión",
      icon: Icons.report_problem,
      color: Colors.red,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReclamosAnalyticsScreen(),
          ),
        );
      },
    ),

    dashboardCard(
      title: "Ventas",
      value: "S/ ${ventasEntregadas.toStringAsFixed(0)}",
      subtitle: "Ventas entregadas",
      icon: Icons.payments,
      color: primaryColor,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VentasAnalyticsScreen(),
          ),
        );
      },
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