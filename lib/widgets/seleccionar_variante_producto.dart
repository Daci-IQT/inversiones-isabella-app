import 'package:flutter/material.dart';

Future<void> mostrarSelectorVarianteProducto({
  required BuildContext context,
  required String productoId,
  required Map<String, dynamic> producto,
  required Function(Map<String, dynamic> itemCarrito) onAgregar,
}) async {
  String? colorSeleccionado;
  String? tallaSeleccionada;
  int cantidad = 1;

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final colores = List<String>.from(producto['colores'] ?? []);
  final tallas = List<String>.from(producto['tallas'] ?? []);
  final stockVariantes = Map<String, dynamic>.from(
    producto['stockVariantes'] ?? {},
  );

  int obtenerStockDisponible() {
    if (colores.isNotEmpty && tallas.isNotEmpty) {
      if (colorSeleccionado == null || tallaSeleccionada == null) return 0;

      final key = "${colorSeleccionado}_$tallaSeleccionada";
      return int.tryParse(stockVariantes[key].toString()) ?? 0;
    }

    return int.tryParse(producto['stock'].toString()) ?? 0;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final stockDisponible = obtenerStockDisponible();
          final precio = double.tryParse(producto['precio'].toString()) ?? 0;

          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    producto['nombre'] ?? 'Producto',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "S/ ${precio.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (colores.isNotEmpty) ...[
                    const Text(
                      "Selecciona color",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colores.map((color) {

  bool disponible = true;

  if (tallaSeleccionada != null) {
    final key = "${color}_$tallaSeleccionada";

    disponible =
        (int.tryParse(stockVariantes[key].toString()) ?? 0) > 0;
  }

  final seleccionado = colorSeleccionado == color;

  return Opacity(
    opacity: disponible ? 1 : 0.35,
    child: ChoiceChip(
      label: Text(color),
      selected: seleccionado,
      selectedColor:
          primaryColor.withValues(alpha: 0.20),

      onSelected: disponible
          ? (_) {
              setModalState(() {
                colorSeleccionado = color;
                cantidad = 1;
              });
            }
          : null,
    ),
  );
}).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (tallas.isNotEmpty) ...[
                    const Text(
                      "Selecciona talla",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tallas.map((talla) {

  bool disponible = true;

  if (colorSeleccionado != null) {
    final key = "${colorSeleccionado}_$talla";

    disponible =
        (int.tryParse(stockVariantes[key].toString()) ?? 0) > 0;
  }

  final seleccionado = tallaSeleccionada == talla;

  return Opacity(
    opacity: disponible ? 1 : 0.35,
    child: ChoiceChip(
      label: Text(talla),
      selected: seleccionado,
      selectedColor:
          primaryColor.withValues(alpha: 0.20),

      onSelected: disponible
          ? (_) {
              setModalState(() {
                tallaSeleccionada = talla;
                cantidad = 1;
              });
            }
          : null,
    ),
  );
}).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: stockDisponible > 0
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      stockDisponible > 0
                          ? "Stock disponible: $stockDisponible"
                          : "Sin stock disponible para esta variante",
                      style: TextStyle(
                        color: stockDisponible > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Text(
                        "Cantidad",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: cantidad > 1
                            ? () {
                                setModalState(() {
                                  cantidad--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        "$cantidad",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        onPressed: cantidad < stockDisponible
                            ? () {
                                setModalState(() {
                                  cantidad++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

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
                      onPressed: stockDisponible <= 0
                          ? null
                          : () {
                              if (colores.isNotEmpty &&
                                  colorSeleccionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Selecciona un color"),
                                  ),
                                );
                                return;
                              }

                              if (tallas.isNotEmpty &&
                                  tallaSeleccionada == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Selecciona una talla"),
                                  ),
                                );
                                return;
                              }

                              final itemCarrito = {
                                'productoId': productoId,
                                'nombre': producto['nombre'],
                                'descripcion': producto['descripcion'],
                                'precio': precio,
                                'imagenUrl': producto['imagenUrl'],
                                'imagenes': producto['imagenes'] ?? [],
                                'cantidad': cantidad,
                                'subtotal': cantidad * precio,
                                'stock': stockDisponible,
                                'categoriaId': producto['categoriaId'],
                                'categoriaNombre': producto['categoriaNombre'],
                                'colorSeleccionado': colorSeleccionado,
                                'tallaSeleccionada': tallaSeleccionada,
                                'stockKey': colorSeleccionado != null &&
                                        tallaSeleccionada != null
                                    ? "${colorSeleccionado}_$tallaSeleccionada"
                                    : null,
                              };

                              onAgregar(itemCarrito);

                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
                      label: const Text(
                        "Agregar al carrito",
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
          );
        },
      );
    },
  );
}