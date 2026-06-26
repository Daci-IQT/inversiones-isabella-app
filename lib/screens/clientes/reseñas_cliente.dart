
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
/// PANTALLA MIS RESEÑAS CLIENTE
////////////////////////////////////////////

class MisResenasClienteScreen extends StatelessWidget {
  const MisResenasClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Cliente no autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      appBar: AppBar(
        title: const Text(
          "Mis reseñas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where('clienteId', isEqualTo: user.uid)
            .where('estado', isEqualTo: 'entregado')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          if (pedidos.isEmpty) {
            return const Center(
              child: Text(
                "Aún no tienes productos entregados para reseñar",
                textAlign: TextAlign.center,
              ),
            );
          }

          final List<Map<String, dynamic>> productos = [];

          for (final pedido in pedidos) {
            final data = pedido.data() as Map<String, dynamic>;
            final lista = List<Map<String, dynamic>>.from(data['productos'] ?? []);

            for (final producto in lista) {
              productos.add({
                ...producto,
                'pedidoId': pedido.id,
              });
            }
          }

          if (productos.isEmpty) {
            return const Center(
              child: Text("No hay productos para reseñar"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];

              final imagenUrl = producto['imagenUrl'] ?? '';
              final nombre = producto['nombre'] ?? 'Producto';
              final precio = double.tryParse(producto['precio'].toString()) ?? 0;
              final cantidad =
                  int.tryParse(producto['cantidad'].toString()) ?? 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
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
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imagenUrl.toString().isNotEmpty
                          ? Image.network(
                              imagenUrl,
                              width: 78,
                              height: 78,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 78,
                              height: 78,
                              color: primaryColor.withValues(alpha: 0.10),
                              child: Icon(
                                Icons.shopping_bag,
                                color: primaryColor,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cantidad comprada: $cantidad",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "S/ ${precio.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.star_border,
                      color: Colors.amber,
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