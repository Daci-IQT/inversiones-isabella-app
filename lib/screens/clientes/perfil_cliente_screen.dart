
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../clientes/carrito_cliente_screen.dart';
import '../clientes/ayuda_cliente_screen.dart';
import '../clientes/direcciones_cliente_screen.dart';
import '../clientes/reseñas_cliente.dart';
import '../clientes/configuracion_cliente_screen.dart';
import '../clientes/editarperfil_cliente_screen.dart';
import '../clientes/pedidos_cliente_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/seleccionar_variante_producto.dart';


/// PANTALLA PRINCIPAL PERFIL CLIENTE


class PerfilClienteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final VoidCallback actualizar;

  const PerfilClienteScreen({
    super.key,
    required this.carrito,
    required this.actualizar,
  });

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final productosRef = FirebaseFirestore.instance.collection('productos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  User? get usuarioActual => auth.currentUser;

  void irAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoClienteScreen(
          carrito: widget.carrito,
          actualizar: widget.actualizar,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
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

  bool agregarAlCarritoDesdePerfil(
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

  void mostrarDetalleProductoPerfil({
  required String productoId,
  required Map<String, dynamic> producto,
}) {
  final imagenUrl = producto['imagenUrl'] ?? '';
  final imagenes = List<String>.from(producto['imagenes'] ?? []);
  final stock = int.tryParse(producto['stock'].toString()) ?? 0;
 final rootContext = Navigator.of(context, rootNavigator: true).context;
 bool productoAgregado = false;

  final List<String> imagenesMostrar = imagenes.isNotEmpty
      ? imagenes
      : imagenUrl.toString().isNotEmpty
          ? [imagenUrl]
          : [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) {
return StatefulBuilder(
builder: (context, setDetalleState) { return DraggableScrollableSheet(
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
                      height: 320,
                      width: double.infinity,
                      child: imagenesMostrar.isNotEmpty
                          ? PageView(
                              children: imagenesMostrar.map((img) {
                                return Image.network(
                                  img,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                );
                              }).toList(),
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
                          Text(
                            producto['nombre'] ?? 'Producto',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "S/ ${producto['precio'] ?? 0}",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            stock > 0
                                ? "Stock total disponible: $stock"
                                : "Sin stock",
                            style: TextStyle(
                              color: stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            producto['descripcion'] ?? 'Sin descripción',
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 22),

                          if (List<String>.from(producto['colores'] ?? [])
                              .isNotEmpty) ...[
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
                              children:
                                  List<String>.from(producto['colores'] ?? [])
                                      .map((color) {
                                return Chip(
                                  label: Text(color),
                                  avatar: CircleAvatar(
                                    backgroundColor: obtenerColor(color),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                          ],

                          if (List<String>.from(producto['tallas'] ?? [])
                              .isNotEmpty) ...[
                            const Text(
                              "Tallas disponibles",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  List<String>.from(producto['tallas'] ?? [])
                                      .map((talla) {
                                return Chip(label: Text(talla));
                              }).toList(),
                            ),
                          ],

                          productosRelacionadosPerfil(
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
                    icon: const Icon(Icons.close, color: Colors.white),
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
                irAlCarrito();
              },
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: const Text(
                "Ir al carrito",
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
                      final agregado = agregarAlCarritoDesdePerfil(
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
      );},);
     


      
    },
  );
}

Widget productosRelacionadosPerfil({
  required String productoActualId,
  required String? categoriaId,
}) {
  if (categoriaId == null) return const SizedBox();

  return StreamBuilder<QuerySnapshot>(
    stream: productosRef
        .where('activo', isEqualTo: true)
        .where('categoriaId', isEqualTo: categoriaId)
        .limit(8)
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

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relacionados.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.70,
            ),
            itemBuilder: (context, index) {
              final doc = relacionados[index];
              final data = doc.data() as Map<String, dynamic>;

              final imagenUrl = data['imagenUrl'] ?? '';
              final imagenes = List<String>.from(data['imagenes'] ?? []);
              final imagenMostrar =
                  imagenes.isNotEmpty ? imagenes.first : imagenUrl;

              final stock =
                  int.tryParse(data['stock'].toString()) ?? 0;

              final precio =
                  double.tryParse(data['precio'].toString()) ?? 0;

              return GestureDetector(
                onTap: () {
                  mostrarDetalleProductoPerfil(
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
                          top: Radius.circular(18),
                        ),
                        child: SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: imagenMostrar.toString().isNotEmpty
                              ? Container(
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                  child: Image.network(
                                    imagenMostrar,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Container(
                                  color: primaryColor.withValues(alpha: 0.10),
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: primaryColor,
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(9),
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
                                "S/ ${precio.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                stock > 0 ? "Disponible" : "Sin stock",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: stock > 0
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
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
        ],
      );
    },
  );
}

  Widget accesosRapidosPerfil() {
    return SizedBox(
      height: 118,
      child: Row(
        children: [
          Expanded(
            child: botonAccesoPerfil(
              icono: Icons.inventory_2_outlined,
              titulo: "Mis pedidos",
              onTap: () {
                if (!usuarioLogueado()) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PedidosClienteScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: botonAccesoPerfil(
              icono: Icons.rate_review_outlined,
              titulo: "Mis reseñas",
              onTap: () {
                if (!usuarioLogueado()) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MisResenasClienteScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: botonAccesoPerfil(
              icono: Icons.location_on_outlined,
              titulo: "Direcciones",
              onTap: () {
                if (!usuarioLogueado()) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DireccionesClienteScreen(
                      uid: usuarioActual!.uid,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  bool usuarioLogueado() {
  return FirebaseAuth.instance.currentUser != null;
}

  Widget botonAccesoPerfil({
    required IconData icono,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              child: Icon(icono, color: primaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productosPerfilCliente() {
    return StreamBuilder<QuerySnapshot>(
      stream: productosRef
          .where('activo', isEqualTo: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final productos = snapshot.data!.docs;

        if (productos.isEmpty) return const SizedBox();

        return GridView.builder(
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
                mostrarDetalleProductoPerfil(
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
                                ? Container(
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.network(
    imagenMostrar,
    fit: BoxFit.contain,
  ),
)
                                : Container(
                                    color: primaryColor.withValues(alpha: 0.10),
                                    child: Icon(
                                      Icons.shopping_bag,
                                      color: primaryColor,
                                      size: 42,
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
                              color: stock > 0 ? Colors.green : Colors.red,
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
                                onPressed: () {
                                  mostrarDetalleProductoPerfil(
                                    productoId: doc.id,
                                    producto: {
                                      ...data,
                                      'productoId': doc.id,
                                    },
                                  );
                                },
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (usuarioActual == null) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFF4F7),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: primaryColor,
                ),

                const SizedBox(height: 16),

                const Text(
                  "Inicia sesión",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Accede a tu perfil, pedidos, direcciones y reseñas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final loginOk = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(),
                        ),
                      );

                      if (loginOk == true || FirebaseAuth.instance.currentUser != null) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(
                      Icons.login,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: usuariosRef.doc(usuarioActual!.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>
                : {};

            final nombre =
                data['nombre'] ?? usuarioActual!.displayName ?? 'Cliente';
            final correo = data['correo'] ?? usuarioActual!.email ?? '';
            final fotoUrl = data['fotoUrl'];

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarPerfilClienteScreen(
                                uid: usuarioActual!.uid,
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          backgroundImage: fotoUrl != null && fotoUrl != ''
                              ? NetworkImage(fotoUrl)
                              : null,
                          child: fotoUrl == null || fotoUrl == ''
                              ? Icon(
                                  Icons.person,
                                  color: primaryColor,
                                  size: 32,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditarPerfilClienteScreen(
                                  uid: usuarioActual!.uid,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                correo,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.help_outline, color: primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AyudaClienteScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.settings, color: primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfiguracionClienteScreen(
                                uid: usuarioActual!.uid,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        "Mi cuenta",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Gestiona tus pedidos, reseñas y direcciones.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      accesosRapidosPerfil(),
                      const SizedBox(height: 26),
                      const Text(
                        "Productos que te pueden interesar",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Explora productos disponibles en la tienda.",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      productosPerfilCliente(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}