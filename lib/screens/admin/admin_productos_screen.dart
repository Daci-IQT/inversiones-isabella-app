import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';


/// PANTALLA PRODUCTOS ADMIN
///////////////

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});

  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  final productosRef = FirebaseFirestore.instance.collection('productos');
  final categoriasRef = FirebaseFirestore.instance.collection('categorias');

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();
  final buscadorController = TextEditingController();
  final colorController = TextEditingController();

  String? categoriaId;
  String? categoriaNombre;
  bool categoriaActivaActual = true;

  String textoBusqueda = "";
  String? categoriaFiltroId;

  List<File> imagenesSeleccionadas = [];
  List<String> imagenesActualesUrls = [];

  List<String> colores = [];
  List<String> tallas = [];

  final List<String> tallasDisponibles = [
    "XS",
    "S",
    "M",
    "L",
    "XL",
    "XXL",
    "35",
    "36",
    "37",
    "38",
    "39",
    "40",
    "41",
    "42",
  ];

  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
    precioController.clear();
    stockController.clear();
    colorController.clear();

    categoriaId = null;
    categoriaNombre = null;
    categoriaActivaActual = true;

    imagenesSeleccionadas.clear();
    imagenesActualesUrls.clear();

    colores.clear();
    tallas.clear();
  }

  Future<void> seleccionarImagenes() async {
    final List<XFile> imagenes = await picker.pickMultiImage(
      imageQuality: 75,
    );

    if (imagenes.isNotEmpty) {
      setState(() {
        imagenesSeleccionadas.addAll(
          imagenes.map((img) => File(img.path)).toList(),
        );
      });
    }
  }

  Future<List<String>> subirImagenesProducto() async {
    List<String> urls = [...imagenesActualesUrls];

    for (final imagen in imagenesSeleccionadas) {
      final nombreArchivo =
          "productos/${DateTime.now().millisecondsSinceEpoch}_${imagen.path.split('/').last}";

      final ref = FirebaseStorage.instance.ref().child(nombreArchivo);

      await ref.putFile(imagen);

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<Map<String, dynamic>?> obtenerCategoriaPorId(String id) async {
    final doc = await categoriasRef.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> guardarProducto({String? productoId}) async {
    if (nombreController.text.trim().isEmpty ||
        precioController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty ||
        categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    final imagenesUrls = await subirImagenesProducto();
    final imagenPrincipal = imagenesUrls.isNotEmpty ? imagenesUrls.first : "";

    final data = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'precio': double.tryParse(precioController.text.trim()) ?? 0,
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'imagenUrl': imagenPrincipal,
      'imagenes': imagenesUrls,
      'colores': colores,
      'tallas': tallas,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    if (productoId == null) {
      await productosRef.add({
        ...data,
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    } else {
      await productosRef.doc(productoId).update(data);
    }

    limpiarCampos();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productoId == null
                ? "Producto registrado correctamente"
                : "Producto actualizado correctamente",
          ),
        ),
      );
    }
  }

  Future<void> cambiarEstadoProducto(String id, bool estadoActual) async {
    await productosRef.doc(id).update({
      'activo': !estadoActual,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estadoActual
                ? "Producto inhabilitado correctamente"
                : "Producto habilitado correctamente",
          ),
        ),
      );
    }
  }

  Future<void> eliminarProductoSeguro(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: const Text(
          "Esta acción es permanente.\n\n"
          "Solo elimina el producto si fue creado por error y no tiene pedidos, ventas ni historial.\n\n"
          "¿Deseas eliminarlo definitivamente?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await productosRef.doc(id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Producto eliminado definitivamente")),
        );
      }
    }
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

  Widget barraStock(int stock) {
    double valor = stock >= 20 ? 1 : stock / 20;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 6,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(
          stock < 4
              ? Colors.red
              : stock < 10
                  ? Colors.orange
                  : Colors.green,
        ),
      ),
    );
  }

  Widget alertaBajoStock(int stock) {
    if (stock >= 4) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        "⚠ Bajo stock",
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void mostrarFormularioProducto({
    String? productoId,
    Map<String, dynamic>? producto,
  }) async {
    if (producto != null) {
      nombreController.text = producto['nombre'] ?? '';
      descripcionController.text = producto['descripcion'] ?? '';
      precioController.text = producto['precio'].toString();
      stockController.text = producto['stock'].toString();

      categoriaId = producto['categoriaId'];
      categoriaNombre = producto['categoriaNombre'];

      imagenesActualesUrls = List<String>.from(producto['imagenes'] ?? []);

      if (imagenesActualesUrls.isEmpty &&
          producto['imagenUrl'] != null &&
          producto['imagenUrl'].toString().isNotEmpty) {
        imagenesActualesUrls.add(producto['imagenUrl']);
      }

      imagenesSeleccionadas.clear();

      colores = List<String>.from(producto['colores'] ?? []);
      tallas = List<String>.from(producto['tallas'] ?? []);

      if (categoriaId != null) {
        final categoriaData = await obtenerCategoriaPorId(categoriaId!);
        categoriaActivaActual = categoriaData?['activo'] ?? true;
      }
    } else {
      limpiarCampos();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void actualizarModal(VoidCallback action) {
              setModalState(action);
              setState(() {});
            }

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
                          Expanded(
                            child: Text(
                              productoId == null
                                  ? "Nuevo Producto"
                                  : "Editar Producto",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              limpiarCampos();
                              Navigator.pop(context);
                            },
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
                            const Text(
                              "Imágenes del producto",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ...imagenesActualesUrls.map((url) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          url,
                                          width: 85,
                                          height: 85,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            actualizarModal(() {
                                              imagenesActualesUrls.remove(url);
                                            });
                                          },
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                ...imagenesSeleccionadas.map((file) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          file,
                                          width: 85,
                                          height: 85,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            actualizarModal(() {
                                              imagenesSeleccionadas.remove(file);
                                            });
                                          },
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                GestureDetector(
                                  onTap: () async {
                                    final List<XFile> imagenes =
                                        await picker.pickMultiImage(
                                      imageQuality: 75,
                                    );

                                    if (imagenes.isNotEmpty) {
                                      actualizarModal(() {
                                        imagenesSeleccionadas.addAll(
                                          imagenes
                                              .map((img) => File(img.path))
                                              .toList(),
                                        );
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      color:
                                          primaryColor.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor
                                            .withValues(alpha: 0.30),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: nombreController,
                              decoration: const InputDecoration(
                                labelText: "Nombre del producto *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descripcionController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: "Descripción",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: precioController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Precio *",
                                prefixText: "S/ ",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Stock general *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: categoriasRef
                                  .where('activo', isEqualTo: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final categoriasActivas = snapshot.data!.docs;

                                final existeCategoriaSeleccionada =
                                    categoriaId != null &&
                                        categoriasActivas.any(
                                          (doc) => doc.id == categoriaId,
                                        );

                                final dropdownItems =
                                    categoriasActivas.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text(
                                      data['nombre'] ?? 'Sin nombre',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList();

                                if (categoriaId != null &&
                                    !existeCategoriaSeleccionada &&
                                    categoriaNombre != null) {
                                  dropdownItems.add(
                                    DropdownMenuItem<String>(
                                      value: categoriaId,
                                      child: Text(
                                        "$categoriaNombre (Inactiva)",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<String>(
                                  value: categoriaId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: "Categoría *",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: dropdownItems,
                                  onChanged: (value) {
                                    final doc = categoriasActivas.where(
                                      (element) => element.id == value,
                                    );

                                    if (doc.isNotEmpty) {
                                      final data = doc.first.data()
                                          as Map<String, dynamic>;

                                      actualizarModal(() {
                                        categoriaId = doc.first.id;
                                        categoriaNombre = data['nombre'];
                                        categoriaActivaActual = true;
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              "Colores disponibles",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: colorController,
                                    decoration: const InputDecoration(
                                      labelText: "Ejemplo: Negro, Rojo, Beige",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                  ),
                                  onPressed: () {
                                    final color = colorController.text.trim();

                                    if (color.isNotEmpty &&
                                        !colores.contains(color)) {
                                      actualizarModal(() {
                                        colores.add(color);
                                        colorController.clear();
                                      });
                                    }
                                  },
                                  child: const Text(
                                    "Agregar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: colores.map((color) {
                                return Chip(
                                  label: Text(color),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () {
                                    actualizarModal(() {
                                      colores.remove(color);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              "Tallas disponibles",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tallasDisponibles.map((talla) {
                                final seleccionado = tallas.contains(talla);

                                return FilterChip(
                                  label: Text(talla),
                                  selected: seleccionado,
                                  selectedColor:
                                      primaryColor.withValues(alpha: 0.20),
                                  checkmarkColor: primaryColor,
                                  onSelected: (value) {
                                    actualizarModal(() {
                                      if (value) {
                                        if (!tallas.contains(talla)) {
                                          tallas.add(talla);
                                        }
                                      } else {
                                        tallas.remove(talla);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (categoriaId != null &&
                                categoriaActivaActual == false)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  "Esta categoría está inactiva. Puedes conservarla en este producto, pero no estará disponible para nuevos productos.",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
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
                            onPressed: () {
                              limpiarCampos();
                              Navigator.pop(context);
                            },
                            child: const Text("Cancelar"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () =>
                                guardarProducto(productoId: productoId),
                            child: const Text(
                              "Guardar",
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

  Widget filtrosProductos() {
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
            hintText: "Buscar producto por nombre...",
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
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: categoriasRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            return DropdownButtonFormField<String>(
              value: categoriaFiltroId,
              hint: const Text("Filtrar por categoría"),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: "todas",
                  child: Text("Todas las categorías"),
                ),
                ...snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool activo = data['activo'] ?? true;

                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      activo
                          ? data['nombre'] ?? 'Sin nombre'
                          : "${data['nombre'] ?? 'Sin nombre'} (Inactiva)",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  categoriaFiltroId = value == "todas" ? null : value;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget tarjetaProducto({
    required String productoId,
    required Map<String, dynamic> data,
  }) {
    final stock = data['stock'] ?? 0;
    final imagenUrl = data['imagenUrl'] ?? '';
    final imagenes = List<String>.from(data['imagenes'] ?? []);
    final productoCategoriaNombre = data['categoriaNombre'] ?? 'Sin categoría';
    final bool productoActivo = data['activo'] ?? true;

    final productoColores = List<String>.from(data['colores'] ?? []);
    final productoTallas = List<String>.from(data['tallas'] ?? []);

    final List<String> imagenesMostrar = imagenes.isNotEmpty
        ? imagenes
        : imagenUrl.toString().isNotEmpty
            ? [imagenUrl]
            : [];

    bool presionado = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return GestureDetector(
          onTapDown: (_) {
            setCardState(() {
              presionado = true;
            });
          },
          onTapUp: (_) {
            setCardState(() {
              presionado = false;
            });
          },
          onTapCancel: () {
            setCardState(() {
              presionado = false;
            });
          },
          onTap: () {
            mostrarFormularioProducto(
              productoId: productoId,
              producto: data,
            );
          },
          child: AnimatedScale(
            scale: presionado ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Opacity(
              opacity: productoActivo ? 1 : 0.55,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFFF1F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                            top: Radius.circular(22),
                          ),
                          child: SizedBox(
                            height: 135,
                            width: double.infinity,
                            child: imagenesMostrar.isNotEmpty
                                ? CarouselSlider(
                                    options: CarouselOptions(
                                      height: 135,
                                      viewportFraction: 1,
                                      autoPlay: imagenesMostrar.length > 1,
                                      autoPlayInterval:
                                          const Duration(seconds: 3),
                                    ),
                                    items: imagenesMostrar.map((img) {
                                      return Image.network(
                                        img,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: primaryColor
                                                .withValues(alpha: 0.10),
                                            child: Icon(
                                              Icons.broken_image,
                                              color: primaryColor,
                                              size: 42,
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  )
                                : Container(
                                    color:
                                        primaryColor.withValues(alpha: 0.10),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: primaryColor,
                                      size: 45,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: productoActivo
                                  ? Colors.green.withValues(alpha: 0.90)
                                  : Colors.red.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              productoActivo ? "Activo" : "Inactivo",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: Colors.white,
                            onSelected: (value) {
                              if (value == "editar") {
                                mostrarFormularioProducto(
                                  productoId: productoId,
                                  producto: data,
                                );
                              } else if (value == "estado") {
                                cambiarEstadoProducto(
                                  productoId,
                                  productoActivo,
                                );
                              } else if (value == "eliminar") {
                                eliminarProductoSeguro(productoId);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "editar",
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text("Editar"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: "estado",
                                child: Row(
                                  children: [
                                    Icon(
                                      productoActivo
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: productoActivo
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      productoActivo
                                          ? "Inhabilitar"
                                          : "Habilitar",
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: "eliminar",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Eliminar permanente",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (imagenesMostrar.length > 1)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${imagenesMostrar.length}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
                              data['nombre'] ?? 'Sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              productoCategoriaNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "S/ ${data['precio'] ?? 0}",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color:
                                      stock < 4 ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Stock: $stock",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        stock < 4 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            barraStock(stock),
                            if (stock < 4) ...[
                              const SizedBox(height: 5),
                              alertaBajoStock(stock),
                            ],
                            const Spacer(),
                            if (productoColores.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: productoColores.take(4).map((color) {
                                  return Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: obtenerColor(color),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (productoTallas.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                "Tallas: ${productoTallas.take(4).join(', ')}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    stockController.dispose();
    buscadorController.dispose();
    colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => mostrarFormularioProducto(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Productos",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Administra productos, imágenes, colores, tallas, stock y categorías.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            filtrosProductos(),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: productosRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar productos"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay productos registrados"),
                    );
                  }

                  final productosFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final nombre =
                        (data['nombre'] ?? '').toString().toLowerCase();
                    final productoCategoriaId = data['categoriaId'];

                    final coincideNombre = nombre.contains(textoBusqueda);

                    final coincideCategoria = categoriaFiltroId == null
                        ? true
                        : categoriaFiltroId == productoCategoriaId;

                    return coincideNombre && coincideCategoria;
                  }).toList();

                  if (productosFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron productos"),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: productosFiltrados.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.60,
                    ),
                    itemBuilder: (context, index) {
                      final doc = productosFiltrados[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return tarjetaProducto(
                        productoId: doc.id,
                        data: data,
                      );
                    },
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