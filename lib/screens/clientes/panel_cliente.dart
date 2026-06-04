
import 'package:flutter/material.dart';
import '../clientes/inicio_cliente_screen.dart';
import '../clientes/carrito_cliente_screen.dart';
import '../clientes/perfil_cliente_screen.dart';
import '../clientes/categorias_cliente_screen.dart';


/// 🚀 PANTALLA PRINCIPAL CLIENTE
////////////////////////////////////////////////////////
class ClientePanel extends StatefulWidget {
  const ClientePanel({super.key});

  @override
  State<ClientePanel> createState() => _ClientePanelState();
}

class _ClientePanelState extends State<ClientePanel> {
  int index = 0;
  int? indexAnterior;

  DateTime? ultimoBack;

  String? productoDetallePendienteId;
  Map<String, dynamic>? productoDetallePendiente;

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final List<Map<String, dynamic>> carrito = [];

  bool agregarAlCarrito(
    Map<String, dynamic> producto,
    String productoId,
  ) {
    final int cantidadNueva =
        int.tryParse(producto['cantidad'].toString()) ?? 1;

    final double precio =
        double.tryParse(producto['precio'].toString()) ?? 0;

    final int stockDisponible =
        int.tryParse(producto['stock'].toString()) ?? 0;

    final String? colorSeleccionado = producto['colorSeleccionado'];
    final String? tallaSeleccionada = producto['tallaSeleccionada'];

    final indexProducto = carrito.indexWhere(
      (item) =>
          item['productoId'] == productoId &&
          item['colorSeleccionado'] == colorSeleccionado &&
          item['tallaSeleccionada'] == tallaSeleccionada,
    );

    bool agregado = false;

    setState(() {
      if (indexProducto >= 0) {
        final int cantidadActual =
            int.tryParse(carrito[indexProducto]['cantidad'].toString()) ?? 1;

        final int nuevaCantidadTotal = cantidadActual + cantidadNueva;

        if (nuevaCantidadTotal > stockDisponible) {
          agregado = false;
          return;
        }

        carrito[indexProducto]['cantidad'] = nuevaCantidadTotal;
        carrito[indexProducto]['subtotal'] = nuevaCantidadTotal * precio;
        agregado = true;
      } else {
        if (cantidadNueva > stockDisponible) {
          agregado = false;
          return;
        }

        carrito.add({
          'productoId': productoId,
          'nombre': producto['nombre'],
          'descripcion': producto['descripcion'],
          'precio': precio,
          'imagenUrl': producto['imagenUrl'],
          'imagenes': producto['imagenes'] ?? [],
          'cantidad': cantidadNueva,
          'subtotal': cantidadNueva * precio,
          'stock': stockDisponible,
          'categoriaId': producto['categoriaId'],
          'categoriaNombre': producto['categoriaNombre'],
          'colorSeleccionado': colorSeleccionado,
          'tallaSeleccionada': tallaSeleccionada,
        });

        agregado = true;
      }
    });

    return agregado;
  }

  void irAlCarritoDesdeDetalle({
    required String productoId,
    required Map<String, dynamic> producto,
  }) {
    setState(() {
      indexAnterior = index;
      productoDetallePendienteId = productoId;
      productoDetallePendiente = producto;
      index = 2;
    });
  }

  void limpiarDetallePendiente() {
    productoDetallePendienteId = null;
    productoDetallePendiente = null;
  }

  void actualizarCarrito() {
    setState(() {});
  }

  int cantidadTotalCarrito() {
    int total = 0;

    for (final item in carrito) {
      total += int.tryParse(item['cantidad'].toString()) ?? 1;
    }

    return total;
  }

  Future<bool> controlarRetroceso() async {
    if (index == 2 && indexAnterior != null) {
      setState(() {
        index = indexAnterior!;
        indexAnterior = null;
      });

      return false;
    }

    if (index != 0) {
      setState(() {
        indexAnterior = null;
        limpiarDetallePendiente();
        index = 0;
      });

      return false;
    }

    final ahora = DateTime.now();

    if (ultimoBack == null ||
        ahora.difference(ultimoBack!) > const Duration(seconds: 2)) {
      ultimoBack = ahora;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            "Presiona nuevamente para salir",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      return false;
    }

    return true;
  }

  void cambiarPantalla(int i) {
    setState(() {
      indexAnterior = null;
      limpiarDetallePendiente();
      index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      InicioScreen(
        agregarAlCarrito: agregarAlCarrito,
        irAlCarritoDesdeDetalle: irAlCarritoDesdeDetalle,
        productoDetallePendienteId: productoDetallePendienteId,
        productoDetallePendiente: productoDetallePendiente,
        limpiarDetallePendiente: limpiarDetallePendiente,
      ),
      CategoriasClienteScreen(
        agregarAlCarrito: agregarAlCarrito,
        irAlCarritoDesdeDetalle: irAlCarritoDesdeDetalle,
        productoDetallePendienteId: productoDetallePendienteId,
        productoDetallePendiente: productoDetallePendiente,
        limpiarDetallePendiente: limpiarDetallePendiente,
      ),
      CarritoClienteScreen(
        carrito: carrito,
        actualizar: actualizarCarrito,
      ),
      PerfilClienteScreen(
        carrito: carrito,
        actualizar:actualizarCarrito,
      ),
    ];

    return WillPopScope(
      onWillPop: controlarRetroceso,
      child: Scaffold(
        body: screens[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: cambiarPantalla,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Inicio",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: "Categorías",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart),
                  if (carrito.isNotEmpty)
                    Positioned(
                      right: -10,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cantidadTotalCarrito().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "Carrito",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Perfil",
            ),
          ],
        ),
      ),
    );
  }
}