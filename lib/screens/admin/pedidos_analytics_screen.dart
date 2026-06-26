import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidosAnalyticsScreen extends StatelessWidget {
  const PedidosAnalyticsScreen({super.key});

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "confirmado":
      case "confirmados":
        return Colors.blue;
      case "en_proceso":
        return Colors.purple;
      case "enviado":
      case "enviados":
        return Colors.teal;
      case "entregado":
      case "entregados":
        return Colors.green;
      case "cancelado":
      case "cancelados":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData iconoEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Icons.pending_actions;
      case "confirmado":
      case "confirmados":
        return Icons.verified;
      case "en_proceso":
        return Icons.sync;
      case "enviado":
      case "enviados":
        return Icons.local_shipping;
      case "entregado":
      case "entregados":
        return Icons.check_circle;
      case "cancelado":
      case "cancelados":
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return "Pendientes";
      case "confirmado":
      case "confirmados":
        return "Confirmados";
      case "en_proceso":
        return "En proceso";
      case "enviado":
      case "enviados":
        return "Enviados";
      case "entregado":
      case "entregados":
        return "Entregados";
      case "cancelado":
      case "cancelados":
        return "Cancelados";
      default:
        return estado;
    }
  }

  double obtenerTotal(Map<String, dynamic> data) {
    return double.tryParse((data['total'] ?? 0).toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Análisis de Pedidos"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pedidosRef.orderBy('fechaPedido', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar pedidos"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          int pendientes = 0;
          int confirmados = 0;
          int enProceso = 0;
          int enviados = 0;
          int entregados = 0;
          int cancelados = 0;
          int delivery = 0;
          int recojo = 0;

          double montoPendiente = 0;
          double montoEntregado = 0;

          for (final doc in pedidos) {
            final data = doc.data() as Map<String, dynamic>;

            final estado = (data['estado'] ?? 'pendiente').toString();
            final metodoEntrega = (data['metodoEntrega'] ?? '').toString();
            final total = obtenerTotal(data);

            if (estado == "pendiente") {
              pendientes++;
              montoPendiente += total;
            } else if (estado == "confirmado" || estado == "confirmados") {
              confirmados++;
            } else if (estado == "en_proceso") {
              enProceso++;
            } else if (estado == "enviado" || estado == "enviados") {
              enviados++;
            } else if (estado == "entregado" || estado == "entregados") {
              entregados++;
              montoEntregado += total;
            } else if (estado == "cancelado" || estado == "cancelados") {
              cancelados++;
            }

            if (metodoEntrega == "delivery") {
              delivery++;
            } else {
              recojo++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    resumenCard(
                      "Pedidos",
                      pedidos.length.toString(),
                      Icons.receipt_long,
                      Colors.blue,
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
                      "Entregados",
                      entregados.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Cancelados",
                      cancelados.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                valorPedidosCard(
                  montoEntregado: montoEntregado,
                  montoPendiente: montoPendiente,
                ),

                const SizedBox(height: 12),

                estadosPedidosCard(
                  pendientes: pendientes,
                  confirmados: confirmados,
                  enProceso: enProceso,
                  enviados: enviados,
                  entregados: entregados,
                  cancelados: cancelados,
                ),

                const SizedBox(height: 12),

                metodoEntregaCard(
                  delivery: delivery,
                  recojo: recojo,
                ),

                const SizedBox(height: 12),

                pedidosRecientesCard(pedidos),
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

  Widget valorPedidosCard({
    required double montoEntregado,
    required double montoPendiente,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.payments, color: Colors.green, size: 38),
          const SizedBox(height: 8),
          Text(
            "S/ ${montoEntregado.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.green,
            ),
          ),
          const Text("Monto entregado"),
          const SizedBox(height: 8),
          Text(
            "Pendiente por atender: S/ ${montoPendiente.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget estadosPedidosCard({
    required int pendientes,
    required int confirmados,
    required int enProceso,
    required int enviados,
    required int entregados,
    required int cancelados,
  }) {
    final estados = {
      "pendiente": pendientes,
      "confirmados": confirmados,
      "en_proceso": enProceso,
      "enviados": enviados,
      "entregados": entregados,
      "cancelados": cancelados,
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
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Pedidos por estado",
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

  Widget metodoEntregaCard({
    required int delivery,
    required int recojo,
  }) {
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
              Icon(Icons.local_shipping, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                "Método de entrega",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: resumenMini(
                  "Delivery",
                  delivery.toString(),
                  Icons.delivery_dining,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: resumenMini(
                  "Recojo",
                  recojo.toString(),
                  Icons.store,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget resumenMini(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(titulo),
        ],
      ),
    );
  }

  Widget pedidosRecientesCard(List<QueryDocumentSnapshot> pedidos) {
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
                "Pedidos recientes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pedidos.isEmpty) const Text("No hay pedidos registrados"),
          ...pedidos.take(8).map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final cliente = data['clienteNombre'] ?? 'Cliente';
            final estado = (data['estado'] ?? 'pendiente').toString();
            final total = obtenerTotal(data);

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
                cliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("Pedido #${doc.id.substring(0, 6).toUpperCase()}"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "S/ ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    textoEstado(estado),
                    style: TextStyle(
                      color: colorEstado(estado),
                      fontSize: 11,
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
}