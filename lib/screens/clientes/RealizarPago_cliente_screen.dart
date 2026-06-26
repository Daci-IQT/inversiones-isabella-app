import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../clientes/direcciones_cliente_screen.dart';
import '../../services/pedido_service.dart';

class RealizarPagoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final double total;
  final VoidCallback actualizar;

  const RealizarPagoScreen({
    super.key,
    required this.carrito,
    required this.total,
    required this.actualizar,
  });

  @override
  State<RealizarPagoScreen> createState() => _RealizarPagoScreenState();
}

class _RealizarPagoScreenState extends State<RealizarPagoScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final PedidosService pedidosService = PedidosService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);
  final Color orangeColor = const Color(0xFFFF7A00);

  String metodoPagoSeleccionado = "Contra entrega";
  String metodoEntregaSeleccionado = "delivery";
  double costoDelivery = 5.00;

  bool procesando = false;

  Map<String, dynamic>? direccionSeleccionada;
  String? direccionSeleccionadaId;

  double get totalFinal => widget.total + costoDelivery;

  @override
  void initState() {
    super.initState();
    cargarDireccionPrincipal();
  }

  Future<void> cargarDireccionPrincipal() async {
    final usuarioActual = auth.currentUser;
    if (usuarioActual == null) return;

    final direccionesRef = firestore
        .collection('usuarios')
        .doc(usuarioActual.uid)
        .collection('direcciones');

    final snapshot = await direccionesRef.get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        direccionSeleccionada = null;
        direccionSeleccionadaId = null;
      });
      return;
    }

    final predeterminadas = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['predeterminada'] == true;
    }).toList();

    final docSeleccionado =
        predeterminadas.isNotEmpty ? predeterminadas.first : snapshot.docs.first;

    setState(() {
      direccionSeleccionada = docSeleccionado.data();
      direccionSeleccionadaId = docSeleccionado.id;
    });
  }

  Future<Map<String, dynamic>> obtenerCliente() async {
    final usuarioActual = auth.currentUser;
    if (usuarioActual == null) return {};

    final doc = await firestore.collection('usuarios').doc(usuarioActual.uid).get();
    return doc.data() ?? {};
  }

  Future<void> irADirecciones() async {
    final usuarioActual = auth.currentUser;
    if (usuarioActual == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DireccionesClienteScreen(uid: usuarioActual.uid),
      ),
    );

    cargarDireccionPrincipal();
  }

  bool direccionValida() {
    if (direccionSeleccionada == null) return false;

    final campos = [
      direccionSeleccionada!['pais'],
      direccionSeleccionada!['nombre'],
      direccionSeleccionada!['apellidos'],
      direccionSeleccionada!['direccionExacta'],
      direccionSeleccionada!['departamento'],
      direccionSeleccionada!['provincia'],
      direccionSeleccionada!['distrito'],
      direccionSeleccionada!['numeroContacto'],
      direccionSeleccionada!['dni'],
    ];

    return campos.every(
      (campo) => campo != null && campo.toString().trim().isNotEmpty,
    );
  }

  Future<void> confirmarFinalizarPedido() async {
    if (!direccionValida()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes registrar una dirección antes de confirmar el pedido"),
        ),
      );

      irADirecciones();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Finalizar compra"),
          content: Text(
            "¿Estás seguro de finalizar tu compra?\n\n"
            "Método de entrega: ${metodoEntregaSeleccionado == 'delivery' ? 'Delivery' : 'Recojo en tienda'}\n"
            "Total a pagar: S/ ${totalFinal.toStringAsFixed(2)}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Sí, finalizar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      finalizarPedido();
    }
  }

  Future<void> finalizarPedido() async {
    final usuarioActual = auth.currentUser;

    if (usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe iniciar sesión para realizar pedido")),
      );
      return;
    }

    if (metodoPagoSeleccionado != "Contra entrega") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por ahora solo está disponible Contra entrega"),
        ),
      );
      return;
    }

    if (!direccionValida()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes registrar una dirección válida")),
      );
      return;
    }

    setState(() {
      procesando = true;
    });

    try {
      final dir = direccionSeleccionada!;

      final direccionTexto =
          "${dir['direccionExacta']}, ${dir['distrito']}, ${dir['provincia']}, ${dir['departamento']}, ${dir['pais']}";

      await pedidosService.crearPedidoConStock(
        productos: widget.carrito,
        pedidoData: {
          'clienteId': usuarioActual.uid,
          'clienteNombre':
              "${dir['nombre'] ?? ''} ${dir['apellidos'] ?? ''}".trim(),
          'clienteCorreo': usuarioActual.email ?? '',
          'clienteDireccion': direccionTexto,
          'clienteCelular': dir['numeroContacto'] ?? '',
          'clienteDni': dir['dni'] ?? '',
          'direccionId': direccionSeleccionadaId,
          'direccionEntrega': dir,
          'productos': widget.carrito,

          'totalProductos': widget.total,
          'costoDelivery': costoDelivery,
          'total': totalFinal,

          'metodoPago': metodoPagoSeleccionado,
          'estadoPago': 'pendiente',
          'estado': 'pendiente',

          'metodoEntrega': metodoEntregaSeleccionado,
          'estadoEntrega': 'pendiente',
          'repartidorId': '',
'repartidorNombre': '',
'fotoEntregaUrl': '',
'fechaEntrega': null,
'entregadoPor': '',
        },
      );

      widget.carrito.clear();
      widget.actualizar();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryColor,
          content: const Text("Pedido enviado correctamente"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al registrar pedido: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          procesando = false;
        });
      }
    }
  }

  Widget tarjetaSeccion({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget direccionCliente() {
    final dir = direccionSeleccionada;

    return InkWell(
      onTap: irADirecciones,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: direccionValida() ? Colors.green : Colors.redAccent,
            width: 1.4,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              color: direccionValida() ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: dir == null
                  ? const Text(
                      "No tienes dirección registrada. Presiona aquí para agregar una.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${dir['nombre'] ?? ''} ${dir['apellidos'] ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text("${dir['direccionExacta'] ?? ''}"),
                        Text(
                          "${dir['distrito'] ?? ''}, ${dir['provincia'] ?? ''}, ${dir['departamento'] ?? ''}, ${dir['pais'] ?? ''}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Celular: ${dir['numeroContacto'] ?? ''} | DNI: ${dir['dni'] ?? ''}",
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ],
                    ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget detalleProducto(Map<String, dynamic> item) {
    final cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;
    final precio = double.tryParse(item['precio'].toString()) ?? 0;
    final subtotal = cantidad * precio;
    final imagenUrl = item['imagenUrl'] ?? '';
    final colorSeleccionado = item['colorSeleccionado'];
    final tallaSeleccionada = item['tallaSeleccionada'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
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
                    child: Icon(Icons.shopping_bag, color: primaryColor),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nombre'] ?? 'Producto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (colorSeleccionado != null || tallaSeleccionada != null)
                  Text(
                    "${colorSeleccionado != null ? 'Color: $colorSeleccionado' : ''}"
                    "${colorSeleccionado != null && tallaSeleccionada != null ? ' | ' : ''}"
                    "${tallaSeleccionada != null ? 'Talla: $tallaSeleccionada' : ''}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                Text(
                  "Cantidad: $cantidad",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                Text(
                  "Precio: S/ ${precio.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "S/ ${subtotal.toStringAsFixed(2)}",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget metodoEntregaItem({
    required String titulo,
    required String valor,
    required IconData icono,
    required String descripcion,
  }) {
    final seleccionado = metodoEntregaSeleccionado == valor;

    return InkWell(
      onTap: () {
        setState(() {
          metodoEntregaSeleccionado = valor;
          costoDelivery = valor == "delivery" ? 5.00 : 0.00;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? primaryColor.withValues(alpha: 0.10)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? primaryColor : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: seleccionado ? primaryColor : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(
                    descripcion,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
              color: seleccionado ? primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget metodoPagoItem({
    required String titulo,
    required IconData icono,
    required bool disponible,
  }) {
    final seleccionado = metodoPagoSeleccionado == titulo;

    return InkWell(
      onTap: disponible
          ? () {
              setState(() {
                metodoPagoSeleccionado = titulo;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? primaryColor.withValues(alpha: 0.10)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? primaryColor : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: disponible ? primaryColor : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: disponible ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            if (!disponible)
              const Text(
                "Próximamente",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            if (disponible)
              Icon(
                seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
                color: seleccionado ? primaryColor : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget resumenTotal() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          filaResumenPago("Subtotal productos", widget.total),
          filaResumenPago("Delivery", costoDelivery),
          const Divider(),
          filaResumenPago("Total del pedido", totalFinal, destacado: true),
        ],
      ),
    );
  }

  Widget filaResumenPago(String titulo, double monto, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            "S/ ${monto.toStringAsFixed(2)}",
            style: TextStyle(
              color: destacado ? primaryColor : Colors.black87,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
              fontSize: destacado ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Realizar pago"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: obtenerCliente(),
        builder: (context, snapshot) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      tarjetaSeccion(
                        titulo: "Dirección de entrega",
                        child: direccionCliente(),
                      ),
                      tarjetaSeccion(
                        titulo: "Método de entrega",
                        child: Column(
                          children: [
                            metodoEntregaItem(
                              titulo: "Delivery",
                              valor: "delivery",
                              icono: Icons.local_shipping,
                              descripcion: "Entrega a domicilio. Costo: S/ 5.00",
                            ),
                            metodoEntregaItem(
                              titulo: "Recojo en tienda",
                              valor: "recojo_tienda",
                              icono: Icons.store,
                              descripcion: "El cliente recoge su pedido en la tienda.",
                            ),
                          ],
                        ),
                      ),
                      tarjetaSeccion(
                        titulo: "Detalle del pedido",
                        child: Column(
                          children: [
                            ...widget.carrito.map(detalleProducto),
                            const SizedBox(height: 8),
                            resumenTotal(),
                          ],
                        ),
                      ),
                      tarjetaSeccion(
                        titulo: "Método de pago",
                        child: Column(
                          children: [
                            metodoPagoItem(
                              titulo: "Tarjeta",
                              icono: Icons.credit_card,
                              disponible: false,
                            ),
                            metodoPagoItem(
                              titulo: "Yape",
                              icono: Icons.qr_code_2,
                              disponible: false,
                            ),
                            metodoPagoItem(
                              titulo: "Plin",
                              icono: Icons.qr_code,
                              disponible: false,
                            ),
                            metodoPagoItem(
                              titulo: "Contra entrega",
                              icono: Icons.local_shipping,
                              disponible: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Total a pagar",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "S/ ${totalFinal.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              direccionValida() ? primaryColor : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: procesando ? null : confirmarFinalizarPedido,
                        icon: procesando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          procesando ? "Enviando pedido..." : "Finalizar pedido",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}