
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../clientes/RealizarPago_cliente_screen.dart';
import '../../widgets/seleccionar_variante_producto.dart';


// PANTALLA CARRITO CLIENTE
////////////////////////////////////////////

class CarritoClienteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final VoidCallback actualizar;

  const CarritoClienteScreen({
    super.key,
    required this.carrito,
    required this.actualizar,
  });

  @override
  State<CarritoClienteScreen> createState() => _CarritoClienteScreenState();
}

class _CarritoClienteScreenState extends State<CarritoClienteScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final productosRef = FirebaseFirestore.instance.collection('productos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  double calcularTotal() {
    double total = 0;

    for (final item in widget.carrito) {
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;
      final precio = double.tryParse(item['precio'].toString()) ?? 0;

      item['subtotal'] = cantidad * precio;
      total += item['subtotal'];
    }

    return total;
  }

  Color obtenerColor(String color) {
    switch (color.toLowerCase()) {
      case 'negro':
        return Colors.black;
      case 'blanco':
        return Colors.white;
      case 'rojo':
        return Colors.red;
      case 'azul':
        return Colors.blue;
      case 'verde':
        return Colors.green;
      case 'gris':
        return Colors.grey;
      case 'rosado':
      case 'rosa':
        return Colors.pink;
      case 'beige':
        return const Color(0xFFD7B899);
      case 'marrón':
      case 'marron':
        return Colors.brown;
      case 'amarillo':
        return Colors.yellow;
      case 'morado':
        return Colors.purple;
      case 'naranja':
        return Colors.orange;
      default:
        return primaryColor;
    }
  }

  void mensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool agregarAlCarritoLocal(
    Map<String, dynamic> producto,
    String productoId,
  ) {
    final int cantidadNueva =
        int.tryParse(producto['cantidad'].toString()) ?? 1;

    final double precio = double.tryParse(producto['precio'].toString()) ?? 0;

    final int stockDisponible =
        int.tryParse(producto['stock'].toString()) ?? 0;

    final String? colorSeleccionado = producto['colorSeleccionado'];
    final String? tallaSeleccionada = producto['tallaSeleccionada'];

    final indexProducto = widget.carrito.indexWhere(
      (item) =>
          item['productoId'] == productoId &&
          item['colorSeleccionado'] == colorSeleccionado &&
          item['tallaSeleccionada'] == tallaSeleccionada,
    );

    bool agregado = false;

    setState(() {
      if (indexProducto >= 0) {
        final int cantidadActual =
            int.tryParse(widget.carrito[indexProducto]['cantidad'].toString()) ??
                1;

        final int nuevaCantidadTotal = cantidadActual + cantidadNueva;

        if (nuevaCantidadTotal > stockDisponible) {
          agregado = false;
          return;
        }

        widget.carrito[indexProducto]['cantidad'] = nuevaCantidadTotal;
        widget.carrito[indexProducto]['subtotal'] = nuevaCantidadTotal * precio;
        agregado = true;
      } else {
        if (cantidadNueva > stockDisponible) {
          agregado = false;
          return;
        }

        widget.carrito.add({
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
          'stockKey': producto['stockKey'],
        });

        agregado = true;
      }
    });

    widget.actualizar();
    return agregado;
  }

  void aumentarCantidad(int index) {
    final int cantidadActual =
        int.tryParse(widget.carrito[index]['cantidad'].toString()) ?? 1;

    final int stockDisponible =
        int.tryParse(widget.carrito[index]['stock'].toString()) ?? 0;

    final double precio =
        double.tryParse(widget.carrito[index]['precio'].toString()) ?? 0;

    if (cantidadActual >= stockDisponible) {
      mensaje(
        "No puedes agregar más. Stock disponible: $stockDisponible",
        Colors.redAccent,
      );
      return;
    }

    setState(() {
      widget.carrito[index]['cantidad'] = cantidadActual + 1;
      widget.carrito[index]['subtotal'] =
          widget.carrito[index]['cantidad'] * precio;
    });

    widget.actualizar();
  }

  void disminuirCantidad(int index) {
    setState(() {
      final cantidadActual =
          int.tryParse(widget.carrito[index]['cantidad'].toString()) ?? 1;

      final precio =
          double.tryParse(widget.carrito[index]['precio'].toString()) ?? 0;

      if (cantidadActual > 1) {
        widget.carrito[index]['cantidad'] = cantidadActual - 1;
        widget.carrito[index]['subtotal'] =
            widget.carrito[index]['cantidad'] * precio;
      } else {
        widget.carrito.removeAt(index);
      }
    });

    widget.actualizar();
  }

 Future<void> confirmarEliminarProducto(int index) async {
  final item = widget.carrito[index];

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Eliminar producto"),
        content: Text(
          "¿Deseas quitar ${item['nombre'] ?? 'este producto'} del carrito?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar == true) {
    setState(() {
      widget.carrito.removeAt(index);
    });

    widget.actualizar();

    mensaje("Producto eliminado del carrito", Colors.redAccent);
  }
}

