import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' as io;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
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
  "en_proceso",
  "en_camino",
  "entregado",
  "incidencia",
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
    case "en_proceso":
      return Colors.blue;
    case "en_camino":
      return Colors.deepOrange;
    case "entregado":
      return Colors.green;
    case "incidencia":
      return Colors.redAccent;
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
        color: color.withValues(alpha: 0.12),
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
          initialValue: estadoFiltro,
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
    value: "en_proceso",
    child: Text("En proceso"),
  ),
  DropdownMenuItem(
    value: "en_camino",
    child: Text("En camino"),
  ),
  DropdownMenuItem(
    value: "entregado",
    child: Text("Entregados"),
  ),
  DropdownMenuItem(
    value: "incidencia",
    child: Text("Incidencias"),
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

Widget tarjetaResumen({
  required String titulo,
  required int cantidad,
  required IconData icono,
  required Color color,
}) {
  return Container(
    width: 150,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icono, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          cantidad.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
Widget resumenLogistico(List<QueryDocumentSnapshot> pedidos) {
  int contar(String estado) {
    return pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['estado'] ?? '').toString() == estado;
    }).length;
  }

  return SizedBox(
    height: 130,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        tarjetaResumen(
          titulo: "Pendientes",
          cantidad: contar("pendiente"),
          icono: Icons.pending_actions,
          color: Colors.orange,
        ),
        tarjetaResumen(
          titulo: "En proceso",
          cantidad: contar("en_proceso"),
          icono: Icons.inventory_2,
          color: Colors.blue,
        ),
        tarjetaResumen(
          titulo: "En camino",
          cantidad: contar("en_camino"),
          icono: Icons.local_shipping,
          color: Colors.deepOrange,
        ),
        tarjetaResumen(
          titulo: "Entregados",
          cantidad: contar("entregado"),
          icono: Icons.check_circle,
          color: Colors.green,
        ),
        tarjetaResumen(
          titulo: "Incidencias",
          cantidad: contar("incidencia"),
          icono: Icons.report_problem,
          color: Colors.redAccent,
        ),
        tarjetaResumen(
          titulo: "Cancelados",
          cantidad: contar("cancelado"),
          icono: Icons.cancel,
          color: Colors.red,
        ),
      ],
    ),
  );
}
  Future<void> asignarRepartidor({
  required String pedidoId,
  required String repartidorId,
  required String repartidorNombre,
}) async {
  await pedidosRef.doc(pedidoId).update({
  'repartidorId': repartidorId,
  'repartidorNombre': repartidorNombre,

  'estado': 'en_proceso',
  'estadoEntrega': 'en_proceso',

  'fechaAsignacionRepartidor': FieldValue.serverTimestamp(),
  'fechaActualizacion': FieldValue.serverTimestamp(),
});
await FirebaseFirestore.instance
    .collection('pedidos')
    .doc(pedidoId)
    .collection('historial')
    .add({
  'accion': 'Repartidor asignado',
  'descripcion': 'Pedido asignado a $repartidorNombre',
  'usuarioId': FirebaseAuth.instance.currentUser?.uid ?? '',
  'usuarioNombre': 'Administrador',
  'fecha': FieldValue.serverTimestamp(),
});
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Repartidor asignado: $repartidorNombre"),
      ),
    );
  }
}


