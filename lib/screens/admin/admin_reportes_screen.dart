import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

///PANTALLA REPORTES ADMIN
///////////////////////////


class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final productosRef = FirebaseFirestore.instance.collection('productos');
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String filtroTiempo = "mes";

  bool estaEnFiltro(DateTime fecha) {
    final ahora = DateTime.now();

    if (filtroTiempo == "hoy") {
      return fecha.year == ahora.year &&
          fecha.month == ahora.month &&
          fecha.day == ahora.day;
    }

    if (filtroTiempo == "semana") {
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      return fecha.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
          fecha.isBefore(ahora.add(const Duration(days: 1)));
    }

    return fecha.year == ahora.year && fecha.month == ahora.month;
  }

  String nombreMesActual() {
    final meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];

    final ahora = DateTime.now();
    return "${meses[ahora.month - 1]} ${ahora.year}";
  }

  Widget filtroBoton(String texto, String valor) {
    final seleccionado = filtroTiempo == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          filtroTiempo = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget resumenCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icono, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget seccionCard({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget graficoVentas(Map<int, double> ventasPorDia) {
    final spots = ventasPorDia.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (spots.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("No hay ventas para mostrar")),
      );
    }

    final maxY = ventasPorDia.values.isEmpty
        ? 100.0
        : ventasPorDia.values.reduce((a, b) => a > b ? a : b) + 50;

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 31,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: primaryColor,
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withValues(alpha: 0.15),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget graficoTopProductos(Map<String, int> topProductos) {
    if (topProductos.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("No hay productos vendidos")),
      );
    }

    final entries = topProductos.entries.take(5).toList();

    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= entries.length) {
                    return const SizedBox();
                  }

                  final nombre = entries[index].key;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      nombre.length > 8 ? "${nombre.substring(0, 8)}..." : nombre,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: primaryColor,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget pedidoEstadoItem(String titulo, int cantidad, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            cantidad.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "confirmado":
        return Colors.blue;
      case "enviado":
        return Colors.purple;
      case "entregado":
        return Colors.green;
      case "cancelado":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
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

                      final pedidosFiltrados = pedidos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        if (data['fechaPedido'] == null) return false;

                        final fecha =
                            (data['fechaPedido'] as Timestamp).toDate();

                        return estaEnFiltro(fecha);
                      }).toList();

                      double ventasTotales = 0;
                      int pedidosTotales = pedidosFiltrados.length;

                      int pendientes = 0;
                      int confirmados = 0;
                      int enviados = 0;
                      int entregados = 0;
                      int cancelados = 0;

                      Map<int, double> ventasPorDia = {};
                      Map<String, int> productosVendidos = {};

                      for (final doc in pedidosFiltrados) {
                        final data = doc.data() as Map<String, dynamic>;
                        final estado = data['estado'] ?? 'pendiente';

                        if (estado == "pendiente") pendientes++;
                        if (estado == "confirmado") confirmados++;
                        if (estado == "enviado") enviados++;
                        if (estado == "entregado") entregados++;
                        if (estado == "cancelado") cancelados++;

                        if (estado == "entregado") {
                          final total = (data['total'] ?? 0).toDouble();
                          ventasTotales += total;

                          final fecha =
                              (data['fechaPedido'] as Timestamp).toDate();

                          ventasPorDia[fecha.day] =
                              (ventasPorDia[fecha.day] ?? 0) + total;

                          final productosPedido =
                              List<Map<String, dynamic>>.from(
                            data['productos'] ?? [],
                          );

                          for (final producto in productosPedido) {
                            final nombre = producto['nombre'] ?? 'Producto';
                            final cantidad = producto['cantidad'] ?? 0;

                            productosVendidos[nombre] =
                                (productosVendidos[nombre] ?? 0) +
                                    (cantidad as num).toInt();
                          }
                        }
                      }

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

                      final reclamosPendientes = reclamos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final estado = data['estado'] ?? 'pendiente';
                        return estado == 'pendiente' ||
                            estado == 'en_revision';
                      }).length;

                      final topProductosOrdenado = Map.fromEntries(
                        productosVendidos.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)),
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reportes",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Resumen ejecutivo de ventas y actividad del sistema.",
                              style: TextStyle(color: Colors.grey[600]),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      nombreMesActual(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                filtroBoton("HOY", "hoy"),
                                const SizedBox(width: 6),
                                filtroBoton("SEMANA", "semana"),
                                const SizedBox(width: 6),
                                filtroBoton("MES", "mes"),
                              ],
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Resumen General",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                              children: [
                                resumenCard(
                                  titulo: "Ventas Totales",
                                  valor:
                                      "S/ ${ventasTotales.toStringAsFixed(2)}",
                                  subtitulo: "Pedidos entregados",
                                  icono: Icons.payments,
                                  color: Colors.green,
                                ),
                                resumenCard(
                                  titulo: "Pedidos",
                                  valor: pedidosTotales.toString(),
                                  subtitulo: "Según filtro",
                                  icono: Icons.receipt_long,
                                  color: Colors.orange,
                                ),
                                resumenCard(
                                  titulo: "Clientes",
                                  valor: clientes.length.toString(),
                                  subtitulo: "Registrados",
                                  icono: Icons.people,
                                  color: Colors.blue,
                                ),
                                resumenCard(
                                  titulo: "Productos Activos",
                                  valor: productosActivos.toString(),
                                  subtitulo: "Disponibles",
                                  icono: Icons.inventory_2,
                                  color: primaryColor,
                                ),
                                resumenCard(
                                  titulo: "Bajo Stock",
                                  valor: bajoStock.toString(),
                                  subtitulo: "Stock menor a 4",
                                  icono: Icons.warning,
                                  color: Colors.red,
                                ),
                                resumenCard(
                                  titulo: "Reclamos",
                                  valor: reclamosPendientes.toString(),
                                  subtitulo: "Pendientes/revisión",
                                  icono: Icons.report_problem,
                                  color: Colors.deepOrange,
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            seccionCard(
                              titulo: "Evolución de Ventas",
                              child: graficoVentas(ventasPorDia),
                            ),

                            seccionCard(
                              titulo: "Top Productos",
                              child: graficoTopProductos(topProductosOrdenado),
                            ),

                            seccionCard(
                              titulo: "Pedidos por Estado",
                              child: Column(
                                children: [
                                  pedidoEstadoItem(
                                    "Pendientes",
                                    pendientes,
                                    colorEstado("pendiente"),
                                  ),
                                  pedidoEstadoItem(
                                    "Confirmados",
                                    confirmados,
                                    colorEstado("confirmado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Enviados",
                                    enviados,
                                    colorEstado("enviado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Entregados",
                                    entregados,
                                    colorEstado("entregado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Cancelados",
                                    cancelados,
                                    colorEstado("cancelado"),
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
              );
            },
          );
        },
      ),
    );
  }
}