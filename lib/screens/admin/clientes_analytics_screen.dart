import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientesAnalyticsScreen extends StatelessWidget {
  const ClientesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
    final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Análisis de Clientes"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usuariosRef.where('rol', isEqualTo: 'cliente').snapshots(),
        builder: (context, clientesSnapshot) {
          if (!clientesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: pedidosRef.snapshots(),
            builder: (context, pedidosSnapshot) {
              if (!pedidosSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final clientes = clientesSnapshot.data!.docs;
              final pedidos = pedidosSnapshot.data!.docs;

              final Map<String, int> pedidosPorCliente = {};
              final Map<String, double> comprasPorCliente = {};
              final Map<String, String> nombresClientes = {};

              for (final pedido in pedidos) {
                final data = pedido.data() as Map<String, dynamic>;

                final clienteId = (data['clienteId'] ?? data['usuarioId'] ?? '').toString();
                final clienteNombre = (data['clienteNombre'] ?? 'Cliente').toString();
                final total = double.tryParse((data['total'] ?? 0).toString()) ?? 0;

                if (clienteId.isEmpty) continue;

                pedidosPorCliente[clienteId] = (pedidosPorCliente[clienteId] ?? 0) + 1;
                comprasPorCliente[clienteId] = (comprasPorCliente[clienteId] ?? 0) + total;
                nombresClientes[clienteId] = clienteNombre;
              }

              final topPedidos = pedidosPorCliente.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final topCompras = comprasPorCliente.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        resumenCard(
                          "Clientes",
                          clientes.length.toString(),
                          Icons.people,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        resumenCard(
                          "Con pedidos",
                          pedidosPorCliente.length.toString(),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        resumenCard(
                          "Pedidos",
                          pedidos.length.toString(),
                          Icons.receipt_long,
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        resumenCard(
                          "Compras",
                          "S/ ${comprasPorCliente.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(2)}",
                          Icons.payments,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    topClientesCard(
                      titulo: "Clientes con más pedidos",
                      icono: Icons.emoji_events,
                      color: Colors.amber,
                      lista: topPedidos.take(8).map((e) {
                        return {
                          'nombre': nombresClientes[e.key] ?? 'Cliente',
                          'valor': "${e.value} pedido(s)",
                        };
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    topClientesCard(
                      titulo: "Clientes que más compran",
                      icono: Icons.workspace_premium,
                      color: Colors.green,
                      lista: topCompras.take(8).map((e) {
                        return {
                          'nombre': nombresClientes[e.key] ?? 'Cliente',
                          'valor': "S/ ${e.value.toStringAsFixed(2)}",
                        };
                      }).toList(),
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

  Widget topClientesCard({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Map<String, String>> lista,
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
          Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (lista.isEmpty)
            const Text("Aún no hay datos suficientes"),

          ...lista.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                item['nombre'] ?? 'Cliente',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                item['valor'] ?? '',
                style: TextStyle(
                  color: color,
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