void mostrarDialogoAsignarRepartidor(String pedidoId) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Asignar repartidor"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where('rol', isEqualTo: 'repartidor')
                .where('estado', isEqualTo: 'activo')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text("Error al cargar repartidores");
              }

              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final repartidores = snapshot.data!.docs;

              if (repartidores.isEmpty) {
                return const Text("No hay repartidores activos");
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: repartidores.length,
                itemBuilder: (context, index) {
                  final doc = repartidores[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final nombre = data['nombre'] ?? 'Sin nombre';
                  final correo =
                      data['correo electrónico'] ?? data['correo'] ?? '';
                  final celular = data['celular'] ?? '';

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.delivery_dining),
                    ),
                    title: Text(nombre),
                    subtitle: Text("$correo\nCelular: $celular"),
                    isThreeLine: true,
                    onTap: () async {
                      await asignarRepartidor(
                        pedidoId: pedidoId,
                        repartidorId: doc.id,
                        repartidorNombre: nombre,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
        ],
      );
    },
  );
}
Future<void> reprogramarPedido(String pedidoId) async {
  await pedidosRef.doc(pedidoId).update({
    'estado': 'en_proceso',
    'estadoEntrega': 'en_proceso',
    'motivoIncidencia': '',
    'fechaReprogramacion': FieldValue.serverTimestamp(),
    'fechaActualizacion': FieldValue.serverTimestamp(),
  });
  await pedidosRef.doc(pedidoId).collection('historial').add({
  'accion': 'Pedido reprogramado',
  'descripcion': 'El administrador reprogramó la entrega',
  'usuarioId': FirebaseAuth.instance.currentUser?.uid ?? '',
  'usuarioNombre': 'Administrador',
  'fecha': FieldValue.serverTimestamp(),
});

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Pedido reprogramado correctamente")),
  );
}
Future<void> cancelarPedidoPorIncidencia({
  required String pedidoId,
  required List<Map<String, dynamic>> productos,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Cancelar pedido"),
      content: const Text(
        "¿Deseas cancelar este pedido y devolver el stock automáticamente?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("No"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Sí, cancelar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final pedidoRef = pedidosRef.doc(pedidoId);

    for (final item in productos) {
      final productoId = item['productoId'];
      final stockKey = item['stockKey'];
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;

      if (productoId != null && productoId.toString().isNotEmpty) {
        final productoRef =
            FirebaseFirestore.instance.collection('productos').doc(productoId);

        final Map<String, dynamic> updateData = {
          'stock': FieldValue.increment(cantidad),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        };

        if (stockKey != null && stockKey.toString().isNotEmpty) {
          updateData['stockVariantes.$stockKey'] =
              FieldValue.increment(cantidad);
        }

        transaction.update(productoRef, updateData);
      }
    }

    transaction.update(pedidoRef, {
      'estado': 'cancelado',
      'estadoEntrega': 'cancelado',
      'fechaCancelacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  });

  await pedidosRef.doc(pedidoId).collection('historial').add({
    'accion': 'Pedido cancelado',
    'descripcion':
        'El administrador canceló el pedido y devolvió el stock general y por variante',
    'usuarioId': FirebaseAuth.instance.currentUser?.uid ?? '',
    'usuarioNombre': 'Administrador',
    'fecha': FieldValue.serverTimestamp(),
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Pedido cancelado y stock devuelto correctamente"),
    ),
  );
}
Future<io.File> generarPdfPedidoAdmin({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) async {
  final pdf = pw.Document();
  final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
  final direccion = Map<String, dynamic>.from(pedido['direccionEntrega'] ?? {});

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(
          "INVERSIONES ISABELLA",
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text("Pedido: #$pedidoId"),
        pw.Text("Fecha: ${formatearFecha(pedido['fechaPedido'])}"),
        pw.Divider(),

        pw.Text("DATOS DEL CLIENTE",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text("Nombres: ${direccion['nombre'] ?? pedido['clienteNombre'] ?? ''}"),
        pw.Text("Apellidos: ${direccion['apellidos'] ?? ''}"),
        pw.Text("DNI: ${direccion['dni'] ?? pedido['clienteDni'] ?? ''}"),
        pw.Text("Celular: ${direccion['numeroContacto'] ?? pedido['clienteCelular'] ?? ''}"),
        pw.Text("Correo: ${pedido['clienteCorreo'] ?? ''}"),
        pw.Text("Dirección: ${direccion['direccionExacta'] ?? pedido['clienteDireccion'] ?? ''}"),

        pw.SizedBox(height: 16),

        pw.Text("ENTREGA",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text("Estado: ${pedido['estado'] ?? ''}"),
        pw.Text("Estado entrega: ${pedido['estadoEntrega'] ?? ''}"),
        pw.Text("Repartidor: ${pedido['repartidorNombre'] ?? 'No asignado'}"),
        if ((pedido['motivoIncidencia'] ?? '').toString().isNotEmpty)
          pw.Text("Incidencia: ${pedido['motivoIncidencia']}"),

        pw.SizedBox(height: 16),

        pw.Text("PRODUCTOS",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),

        pw.Table.fromTextArray(
          headers: ["Producto", "Color", "Talla", "Cant.", "Precio", "Subtotal"],
          data: productos.map((item) {
            final cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;
            final precio = double.tryParse(item['precio'].toString()) ?? 0;
            return [
              item['nombre'] ?? '',
              item['colorSeleccionado'] ?? '',
              item['tallaSeleccionada'] ?? '',
              cantidad.toString(),
              "S/ ${precio.toStringAsFixed(2)}",
              "S/ ${(cantidad * precio).toStringAsFixed(2)}",
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 18),

        pw.Text(
          "TOTAL: S/ ${pedido['total'] ?? 0}",
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 40),

        pw.Center(child: pw.Text("Documento generado desde Panel Administrador")),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = io.File('${dir.path}/pedido_admin_$pedidoId.pdf');

  await file.writeAsBytes(await pdf.save());
  return file;
}
Future<void> descargarPdfPedidoAdmin({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) async {
  final archivo = await generarPdfPedidoAdmin(
    pedidoId: pedidoId,
    pedido: pedido,
  );

  await OpenFilex.open(archivo.path);
}



Future<void> compartirPdfPedidoAdmin({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) async {
  final archivo = await generarPdfPedidoAdmin(
    pedidoId: pedidoId,
    pedido: pedido,
  );

  await Share.shareXFiles(
    [XFile(archivo.path)],
    text: "Pedido #$pedidoId - Inversiones Isabella",
  );
}
Future<void> confirmarEntregaEnTienda(String pedidoId) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirmar entrega"),
      content: const Text(
        "¿Confirmas que el cliente recogió el pedido en tienda?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Sí, entregar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  final user = FirebaseAuth.instance.currentUser;

  await pedidosRef.doc(pedidoId).update({
    'estado': 'entregado',
    'estadoEntrega': 'entregado',
    'fechaEntrega': FieldValue.serverTimestamp(),
    'entregadoPor': user?.uid ?? '',
    'entregadoPorNombre': 'Administrador',
    'fechaActualizacion': FieldValue.serverTimestamp(),
  });

  await pedidosRef.doc(pedidoId).collection('historial').add({
    'accion': 'Pedido entregado en tienda',
    'descripcion': 'El administrador confirmó que el cliente recogió el pedido en tienda',
    'usuarioId': user?.uid ?? '',
    'usuarioNombre': 'Administrador',
    'fecha': FieldValue.serverTimestamp(),
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.green,
      content: Text("Pedido marcado como entregado en tienda"),
    ),
  );
}

Widget repartidorAsignadoCard(Map<String, dynamic> pedidoActual) {
  final repartidorId = pedidoActual['repartidorId'];

  if (repartidorId == null || repartidorId.toString().isEmpty) {
    return const SizedBox();
  }

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('usuarios')
        .doc(repartidorId)
        .get(),
    builder: (context, snapshot) {
      String nombre = pedidoActual['repartidorNombre'] ?? 'Repartidor';
      String apellidos = '';
      String celular = 'Sin celular';
      String correo = 'Sin correo';
      String fotoUrl = '';

      if (snapshot.hasData && snapshot.data!.exists) {
        final data = snapshot.data!.data() as Map<String, dynamic>;

        nombre = data['nombre'] ?? nombre;
        apellidos = data['apellidos'] ?? '';
        celular = data['celular'] ?? 'Sin celular';
        correo = data['correo'] ??
            data['correo electrónico'] ??
            'Sin correo';
        fotoUrl = data['fotoUrl'] ?? '';
      }

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              backgroundImage:
                  fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
              child: fotoUrl.isEmpty
                  ? const Icon(
                      Icons.delivery_dining,
                      color: Colors.blue,
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$nombre $apellidos",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    "Celular: $celular",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),

                  Text(
                    "Correo: $correo",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

void mostrarImagenPantallaCompleta(String imageUrl) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            Positioned(
              top: 35,
              right: 15,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget lineaTiempoPedido(String pedidoId) {
  return StreamBuilder<QuerySnapshot>(
    stream: pedidosRef
        .doc(pedidoId)
        .collection('historial')
        .orderBy('fecha', descending: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text("Error al cargar línea de tiempo");
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final historial = snapshot.data!.docs;

      if (historial.isEmpty) {
        return const Text("Aún no hay movimientos del pedido");
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Línea de tiempo",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ...historial.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;

              final accion = data['accion'] ?? 'Movimiento';
              final descripcion = data['descripcion'] ?? '';
              final fecha = data['fecha'];
              final color = colorHistorial(accion);
              final esUltimo = index == historial.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: color,
                      ),
                      if (!esUltimo)
                        Container(
                          width: 2,
                          height: 45,
                          color: color.withValues(alpha: 0.35),
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accion,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (descripcion.toString().isNotEmpty)
                            Text(
                              descripcion.toString(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            formatearFecha(fecha),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    },
  );
}

void mostrarDetallePedido({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) {


  final Map<String, dynamic> direccionEntrega =
      Map<String, dynamic>.from(pedido['direccionEntrega'] ?? {});

  Widget datoItem(String titulo, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: "$titulo: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: valor.toString().trim().isEmpty
                        ? "No registrado"
                        : valor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tarjetaDatosCliente() {
    final nombres = direccionEntrega['nombre'] ??
        pedido['clienteNombre'] ??
        'No registrado';

    final apellidos = direccionEntrega['apellidos'] ?? '';
    final celular = direccionEntrega['numeroContacto'] ??
        pedido['clienteCelular'] ??
        'No registrado';

    final dni = direccionEntrega['dni'] ??
        pedido['clienteDni'] ??
        'No registrado';

    final correo = pedido['clienteCorreo'] ?? 'No registrado';

    final direccionExacta = direccionEntrega['direccionExacta'] ??
        pedido['clienteDireccion'] ??
        'No registrado';

    final distrito = direccionEntrega['distrito'] ?? '';
    final provincia = direccionEntrega['provincia'] ?? '';
    final departamento = direccionEntrega['departamento'] ?? '';
    final pais = direccionEntrega['pais'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos del cliente",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          datoItem("Nombres", nombres.toString(), Icons.person),
          datoItem("Apellidos", apellidos.toString(), Icons.person_outline),
          datoItem("Celular", celular.toString(), Icons.phone),
          datoItem("DNI", dni.toString(), Icons.badge),
          datoItem("Correo", correo.toString(), Icons.email),
          datoItem("Dirección exacta", direccionExacta.toString(), Icons.home),
          datoItem(
            "Ubicación",
            "$distrito, $provincia, $departamento, $pais",
            Icons.location_on,
          ),
          datoItem(
            "Fecha del pedido",
            formatearFecha(pedido['fechaPedido']),
            Icons.calendar_month,
          ),
        ],
      ),
    );
  }

 Widget tarjetaEntrega({
  required Map<String, dynamic> pedidoActual,
  required String estadoActualReal,
}) {
  final estadoEntregaReal =
      (pedidoActual['estadoEntrega'] ?? 'pendiente').toString();

  final metodoEntrega = pedidoActual['metodoEntrega'] == 'delivery'
      ? 'Delivery'
      : 'Recojo en tienda';

  final color = colorEstado(estadoActualReal);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.20)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                pedidoActual['metodoEntrega'] == 'delivery'
                    ? Icons.local_shipping
                    : Icons.store,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Información logística",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    metodoEntrega,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            etiquetaEstado(estadoActualReal),
          ],
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              datoItem(
                "Estado pedido",
                estadoActualReal,
                Icons.info,
              ),
              datoItem(
                "Estado entrega",
                estadoEntregaReal,
                Icons.delivery_dining,
              ),
            ],
          ),
        ),

        if ((pedidoActual['repartidorNombre'] ?? '').toString().isNotEmpty)
          repartidorAsignadoCard(pedidoActual),
      ],
    ),
  );
}

  showDialog(
  context: context,
  builder: (_) {
    return StreamBuilder<DocumentSnapshot>(
      stream: pedidosRef.doc(pedidoId).snapshots(),
      builder: (context, snapshot) {
        final pedidoActual = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : pedido;

        final productosActuales = List<Map<String, dynamic>>.from(
          pedidoActual['productos'] ?? [],
        );

        final estadoActualReal = pedidoActual['estado'] ?? 'pendiente';

        return Dialog(
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Detalle del pedido",
                        style: TextStyle(
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
                      Text("Código: $pedidoId",style: const TextStyle(fontWeight: FontWeight.bold),),
                      const SizedBox(height: 14),
                      lineaTiempoPedido(pedidoId),

                      const SizedBox(height: 14),

                      tarjetaDatosCliente(),

                      const SizedBox(height: 14),
                      tarjetaEntrega(
  pedidoActual: pedidoActual,
  estadoActualReal: estadoActualReal.toString(),
),
                      if ((pedidoActual['fotoEntregaUrl'] ?? '').toString().isNotEmpty) ...[
  const SizedBox(height: 14),

  const Text(
    "Evidencia de entrega",
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

 GestureDetector(
  onTap: () {
    mostrarImagenPantallaCompleta(
      pedidoActual['fotoEntregaUrl'].toString(),
    );
  },
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      children: [
        Image.network(
          pedidoActual['fotoEntregaUrl'],
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),

        Positioned(
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 18),
                SizedBox(width: 5),
                Text(
                  "Ver imagen",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),
],

const SizedBox(height: 12),

Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
        onPressed: () {
          descargarPdfPedidoAdmin(
            pedidoId: pedidoId,
            pedido: pedidoActual,
          );
        },
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text(
          "Descargar PDF",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
        ),
        onPressed: () {
          compartirPdfPedidoAdmin(
            pedidoId: pedidoId,
            pedido: pedidoActual,
          );
        },
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text(
          "Compartir",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  ],
),

                      const SizedBox(height: 14),

                      etiquetaEstado(estadoActualReal.toString()),

                      if ((pedidoActual['estado'] ?? '') == 'incidencia') ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      "Incidencia reportada",
      style: TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 6),

    Text(
      "Motivo: ${pedidoActual['motivoIncidencia'] ?? 'No registrado'}",
    ),

    const SizedBox(height: 10),

    datoItem(
      "Fecha incidencia",
      formatearFecha(
        pedidoActual['fechaIncidencia'],
      ),
      Icons.calendar_month,
    ),
  ],
),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () async {
                                  await reprogramarPedido(pedidoId);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: const Text(
                                  "Reprogramar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  await cancelarPedidoPorIncidencia(
                                    pedidoId: pedidoId,
                                    productos: productosActuales,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(Icons.cancel, color: Colors.white),
                                label: const Text(
                                  "Cancelar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      if (pedidoActual['metodoEntrega'] == 'delivery' &&
                          estadoActualReal != 'entregado' &&
                          estadoActualReal != 'cancelado') ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              mostrarDialogoAsignarRepartidor(pedidoId);
                            },
                            icon: const Icon(Icons.delivery_dining),
                            label: Text(
                              (pedidoActual['repartidorNombre'] ?? '').toString().isEmpty
                                  ? "Asignar repartidor"
                                  : "Cambiar repartidor",
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (pedidoActual['metodoEntrega'] == 'recojo_tienda' &&
    estadoActualReal != 'entregado' &&
    estadoActualReal != 'cancelado') ...[
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      onPressed: () {
        confirmarEntregaEnTienda(pedidoId);
      },
      icon: const Icon(Icons.store, color: Colors.white),
      label: const Text(
        "Confirmar entrega en tienda",
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
  const SizedBox(height: 18),
],

                      const Text(
                        "Productos del pedido",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (productosActuales.isEmpty)
                        const Text("Este pedido no tiene productos."),

                      ...productosActuales.map((producto) {
                        final imagenUrl = producto['imagenUrl'] ?? '';
                        final nombre = producto['nombre'] ?? 'Producto';
                        final cantidad =
                            int.tryParse(producto['cantidad'].toString()) ?? 1;
                        final precio =
                            double.tryParse(producto['precio'].toString()) ?? 0;
                        final subtotal = cantidad * precio;

                        final colorSeleccionado = producto['colorSeleccionado'];
                        final tallaSeleccionada = producto['tallaSeleccionada'];
                        final stockKey = producto['stockKey'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imagenUrl.toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        imagenUrl,
                                        width: 75,
                                        height: 75,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 75,
                                      height: 75,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: primaryColor,
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

                                    const SizedBox(height: 5),

                                    if (colorSeleccionado != null ||
                                        tallaSeleccionada != null)
                                      Text(
                                        "${colorSeleccionado != null ? 'Color: $colorSeleccionado' : ''}"
                                        "${colorSeleccionado != null && tallaSeleccionada != null ? ' | ' : ''}"
                                        "${tallaSeleccionada != null ? 'Talla: $tallaSeleccionada' : ''}",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                    if (stockKey != null)
                                      Text(
                                        "Variante: $stockKey",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),

                                    const SizedBox(height: 5),

                                    Text("Cantidad: $cantidad"),
                                    Text("Precio: S/ ${precio.toStringAsFixed(2)}"),
                                    Text("Subtotal: S/ ${subtotal.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Total del pedido: S/ ${pedidoActual['total'] ?? 0}",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

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
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
});
}

Color colorHistorial(String accion) {
  final texto = accion.toLowerCase();

  if (texto.contains('creado')) return Colors.green;
  if (texto.contains('asignado')) return Colors.blue;
  if (texto.contains('camino')) return Colors.orange;
  if (texto.contains('entregado')) return Colors.green;
  if (texto.contains('incidencia')) return Colors.redAccent;
  if (texto.contains('cancelado')) return Colors.red;
  if (texto.contains('reprogramado')) return Colors.purple;

  return Colors.grey;
}

Widget historialPedidoWidget(String pedidoId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .collection('historial')
        .orderBy('fecha', descending: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text("Error al cargar historial");
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final historial = snapshot.data!.docs;

      if (historial.isEmpty) {
        return const Text("Aún no hay historial del pedido");
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: historial.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final accion = data['accion'] ?? 'Movimiento';
          final descripcion = data['descripcion'] ?? '';
          final usuarioNombre = data['usuarioNombre'] ?? '';
          final fecha = data['fecha'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorHistorial(accion).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
  radius: 16,
  backgroundColor: colorHistorial(accion).withValues(alpha: 0.12),
  child: Icon(
    Icons.timeline,
    color: colorHistorial(accion),
    size: 18,
  ),
),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accion,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (descripcion.toString().isNotEmpty)
                        Text(descripcion),
                      if (usuarioNombre.toString().isNotEmpty)
                        Text(
                          "Usuario: $usuarioNombre",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        formatearFecha(fecha),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
        leading: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('usuarios')
      .doc(pedido['clienteId'])
      .get(),
  builder: (context, snapshot) {
    String fotoUrl = "";

    if (snapshot.hasData && snapshot.data!.exists) {
      final userData = snapshot.data!.data() as Map<String, dynamic>;
      fotoUrl = userData['fotoUrl'] ?? '';
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: colorEstado(estado).withValues(alpha: 0.12),
      backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
      child: fotoUrl.isEmpty
          ? Icon(
              Icons.person,
              color: colorEstado(estado),
            )
          : null,
    );
  },
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

    Text("Celular: ${pedido['clienteCelular'] ?? 'Sin celular'}"),

    if ((pedido['repartidorNombre'] ?? '').toString().isNotEmpty)
      Text(
        "Repartidor: ${pedido['repartidorNombre']}",
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),

    Text("Fecha: ${formatearFecha(pedido['fechaPedido'])}"),

    Text("Productos: ${productos.length}"),

    Text(
      "Total: S/ $total",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 6),

if (estado == "incidencia") ...[
  Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.redAccent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.redAccent),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.report_problem,
          color: Colors.redAccent,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            pedido['motivoIncidencia'] ?? 'Incidencia reportada',
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
],

etiquetaEstado(estado),
  ],
),
        trailing: const Icon(
  Icons.arrow_forward_ios,
  size: 16,
  color: Colors.grey,
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
                  final todosPedidos = snapshot.data!.docs;

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
  children: [
    resumenLogistico(todosPedidos),
    const SizedBox(height: 16),

    ...pedidosFiltrados.map((doc) {
      final pedido = doc.data() as Map<String, dynamic>;

      return pedidoCard(
        pedidoId: doc.id,
        pedido: pedido,
      );
    }),
  ],
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
