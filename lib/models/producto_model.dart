
class ProductoModel {
  final String id;
  final String nombre;
  final double precio;
  final String descripcion;
  final List<String> imagenes;
  final int stock;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.imagenes,
    required this.stock,
  });

  factory ProductoModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return ProductoModel(
      id: id,
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      descripcion: data['descripcion'] ?? '',
      imagenes: List<String>.from(data['imagenes'] ?? []),
      stock: data['stock'] ?? 0,
    );
  }
}