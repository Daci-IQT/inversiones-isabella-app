import 'package:cloud_firestore/cloud_firestore.dart';

class PedidosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearPedidoConStock({
    required Map<String, dynamic> pedidoData,
    required List<Map<String, dynamic>> productos,
  }) async {
    await _db.runTransaction((transaction) async {
      // 1. Validar stock antes de crear el pedido
      for (final item in productos) {
        final productoId = item['productoId'];
        final stockKey = item['stockKey'];

        if (productoId == null || productoId.toString().isEmpty) {
          throw Exception('Hay un producto sin ID en el carrito');
        }

        final productoRef = _db.collection('productos').doc(productoId);
        final productoSnap = await transaction.get(productoRef);

        if (!productoSnap.exists) {
          throw Exception('Uno de los productos ya no existe');
        }

        final productoData = productoSnap.data() as Map<String, dynamic>;

        final cantidadSolicitada =
            int.tryParse(item['cantidad'].toString()) ?? 1;

        final nombre = productoData['nombre'] ?? 'Producto';

        if (stockKey != null && stockKey.toString().isNotEmpty) {
          final stockVariantes = Map<String, dynamic>.from(
            productoData['stockVariantes'] ?? {},
          );

          final stockVariante =
              int.tryParse(stockVariantes[stockKey].toString()) ?? 0;

          if (cantidadSolicitada > stockVariante) {
            throw Exception(
              'Stock insuficiente para $nombre en la variante $stockKey. Disponible: $stockVariante',
            );
          }
        } else {
          final stockActual =
              int.tryParse(productoData['stock'].toString()) ?? 0;

          if (cantidadSolicitada > stockActual) {
            throw Exception(
              'Stock insuficiente para $nombre. Disponible: $stockActual',
            );
          }
        }
      }

      // 2. Descontar stock general y stock por variante
      for (final item in productos) {
        final productoId = item['productoId'];
        final stockKey = item['stockKey'];

        final cantidadSolicitada =
            int.tryParse(item['cantidad'].toString()) ?? 1;

        final productoRef = _db.collection('productos').doc(productoId);

        final Map<String, dynamic> updateData = {
          'stock': FieldValue.increment(-cantidadSolicitada),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        };

        if (stockKey != null && stockKey.toString().isNotEmpty) {
          updateData['stockVariantes.$stockKey'] =
              FieldValue.increment(-cantidadSolicitada);
        }

        transaction.update(productoRef, updateData);
      }

      // 3. Crear pedido
      final pedidoRef = _db.collection('pedidos').doc();

      transaction.set(pedidoRef, {
        ...pedidoData,
        'fechaPedido': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // 4. Crear historial inicial
      transaction.set(
        pedidoRef.collection('historial').doc(),
        {
          'accion': 'Pedido creado',
          'descripcion': 'El cliente realizó el pedido',
          'usuarioId': pedidoData['clienteId'] ?? '',
          'usuarioNombre': pedidoData['clienteNombre'] ?? 'Cliente',
          'fecha': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<void> agregarHistorialPedido({
    required String pedidoId,
    required String accion,
    required String descripcion,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .collection('historial')
        .add({
      'accion': accion,
      'descripcion': descripcion,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'fecha': FieldValue.serverTimestamp(),
    });
  }
}