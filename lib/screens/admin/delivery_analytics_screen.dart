import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryAnalyticsScreen extends StatelessWidget {
  const DeliveryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
    final repartidoresRef = FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'repartidor');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Análisis Delivery"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pedidosRef.snapshots(),
        builder: (context, pedidosSnapshot) {
          if (!pedidosSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: repartidoresRef.snapshots(),
            builder: (context, repartidoresSnapshot) {
              if (!repartidoresSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final pedidos = pedidosSnapshot.data!.docs;
              final repartidores = repartidoresSnapshot.data!.docs;

              int asignados = 0;
              int enCamino = 0;
              int entregados = 0;
              int incidencias = 0;

              final Map<String, int> entregasPorRepartidor = {};
              final Map<String, String> nombresRepartidores = {};

              for (final doc in repartidores) {
                final data = doc.data() as Map<String, dynamic>;
                nombresRepartidores[doc.id] =
                    data['nombre'] ?? data['email'] ?? 'Repartidor';
              }

              for (final doc in pedidos) {
                final data = doc.data() as Map<String, dynamic>;

                final estadoEntrega =
                    (data['estadoEntrega'] ?? '').toString();
                final repartidorId =
                    (data['repartidorId'] ?? '').toString();

                if (estadoEntrega == "asignado") asignados++;
                if (estadoEntrega == "en_camino") enCamino++;
                if (estadoEntrega == "entregado") entregados++;
                if (estadoEntrega == "incidencia") incidencias++;

                if (estadoEntrega == "entregado" &&
                    repartidorId.isNotEmpty) {
                  entregasPorRepartidor[repartidorId] =
                      (entregasPorRepartidor[repartidorId] ?? 0) + 1;
                }
              }

              final ranking = entregasPorRepartidor.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        resumenCard(
                          "Repartidores",
                          repartidores.length.toString(),
                          Icons.delivery_dining,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        resumenCard(
                          "Asignados",
                          asignados.toString(),
                          Icons.assignment_ind,
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        resumenCard(
                          "En camino",
                          enCamino.toString(),
                          Icons.local_shipping,
                          Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        resumenCard(
                          "Entregados",
                          entregados.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        resumenCard(
                          "Incidencias",
                          incidencias.toString(),
                          Icons.report_problem,
                          Colors.red,
                        ),
                        const SizedBox(width: 8),
                        resumenCard(
                          "Total pedidos",
                          pedidos.length.toString(),
                          Icons.receipt_long,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    rankingRepartidoresCard(
                      ranking: ranking,
                      nombres: nombresRepartidores,
                    ),

                    const SizedBox(height: 12),

                    pedidosDeliveryRecientesCard(pedidos),
                  ],
                ),
              );
            },
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

  Widget rankingRepartidoresCard({
    required List<MapEntry<String, int>> ranking,
    required Map<String, String> nombres,
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
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                "Ranking de repartidores",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ranking.isEmpty)
            const Text("Aún no hay entregas registradas"),
          ...ranking.take(8).toList().asMap().entries.map((entry) {
            final index = entry.key + 1;
            final repartidorId = entry.value.key;
            final total = entry.value.value;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
                child: Text(
                  index.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                nombres[repartidorId] ?? 'Repartidor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                "$total entrega(s)",
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

  Widget pedidosDeliveryRecientesCard(List<QueryDocumentSnapshot> pedidos) {
    final deliveryPedidos = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['metodoEntrega'] ?? '') == 'delivery';
    }).take(8).toList();

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
                "Pedidos delivery recientes",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (deliveryPedidos.isEmpty)
            const Text("No hay pedidos delivery recientes"),
          ...deliveryPedidos.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cliente = data['clienteNombre'] ?? 'Cliente';
            final estadoEntrega =
                (data['estadoEntrega'] ?? 'pendiente').toString();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2F1),
                child: Icon(Icons.local_shipping, color: Colors.teal),
              ),
              title: Text(
                cliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("Estado: $estadoEntrega"),
              trailing: Text(
                "#${doc.id.substring(0, 6).toUpperCase()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }
}