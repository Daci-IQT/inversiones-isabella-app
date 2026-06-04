import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:path_provider/path_provider.dart';

import 'package:open_filex/open_filex.dart';

import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';


/// PANTALLA PEDIDOS CLIENTE
////////////////////////////////////////////

class PedidosClienteScreen extends StatefulWidget {
  const PedidosClienteScreen({super.key});

  @override
  State<PedidosClienteScreen> createState() => _PedidosClienteScreenState();
}

class _PedidosClienteScreenState extends State<PedidosClienteScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String filtroSeleccionado = "todos";

  final List<String> filtros = [
  "todos",
  "pendiente",
  "confirmado",
  "enviado",
  "entregado",
  "cancelado",
];

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    try {
      final DateTime fecha = (timestamp as Timestamp).toDate();

      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year}";
    } catch (e) {
      return "Sin fecha";
    }
  }

  Color colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "confirmado":
        return Colors.blue;
      case "enviado":
      case "en proceso":
        return Colors.orange;
      case "entregado":
        return Colors.green;
      case "cancelado":
        return Colors.red;
      default:
        return primaryColor;
    }
  }

  IconData iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "confirmado":
        return Icons.verified_outlined;
      case "enviado":
      case "en proceso":
        return Icons.local_shipping_outlined;
      case "entregado":
        return Icons.check_circle_outline;
      case "cancelado":
        return Icons.cancel_outlined;
      default:
        return Icons.pending_actions_outlined;
    }
  }

  String textoFiltro(String filtro) {
    switch (filtro) {
      case "todos":
        return "Todos";
      case "pendiente": 
      return "Pendientes";
      case "confirmado":
        return "Confirmados";
      case "enviado":
        return "Enviados";
      case "entregado":
        return "Entregados";
      case "cancelado":
        return "Cancelados";
      default:
        return filtro;
    }
  }

  double obtenerSubtotal(Map<String, dynamic> producto) {
    final cantidad = int.tryParse(producto['cantidad'].toString()) ?? 1;
    final precio = double.tryParse(producto['precio'].toString()) ?? 0;
    return cantidad * precio;
  }

  void abrirDetallePedido({
    required String pedidoId,
    required Map<String, dynamic> data,
  }) {
    final estado = (data['estado'] ?? 'pendiente').toString().toLowerCase();
    final productos = List<Map<String, dynamic>>.from(data['productos'] ?? []);

    if (estado == "entregado") {
      abrirBoletaPedido(
        pedidoId: pedidoId,
        data: data,
        productos: productos,
      );
    } else {
      abrirProductosPedido(
        pedidoId: pedidoId,
        data: data,
        productos: productos,
      );
    }
  }

  void abrirProductosPedido({
    required String pedidoId,
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> productos,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.55,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  "Detalle del pedido #${pedidoId.substring(0, 6)}",
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Estado: ${data['estado'] ?? 'pendiente'}",
                  style: TextStyle(
                    color: colorEstado(data['estado'] ?? 'pendiente'),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                ...productos.map((producto) {
                  final imagenUrl = producto['imagenUrl'] ?? '';
                  final nombre = producto['nombre'] ?? 'Producto';
                  final cantidad =
                      int.tryParse(producto['cantidad'].toString()) ?? 1;
                  final precio =
                      double.tryParse(producto['precio'].toString()) ?? 0;
                  final subtotal = obtenerSubtotal(producto);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imagenUrl.toString().isNotEmpty
                              ? Image.network(
                                  imagenUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: primaryColor.withOpacity(0.10),
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
                                ),
                              ),
                              const SizedBox(height: 4),

                              if (producto['colorSeleccionado'] != null ||
                                  producto['tallaSeleccionada'] != null)
                                Text(
                                  "${producto['colorSeleccionado'] != null ? 'Color: ${producto['colorSeleccionado']}' : ''}"
                                  "${producto['colorSeleccionado'] != null && producto['tallaSeleccionada'] != null ? ' | ' : ''}"
                                  "${producto['tallaSeleccionada'] != null ? 'Talla: ${producto['tallaSeleccionada']}' : ''}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),

                              const SizedBox(height: 4),

                              Text(
                                "Cantidad: $cantidad",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),

                              Text(
                                "Precio: S/ ${precio.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          "S/ ${subtotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),

                resumenPedido(data),

                const SizedBox(height: 25),
              ],
            );
          },
        );
      },
    );
  }

  void abrirBoletaPedido({
    required String pedidoId,
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> productos,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F3F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          maxChildSize: 0.96,
          minChildSize: 0.70,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "INVERSIONES ISABELLA",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Boleta de venta electrónica",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Orden: #${pedidoId.substring(0, 8).toUpperCase()}",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 30),

                      const Text(
                        "Datos de la empresa",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      itemBoleta("Empresa", "Inversiones Isabella"),
                      itemBoleta("RUC", "No registrado"),
                      itemBoleta("Dirección", "Iquitos, Loreto, Perú"),
                      itemBoleta("Correo", "ventas@inversionesisabella.com"),

                      const Divider(height: 30),

                      const Text(
                        "Datos del cliente",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      itemBoleta("Cliente", data['clienteNombre'] ?? 'Cliente'),
                      itemBoleta("Correo", data['clienteCorreo'] ?? ''),
                      itemBoleta("Celular", data['clienteCelular'] ?? ''),
                      itemBoleta("Dirección", data['clienteDireccion'] ?? ''),

                      const Divider(height: 30),

                      const Text(
                        "Detalle de productos",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ...productos.map((producto) {
                        final nombre = producto['nombre'] ?? 'Producto';
                        final cantidad =
                            int.tryParse(producto['cantidad'].toString()) ?? 1;
                        
                        final subtotal = obtenerSubtotal(producto);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "$cantidad x $nombre",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                "S/ ${subtotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const Divider(height: 30),

                      resumenBoleta(data, productos),

                      const SizedBox(height: 18),

                      Column(
  children: [
    SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          descargarBoletaPDF(
            pedidoId: pedidoId,
            data: data,
            productos: productos,
          );
        },
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text(
          "Descargar boleta PDF",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),

    const SizedBox(height: 10),

    SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          compartirBoletaPDF(
            pedidoId: pedidoId,
            data: data,
            productos: productos,
          );
        },
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text(
          "Compartir PDF",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),

    const SizedBox(height: 10),

    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              compartirPorWhatsApp(
                pedidoId: pedidoId,
                data: data,
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text("WhatsApp"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              enviarBoletaPorCorreo(
                pedidoId: pedidoId,
                data: data,
              );
            },
            icon: const Icon(Icons.email),
            label: const Text("Correo"),
          ),
        ),
      ],
    ),
  ],
),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }



