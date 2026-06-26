import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class InventarioAnalyticsScreen extends StatelessWidget {
  const InventarioAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productosRef =
        FirebaseFirestore.instance.collection('productos');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          "Análisis de Inventario",
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: productosRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final productos = snapshot.data!.docs;

          int total = productos.length;
          int destacados = 0;
          int agotados = 0;
          int bajoStock = 0;

          double valorInventario = 0;

          for (final doc in productos) {
            final data =
                doc.data() as Map<String, dynamic>;

            final stock =
                int.tryParse(
                      data['stock'].toString(),
                    ) ??
                    0;

            final precio =
                double.tryParse(
                      data['precio'].toString(),
                    ) ??
                    0;

            final stockMinimo =
                int.tryParse(
                      (data['stockMinimo'] ?? 5)
                          .toString(),
                    ) ??
                    5;

            if (data['destacado'] == true) {
              destacados++;
            }

            if (stock <= 0) {
              agotados++;
            }

            if (stock > 0 &&
                stock <= stockMinimo) {
              bajoStock++;
            }

            valorInventario +=
                stock * precio;
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [

                Row(
                  children: [
                    resumenCard(
                      "Productos",
                      total.toString(),
                      Icons.inventory,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Destacados",
                      destacados.toString(),
                      Icons.star,
                      Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    resumenCard(
                      "Bajo Stock",
                      bajoStock.toString(),
                      Icons.warning,
                      Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    resumenCard(
                      "Agotados",
                      agotados.toString(),
                      Icons.remove_shopping_cart,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments,
                        size: 40,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "S/ ${valorInventario.toStringAsFixed(2)}",
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Valor total inventario",
                      ),
                    ],
                  ),
                ),
                
const SizedBox(height: 12),
productosPorCategoriaCard(productos),

const SizedBox(height: 12),
productosCriticosCard(productos),

const SizedBox(height: 12),
topProductosCard(productos),

const SizedBox(height: 12),
graficoCategoriasCard(productos),
const SizedBox(height: 12),

movimientosRecientesCard(),
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
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }

  Widget productosPorCategoriaCard(
  List<QueryDocumentSnapshot> productos,
) {
  final Map<String, int> categorias = {};

  for (final doc in productos) {
    final data = doc.data() as Map<String, dynamic>;

    final categoria =
        (data['categoriaNombre'] ?? 'Sin categoría').toString();

    categorias[categoria] = (categorias[categoria] ?? 0) + 1;
  }

  final lista = categorias.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

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
            Icon(Icons.category, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "Productos por categoría",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (lista.isEmpty)
          const Text("No hay categorías registradas"),

        ...lista.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.key,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.value.toString(),
                    style: const TextStyle(
                      color: Colors.blue,
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
Widget productosCriticosCard(
  List<QueryDocumentSnapshot> productos,
) {
  final criticos = productos.where((doc) {
    final data = doc.data() as Map<String, dynamic>;

    final stock = int.tryParse(data['stock'].toString()) ?? 0;
    final stockMinimo =
        int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;
    final activo = data['activo'] ?? true;

    return activo == true && stock <= stockMinimo;
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
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Productos críticos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (criticos.isEmpty)
          const Text("No hay productos críticos"),

        ...criticos.take(8).map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final nombre = data['nombre'] ?? 'Sin nombre';
          final stock = int.tryParse(data['stock'].toString()) ?? 0;
          final stockMinimo =
              int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: stock <= 0
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.red.withValues(alpha: 0.10),
              child: Icon(
                stock <= 0
                    ? Icons.remove_shopping_cart
                    : Icons.warning,
                color: stock <= 0 ? Colors.black : Colors.red,
              ),
            ),
            title: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("Mínimo: $stockMinimo"),
            trailing: Text(
              stock <= 0 ? "Agotado" : "Stock: $stock",
              style: TextStyle(
                color: stock <= 0 ? Colors.black : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ],
    ),
  );
}
Widget topProductosCard(
  List<QueryDocumentSnapshot> productos,
) {
  final lista = productos.toList();

  lista.sort((a, b) {
    final stockA = int.tryParse(
          (a.data() as Map<String, dynamic>)['stock']
              .toString(),
        ) ??
        0;

    final stockB = int.tryParse(
          (b.data() as Map<String, dynamic>)['stock']
              .toString(),
        ) ??
        0;

    return stockB.compareTo(stockA);
  });

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
            Icon(Icons.emoji_events,
                color: Colors.amber),
            SizedBox(width: 8),
            Text(
              "Top productos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ...lista.take(5).toList().asMap().entries.map((entry) {
          final posicion = entry.key + 1;
          final data =
              entry.value.data() as Map<String, dynamic>;

          final nombre =
              data['nombre'] ?? 'Sin nombre';

          final stock = int.tryParse(
                data['stock'].toString(),
              ) ??
              0;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor:
                  Colors.amber.withValues(alpha: 0.15),
              child: Text(
                posicion.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.green
                    .withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                "$stock und.",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
Widget graficoCategoriasCard(
  List<QueryDocumentSnapshot> productos,
) {
  final Map<String, int> categorias = {};

  for (final doc in productos) {
    final data = doc.data() as Map<String, dynamic>;
    final categoria = (data['categoriaNombre'] ?? 'Sin categoría').toString();

    categorias[categoria] = (categorias[categoria] ?? 0) + 1;
  }

  final lista = categorias.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (lista.isEmpty) {
    return const SizedBox();
  }

  final maxValor = lista.first.value.toDouble();

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
            Icon(Icons.bar_chart, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              "Gráfico por categoría",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: maxValor + 2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= lista.length) {
                        return const SizedBox();
                      }

                      final nombre = lista[index].key;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            nombre.length > 10
                                ? "${nombre.substring(0, 10)}..."
                                : nombre,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: lista.asMap().entries.map((entry) {
                final index = entry.key;
                final cantidad = entry.value.value;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: cantidad.toDouble(),
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.indigo,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}
Widget movimientosRecientesCard() {
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
              "Movimientos recientes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('movimientos_inventario')
              .orderBy('fecha', descending: true)
              .limit(6)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final movimientos = snapshot.data!.docs;

            if (movimientos.isEmpty) {
              return const Text("No hay movimientos recientes");
            }

            return Column(
              children: movimientos.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final tipo = data['tipo'] ?? '';
                final producto = data['productoNombre'] ?? 'Producto';
                final descripcion = data['descripcion'] ?? '';
                final usuario = data['usuarioNombre'] ?? 'Administrador';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorMovimiento(tipo).withValues(alpha: 0.12),
                    child: Icon(
                      iconoMovimiento(tipo),
                      color: colorMovimiento(tipo),
                    ),
                  ),
                  title: Text(
                    producto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "$descripcion\n$usuario",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}
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


}