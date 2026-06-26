import 'dart:io' as io;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart' as excel;



/// PANTALLA PRODUCTOS ADMIN

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
  final stockMinimoController = TextEditingController();
  final TextEditingController tallaController =
    TextEditingController();

  String? categoriaId;
  String? categoriaNombre;
  bool categoriaActivaActual = true;

  String textoBusqueda = "";
  String? categoriaFiltroId;
  String estadoProductoFiltro = "todos";

  List<io.File> imagenesSeleccionadas = [];
  List<String> imagenesActualesUrls = [];

  List<String> colores = [];
  List<String> tallas = [];
  Map<String, int> stockVariantes = {};
  String tipoVariante = "sin_variantes";
  bool destacado = false;

  final List<String> tallasDisponibles = [
  "XS",
  "S",
  "M",
  "L",
  "XL",
  "XXL",
  "26",
  "28",
  "30",
  "32",
  "34",
  "35",
  "36",
  "37",
  "38",
  "39",
  "40",
  "41",
  "42",
  "43",
  "44",
];

  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
    precioController.clear();
    stockController.clear();
    colorController.clear();
    tallaController.clear();
    stockMinimoController.clear();
    tipoVariante = "sin_variantes";
    

    categoriaId = null;
    categoriaNombre = null;
    categoriaActivaActual = true;

    imagenesSeleccionadas.clear();
    imagenesActualesUrls.clear();

    colores.clear();
    tallas.clear();
    stockVariantes.clear();
    destacado = false;
  }

  Future<void> seleccionarImagenes() async {
    final List<XFile> imagenes = await picker.pickMultiImage(
      imageQuality: 75,
    );

    if (imagenes.isNotEmpty) {
      setState(() {
        imagenesSeleccionadas.addAll(
          imagenes.map((img) => io.File(img.path)).toList(),
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

  String generarSkuProducto({
  required String nombre,
  required String productoId,
}) {
  final limpio = nombre
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), '');

  final partes = limpio.split(' ').where((p) => p.isNotEmpty).toList();

  String prefijo = "PRO";

  if (partes.isNotEmpty) {
    prefijo = partes.first.length >= 3
        ? partes.first.substring(0, 3)
        : partes.first.padRight(3, 'X');
  }

  final codigo = productoId.length >= 6
      ? productoId.substring(0, 6).toUpperCase()
      : productoId.toUpperCase();

  return "$prefijo-$codigo";
}

Future<void> registrarMovimientoInventario({
  required String productoId,
  required String productoNombre,
  required String tipo,
  required String descripcion,
  int? cantidad,
}) async {
  await FirebaseFirestore.instance
      .collection('movimientos_inventario')
      .add({
    'productoId': productoId,
    'productoNombre': productoNombre,
    'tipo': tipo,
    'descripcion': descripcion,
    'usuarioId': FirebaseAuth.instance.currentUser?.uid ?? '',
    'usuarioNombre': FirebaseAuth.instance.currentUser?.email ?? 'Administrador',
    'fecha': FieldValue.serverTimestamp(),
    'cantidad': cantidad,
  });
}
  
  Future<void> guardarProducto({String? productoId}) async {
    
  if (nombreController.text.trim().isEmpty ||
      precioController.text.trim().isEmpty ||
      categoriaId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Completa todos los campos obligatorios")),
    );
    return;
  }

  int stockTotal = 0;

  if (stockVariantes.isNotEmpty) {
    stockVariantes.forEach((key, value) {
      stockTotal += value;
    });
  } else {
    stockTotal = int.tryParse(stockController.text.trim()) ?? 0;
  }

  final imagenesUrls = await subirImagenesProducto();
  final imagenPrincipal = imagenesUrls.isNotEmpty ? imagenesUrls.first : "";

  final data = {
    'nombre': nombreController.text.trim(),
    'descripcion': descripcionController.text.trim(),
    'precio': double.tryParse(precioController.text.trim()) ?? 0,
    'stock': stockTotal,
    'categoriaId': categoriaId,
    'categoriaNombre': categoriaNombre,
    'imagenUrl': imagenPrincipal,
    'imagenes': imagenesUrls,
    'colores': colores,
    'tallas': tallas,
    'stockVariantes': stockVariantes,
    'destacado': destacado,
    'stockMinimo': int.tryParse(stockMinimoController.text.trim()) ?? 5,
    'fechaActualizacion': FieldValue.serverTimestamp(),
  };

  if (productoId == null) {
  final nuevoRef = productosRef.doc();

  final sku = generarSkuProducto(
    nombre: nombreController.text.trim(),
    productoId: nuevoRef.id,
  );

  await nuevoRef.set({
    ...data,
    'sku': sku,
    'activo': true,
    'fechaRegistro': FieldValue.serverTimestamp(),
  });

  await registrarMovimientoInventario(
    productoId: nuevoRef.id,
    productoNombre: nombreController.text.trim(),
    tipo: "crear",
    descripcion: "Producto creado",
  );
} else {
  final productoDoc = await productosRef.doc(productoId).get();
  final productoActual = productoDoc.data();
  final skuExistente = productoActual?['sku'];
  final sku = skuExistente ??generarSkuProducto(nombre: nombreController.text.trim(),productoId: productoId,);

data['sku'] = sku;
final productoAnterior = await productosRef.doc(productoId).get();

final stockAnterior =int.tryParse((productoAnterior.data()?['stock'] ?? 0).toString(),) ??0;
await productosRef.doc(productoId).update(data);

if (stockAnterior != stockTotal) {
   final diferencia = stockTotal - stockAnterior;
  await registrarMovimientoInventario(
    productoId: productoId,
    productoNombre: nombreController.text.trim(),
    tipo: "stock",
    cantidad: diferencia,
    descripcion:
        "Stock modificado de $stockAnterior a $stockTotal",
  );
}
    await registrarMovimientoInventario(
  productoId: productoId,
  productoNombre: nombreController.text.trim(),
  tipo: "editar",
  descripcion: "Producto actualizado",
);
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

Color colorStock(int stock) {
  if (stock <= 0) return Colors.black;
  if (stock <= 3) return Colors.red;
  if (stock <= 5) return Colors.orange;
  return Colors.green;
}

String textoStock(int stock) {
  if (stock <= 0) return "Agotado";
  if (stock <= 3) return "Crítico";
  if (stock <= 5) return "Bajo";
  return "Normal";
}

IconData iconoStock(int stock) {
  if (stock <= 0) return Icons.remove_shopping_cart;
  if (stock <= 3) return Icons.warning;
  if (stock <= 5) return Icons.error_outline;
  return Icons.check_circle;
}

Future<void> cambiarEstadoProducto(
  String id,
  bool estadoActual,
  String nombreProducto,
) async {
  await productosRef.doc(id).update({
    'activo': !estadoActual,
    'fechaActualizacion': FieldValue.serverTimestamp(),
  });

  await registrarMovimientoInventario(
    productoId: id,
    productoNombre: nombreProducto,
    tipo: estadoActual ? "inactivar" : "activar",
    descripcion: estadoActual
        ? "Producto inactivado"
        : "Producto activado",
  );

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

Widget stockVariantesWidget(StateSetter setModalState) {
  final variantes = <Map<String, String>>[];

  if (colores.isNotEmpty && tallas.isNotEmpty) {
    for (final color in colores) {
      for (final talla in tallas) {
        final key = "${color}_$talla";

        variantes.add({
          'key': key,
          'color': color,
          'talla': talla,
          'label': "$color - $talla",
        });

        stockVariantes.putIfAbsent(key, () => 0);
      }
    }
  } else if (colores.isNotEmpty && tallas.isEmpty) {
    for (final color in colores) {
      final key = color;

      variantes.add({
        'key': key,
        'color': color,
        'talla': '',
        'label': color,
      });

      stockVariantes.putIfAbsent(key, () => 0);
    }
  } else if (colores.isEmpty && tallas.isNotEmpty) {
    for (final talla in tallas) {
      final key = talla;

      variantes.add({
        'key': key,
        'color': '',
        'talla': talla,
        'label': talla,
      });

      stockVariantes.putIfAbsent(key, () => 0);
    }
  } else {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Si no agregas colores ni tallas, se usará el stock general.",
        style: TextStyle(color: Colors.blue),
      ),
    );
  }

  final keysValidas = variantes.map((v) => v['key']).toSet();

  stockVariantes.removeWhere((key, value) => !keysValidas.contains(key));

  int stockTotal = 0;
  stockVariantes.forEach((_, value) {
    stockTotal += value;
  });

  stockController.text = stockTotal.toString();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Stock por variante",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

      const SizedBox(height: 8),

      Text(
        colores.isNotEmpty && tallas.isNotEmpty
            ? "Stock por combinación de color y talla."
            : colores.isNotEmpty
                ? "Stock por color."
                : "Stock por talla.",
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),

      const SizedBox(height: 12),

      ...variantes.map((variante) {
        final key = variante['key']!;
        final color = variante['color']!;
        final label = variante['label']!;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              if (color.isNotEmpty) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: obtenerColor(color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(
                width: 85,
                child: TextFormField(
                  initialValue: stockVariantes[key].toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Stock",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final stock = int.tryParse(value) ?? 0;

                    setModalState(() {
                      stockVariantes[key] = stock;

                      int total = 0;
                      stockVariantes.forEach((_, cantidad) {
                        total += cantidad;
                      });

                      stockController.text = total.toString();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }),

      const SizedBox(height: 8),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Stock total calculado: ${stockController.text.isEmpty ? '0' : stockController.text}",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
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
  
Future<pw.ImageProvider?> cargarImagenPdf(String url) async {
  try {
    if (url.trim().isEmpty) return null;

    return await networkImage(url);
  } catch (e) {
    return null;
  }
}

Future<io.File> generarCatalogoProductosPdf() async {
  final pdf = pw.Document();

  final snapshot = await productosRef.where('activo', isEqualTo: true).get();

  final productos = snapshot.docs
      .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
      .where((producto) {
        final stock = int.tryParse(producto['stock'].toString()) ?? 0;
        return stock > 0;
      })
      .toList();

  productos.sort((a, b) {
    final catA = (a['categoriaNombre'] ?? 'Sin categoría').toString();
    final catB = (b['categoriaNombre'] ?? 'Sin categoría').toString();
    final nombreA = (a['nombre'] ?? '').toString();
    final nombreB = (b['nombre'] ?? '').toString();

    final compareCat = catA.compareTo(catB);
    if (compareCat != 0) return compareCat;
    return nombreA.compareTo(nombreB);
  });

  final Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};

  for (final producto in productos) {
    final categoria =
        (producto['categoriaNombre'] ?? 'Sin categoría').toString();

    productosPorCategoria.putIfAbsent(categoria, () => []);
    productosPorCategoria[categoria]!.add(producto);
  }

  final Map<String, pw.ImageProvider?> imagenesPdf = {};

  for (final producto in productos) {
    final imagenUrl = (producto['imagenUrl'] ?? '').toString();

    if (imagenUrl.isNotEmpty) {
      imagenesPdf[producto['id'].toString()] =
          await cargarImagenPdf(imagenUrl);
    }
  }

  String variantesDisponibles(Map<String, dynamic> producto) {
    final stockVariantes =
        Map<String, dynamic>.from(producto['stockVariantes'] ?? {});

    final disponibles = stockVariantes.entries.where((e) {
      final stock = int.tryParse(e.value.toString()) ?? 0;
      return stock > 0;
    }).map((e) {
      return "${e.key}: ${e.value}";
    }).toList();

    if (disponibles.isEmpty) return "Sin variantes";

    return disponibles.take(4).join("  |  ");
  }

  pw.Widget productoCatalogoCard(Map<String, dynamic> producto) {
    final nombre = producto['nombre'] ?? 'Sin nombre';
    final descripcion = producto['descripcion'] ?? '';
    final precio = double.tryParse(producto['precio'].toString()) ?? 0;
    final stock = int.tryParse(producto['stock'].toString()) ?? 0;
    final sku = (producto['sku'] ?? '').toString();
    final destacado = producto['destacado'] == true;

    final colores = List<String>.from(producto['colores'] ?? []);
    final tallas = List<String>.from(producto['tallas'] ?? []);
    final imagen = imagenesPdf[producto['id'].toString()];

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Stack(
            children: [
              pw.Container(
                height: 100,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: imagen != null
                    ? pw.ClipRRect(
                        horizontalRadius: 10,
                        verticalRadius: 10,
                        child: pw.Image(
                          imagen,
                          fit: pw.BoxFit.cover,
                        ),
                      )
                    : pw.Center(
                        child: pw.Text(
                          "Sin imagen",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
              ),
              if (destacado)
                pw.Positioned(
                  top: 6,
                  left: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      "DESTACADO",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          pw.SizedBox(height: 7),

          if (sku.isNotEmpty)
            pw.Text(
              "SKU: $sku",
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),

          pw.Text(
            nombre.toString(),
            maxLines: 2,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          if (descripcion.toString().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              descripcion.toString(),
              maxLines: 2,
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey700,
              ),
            ),
          ],

          pw.SizedBox(height: 5),

          pw.Text(
            "S/ ${precio.toStringAsFixed(2)}",
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),

          pw.Text(
            "Stock disponible: $stock",
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey800,
            ),
          ),

          if (colores.isNotEmpty)
            pw.Text(
              "Colores: ${colores.take(5).join(', ')}",
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 7),
            ),

          if (tallas.isNotEmpty)
            pw.Text(
              "Tallas: ${tallas.take(8).join(', ')}",
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 7),
            ),

          pw.SizedBox(height: 3),

          pw.Text(
            "Variantes: ${variantesDisponibles(producto)}",
            maxLines: 2,
            style: const pw.TextStyle(
              fontSize: 6.5,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // PORTADA
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.red, width: 2),
            borderRadius: pw.BorderRadius.circular(18),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  "INVERSIONES ISABELLA",
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  "CATÁLOGO PREMIUM",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  "Productos disponibles organizados por categoría",
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 35),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    "Total de productos disponibles: ${productos.length}",
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  productosPorCategoria.forEach((categoria, listaProductos) {
    final chunks = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < listaProductos.length; i += 8) {
      chunks.add(
        listaProductos.sublist(
          i,
          i + 8 > listaProductos.length ? listaProductos.length : i + 8,
        ),
      );
    }

    for (final productosPagina in chunks) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "INVERSIONES ISABELLA",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                    pw.Text(
                      "Catálogo Premium",
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    categoria.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 12),

                pw.GridView(
                  crossAxisCount: 2,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: productosPagina.map(productoCatalogoCard).toList(),
                ),

                pw.Spacer(),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(top: 6),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Solo productos disponibles",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        "Página ${context.pageNumber}",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
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
  });

  final dir = await getTemporaryDirectory();

  final file = io.File(
    '${dir.path}/catalogo_premium_inversiones_isabella.pdf',
  );

  await file.writeAsBytes(await pdf.save());

  return file;
}

Future<void> descargarCatalogoProductosPdf() async {
  try {
    final archivo = await generarCatalogoProductosPdf();
    await OpenFilex.open(archivo.path);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Error al generar catálogo: $e"),
      ),
    );
  }
}

Future<void> compartirCatalogoProductosPdf() async {
  try {
    final archivo = await generarCatalogoProductosPdf();

    await Share.shareXFiles(
      [XFile(archivo.path)],
      text: "Catálogo de productos - Inversiones Isabella",
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Error al compartir catálogo: $e"),
      ),
    );
  }
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
      stockMinimoController.text =(producto['stockMinimo'] ?? 5).toString();

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

      stockVariantes = Map<String, int>.from(producto['stockVariantes'] ?? {},);

      destacado = producto['destacado'] ?? false;

if (colores.isNotEmpty && tallas.isNotEmpty) 
{tipoVariante = "color_talla";
} else if (colores.isNotEmpty) {
  tipoVariante = "solo_color";
} else if (tallas.isNotEmpty) {
  tipoVariante = "solo_talla";
} else {
  tipoVariante = "sin_variantes";
}

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
                                        child: Container(
  width: 85,
  height: 85,
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.network(
    url,
    width: 85,
    height: 85,
    fit: BoxFit.contain,
  ),
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
                                        child: Container(
  width: 85,
  height: 85,
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.file(
    file,
    width: 85,
    height: 85,
    fit: BoxFit.contain,
  ),
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

TextField(
  controller: stockMinimoController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: "Stock mínimo de alerta",
    helperText: "Cuando el stock sea igual o menor, aparecerá como bajo stock",
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
                                  initialValue: categoriaId,
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
                            Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.amber.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(12),
  ),
  child: SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: destacado,
    activeColor: Colors.orange,
    title: const Text(
      "Producto destacado",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: const Text(
      "Mostrar en promociones y destacados.",
    ),
    secondary: const Icon(
      Icons.star,
      color: Colors.orange,
    ),
    onChanged: (value) {
      actualizarModal(() {
        destacado = value;
      });
    },
  ),
),
                            const SizedBox(height: 18),

const Text(
  "Tipo de variante",
  style: TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
  initialValue: tipoVariante,
  decoration: const InputDecoration(
    labelText: "Selecciona el tipo de producto",
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(
      value: "sin_variantes",
      child: Text("Sin variantes"),
    ),
    DropdownMenuItem(
      value: "solo_color",
      child: Text("Solo colores"),
    ),
    DropdownMenuItem(
      value: "solo_talla",
      child: Text("Solo tallas"),
    ),
    DropdownMenuItem(
      value: "color_talla",
      child: Text("Colores y tallas"),
    ),
  ],
  onChanged: (value) {
    actualizarModal(() {
      tipoVariante = value ?? "sin_variantes";

      colores.clear();
      tallas.clear();
      stockVariantes.clear();

      stockController.clear();
    });
  },
),

if (tipoVariante == "solo_color" || tipoVariante == "color_talla") ...[
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

  if (color.isNotEmpty && !colores.contains(color)) {
    actualizarModal(() {
      colores.add(color);
      colorController.clear();

      if (tallas.isEmpty) {
  stockVariantes.putIfAbsent(color, () => 0);
} else {
  for (final talla in tallas) {
    stockVariantes.putIfAbsent("${color}_$talla", () => 0);
  }
}
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

    stockVariantes.removeWhere(
      (key, value) => key.startsWith("${color}_"),
    );

    int total = 0;
    stockVariantes.forEach((_, cantidad) {
      total += cantidad;
    });

    stockController.text = total.toString();
  });
},
                                );
                              }).toList(),
                            ),


                            const SizedBox(height: 18),],

if (tipoVariante == "solo_talla" || tipoVariante == "color_talla") ...[

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

    if (colores.isEmpty) {
      stockVariantes.putIfAbsent(talla, () => 0);
    } else {
      for (final color in colores) {
        stockVariantes.putIfAbsent("${color}_$talla", () => 0);
      }
    }
  }
} else {
      tallas.remove(talla);

      stockVariantes.removeWhere(
        (key, value) => key.endsWith("_$talla"),
      );
    }

    int total = 0;
    stockVariantes.forEach((_, cantidad) {
      total += cantidad;
    });

    stockController.text = total.toString();
  });
},
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),