pw.Widget filaPdf(String titulo, String valor, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(titulo),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

Future<File> generarBoletaPDF({
  required String pedidoId,
  required Map<String, dynamic> data,
  required List<Map<String, dynamic>> productos,
}) async {
  final pdf = pw.Document();

  const empresaNombre = "INVERSIONES ISABELLA";
  const empresaRuc = "RUC: 00000000000";
  const empresaDireccion = "Iquitos, Loreto, Perú";
  const empresaTelefono = "Teléfono: 999 999 999";

  final codigoPedido = pedidoId.substring(0, 8).toUpperCase();
  final qrTexto =
      "Empresa: $empresaNombre\nPedido: $codigoPedido\nCliente: ${data['clienteNombre'] ?? ''}\nTotal: S/ ${data['total'] ?? 0}";

  double subtotal = 0;

  for (final p in productos) {
    final cantidad = int.tryParse(p['cantidad'].toString()) ?? 1;
    final precio = double.tryParse(p['precio'].toString()) ?? 0;
    subtotal += cantidad * precio;
  }

  final igv = subtotal * 0.18;
  final total = double.tryParse(data['total'].toString()) ?? subtotal;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 70,
                height: 70,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Center(
                  child: pw.Text(
                    "LOGO",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      empresaNombre,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(empresaRuc),
                    pw.Text(empresaDireccion),
                    pw.Text(empresaTelefono),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      "BOLETA DE VENTA",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("B001-$codigoPedido"),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          "DATOS DEL CLIENTE",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(),
        pw.Text("Cliente: ${data['clienteNombre'] ?? ''}"),
        pw.Text("DNI: ${data['clienteDni'] ?? 'No registrado'}"),
        pw.Text("Correo: ${data['clienteCorreo'] ?? ''}"),
        pw.Text("Celular: ${data['clienteCelular'] ?? ''}"),
        pw.Text("Dirección: ${data['clienteDireccion'] ?? ''}"),

        pw.SizedBox(height: 20),

        pw.Text(
          "DETALLE DEL PEDIDO",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text("Producto"),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text("Cant."),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text("Precio"),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text("Subtotal"),
                ),
              ],
            ),
            ...productos.map((p) {
              final cantidad = int.tryParse(p['cantidad'].toString()) ?? 1;
              final precio = double.tryParse(p['precio'].toString()) ?? 0;
              final sub = cantidad * precio;

              final detalleExtra =
                  "${p['colorSeleccionado'] != null ? ' Color: ${p['colorSeleccionado']}' : ''}"
                  "${p['tallaSeleccionada'] != null ? ' Talla: ${p['tallaSeleccionada']}' : ''}";

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text("${p['nombre'] ?? 'Producto'}$detalleExtra"),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text("$cantidad"),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text("S/ ${precio.toStringAsFixed(2)}"),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text("S/ ${sub.toStringAsFixed(2)}"),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 20),

        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 230,
            child: pw.Column(
              children: [
                filaPdf("Subtotal", "S/ ${subtotal.toStringAsFixed(2)}"),
                filaPdf("IGV 18%", "S/ ${igv.toStringAsFixed(2)}"),
                filaPdf("Total", "S/ ${total.toStringAsFixed(2)}", bold: true),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 25),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrTexto,
              width: 90,
              height: 90,
            ),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: codigoPedido,
              width: 180,
              height: 60,
            ),
          ],
        ),

        pw.SizedBox(height: 35),

        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                width: 180,
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 5),
              pw.Text("Firma / conformidad"),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Center(
          child: pw.Text(
            "Representación impresa de la boleta electrónica",
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );

  final directory = await getApplicationDocumentsDirectory();
  final file = File("${directory.path}/boleta_$codigoPedido.pdf");

  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<void> descargarBoletaPDF({
  required String pedidoId,
  required Map<String, dynamic> data,
  required List<Map<String, dynamic>> productos,
}) async {
  final file = await generarBoletaPDF(
    pedidoId: pedidoId,
    data: data,
    productos: productos,
  );

  await OpenFilex.open(file.path);
}

Future<void> compartirBoletaPDF({
  required String pedidoId,
  required Map<String, dynamic> data,
  required List<Map<String, dynamic>> productos,
}) async {
  final file = await generarBoletaPDF(
    pedidoId: pedidoId,
    data: data,
    productos: productos,
  );

  await Share.shareXFiles(
    [XFile(file.path)],
    text: "Boleta de compra - Inversiones Isabella",
  );
}

Future<void> enviarBoletaPorCorreo({
  required String pedidoId,
  required Map<String, dynamic> data,
}) async {
  final correo = data['clienteCorreo'] ?? '';

  final uri = Uri(
    scheme: 'mailto',
    path: correo,
    query: 'subject=Boleta de compra Inversiones Isabella&body=Adjunto mi boleta de compra.',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> compartirPorWhatsApp({
  required String pedidoId,
  required Map<String, dynamic> data,
}) async {
  final codigo = pedidoId.substring(0, 8).toUpperCase();
  final mensaje =
      "Hola, comparto mi boleta de compra de Inversiones Isabella. Pedido: #$codigo";

  final uri = Uri.parse(
    "https://wa.me/?text=${Uri.encodeComponent(mensaje)}",
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
  Widget resumenPedido(Map<String, dynamic> data) {
    final total = double.tryParse(data['total'].toString()) ?? 0;
    final metodoPago = data['metodoPago'] ?? 'No definido';
    final estadoPago = data['estadoPago'] ?? 'pendiente';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          filaResumen("Método de pago", metodoPago.toString()),
          filaResumen("Estado de pago", estadoPago.toString()),
          filaResumen("Total", "S/ ${total.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget resumenBoleta(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> productos,
  ) {
    double subtotal = 0;

    for (final producto in productos) {
      subtotal += obtenerSubtotal(producto);
    }

    final total = double.tryParse(data['total'].toString()) ?? subtotal;

    return Column(
      children: [
        filaResumen("Subtotal", "S/ ${subtotal.toStringAsFixed(2)}"),
        filaResumen("Descuento", "S/ 0.00"),
        filaResumen("Total", "S/ ${total.toStringAsFixed(2)}"),
      ],
    );
  }

  Widget filaResumen(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget itemBoleta(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              "$titulo:",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor.isEmpty ? "No registrado" : valor,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget estadoItem(
    String titulo,
    String valor,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            valor.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget chipFiltro(String filtro) {
    final seleccionado = filtroSeleccionado == filtro;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(textoFiltro(filtro)),
        selected: seleccionado,
        selectedColor: primaryColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: seleccionado ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          setState(() {
            filtroSeleccionado = filtro;
          });
        },
      ),
    );
  }

  Widget pedidoCard(String pedidoId, Map<String, dynamic> data) {
    final estado = data['estado'] ?? 'pendiente';
    final estadoPago = data['estadoPago'] ?? 'pendiente';
    final metodoPago = data['metodoPago'] ?? 'No definido';
    final total = double.tryParse(data['total'].toString()) ?? 0;
    final fecha = data['fechaPedido'];
    final fechaEntrega = data['fechaEntrega'];

    final entregado = estado.toString().toLowerCase() == "entregado";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorEstado(estado).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconoEstado(estado),
                  color: colorEstado(estado),
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pedido #${pedidoId.substring(0, 6).toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Fecha: ${formatearFecha(fecha)}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if (entregado) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Entregado: ${formatearFecha(fechaEntrega)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Text(
                "S/ ${total.toStringAsFixed(2)}",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: estadoItem(
                  "Estado",
                  estado.toString(),
                  colorEstado(estado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: estadoItem(
                  "Pago",
                  estadoPago.toString(),
                  estadoPago == 'pagado' ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.payments, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Método de pago: $metodoPago",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: entregado ? Colors.green : primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                abrirDetallePedido(
                  pedidoId: pedidoId,
                  data: data,
                );
              },
              icon: Icon(
                entregado
                    ? Icons.receipt_long
                    : Icons.remove_red_eye_outlined,
                color: Colors.white,
              ),
              label: Text(
                entregado ? "Ver boleta" : "Ver detalles",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Cliente no autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Mis pedidos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: primaryColor,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filtros.map(chipFiltro).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('clienteId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error al cargar pedidos:\n${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> pedidos =
                    List<QueryDocumentSnapshot>.from(snapshot.data!.docs);

                pedidos.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final fechaA = dataA['fechaPedido'];
                  final fechaB = dataB['fechaPedido'];

                  if (fechaA == null || fechaB == null) return 0;

                  return (fechaB as Timestamp).compareTo(fechaA as Timestamp);
                });

                if (filtroSeleccionado != "todos") {
                  pedidos = pedidos.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final estado =
                        (data['estado'] ?? 'pendiente').toString().toLowerCase();

                    if (filtroSeleccionado == "enviado") {
                      return estado == "enviado" || estado == "en proceso";
                    }

                    return estado == filtroSeleccionado;
                  }).toList();
                }

                if (pedidos.isEmpty) {
                  return Center(
                    child: Text(
                      filtroSeleccionado == "todos"
                          ? "Aún no tienes pedidos registrados"
                          : "No tienes pedidos ${textoFiltro(filtroSeleccionado).toLowerCase()}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final doc = pedidos[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return pedidoCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
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
                      color: Colors.black.withOpacity(0.06),
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
                              color: primaryColor.withOpacity(0.10),
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
/////////////////////////////////
///PANTALLA PEDIDOS ADMIN
////////////////////////////////////

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

  final buscadorController = TextEditingController();

  String textoBusqueda = "";
  String estadoFiltro = "todos";

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final List<String> estados = [
    "pendiente",
    "confirmado",
    "enviado",
    "entregado",
    "cancelado",
  ];

  Future<void> cambiarEstadoPedido(String pedidoId, String nuevoEstado) async {
    await pedidosRef.doc(pedidoId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pedido actualizado a $nuevoEstado"),
        ),
      );
    }
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

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    final DateTime fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year} "
        "${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}";
  }

  Widget etiquetaEstado(String estado) {
    final color = colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filtrosPedidos() {
    return Column(
      children: [
        TextField(
          controller: buscadorController,
          onChanged: (value) {
            setState(() {
              textoBusqueda = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: "Buscar por cliente, correo o código de pedido...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: buscadorController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      buscadorController.clear();
                      setState(() {
                        textoBusqueda = "";
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: estadoFiltro,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Filtrar por estado",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "todos",
              child: Text("Todos los pedidos"),
            ),
            DropdownMenuItem(
              value: "pendiente",
              child: Text("Pendientes"),
            ),
            DropdownMenuItem(
              value: "confirmado",
              child: Text("Confirmados"),
            ),
            DropdownMenuItem(
              value: "enviado",
              child: Text("Enviados"),
            ),
            DropdownMenuItem(
              value: "entregado",
              child: Text("Entregados"),
            ),
            DropdownMenuItem(
              value: "cancelado",
              child: Text("Cancelados"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              estadoFiltro = value ?? "todos";
            });
          },
        ),
      ],
    );
  }

  void mostrarDetallePedido({
    required String pedidoId,
    required Map<String, dynamic> pedido,
  }) {
    final productos = List<Map<String, dynamic>>.from(
      pedido['productos'] ?? [],
    );

    final estadoActual = pedido['estado'] ?? 'pendiente';

    showDialog(
      context: context,
      builder: (_) {
        String estadoTemporal = estadoActual;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Detalle del pedido",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Código: $pedidoId",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Cliente: ${pedido['clienteNombre'] ?? 'Sin nombre'}",
                            ),
                            Text(
                              "Correo: ${pedido['clienteCorreo'] ?? 'Sin correo'}",
                            ),
                            Text(
                              "Fecha: ${formatearFecha(pedido['fechaPedido'])}",
                            ),

                            const SizedBox(height: 12),

                            etiquetaEstado(estadoTemporal),

                            const SizedBox(height: 18),

                            DropdownButtonFormField<String>(
                              value: estadoTemporal,
                              decoration: const InputDecoration(
                                labelText: "Cambiar estado del pedido",
                                border: OutlineInputBorder(),
                              ),
                              items: estados.map((estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(estado.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  estadoTemporal = value ?? estadoTemporal;
                                });
                              },
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              "Productos del pedido",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (productos.isEmpty)
                              const Text("Este pedido no tiene productos."),

                            ...productos.map((producto) {
                              final imagenUrl = producto['imagenUrl'] ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: imagenUrl.toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            imagenUrl,
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor:
                                              primaryColor.withOpacity(0.12),
                                          child: Icon(
                                            Icons.shopping_bag,
                                            color: primaryColor,
                                          ),
                                        ),
                                  title: Text(
                                    producto['nombre'] ?? 'Producto',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Cantidad: ${producto['cantidad'] ?? 0}",
                                      ),
                                      Text(
                                        "Precio: S/ ${producto['precio'] ?? 0}",
                                      ),
                                      Text(
                                        "Subtotal: S/ ${producto['subtotal'] ?? 0}",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 18),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                "Total del pedido: S/ ${pedido['total'] ?? 0}",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cerrar"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () async {
                              await cambiarEstadoPedido(
                                pedidoId,
                                estadoTemporal,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Guardar estado",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget pedidoCard({
    required String pedidoId,
    required Map<String, dynamic> pedido,
  }) {
    final estado = pedido['estado'] ?? 'pendiente';
    final total = pedido['total'] ?? 0;
    final productos = pedido['productos'] ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: colorEstado(estado).withOpacity(0.12),
          child: Icon(
            Icons.receipt_long,
            color: colorEstado(estado),
          ),
        ),
        title: Text(
          pedido['clienteNombre'] ?? 'Cliente sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Código: $pedidoId"),
            Text("Correo: ${pedido['clienteCorreo'] ?? 'Sin correo'}"),
            Text("Fecha: ${formatearFecha(pedido['fechaPedido'])}"),
            Text("Productos: ${productos.length}"),
            Text(
              "Total: S/ $total",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            etiquetaEstado(estado),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "detalle") {
              mostrarDetallePedido(
                pedidoId: pedidoId,
                pedido: pedido,
              );
            }

            if (value.startsWith("estado_")) {
              final nuevoEstado = value.replaceFirst("estado_", "");
              cambiarEstadoPedido(pedidoId, nuevoEstado);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "detalle",
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Ver detalle"),
                ],
              ),
            ),
            const PopupMenuDivider(),
            ...estados.map(
              (estado) => PopupMenuItem(
                value: "estado_$estado",
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: colorEstado(estado),
                    ),
                    const SizedBox(width: 8),
                    Text("Marcar $estado"),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          mostrarDetallePedido(
            pedidoId: pedidoId,
            pedido: pedido,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Pedidos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Visualiza, filtra y actualiza el estado de los pedidos.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 18),

            filtrosPedidos(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: pedidosRef
                    .orderBy('fechaPedido', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar pedidos"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay pedidos registrados"),
                    );
                  }

                  final pedidosFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final clienteNombre =
                        (data['clienteNombre'] ?? '').toString().toLowerCase();

                    final clienteCorreo =
                        (data['clienteCorreo'] ?? '').toString().toLowerCase();

                    final codigoPedido = doc.id.toLowerCase();

                    final estado = data['estado'] ?? 'pendiente';

                    final coincideBusqueda =
                        clienteNombre.contains(textoBusqueda) ||
                            clienteCorreo.contains(textoBusqueda) ||
                            codigoPedido.contains(textoBusqueda);

                    final coincideEstado =
                        estadoFiltro == "todos" ? true : estado == estadoFiltro;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  if (pedidosFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron pedidos"),
                    );
                  }

                  return ListView(
                    children: pedidosFiltrados.map((doc) {
                      final pedido = doc.data() as Map<String, dynamic>;

                      return pedidoCard(
                        pedidoId: doc.id,
                        pedido: pedido,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}