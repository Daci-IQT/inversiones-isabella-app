
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// PANTALLA INICIO CLIENTE

////////////////////////////////////////////////////////

class InicioScreen extends StatefulWidget {
  /// Función que viene desde ClientePanel para agregar productos al carrito
  final bool Function(Map<String, dynamic>, String) agregarAlCarrito;

  /// Función que lleva al carrito desde el detalle del producto
  final void Function({
    required String productoId,
    required Map<String, dynamic> producto,
  }) irAlCarritoDesdeDetalle;

  /// Producto pendiente para reabrir el detalle cuando se vuelve desde carrito
  final String? productoDetallePendienteId;
  final Map<String, dynamic>? productoDetallePendiente;

  /// Limpia el producto pendiente después de abrirlo
  final VoidCallback limpiarDetallePendiente;

  const InicioScreen({
    super.key,
    required this.agregarAlCarrito,
    required this.irAlCarritoDesdeDetalle,
    required this.productoDetallePendienteId,
    required this.productoDetallePendiente,
    required this.limpiarDetallePendiente,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  ////////////////////////////////////////////////////////
  /// REFERENCIAS FIREBASE
  ////////////////////////////////////////////////////////

  final productosRef = FirebaseFirestore.instance.collection('productos');
  final categoriasRef = FirebaseFirestore.instance.collection('categorias');
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final configRef = FirebaseFirestore.instance.collection('configuracion');

  ////////////////////////////////////////////////////////
  /// VARIABLES DE DISEÑO Y CONTROL
  ////////////////////////////////////////////////////////

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final buscadorController = TextEditingController();

  String textoBusqueda = "";
  String? categoriaSeleccionadaId;
  String categoriaSeleccionadaNombre = "Todo";

  User? get usuarioActual => FirebaseAuth.instance.currentUser;

  ////////////////////////////////////////////////////////
  /// ABRIR DETALLE PENDIENTE AL VOLVER DEL CARRITO
  ////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      abrirDetallePendienteSiExiste();
    });
  }

  @override
  void didUpdateWidget(covariant InicioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      abrirDetallePendienteSiExiste();
    });
  }

  void abrirDetallePendienteSiExiste() {
    if (!mounted) return;

    if (widget.productoDetallePendienteId != null &&
        widget.productoDetallePendiente != null) {
      final productoId = widget.productoDetallePendienteId!;
      final producto = Map<String, dynamic>.from(
        widget.productoDetallePendiente!,
      );

      widget.limpiarDetallePendiente();

      mostrarDetalleProducto(
        productoId: productoId,
        producto: producto,
      );
    }
  }

  ////////////////////////////////////////////////////////
  /// CONVERTIR TEXTO DE COLOR A COLOR VISUAL
  ////////////////////////////////////////////////////////

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

  ////////////////////////////////////////////////////////
  /// BUSCADOR SUPERIOR FIJO
  ////////////////////////////////////////////////////////

  Widget buscadorInicio() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: primaryColor),
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: buscadorController,
              onChanged: (value) {
                setState(() {
                  textoBusqueda = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: "Buscar productos, categorías, colores...",
                border: InputBorder.none,
              ),
            ),
          ),

          if (buscadorController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                buscadorController.clear();
                setState(() {
                  textoBusqueda = "";
                });
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// CHIP DE CATEGORÍA HORIZONTAL
  ////////////////////////////////////////////////////////

  Widget categoriaChipFiltro({
    required String nombre,
    required String? id,
    required bool seleccionado,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          categoriaSeleccionadaId = id;
          categoriaSeleccionadaNombre = nombre;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: seleccionado ? primaryColor : Colors.grey.shade300,
          ),
          boxShadow: [
            if (seleccionado)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          nombre,
          style: TextStyle(
            color: seleccionado ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// CATEGORÍAS HORIZONTALES
  /// Incluye "Todo" y luego categorías ordenadas alfabéticamente
  ////////////////////////////////////////////////////////

  Widget categoriasHorizontales() {
    return StreamBuilder<QuerySnapshot>(
      stream: categoriasRef.where('activo', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 45,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categorias = snapshot.data!.docs.toList();

        categorias.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          return (dataA['nombre'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                (dataB['nombre'] ?? '').toString().toLowerCase(),
              );
        });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              categoriaChipFiltro(
                nombre: "Todo",
                id: null,
                seleccionado: categoriaSeleccionadaId == null,
              ),
              ...categorias.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return categoriaChipFiltro(
                  nombre: data['nombre'] ?? 'Categoría',
                  id: doc.id,
                  seleccionado: categoriaSeleccionadaId == doc.id,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  ////////////////////////////////////////////////////////
  /// BANNER PROMOCIONAL
  ////////////////////////////////////////////////////////

  Widget bannerPrincipal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Encuentra tus productos favoritos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Moda, carteras, sandalias y novedades para ti.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////
  /// CARD DE PRODUCTO EN INICIO
  /// Al presionar entra al detalle del producto
  ////////////////////////////////////////////////////////

  Widget productoCard({
    required String productoId,
    required Map<String, dynamic> producto,
  }) {
    final imagenUrl = producto['imagenUrl'] ?? '';
    final imagenes = List<String>.from(producto['imagenes'] ?? []);
    final stock = int.tryParse(producto['stock'].toString()) ?? 0;
    final precio = producto['precio'] ?? 0;

    final imagenMostrar = imagenes.isNotEmpty
        ? imagenes.first
        : imagenUrl.toString().isNotEmpty
            ? imagenUrl
            : "";

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        mostrarDetalleProducto(
          productoId: productoId,
          producto: producto,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
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
                                size: 42,
                              ),
                            ),
                    ),
                  ),

                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),

                  if (stock <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Sin stock",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? 'Producto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    producto['categoriaNombre'] ?? 'Sin categoría',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "S/ $precio",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    stock > 0 ? "Stock: $stock" : "No disponible",
                    style: TextStyle(
                      color: stock > 0 ? Colors.green : Colors.red,
                      fontSize: 11,
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
  }

  ////////////////////////////////////////////////////////
  /// PRODUCTOS RELACIONADOS EN EL DETALLE
  ////////////////////////////////////////////////////////

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
        if (!snapshot.hasData) return const SizedBox();

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
              height: 185,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: relacionados.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = relacionados[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return productoRelacionadoMini(
                    productoId: doc.id,
                    producto: data,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////////////////////////////
  /// CARD MINI DE PRODUCTO RELACIONADO
  ////////////////////////////////////////////////////////

  Widget productoRelacionadoMini({
    required String productoId,
    required Map<String, dynamic> producto,
  }) {
    final imagenUrl = producto['imagenUrl'] ?? '';
    final imagenes = List<String>.from(producto['imagenes'] ?? []);
    final stock = int.tryParse(producto['stock'].toString()) ?? 0;

    final imagenMostrar = imagenes.isNotEmpty
        ? imagenes.first
        : imagenUrl.toString().isNotEmpty
            ? imagenUrl
            : "";

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);

        Future.delayed(const Duration(milliseconds: 250), () {
          mostrarDetalleProducto(
            productoId: productoId,
            producto: producto,
          );
        });
      },
      child: Container(
        width: 125,
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
                height: 95,
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
                    producto['nombre'] ?? 'Producto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "S/ ${producto['precio'] ?? 0}",
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
                      color: stock > 0 ? Colors.green : Colors.red,
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
  }

  ////////////////////////////////////////////////////////
  /// DETALLE DEL PRODUCTO
  ////////////////////////////////////////////////////////

  void mostrarDetalleProducto({
    required String productoId,
    required Map<String, dynamic> producto,
  }) {
    final imagenUrl = producto['imagenUrl'] ?? '';
    final imagenes = List<String>.from(producto['imagenes'] ?? []);
    final colores = List<String>.from(producto['colores'] ?? []);
    final tallas = List<String>.from(producto['tallas'] ?? []);
    final stock = int.tryParse(producto['stock'].toString()) ?? 0;

    final List<String> imagenesMostrar = imagenes.isNotEmpty
        ? imagenes
        : imagenUrl.toString().isNotEmpty
            ? [imagenUrl]
            : [];

    String? colorSeleccionado;
    String? tallaSeleccionada;
    int cantidad = 1;
    bool productoAgregadoActual = false;

    String? mensajeModal;
    Color colorMensajeModal = Colors.green;
    IconData iconoMensajeModal = Icons.check_circle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void mostrarMensajeModal({
              required String mensaje,
              required Color color,
              required IconData icono,
            }) {
              setModalState(() {
                mensajeModal = mensaje;
                colorMensajeModal = color;
                iconoMensajeModal = icono;
              });

              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setModalState(() {
                    mensajeModal = null;
                  });
                }
              });
            }

            return Stack(
              children: [
                DraggableScrollableSheet(
                  initialChildSize: 0.92,
                  maxChildSize: 0.96,
                  minChildSize: 0.65,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 330,
                            width: double.infinity,
                            child: imagenesMostrar.isNotEmpty
                                ? CarouselSlider(
                                    options: CarouselOptions(
                                      height: 330,
                                      viewportFraction: 1,
                                      enableInfiniteScroll:
                                          imagenesMostrar.length > 1,
                                    ),
                                    items: imagenesMostrar.map((img) {
                                      return Image.network(
                                        img,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
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
                                      ? "Stock disponible: $stock"
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

                                if (colores.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  const Text(
                                    "Colores",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    children: colores.map((color) {
                                      final seleccionado =
                                          colorSeleccionado == color;

                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            colorSeleccionado = color;
                                            productoAgregadoActual = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: seleccionado
                                                  ? primaryColor
                                                  : Colors.grey.shade300,
                                              width: seleccionado ? 3 : 1,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                obtenerColor(color),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],

                                if (tallas.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  const Text(
                                    "Tallas",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: tallas.map((talla) {
                                      final seleccionado =
                                          tallaSeleccionada == talla;

                                      return ChoiceChip(
                                        label: Text(talla),
                                        selected: seleccionado,
                                        selectedColor:
                                            primaryColor.withValues(alpha: 0.18),
                                        labelStyle: TextStyle(
                                          color: seleccionado
                                              ? primaryColor
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onSelected: (_) {
                                          setModalState(() {
                                            tallaSeleccionada = talla;
                                            productoAgregadoActual = false;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                const Text(
                                  "Cantidad",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: cantidad > 1
                                          ? () {
                                              setModalState(() {
                                                cantidad--;
                                                productoAgregadoActual = false;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      "$cantidad",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: cantidad < stock
                                          ? () {
                                              setModalState(() {
                                                cantidad++;
                                                productoAgregadoActual = false;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),

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
                    );
                  },
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: productoAgregadoActual
                              ? Colors.green
                              : primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: stock > 0
                            ? () {
                                if (productoAgregadoActual) {
                                  Navigator.pop(context);

                                  widget.irAlCarritoDesdeDetalle(
                                    productoId: productoId,
                                    producto: producto,
                                  );

                                  return;
                                }

                                if (colores.isNotEmpty &&
                                    colorSeleccionado == null) {
                                  mostrarMensajeModal(
                                    mensaje: "Selecciona un color",
                                    color: Colors.orange,
                                    icono: Icons.color_lens,
                                  );
                                  return;
                                }

                                if (tallas.isNotEmpty &&
                                    tallaSeleccionada == null) {
                                  mostrarMensajeModal(
                                    mensaje: "Selecciona una talla",
                                    color: Colors.redAccent,
                                    icono: Icons.straighten,
                                  );
                                  return;
                                }

                                final double precio = double.tryParse(
                                      producto['precio'].toString(),
                                    ) ??
                                    0;

                                final productoCarrito = {
                                  ...producto,
                                  'productoId': productoId,
                                  'colorSeleccionado': colorSeleccionado,
                                  'tallaSeleccionada': tallaSeleccionada,
                                  'cantidad': cantidad,
                                  'subtotal': cantidad * precio,
                                };

                                final agregado = widget.agregarAlCarrito(
                                  productoCarrito,
                                  productoId,
                                );

                                if (agregado) {
                                  setModalState(() {
                                    productoAgregadoActual = true;
                                  });

                                  mostrarMensajeModal(
                                    mensaje:
                                        "${producto['nombre']} agregado al carrito",
                                    color: primaryColor,
                                    icono: Icons.check_circle,
                                  );
                                } else {
                                  mostrarMensajeModal(
                                    mensaje:
                                        "La cantidad supera el stock disponible",
                                    color: Colors.redAccent,
                                    icono: Icons.warning_amber_rounded,
                                  );
                                }
                              }
                            : null,
                        icon: Icon(
                          productoAgregadoActual
                              ? Icons.shopping_cart_checkout
                              : Icons.shopping_cart,
                          color: Colors.white,
                        ),
                        label: Text(
                          productoAgregadoActual
                              ? "Ir al carrito"
                              : "Agregar al carrito",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (mensajeModal != null)
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorMensajeModal,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(iconoMensajeModal, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                mensajeModal!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////
  /// GRID DE PRODUCTOS CON BUSCADOR Y FILTRO POR CATEGORÍA
  ////////////////////////////////////////////////////////

  Widget productosGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: productosRef.where('activo', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar productos"));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final productosFiltrados = snapshot.data!.docs.where((doc) {
          final producto = doc.data() as Map<String, dynamic>;

          final nombre = (producto['nombre'] ?? '').toString().toLowerCase();
          final descripcion =
              (producto['descripcion'] ?? '').toString().toLowerCase();
          final categoria =
              (producto['categoriaNombre'] ?? '').toString().toLowerCase();
          final precio = (producto['precio'] ?? 0).toString().toLowerCase();
          final categoriaId = producto['categoriaId'];

          final colores = List<String>.from(
            producto['colores'] ?? [],
          ).join(' ').toLowerCase();

          final tallas = List<String>.from(
            producto['tallas'] ?? [],
          ).join(' ').toLowerCase();

          final coincideBusqueda = nombre.contains(textoBusqueda) ||
              descripcion.contains(textoBusqueda) ||
              categoria.contains(textoBusqueda) ||
              precio.contains(textoBusqueda) ||
              colores.contains(textoBusqueda) ||
              tallas.contains(textoBusqueda);

          final coincideCategoria = categoriaSeleccionadaId == null
              ? true
              : categoriaSeleccionadaId == categoriaId;

          return coincideBusqueda && coincideCategoria;
        }).toList();

        if (productosFiltrados.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text("No se encontraron productos")),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int columnas = 2;

            if (constraints.maxWidth >= 900) {
              columnas = 4;
            } else if (constraints.maxWidth >= 600) {
              columnas = 3;
            }

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: productosFiltrados.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final doc = productosFiltrados[index];
                final producto = doc.data() as Map<String, dynamic>;

                return productoCard(
                  productoId: doc.id,
                  producto: producto,
                );
              },
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////
  /// LIBERAR CONTROLADOR
  ////////////////////////////////////////////////////////

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////
  /// BUILD PRINCIPAL
  /// Buscador y categorías quedan fijos.
  /// Solo se mueve el contenido de productos.
  ////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: Column(
          children: [
            ////////////////////////////////////////////////////////
            /// PARTE SUPERIOR FIJA
            ////////////////////////////////////////////////////////

            Container(
              color: const Color(0xFFFFF4F7),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ////////////////////////////////////////////////////////
                  /// DATOS DE EMPRESA Y CLIENTE
                  ////////////////////////////////////////////////////////

                  if (usuarioActual != null)
  StreamBuilder<DocumentSnapshot>(
    stream: configRef.doc('negocio').snapshots(),
    builder: (context, negocioSnapshot) {
      String nombreNegocio = "Inversiones Isabella";
      String logoUrl = "";

      if (negocioSnapshot.hasData && negocioSnapshot.data!.exists) {
        final data = negocioSnapshot.data!.data() as Map<String, dynamic>;
        nombreNegocio = data['nombreNegocio'] ?? nombreNegocio;
        logoUrl = data['logoUrl'] ?? "";
      }

      return StreamBuilder<DocumentSnapshot>(
        stream: usuariosRef.doc(usuarioActual!.uid).snapshots(),
        builder: (context, clienteSnapshot) {
          String nombreCliente = "Cliente";

          if (clienteSnapshot.hasData && clienteSnapshot.data!.exists) {
            final data = clienteSnapshot.data!.data() as Map<String, dynamic>;
            nombreCliente = data['nombre'] ?? "Cliente";
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                backgroundImage: logoUrl.isNotEmpty
                    ? NetworkImage(logoUrl)
                    : null,
                child: logoUrl.isEmpty
                    ? Icon(Icons.store, color: primaryColor)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreNegocio,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Hola, $nombreCliente 👋",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.notifications_none,
                color: primaryColor,
              ),
            ],
          );
        },
      );
    },
  ),

                  const SizedBox(height: 14),

                  buscadorInicio(),

                  const SizedBox(height: 12),

                  categoriasHorizontales(),
                ],
              ),
            ),

            ////////////////////////////////////////////////////////
            /// CONTENIDO CON SCROLL
            ////////////////////////////////////////////////////////

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (usuarioActual != null) bannerPrincipal(),

                    if (usuarioActual != null) const SizedBox(height: 20),

                    Text(
                      categoriaSeleccionadaNombre == "Todo"
                          ? "Todos los productos"
                          : categoriaSeleccionadaNombre,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    productosGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