Row(
  children: [
    Expanded(
      child: TextField(
        controller: tallaController,
        decoration: const InputDecoration(
          labelText: "Agregar talla personalizada",
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
        final nuevaTalla =
            tallaController.text.trim();

        if (nuevaTalla.isEmpty) return;

        actualizarModal(() {
          if (!tallas.contains(nuevaTalla)) {
            tallas.add(nuevaTalla);

            if (colores.isEmpty) {
              stockVariantes.putIfAbsent(
                nuevaTalla,
                () => 0,
              );
            } else {
              for (final color in colores) {
                stockVariantes.putIfAbsent(
                  "${color}_$nuevaTalla",
                  () => 0,
                );
              }
            }
          }

          tallaController.clear();
        });
      },
      child: const Text(
        "Agregar",
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
),
const SizedBox(height: 10),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: tallas
      .where(
        (talla) =>
            !tallasDisponibles.contains(talla),
      )
      .map((talla) {
    return Chip(
      backgroundColor:
          Colors.orange.withValues(alpha: 0.15),
      label: Text(talla),
      deleteIcon: const Icon(Icons.close),
      onDeleted: () {
        actualizarModal(() {
          tallas.remove(talla);

          stockVariantes.removeWhere(
            (key, value) =>
                key == talla ||
                key.endsWith("_$talla"),
          );
        });
      },
    );
  }).toList(),
),
                            const SizedBox(height: 18),],

stockVariantesWidget(setModalState),
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
          hintText: "Buscar producto por nombre o codigo...",
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
            initialValue: categoriaFiltroId,
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

      const SizedBox(height: 12),

      DropdownButtonFormField<String>(
        initialValue: estadoProductoFiltro,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Filtrar por estado",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: "todos",
            child: Text("Todos"),
          ),
          DropdownMenuItem(
            value: "activos",
            child: Text("Activos"),
          ),
          DropdownMenuItem(
            value: "inactivos",
            child: Text("Inactivos"),
          ),
          DropdownMenuItem(
            value: "destacados",
            child: Text("Destacados"),
          ),
          DropdownMenuItem(
            value: "bajo_stock",
            child: Text("Bajo stock"),
          ),
          DropdownMenuItem(
            value: "agotados",
            child: Text("Agotados"),
          ),
        ],
        onChanged: (value) {
          setState(() {
            estadoProductoFiltro = value ?? "todos";
          });
        },
      ),
    ],
  );
}

