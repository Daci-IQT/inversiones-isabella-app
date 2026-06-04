import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
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