Future<void> confirmarVaciarCarrito() async {
  if (widget.carrito.isEmpty) return;

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Vaciar carrito"),
        content: const Text(
          "¿Deseas eliminar todos los productos del carrito?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Vaciar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar == true) {
    setState(() {
      widget.carrito.clear();
    });

    widget.actualizar();

    mensaje(
      "Carrito vaciado correctamente",
      Colors.redAccent,
    );
  }
}
  Future<void> abrirDetalleDesdeCarrito(Map<String, dynamic> item) async {
    final productoId = item['productoId'];

    if (productoId == null) return;

    final doc = await productosRef.doc(productoId).get();

    if (!doc.exists) {
      mensaje("Este producto ya no está disponible", Colors.redAccent);
      return;
    }

    final producto = doc.data() as Map<String, dynamic>;

    mostrarDetalleProducto(
      productoId: productoId,
      producto: {
        ...producto,
        'productoId': productoId,
      },
    );
  }

  Widget productosQueTePuedenInteresar() {
  final idsCarrito = widget.carrito
      .map((e) => e['productoId']?.toString())
      .where((id) => id != null && id.isNotEmpty)
      .toList();

  return StreamBuilder<QuerySnapshot>(
    stream: productosRef
        .where('activo', isEqualTo: true)
        .limit(20)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final productos = snapshot.data!.docs.where((doc) {
        return !idsCarrito.contains(doc.id);
      }).toList();

      if (productos.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            "Productos que te pueden interesar",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Agrega más productos antes de finalizar tu pedido.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final doc = productos[index];
              final data = doc.data() as Map<String, dynamic>;

              final imagenUrl = data['imagenUrl'] ?? '';
              final imagenes = List<String>.from(data['imagenes'] ?? []);
              final imagenMostrar =
                  imagenes.isNotEmpty ? imagenes.first : imagenUrl;

              final stock = int.tryParse(data['stock'].toString()) ?? 0;
              final precio = double.tryParse(data['precio'].toString()) ?? 0;

              return GestureDetector(
                onTap: () {
                  mostrarDetalleProducto(
                    productoId: doc.id,
                    producto: {
                      ...data,
                      'productoId': doc.id,
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                            child: SizedBox(
                              height: 130,
                              width: double.infinity,
                              child: imagenMostrar.toString().isNotEmpty
                                  ? Image.network(
                                      imagenMostrar,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: primaryColor.withValues(alpha: 0.10),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: primaryColor,
                                        size: 40,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: stock > 0
                                    ? Colors.green
                                    : Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                stock > 0 ? "Disponible" : "Sin stock",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['nombre'] ?? 'Producto',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "S/ ${precio.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 34,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: stock > 0
                                      ? () {
                                          mostrarDetalleProducto(
                                            productoId: doc.id,
                                            producto: {
                                              ...data,
                                              'productoId': doc.id,
                                            },
                                          );
                                        }
                                      : null,
                                  child: const Text(
                                    "Ver producto",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      );
    },
  );
}

  Widget productosRelacionados({
    required String productoActualId,
    required String? categoriaId,
  }) {
    if (categoriaId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: productosRef
          .where('activo', isEqualTo: true)
          .where('categoriaId', isEqualTo: categoriaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final relacionados = snapshot.data!.docs
            .where((doc) => doc.id != productoActualId)
            .take(6)
            .toList();

        if (relacionados.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 26),
            const Text(
              "También te puede interesar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: relacionados.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = relacionados[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final imagenUrl = data['imagenUrl'] ?? '';
                  final imagenes = List<String>.from(data['imagenes'] ?? []);
                  final stock = int.tryParse(data['stock'].toString()) ?? 0;

                  final imagenMostrar =
                      imagenes.isNotEmpty ? imagenes.first : imagenUrl;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);

                      Future.delayed(const Duration(milliseconds: 250), () {
                        mostrarDetalleProducto(
                          productoId: doc.id,
                          producto: {
                            ...data,
                            'productoId': doc.id,
                          },
                        );
                      });
                    },
                    child: Container(
                      width: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: SizedBox(
                              height: 98,
                              width: double.infinity,
                              child: imagenMostrar.toString().isNotEmpty
                                  ? Image.network(
                                      imagenMostrar,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color:
                                          primaryColor.withValues(alpha: 0.10),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: primaryColor,
                                        size: 34,
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['nombre'] ?? 'Producto',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "S/ ${data['precio'] ?? 0}",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  stock > 0 ? "Disponible" : "Sin stock",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        stock > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
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
              ),
            ),
          ],
        );
      },
    );
  }

void mostrarDetalleProducto({
  required String productoId,
  required Map<String, dynamic> producto,
}) {
  final imagenUrl = producto['imagenUrl'] ?? '';
  final imagenes = List<String>.from(producto['imagenes'] ?? []);
  final stock = int.tryParse(producto['stock'].toString()) ?? 0;
final rootContext = Navigator.of(context, rootNavigator: true).context;


  final List<String> imagenesMostrar = imagenes.isNotEmpty
      ? imagenes
      : imagenUrl.toString().isNotEmpty
          ? [imagenUrl]
          : [];

   bool productoAgregado = false;
   int imagenActual = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) {
      return StatefulBuilder(
    builder: (context, setDetalleState) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) {
          return Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(
                      height: 330,
                      width: double.infinity,
                      child: imagenesMostrar.isNotEmpty
    ? Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 330,
              viewportFraction: 1,
              enableInfiniteScroll: imagenesMostrar.length > 1,
              onPageChanged: (index, reason) {
                setDetalleState(() {
                  imagenActual = index;
                });
              },
            ),
            items: imagenesMostrar.asMap().entries.map((entry) {
              final index = entry.key;
              final img = entry.value;

              return GestureDetector(
                onTap: () {
                  mostrarImagenPantallaCompleta(
                    imagenes: imagenesMostrar,
                    indexInicial: index,
                  );
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Image.network(
                    img,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }).toList(),
          ),

          if (imagenesMostrar.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: imagenesMostrar.asMap().entries.map((entry) {
                  final index = entry.key;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: imagenActual == index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: imagenActual == index
                          ? primaryColor
                          : Colors.grey.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      )
                          : Container(
                              color: primaryColor.withValues(alpha: 0.10),
                              child: Icon(
                                Icons.shopping_bag,
                                size: 80,
                                color: primaryColor,
                              ),
                            ),
                    ),

                    Padding(
  padding: const EdgeInsets.all(18),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto['nombre'] ?? 'Producto',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "S/ ${(double.tryParse(producto['precio'].toString()) ?? 0).toStringAsFixed(2)}",
              style: TextStyle(
                color: primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              stock > 0 ? "Stock total disponible: $stock" : "Sin stock",
              style: TextStyle(
                color: stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if ((producto['categoriaNombre'] ?? '').toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  producto['categoriaNombre'],
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      Container(
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
                Icon(Icons.description),
                SizedBox(width: 8),
                Text(
                  "Descripción",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              producto['descripcion'] ?? 'Sin descripción',
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      if (List<String>.from(producto['colores'] ?? []).isNotEmpty) ...[
        const Text(
          "Colores disponibles",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
  spacing: 10,
  runSpacing: 10,
  children: List<String>.from(producto['colores'] ?? []).map((color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: obtenerColor(color),
          ),
          const SizedBox(width: 8),
          Text(
            color,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }).toList(),
),
        const SizedBox(height: 18),
      ],

      if (List<String>.from(producto['tallas'] ?? []).isNotEmpty) ...[
        const Text(
          "Tallas disponibles",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
       Wrap(
  spacing: 10,
  runSpacing: 10,
  children: List<String>.from(producto['tallas'] ?? []).map((talla) {
    return Container(
      width: 55,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        talla,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }).toList(),
),
      ],

      productosRelacionados(
        productoActualId: productoId,
        categoriaId: producto['categoriaId'],
      ),

      const SizedBox(height: 110),
    ],
  ),
),
                  ],
                ),
              ),

              Positioned(
  top: 14,
  left: 14,
  child: CircleAvatar(
    backgroundColor: Colors.black.withValues(alpha: 0.45),
    child: IconButton(
      icon: const Icon(
        Icons.arrow_back,
        color: Colors.white,
      ),
      onPressed: () => Navigator.pop(context),
    ),
  ),
),

             Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  child: Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: productoAgregado
        ? Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
  setDetalleState(() {
    productoAgregado = false;
  });
},
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text("Seguir viendo"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);

Future.delayed(const Duration(milliseconds: 150), () {
  if (!mounted) return;

  Navigator.of(context).popUntil((route) => route.isFirst);
});
                  },
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: const Text(
                    "Volver al carrito",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        : SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: stock > 0 ? primaryColor : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: stock > 0
                  ? () {
                      mostrarSelectorVarianteProducto(
                        context: rootContext,
                        productoId: productoId,
                        producto: producto,
                        onAgregar: (itemCarrito) {
                          final agregado = agregarAlCarritoLocal(
                            itemCarrito,
                            productoId,
                          );

                          if (agregado) {
                            setDetalleState(() {
                              productoAgregado = true;
                            });

                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text("Producto agregado al carrito"),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  "La cantidad supera el stock disponible",
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }
                  : null,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: const Text(
                "Seleccionar y agregar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
  ),
),
            ],
          );
        },
      );
    },);
    },
  );
}

void mostrarImagenPantallaCompleta({
  required List<String> imagenes,
  required int indexInicial,
}) {
  final PageController controller = PageController(
    initialPage: indexInicial,
  );

  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: imagenes.length,
              itemBuilder: (_, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      imagenes[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 45,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
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
  Widget productoCarritoCard(int index) {
    final item = widget.carrito[index];

    final imagenUrl = item['imagenUrl'] ?? '';
    final cantidad = int.tryParse(item['cantidad'].toString()) ?? 1;
    final precio = double.tryParse(item['precio'].toString()) ?? 0;
    final subtotal = cantidad * precio;
    final stock = int.tryParse(item['stock'].toString()) ?? 0;

    final colorSeleccionado = item['colorSeleccionado'];
    final tallaSeleccionada = item['tallaSeleccionada'];

    item['subtotal'] = subtotal;

    return TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 350),
  tween: Tween(begin: 0.96, end: 1),
  curve: Curves.easeOutBack,
  builder: (context, scale, child) {
    return Transform.scale(
      scale: scale,
      child: child,
    );
  },
  child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => abrirDetalleDesdeCarrito(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            imagenUrl.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
  width: 86,
  height: 86,
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.network(
    imagenUrl,
    fit: BoxFit.contain,
  ),
),
                  )
                : Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: primaryColor,
                      size: 36,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (colorSeleccionado != null || tallaSeleccionada != null)
  Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [

      if (colorSeleccionado != null)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor:
                    obtenerColor(colorSeleccionado),
              ),
              const SizedBox(width: 6),
              Text(
                colorSeleccionado,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),

      if (tallaSeleccionada != null)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Talla $tallaSeleccionada",
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ],
  ),
                  const SizedBox(height: 4),
                  Text(
                    "Precio: S/ ${precio.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Subtotal: S/ ${subtotal.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Stock disponible: $stock",
                    style: TextStyle(
                      color: cantidad >= stock ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => disminuirCantidad(index),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          cantidad.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => aumentarCantidad(index),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color:
                                cantidad >= stock ? Colors.grey : primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
             onPressed: () => confirmarEliminarProducto(index),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
        ),
  );
  }

  Future<void> irARealizarPago() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    final loginOk = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
    );

    if (FirebaseAuth.instance.currentUser == null || loginOk != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes iniciar sesión para realizar el pedido"),
        ),
      );
      return;
    }
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RealizarPagoScreen(
        carrito: widget.carrito,
        total: calcularTotal(),
        actualizar: widget.actualizar,
      ),
    ),
  ).then((_) {
    setState(() {});
  });
}

  Widget carritoVacio() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.shopping_cart_outlined,
          size: 76,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            "Tu carrito está vacío",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            "Agrega productos para realizar un pedido.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),
        productosQueTePuedenInteresar(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget carritoConProductos() {
    return ListView(
      children: [
        ...List.generate(
          widget.carrito.length,
          (index) => Dismissible(
  key: Key(
    "${widget.carrito[index]['productoId']}$index",
  ),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Icon(
      Icons.delete,
      color: Colors.white,
      size: 30,
    ),
  ),
  confirmDismiss: (_) async {
  await confirmarEliminarProducto(index);
  return false;
},
  child: productoCarritoCard(index),
),
        ),
        productosQueTePuedenInteresar(),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = calcularTotal();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
  children: [
    Expanded(
      child: Text(
        "Mi Carrito (${widget.carrito.length})",
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    if (widget.carrito.isNotEmpty)
      IconButton(
        tooltip: "Vaciar carrito",
        onPressed: confirmarVaciarCarrito,
        icon: const Icon(
          Icons.delete_sweep_outlined,
          color: Colors.red,
        ),
      ),
  ],
),
              const SizedBox(height: 6),
              Text(
                "Revisa tus productos antes de hacer el pedido.",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: widget.carrito.isEmpty
                    ? carritoVacio()
                    : carritoConProductos(),
              ),
              if (widget.carrito.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
  children: [
    Row(
      children: [
        const Icon(
          Icons.receipt_long,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            "Productos",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        Text(
          "${widget.carrito.length}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    Row(
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            "Subtotal",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        Text(
          "S/ ${total.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),

    const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(),
    ),

    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total a pagar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${widget.carrito.length} producto(s)",
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        Text(
          "S/ ${total.toStringAsFixed(2)}",
          style: TextStyle(
            color: primaryColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),

    const SizedBox(height: 18),

    SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: irARealizarPago,
        icon: const Icon(
          Icons.shopping_bag,
          color: Colors.white,
        ),
        label: const Text(
          "Continuar compra",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  ],
),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