Widget dashboardInventario(List<QueryDocumentSnapshot> productos) {
  int total = productos.length;
  int activos = 0;
  int inactivos = 0;
  int destacados = 0;
  int bajoStock = 0;
  int agotados = 0;
  double valorInventario = 0;

  for (final doc in productos) {
    final data = doc.data() as Map<String, dynamic>;

    final stock = int.tryParse(data['stock'].toString()) ?? 0;
    final precio = double.tryParse(data['precio'].toString()) ?? 0;

    final stockMinimo =
        int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;

    final activo = data['activo'] ?? true;
    final destacado = data['destacado'] == true;

    if (activo) {
      activos++;
    } else {
      inactivos++;
    }

    if (destacado) destacados++;

    if (stock <= 0) {
      agotados++;
    } else if (stock <= stockMinimo) {
      bajoStock++;
    }

    valorInventario += precio * stock;
  }

  Widget card(
    String titulo,
    String valor,
    Color color,
    IconData icono,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    children: [
      Row(
        children: [
          card("Productos", total.toString(), Colors.blue, Icons.inventory_2),
          const SizedBox(width: 8),
          card("Activos", activos.toString(), Colors.green, Icons.check_circle),
          const SizedBox(width: 8),
          card(
            "Inactivos",
            inactivos.toString(),
            Colors.grey,
            Icons.visibility_off,
          ),
        ],
      ),

      const SizedBox(height: 8),

      Row(
        children: [
          card("Destacados", destacados.toString(), Colors.orange, Icons.star),
          const SizedBox(width: 8),
          card("Bajo stock", bajoStock.toString(), Colors.amber, Icons.warning),
          const SizedBox(width: 8),
          card(
            "Agotados",
            agotados.toString(),
            Colors.red,
            Icons.remove_shopping_cart,
          ),
        ],
      ),

      const SizedBox(height: 10),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.payments, color: primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Valor estimado de inventario",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              "S/ ${valorInventario.toStringAsFixed(2)}",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget estadisticasCategorias(
  List<QueryDocumentSnapshot> productos,
) {
  final Map<String, int> categorias = {};

  for (final doc in productos) {
    final data = doc.data() as Map<String, dynamic>;

    final categoria =
        (data['categoriaNombre'] ?? 'Sin categoría')
            .toString();

    categorias[categoria] =
        (categorias[categoria] ?? 0) + 1;
  }

  final categoriasOrdenadas =
      categorias.entries.toList()
        ..sort(
          (a, b) => b.value.compareTo(a.value),
        );

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart),
            SizedBox(width: 8),
            Text(
              "Productos por categoría",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        ...categoriasOrdenadas.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(cat.key),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.value.toString(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

Future<void> duplicarProducto({
  required String productoId,
  required Map<String, dynamic> data,
}) async {
  try {
    final nuevoRef = productosRef.doc();

    final nuevoNombre = "${data['nombre']} (Copia)";

    final sku = generarSkuProducto(
      nombre: nuevoNombre,
      productoId: nuevoRef.id,
    );

    await nuevoRef.set({
      ...data,
      'nombre': nuevoNombre,
      'sku': sku,
      'activo': true,
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    await registrarMovimientoInventario(
      productoId: nuevoRef.id,
      productoNombre: nuevoNombre,
      tipo: "duplicar",
      descripcion: "Producto duplicado desde ${data['nombre'] ?? 'producto'}",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Producto duplicado correctamente"),
        ),
      );
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}

void mostrarImagenProductoPantallaCompleta({
  required List<String> imagenes,
  required int indexInicial,
}) {
  final PageController pageController = PageController(
    initialPage: indexInicial,
  );

  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: imagenes.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
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

Future<void> exportarMovimientosExcel() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('movimientos_inventario')
        .orderBy('fecha', descending: true)
        .get();

    final libro = excel.Excel.createExcel();
    final sheet = libro['Movimientos'];

    sheet.appendRow([
      excel.TextCellValue('Fecha'),
      excel.TextCellValue('Producto'),
      excel.TextCellValue('Tipo'),
      excel.TextCellValue('Cantidad'),
      excel.TextCellValue('Descripción'),
      excel.TextCellValue('Usuario'),
    ]);

    for (final doc in snapshot.docs) {
      final data = doc.data();

      sheet.appendRow([
        excel.TextCellValue(formatearFecha(data['fecha'])),
        excel.TextCellValue((data['productoNombre'] ?? '').toString()),
        excel.TextCellValue((data['tipo'] ?? '').toString().toUpperCase()),
        excel.TextCellValue((data['cantidad'] ?? '').toString()),
        excel.TextCellValue((data['descripcion'] ?? '').toString()),
        excel.TextCellValue((data['usuarioNombre'] ?? '').toString()),
      ]);
    }

    final bytes = libro.encode();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = io.File('${dir.path}/movimientos_inventario_isabella.xlsx');

    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('Error al exportar movimientos: $e'),
      ),
    );
  }
}


Future<void> exportarInventarioExcel() async {
  try {
    final snapshot = await productosRef.orderBy('nombre').get();

    final libro = excel.Excel.createExcel();
   final sheet = libro['Inventario'];

    sheet.appendRow([
      excel.TextCellValue('SKU'),
      excel.TextCellValue('Producto'),
      excel.TextCellValue('Categoría'),
      excel.TextCellValue('Precio'),
      excel.TextCellValue('Stock'),
      excel.TextCellValue('Stock mínimo'),
      excel.TextCellValue('Estado'),
      excel.TextCellValue('Destacado'),
      excel.TextCellValue('Valor inventario'),
    ]);

    double valorTotal = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final sku = data['sku'] ?? '';
      final nombre = data['nombre'] ?? '';
      final categoria = data['categoriaNombre'] ?? '';
      final precio = double.tryParse(data['precio'].toString()) ?? 0;
      final stock = int.tryParse(data['stock'].toString()) ?? 0;
      final stockMinimo =
          int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;
      final activo = data['activo'] == true ? 'Activo' : 'Inactivo';
      final destacado = data['destacado'] == true ? 'Sí' : 'No';
      final valor = precio * stock;

      valorTotal += valor;

      sheet.appendRow([
        excel.TextCellValue(sku.toString()),
        excel.TextCellValue(nombre.toString()),
        excel.TextCellValue(categoria.toString()),
        excel.DoubleCellValue(precio),
        excel.IntCellValue(stock),
        excel.IntCellValue(stockMinimo),
        excel.TextCellValue(activo),
        excel.TextCellValue(destacado),
        excel.DoubleCellValue(valor),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      excel.TextCellValue('TOTAL'),
      excel.TextCellValue(''),
      excel.TextCellValue(''),
      excel.TextCellValue(''),
      excel.TextCellValue(''),
      excel.TextCellValue(''),
      excel.TextCellValue(''),
      excel.TextCellValue('Valor total'),
      excel.DoubleCellValue(valorTotal),
    ]);

    final bytes = libro.encode();

    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = io.File('${dir.path}/inventario_isabella.xlsx');

    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('Error al exportar Excel: $e'),
      ),
    );
  }
}String formatearFecha(dynamic fecha) {
  if (fecha == null) return "Sin fecha";

  if (fecha is Timestamp) {
    final date = fecha.toDate();

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  return fecha.toString();
}


void mostrarKardexProducto({
  required String productoId,
  required String productoNombre,
}) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Kardex - $productoNombre",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('movimientos_inventario')
                      .where('productoId', isEqualTo: productoId)
                      .orderBy('fecha', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error al cargar kardex"),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final movimientos = snapshot.data!.docs;

                    if (movimientos.isEmpty) {
                      return const Center(
                        child: Text("Este producto aún no tiene movimientos"),
                      );
                    }

                    int saldo = 0;
                    int entradas = 0;
                    int salidas = 0;

                    final filas = movimientos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final tipo = data['tipo'] ?? '';
                      final descripcion = data['descripcion'] ?? '';
                      final cantidad =
                          int.tryParse((data['cantidad'] ?? 0).toString()) ??
                              0;

                      if (cantidad > 0) entradas += cantidad;
                      if (cantidad < 0) salidas += cantidad.abs();

                      saldo += cantidad;

                      return {
                        'tipo': tipo,
                        'descripcion': descripcion,
                        'cantidad': cantidad,
                        'saldo': saldo,
                        'fecha': data['fecha'],
                      };
                    }).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              resumenKardexCard(
                                "Entradas",
                                "+$entradas",
                                Colors.green,
                                Icons.arrow_downward,
                              ),
                              const SizedBox(width: 8),
                              resumenKardexCard(
                                "Salidas",
                                "-$salidas",
                                Colors.red,
                                Icons.arrow_upward,
                              ),
                              const SizedBox(width: 8),
                              resumenKardexCard(
                                "Saldo",
                                saldo.toString(),
                                Colors.indigo,
                                Icons.inventory,
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: Colors.grey.shade100,
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Fecha",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Movimiento",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Ent.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Sal.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Saldo",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            itemCount: filas.length,
                            itemBuilder: (context, index) {
                              final fila = filas[index];

                              final cantidad = fila['cantidad'] as int;
                              final saldoFila = fila['saldo'] as int;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatearFecha(fila['fecha']),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        fila['descripcion'].toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        cantidad > 0 ? "+$cantidad" : "-",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        cantidad < 0
                                            ? cantidad.abs().toString()
                                            : "-",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        saldoFila.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget resumenKardexCard(
  String titulo,
  String valor,
  Color color,
  IconData icono,
) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    ),
  );
}


  void mostrarDetalleProductoAdmin({
  required String productoId,
  required Map<String, dynamic> producto,
}) {
  showDialog(
  context: context,
  builder: (_) {
    return StreamBuilder<DocumentSnapshot>(
      stream: productosRef.doc(productoId).snapshots(),
      builder: (context, snapshot) {
        final productoActual =
            snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>
                : producto;
final String imagenUrl =(productoActual['imagenUrl'] ?? '').toString();

final List<String> imagenes = List<String>.from(productoActual['imagenes'] ?? [],);

final List<String> imagenesMostrar = imagenes.isNotEmpty
    ? imagenes
    : imagenUrl.isNotEmpty
        ? [imagenUrl]
        : [];                

final nombre = productoActual['nombre'] ?? 'Sin nombre';
final descripcion = productoActual['descripcion'] ?? 'Sin descripción';
final categoria = productoActual['categoriaNombre'] ?? 'Sin categoría';
final precio = double.tryParse(productoActual['precio'].toString()) ?? 0;
final stock = int.tryParse(productoActual['stock'].toString()) ?? 0;
final activo = productoActual['activo'] ?? true;

final coloresProducto =
    List<String>.from(productoActual['colores'] ?? []);

final tallasProducto =
    List<String>.from(productoActual['tallas'] ?? []);

final stockVariantesProducto =
    Map<String, dynamic>.from(productoActual['stockVariantes'] ?? {});

        return Dialog(
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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
                      if (imagenesMostrar.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 230,
                              viewportFraction: 1,
                              autoPlay: imagenesMostrar.length > 1,
                              autoPlayInterval: const Duration(seconds: 3),
                            ),
                            items: imagenesMostrar.asMap().entries.map((entry) {
  final index = entry.key;
  final img = entry.value;

  return GestureDetector(
    onTap: () {
      mostrarImagenProductoPantallaCompleta(
        imagenes: imagenesMostrar,
        indexInicial: index,
      );
    },
    child: Container(
      width: double.infinity,
      height: 230,
      color: Colors.white,
      alignment: Alignment.center,
      child: Stack(
        children: [
          Center(
            child: Image.network(
              img,
              width: double.infinity,
              height: 230,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 18),
                  SizedBox(width: 5),
                  Text("Ver imagen",style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}).toList(),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 210,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: primaryColor,
                            size: 60,
                          ),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        nombre,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      if (productoActual['destacado'] == true)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 5),
              Text(
                "Producto destacado",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
    ],
  ),
),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: activo
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              activo ? "Activo" : "Inactivo",
                              style: TextStyle(
                                color: activo ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        descripcion,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "S/ ${precio.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text("Categoría: $categoria"),
                            
                            Container(
  margin: const EdgeInsets.only(top: 8),
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: colorStock(stock).withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(
        iconoStock(stock),
        color: colorStock(stock),
      ),
      const SizedBox(width: 8),
      Text("${textoStock(stock)} ($stock unidades)",
        style: TextStyle(
          color: colorStock(stock),
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),
                            const SizedBox(height: 8),
                            barraStock(stock),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (coloresProducto.isNotEmpty) ...[
                        const Text(
                          "Colores",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: coloresProducto.map((color) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: obtenerColor(color),
                              ),
                              label: Text(color),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (tallasProducto.isNotEmpty) ...[
                        const Text(
                          "Tallas",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tallasProducto.map((talla) {
                            return Chip(label: Text(talla));
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (stockVariantesProducto.isNotEmpty) ...[
                        const Text(
                          "Stock por variante",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        ...stockVariantesProducto.entries.map((entry) {
                          final key = entry.key;
                          final stockVariante = int.tryParse(entry.value.toString()) ?? 0;
                          final stockMinimo = int.tryParse((productoActual['stockMinimo'] ?? 5).toString()) ?? 5;

                          final partes = key.split("_");
                          final color =
                              partes.isNotEmpty ? partes.first : "Color";
                          final talla =
                              partes.length > 1 ? partes.last : "Talla";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: stockVariante <= 0? Colors.black.withValues(alpha: 0.07)
                              :stockVariante <= stockMinimo ? Colors.red.withValues(alpha: 0.07)
                              : Colors.grey.shade100,

                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: stockVariante <= 0? Colors.black
                                : stockVariante <= stockMinimo ? Colors.redAccent
                                : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: obtenerColor(color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "$color - $talla",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  ),
  decoration: BoxDecoration(
    color: colorStock(stockVariante)
        .withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
  stockVariante <= 0
      ? "Agotado"
      : stockVariante <= stockMinimo
          ? "Reponer: $stockVariante"
          : "Stock: $stockVariante",
  style: TextStyle(
    color: stockVariante <= 0
        ? Colors.black
        : stockVariante <= stockMinimo
            ? Colors.red
            : Colors.green,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    ),
  ),
),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              Padding(
  padding: const EdgeInsets.all(14),
  child: Column(
  children: [
    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              mostrarFormularioProducto(
                productoId: productoId,
                producto: productoActual,
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text("Editar"),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () {
              duplicarProducto(
                productoId: productoId,
                data: productoActual,
              );
            },
            icon: const Icon(Icons.copy, color: Colors.white),
            label: const Text(
              "Duplicar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: activo ? Colors.orange : Colors.green,
            ),
            onPressed: () {
              Navigator.pop(context);
              cambiarEstadoProducto(
                productoId,
                activo,
                productoActual['nombre'] ?? 'Sin nombre',
              );
            },
            icon: Icon(
              activo ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            label: Text(
              activo ? "Inactivar" : "Activar",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
        ),
        onPressed: () {
          mostrarKardexProducto(
            productoId: productoId,
            productoNombre: productoActual['nombre'] ?? 'Producto',
          );
        },
        icon: const Icon(Icons.inventory, color: Colors.white),
        label: const Text(
          "Ver Kardex",
          style: TextStyle(color: Colors.white),
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
    },
  );
  },
 );
 }

  Widget tarjetaProducto({
    required String productoId,
    required Map<String, dynamic> data,
  }) {
    final stock = data['stock'] ?? 0;
    final stockMinimo = int.tryParse((data['stockMinimo'] ?? 5).toString()) ?? 5;
    final imagenUrl = data['imagenUrl'] ?? '';
    final imagenes = List<String>.from(data['imagenes'] ?? []);
    final productoCategoriaNombre = data['categoriaNombre'] ?? 'Sin categoría';
    final bool productoActivo = data['activo'] ?? true;

    final productoColores = List<String>.from(data['colores'] ?? []);
    final productoTallas = List<String>.from(data['tallas'] ?? []);
    final Map<String, dynamic> productoStockVariantes =
    Map<String, dynamic>.from(data['stockVariantes'] ?? {});

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
  mostrarDetalleProductoAdmin(
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
                                      return Container(
  width: double.infinity,
  height: 135,
  color: Colors.white,
  alignment: Alignment.center,
  child: Image.network(
    img,
    width: double.infinity,
    height: 135,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: primaryColor.withValues(alpha: 0.10),
        child: Icon(
          Icons.broken_image,
          color: primaryColor,
          size: 42,
        ),
      );
    },
  ),
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
    data['nombre'] ?? 'Sin nombre',
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
                            if (data['destacado'] == true)
  Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.orange, size: 14),
        SizedBox(width: 4),
        Text(
          "Destacado",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    ),
  ),
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
                                      stock <= stockMinimo ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  ),
  decoration: BoxDecoration(
    color: colorStock(stock).withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        iconoStock(stock),
        size: 14,
        color: colorStock(stock),
      ),
      const SizedBox(width: 4),
      Text(
        "${textoStock(stock)} ($stock)",
        style: TextStyle(
          color: colorStock(stock),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    ],
  ),
),
                              ],
                            ),
                            const SizedBox(height: 6),
                            barraStock(stock),
                            if (stock <= stockMinimo) ...[
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
                            if (productoStockVariantes.isNotEmpty) ...[
  const SizedBox(height: 5),
  Text(
    "Variantes: ${productoStockVariantes.length}",
    style: TextStyle(
      fontSize: 10,
      color: Colors.grey[700],
      fontWeight: FontWeight.bold,
    ),
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
    tallaController.dispose();
    stockMinimoController.dispose();
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gestión de Productos",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            "Productos, stock y categorías.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 10),

          filtrosProductos(),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: descargarCatalogoProductosPdf,
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white,
                      size: 17,
                    ),
                    label: const Text(
                      "Catálogo PDF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: compartirCatalogoProductosPdf,
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 17,
                    ),
                    label: const Text(
                      "Compartir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  height: 42,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
    ),
    onPressed: exportarInventarioExcel,
    icon: const Icon(
      Icons.table_chart,
      color: Colors.white,
    ),
    label: const Text(
      "Exportar Inventario Excel",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  height: 42,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo,
    ),
    onPressed: exportarMovimientosExcel,
    icon: const Icon(
      Icons.history,
      color: Colors.white,
    ),
    label: const Text(
      "Exportar Movimientos Excel",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

          const SizedBox(height: 10),

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
                  final sku =
                      (data['sku'] ?? '').toString().toLowerCase();
                  final productoCategoriaId = data['categoriaId'];

                  final coincideNombre =
                      nombre.contains(textoBusqueda) ||
                      sku.contains(textoBusqueda);

                  final coincideCategoria = categoriaFiltroId == null
                      ? true
                      : categoriaFiltroId == productoCategoriaId;

                  final activo = data['activo'] ?? true;
                  final destacado = data['destacado'] ?? false;
                  final stock =
                      int.tryParse(data['stock'].toString()) ?? 0;

                  bool coincideEstado = true;

                  if (estadoProductoFiltro == "activos") {
                    coincideEstado = activo == true;
                  } else if (estadoProductoFiltro == "inactivos") {
                    coincideEstado = activo == false;
                  } else if (estadoProductoFiltro == "destacados") {
                    coincideEstado = destacado == true;
                  } else if (estadoProductoFiltro == "bajo_stock") {
                    coincideEstado = stock > 0 && stock <= 5;
                  } else if (estadoProductoFiltro == "agotados") {
                    coincideEstado = stock <= 0;
                  }

                  return coincideNombre &&
                      coincideCategoria &&
                      coincideEstado;
                }).toList();

                final todosProductos = snapshot.data!.docs;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      dashboardInventario(todosProductos),

                      const SizedBox(height: 10),

                      estadisticasCategorias(todosProductos),

                      const SizedBox(height: 10),

                      productosFiltrados.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text("No se encontraron productos"),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(bottom: 90),
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
                                final data =
                                    doc.data() as Map<String, dynamic>;

                                return tarjetaProducto(
                                  productoId: doc.id,
                                  data: data,
                                );
                              },
                            ),
                    ],
                  ),
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