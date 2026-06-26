
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../widgets/seleccionar_variante_producto.dart';

/// PANTALLA CATEGORÍAS CLIENTE
class CategoriasClienteScreen extends StatefulWidget {
  final bool Function(Map<String, dynamic>, String) agregarAlCarrito;

  final void Function({
    required String productoId,
    required Map<String, dynamic> producto,
  }) irAlCarritoDesdeDetalle;

  final String? productoDetallePendienteId;
  final Map<String, dynamic>? productoDetallePendiente;
  final VoidCallback limpiarDetallePendiente;

  const CategoriasClienteScreen({
    super.key,
    required this.agregarAlCarrito,
    required this.irAlCarritoDesdeDetalle,
    required this.productoDetallePendienteId,
    required this.productoDetallePendiente,
    required this.limpiarDetallePendiente,
  });

  @override
  State<CategoriasClienteScreen> createState() =>
      _CategoriasClienteScreenState();
}

class _CategoriasClienteScreenState extends State<CategoriasClienteScreen> {
  final categoriasRef = FirebaseFirestore.instance.collection('categorias');
  final productosRef = FirebaseFirestore.instance.collection('productos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final buscadorController = TextEditingController();

  String textoBusqueda = "";
  String? categoriaSeleccionadaId;
  String categoriaSeleccionadaNombre = "Todos";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      abrirDetallePendienteSiExiste();
    });
  }

  @override
  void didUpdateWidget(covariant CategoriasClienteScreen oldWidget) {
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

  int columnasResponsive(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 700) return 3;
    return 2;
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

  Widget buscadorProfesional() {
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
                hintText: "Buscar ropa, carteras, sandalias...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
          ),
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget categoriaLateralItem({
    required String nombre,
    required String? id,
    required bool seleccionado,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          categoriaSeleccionadaId = id;
          categoriaSeleccionadaNombre = nombre;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: seleccionado ? primaryColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: seleccionado ? primaryColor : Colors.black87,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget productoCard({
    required String productoId,
    required Map<String, dynamic> producto,
  }) {
    final imagenUrl = producto['imagenUrl'] ?? '';
    final imagenes = List<String>.from(producto['imagenes'] ?? []);
    final stock = int.tryParse(producto['stock'].toString()) ?? 0;
    final precio = producto['precio'] ?? 0;

    final List<String> imagenesMostrar = imagenes.isNotEmpty
        ? imagenes
        : imagenUrl.toString().isNotEmpty
            ? [imagenUrl]
            : [];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        mostrarDetalleProducto(
          productoId: productoId,
          producto: producto,
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
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imagenesMostrar.isNotEmpty
                          ? Container(
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.network(
    imagenesMostrar.first,
    fit: BoxFit.contain,
  ),
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
                            top: Radius.circular(18),
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
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 8,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        producto['nombre'] ?? 'Producto',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),

      const SizedBox(height: 6),

      Row(
        children: [
          Expanded(
            child: Text(
              "S/ ${(double.tryParse(
                producto['precio'].toString(),
              ) ?? 0).toStringAsFixed(2)}",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          if ((producto['destacado'] ?? false))
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "TOP",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),

      const SizedBox(height: 8),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            producto['categoriaNombre'] ?? '',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),

      const SizedBox(height: 8),

      Text(
        stock > 0
            ? "Disponible ($stock)"
            : "Agotado",
        style: TextStyle(
          color: stock > 0
              ? Colors.green
              : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
              height: 185,
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
                      imagenes.isNotEmpty ? imagenes.first : imagenUrl.toString();

                  return GestureDetector(
                    onTap: () {
  mostrarDetalleProducto(
    productoId: doc.id,
    producto: data,
  );
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
                              child: imagenMostrar.isNotEmpty
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
                },
              ),
            ),
          ],
        );
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

  widget.irAlCarritoDesdeDetalle(
    productoId: productoId,
    producto: producto,
  );
});
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
                          final agregado = widget.agregarAlCarrito(
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

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query productosQuery = productosRef.where(
      'activo',
      isEqualTo: true,
    );

    if (categoriaSeleccionadaId != null) {
      productosQuery = productosQuery.where(
        'categoriaId',
        isEqualTo: categoriaSeleccionadaId,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: buscadorProfesional(),
            ),
            Expanded(
              child: Row(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final double anchoCategorias =
                          screenWidth >= 700 ? 150 : 86;

                      return Container(
                        width: anchoCategorias,
                        color: const Color(0xFFF7F7F7),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: categoriasRef
                              .where('activo', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return ListView(
                              children: [
                                categoriaLateralItem(
                                nombre: "Todos",
                                  id: null,
                                  seleccionado: categoriaSeleccionadaId == null,
                                ),
                                ...snapshot.data!.docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return categoriaLateralItem(
                                    nombre: data['nombre'] ?? 'Categoría',
                                    id: doc.id,
                                    seleccionado:
                                        categoriaSeleccionadaId == doc.id,
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: productosQuery.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error al cargar productos"),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final productosFiltrados =
                              snapshot.data!.docs.where((doc) {
                            final producto =
                                doc.data() as Map<String, dynamic>;

                            final nombre = (producto['nombre'] ?? '')
                                .toString()
                                .toLowerCase();

                            final descripcion = (producto['descripcion'] ?? '')
                                .toString()
                                .toLowerCase();

                            final categoria =
                                (producto['categoriaNombre'] ?? '')
                                    .toString()
                                    .toLowerCase();

                            final precio = (producto['precio'] ?? 0)
                                .toString()
                                .toLowerCase();

                            final colores = List<String>.from(
                              producto['colores'] ?? [],
                            ).join(' ').toLowerCase();

                            final tallas = List<String>.from(
                              producto['tallas'] ?? [],
                            ).join(' ').toLowerCase();

                            return nombre.contains(textoBusqueda) ||
                                descripcion.contains(textoBusqueda) ||
                                categoria.contains(textoBusqueda) ||
                                precio.contains(textoBusqueda) ||
                                colores.contains(textoBusqueda) ||
                                tallas.contains(textoBusqueda);
                          }).toList();

                          if (productosFiltrados.isEmpty) {
                            return const Center(
                              child: Text("No se encontraron productos"),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final columnas =
                                  columnasResponsive(constraints.maxWidth);

                              return GridView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: productosFiltrados.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnas,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.58,
                                ),
                                itemBuilder: (context, index) {
                                  final doc = productosFiltrados[index];

                                  final producto =
                                      doc.data() as Map<String, dynamic>;

                                  return productoCard(
                                    productoId: doc.id,
                                    producto: producto,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
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
}