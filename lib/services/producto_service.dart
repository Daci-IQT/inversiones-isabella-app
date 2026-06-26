import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosService {
  final productosRef =
      FirebaseFirestore.instance.collection('productos');

  Stream<QuerySnapshot> obtenerProductos() {
    return productosRef.snapshots();
  }
}