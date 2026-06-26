import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class RepartidorPanelScreen extends StatefulWidget {
  const RepartidorPanelScreen({super.key});

  @override
  State<RepartidorPanelScreen> createState() => _RepartidorPanelScreenState();
}

class _RepartidorPanelScreenState extends State<RepartidorPanelScreen> {
  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  DateTime? ultimaVezAtras;
  String filtroPedidos = "todos";

  Color colorEstado(String estado) {
    switch (estado) {
      case 'en_proceso':
        return Colors.blue;
      case 'en_camino':
        return Colors.orange;
      case 'entregado':
        return Colors.green;
      case 'incidencia':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case 'en_proceso':
        return 'EN PROCESO';
      case 'en_camino':
        return 'EN CAMINO';
      case 'entregado':
        return 'ENTREGADO';
      case 'incidencia':
        return 'INCIDENCIA';
      default:
        return estado.toUpperCase();
    }
  }

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    try {
      final fecha = (timestamp as Timestamp).toDate();

      return "${fecha.day.toString().padLeft(2, '0')}/"
          "${fecha.month.toString().padLeft(2, '0')}/"
          "${fecha.year} "
          "${fecha.hour.toString().padLeft(2, '0')}:"
          "${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Sin fecha";
    }
  }

  Future<void> confirmarSalidaApp() async {
  final ahora = DateTime.now();

  if (ultimaVezAtras == null ||
      ahora.difference(ultimaVezAtras!) > const Duration(seconds: 2)) {
    ultimaVezAtras = ahora;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Presiona dos veces seguidas para salir"),
        duration: Duration(seconds: 2),
      ),
    );

    return;
  }

  SystemNavigator.pop();
}
Future<String?> subirFotoRepartidor() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final XFile? imagen = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
  );

  if (imagen == null) return null;

  final archivo = io.File(imagen.path);

  final ref = FirebaseStorage.instance
      .ref()
      .child('perfiles_repartidores')
      .child('${user.uid}.jpg');

  await ref.putFile(archivo);

  return await ref.getDownloadURL();
}
void mostrarConfiguracionRepartidor(Map<String, dynamic> repartidorData) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final nombreController =
      TextEditingController(text: repartidorData['nombre'] ?? '');
  final apellidosController =
      TextEditingController(text: repartidorData['apellidos'] ?? '');
  final celularController =
      TextEditingController(text: repartidorData['celular'] ?? '');
  final dniController =
      TextEditingController(text: repartidorData['dni'] ?? '');
  final direccionController =
      TextEditingController(text: repartidorData['direccion'] ?? '');

  String fotoUrl = repartidorData['fotoUrl'] ?? '';
  bool guardando = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Configuración del repartidor",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () async {
                      final url = await subirFotoRepartidor();

                      if (url != null) {
                        setModalState(() {
                          fotoUrl = url;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      backgroundImage:
                          fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: primaryColor,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Toca la foto para cambiarla",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombres",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: apellidosController,
                    decoration: const InputDecoration(
                      labelText: "Apellidos",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: celularController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Celular",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "DNI",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: direccionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Dirección",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: guardando
                          ? null
                          : () async {
                              setModalState(() {
                                guardando = true;
                              });

                              await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(user.uid)
                                  .update({
                                'nombre': nombreController.text.trim(),
                                'apellidos': apellidosController.text.trim(),
                                'celular': celularController.text.trim(),
                                'dni': dniController.text.trim(),
                                'direccion': direccionController.text.trim(),
                                'fotoUrl': fotoUrl,
                                'fechaActualizacion':
                                    FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Datos actualizados"),
                                ),
                              );
                            },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        guardando ? "Guardando..." : "Guardar cambios",
                        style: const TextStyle(color: Colors.white),
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
Widget menuCard({
  required String titulo,
  required String subtitulo,
  required IconData icono,
  required Color color,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icono, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget resumenEntregas(List<QueryDocumentSnapshot> pedidos) {
  final porEntregar = pedidos.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final estado = data['estadoEntrega'] ?? '';
    return estado == 'en_proceso' || estado == 'en_camino';
  }).length;

  final entregados = pedidos.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['estadoEntrega'] == 'entregado';
  }).length;

  final incidencias = pedidos.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['estadoEntrega'] == 'incidencia';
  }).length;

  Widget tarjeta(String titulo, int cantidad, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icono, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              cantidad.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Row(
    children: [
      tarjeta(
        "Por entregar",
        porEntregar,
        Icons.local_shipping,
        Colors.orange,
      ),
      const SizedBox(width: 8),
      tarjeta(
        "Entregados",
        entregados,
        Icons.check_circle,
        Colors.green,
      ),
      const SizedBox(width: 8),
      tarjeta(
        "Incidencias",
        incidencias,
        Icons.report_problem,
        Colors.redAccent,
      ),
    ],
  );
}
Widget cabeceraRepartidor({
  required Map<String, dynamic> repartidorData,
  required int porEntregar,
  required int entregados,
  required int incidencias,
}) {
  final nombre = repartidorData['nombre'] ?? 'Repartidor';
  final apellidos = repartidorData['apellidos'] ?? '';
  final fotoUrl = repartidorData['fotoUrl'] ?? '';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          primaryColor,
          const Color.fromARGB(255, 120, 0, 40),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          backgroundImage: fotoUrl.toString().isNotEmpty
              ? NetworkImage(fotoUrl)
              : null,
          child: fotoUrl.toString().isEmpty
              ? Icon(
                  Icons.person,
                  color: primaryColor,
                  size: 45,
                )
              : null,
        ),

        const SizedBox(height: 12),

        Text(
          "$nombre $apellidos",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          "Repartidor",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: itemCabeceraResumen(
                titulo: "Por entregar",
                cantidad: porEntregar,
                icono: Icons.local_shipping,
              ),
            ),
            Expanded(
              child: itemCabeceraResumen(
                titulo: "Entregados",
                cantidad: entregados,
                icono: Icons.check_circle,
              ),
            ),
            Expanded(
              child: itemCabeceraResumen(
                titulo: "Incidencias",
                cantidad: incidencias,
                icono: Icons.report_problem,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget itemCabeceraResumen({
  required String titulo,
  required int cantidad,
  required IconData icono,
}) {
  return Column(
    children: [
      Icon(
        icono,
        color: Colors.white,
        size: 22,
      ),
      const SizedBox(height: 5),
      Text(
        cantidad.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        titulo,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
    ],
  );
}
Future<void> confirmarCerrarSesion() async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.logout,
            color: Colors.redAccent,
          ),
          SizedBox(width: 10),
          Text("Cerrar sesión"),
        ],
      ),
      content: const Text(
        "¿Seguro que deseas cerrar sesión y salir del panel de repartidor?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(
            Icons.logout,
            color: Colors.white,
          ),
          label: const Text(
            "Salir",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Error al cerrar sesión: $e",
        ),
      ),
    );
  }
}
Future<void> llamarCliente(String celular) async {
  final numero = celular.replaceAll(' ', '').replaceAll('-', '');

  if (numero.isEmpty || numero == 'Sin celular') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("El cliente no tiene celular registrado")),
    );
    return;
  }

  final uri = Uri.parse("tel:$numero");

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No se pudo abrir la llamada")),
    );
  }
}

Future<void> abrirWhatsAppCliente(String celular) async {
  String numero = celular
      .replaceAll(" ", "")
      .replaceAll("-", "")
      .replaceAll("+", "")
      .replaceAll("(", "")
      .replaceAll(")", "");

  if (numero.isEmpty || numero == "Sin celular") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("El cliente no tiene celular registrado")),
    );
    return;
  }

  if (!numero.startsWith("51")) {
    numero = "51$numero";
  }

  final mensaje = Uri.encodeComponent(
    "Hola, soy el repartidor de Inversiones Isabella. Estoy coordinando la entrega de tu pedido.",
  );

  final whatsappNormal = Uri.parse(
    "whatsapp://send?phone=$numero&text=$mensaje",
  );

  final whatsappBusiness = Uri.parse(
    "https://wa.me/$numero?text=$mensaje",
  );

  try {
    final abiertoNormal = await launchUrl(
      whatsappNormal,
      mode: LaunchMode.externalApplication,
    );

    if (abiertoNormal) return;
  } catch (_) {}

  try {
    final abiertoWeb = await launchUrl(
      whatsappBusiness,
      mode: LaunchMode.externalApplication,
    );

    if (abiertoWeb) return;
  } catch (_) {}

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text("No se pudo abrir WhatsApp"),
    ),
  );
}

  Future<void> iniciarEntrega(String pedidoId) async {
    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'estado': 'en_camino',
        'estadoEntrega': 'en_camino',
        'fechaSalidaDelivery': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .collection('historial')
          .add({
        'accion': 'Pedido en camino',
        'descripcion': 'El repartidor inició la entrega',
        'usuarioId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'usuarioNombre': FirebaseAuth.instance.currentUser?.email ?? 'Repartidor',
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entrega en camino")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al iniciar entrega: $e"),
        ),
      );
    }
  }

  Future<void> entregarPedidoConFoto(String pedidoId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final ImageSource? source = await showModalBottomSheet<ImageSource>(
  context: context,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
  ),
  builder: (_) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Tomar foto"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Seleccionar desde galería"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  },
);

if (source == null) return;

final XFile? imagen = await picker.pickImage(
  source: source,
  imageQuality: 75,
);

  if (imagen == null) return;

  if (!mounted) return;

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text("Confirmar entrega"),
      content: const Text(
        "¿Confirmas que deseas registrar este pedido como entregado?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text(
            "Sí, entregar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  if (confirmar != true) return;

  try {
    final archivo = io.File(imagen.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('evidencias_entrega')
        .child('$pedidoId.jpg');

    await ref.putFile(archivo);

    final fotoUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
      'estado': 'entregado',
      'estadoEntrega': 'entregado',
      'fotoEntregaUrl': fotoUrl,
      'fechaEntrega': FieldValue.serverTimestamp(),
      'entregadoPor': user.uid,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .collection('historial')
        .add({
      'accion': 'Pedido entregado',
      'descripcion': 'Pedido entregado con evidencia fotográfica',
      'usuarioId': user.uid,
      'usuarioNombre': user.email ?? 'Repartidor',
      'fotoUrl': fotoUrl,
      'fecha': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Entrega registrada correctamente"),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Error al entregar pedido: $e"),
      ),
    );
  }
}

  Future<void> reportarIncidencia({
    required String pedidoId,
    required String motivo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('pedidos').doc(pedidoId).update({
        'estado': 'incidencia',
        'estadoEntrega': 'incidencia',
        'motivoIncidencia': motivo,
        'fechaIncidencia': FieldValue.serverTimestamp(),
        'reportadoPor': user.uid,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .collection('historial')
          .add({
        'accion': 'Incidencia reportada',
        'descripcion': motivo,
        'usuarioId': user.uid,
        'usuarioNombre': user.email ?? 'Repartidor',
        'fecha': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incidencia reportada")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al reportar incidencia: $e"),
        ),
      );
    }
  }

void mostrarDialogoIncidencia(String pedidoId) {
  final motivos = [
    "Cliente rechazó el pedido",
    "Cliente ausente",
    "Dirección incorrecta",
    "No contestó llamadas",
    "Producto dañado",
    "Pedido no pudo ser entregado",
    "Otro",
  ];

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Reportar incidencia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: motivos.map((motivo) {
            return ListTile(
              leading: const Icon(
                Icons.report_problem,
                color: Colors.redAccent,
              ),
              title: Text(motivo),
              onTap: () async {
                Navigator.pop(context);

                if (motivo == "Otro") {
                  mostrarDialogoOtroMotivo(pedidoId);
                } else {
                  await confirmarIncidencia(
                    pedidoId: pedidoId,
                    motivo: motivo,
                  );
                }
              },
            );
          }).toList(),
        ),
      );
    },
  );
}
void mostrarDialogoOtroMotivo(String pedidoId) {
  final motivoController = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Otro motivo"),
        content: TextField(
          controller: motivoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Describe la incidencia",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              final motivo = motivoController.text.trim();

              if (motivo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Escribe el motivo de la incidencia"),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              await confirmarIncidencia(
                pedidoId: pedidoId,
                motivo: motivo,
              );
            },
            child: const Text(
              "Reportar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
Future<void> confirmarIncidencia({
  required String pedidoId,
  required String motivo,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Confirmar incidencia"),
        content: Text(
          "¿Deseas reportar esta incidencia?\n\nMotivo: $motivo",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.report_problem, color: Colors.white),
            label: const Text(
              "Sí, reportar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  await reportarIncidencia(
    pedidoId: pedidoId,
    motivo: motivo,
  );
}

  Widget botonesAccionPedido({
    required String pedidoId,
    required String estadoEntrega,
  }) {
    if (estadoEntrega == 'en_proceso') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => iniciarEntrega(pedidoId),
          icon: const Icon(Icons.local_shipping, color: Colors.white),
          label: const Text(
            "Realizar entrega",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (estadoEntrega == 'en_camino') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => entregarPedidoConFoto(pedidoId),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text(
                "Entregar con foto",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => mostrarDialogoIncidencia(pedidoId),
              icon: const Icon(Icons.report_problem),
              label: const Text("Reportar incidencia"),
            ),
          ),
        ],
      );
    }

    if (estadoEntrega == 'entregado') {
      return const Text(
        "Pedido entregado correctamente",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (estadoEntrega == 'incidencia') {
      return const Text(
        "Pedido con incidencia reportada",
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return const SizedBox();
  }

  Widget productoItem(Map<String, dynamic> producto) {
    final imagenUrl = producto['imagenUrl'] ?? '';
    final nombre = producto['nombre'] ?? 'Producto';
    final cantidad = int.tryParse(producto['cantidad'].toString()) ?? 1;
    final precio = double.tryParse(producto['precio'].toString()) ?? 0;
    final subtotal = cantidad * precio;
    final color = producto['colorSeleccionado'];
    final talla = producto['tallaSeleccionada'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imagenUrl.toString().isNotEmpty
                ? Image.network(
                    imagenUrl,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 75,
                    height: 75,
                    color: primaryColor.withValues(alpha: 0.10),
                    child: Icon(Icons.shopping_bag, color: primaryColor),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (color != null || talla != null)
                  Text(
                    "${color != null ? 'Color: $color' : ''}"
                    "${color != null && talla != null ? ' | ' : ''}"
                    "${talla != null ? 'Talla: $talla' : ''}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                Text(
                  "Cantidad: $cantidad",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                Text(
                  "Precio: S/ ${precio.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "S/ ${subtotal.toStringAsFixed(2)}",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget datoDetalle(String titulo, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: "$titulo: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget historialPedidoWidget(String pedidoId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .collection('historial')
        .orderBy('fecha', descending: false)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text("Error al cargar historial");
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final historial = snapshot.data!.docs;

      if (historial.isEmpty) {
        return const Text("Aún no hay historial del pedido");
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: historial.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final accion = data['accion'] ?? 'Movimiento';
          final descripcion = data['descripcion'] ?? '';
          final usuarioNombre = data['usuarioNombre'] ?? '';
          final fecha = data['fecha'];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.timeline, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accion,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (descripcion.toString().isNotEmpty)
                        Text(descripcion),
                      if (usuarioNombre.toString().isNotEmpty)
                        Text(
                          "Usuario: $usuarioNombre",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        formatearFecha(fecha),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    },
  );
}

Future<io.File> generarPdfPedido({
  required String pedidoId,
  required Map<String, dynamic> pedido,
} )
async {
  final pdf = pw.Document();

  final productos =
      List<Map<String, dynamic>>.from(pedido['productos'] ?? []);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(
          "INVERSIONES ISABELLA",
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 15),

        pw.Text("Pedido: $pedidoId"),

        pw.Divider(),

        pw.Text(
          "DATOS DEL CLIENTE",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Text("Cliente: ${pedido['clienteNombre'] ?? ''}"),
        pw.Text("Celular: ${pedido['clienteCelular'] ?? ''}"),
        pw.Text("Correo: ${pedido['clienteCorreo'] ?? ''}"),
        pw.Text("Dirección: ${pedido['clienteDireccion'] ?? ''}"),

        pw.SizedBox(height: 20),

        pw.Text(
          "PRODUCTOS",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Table.fromTextArray(
          headers: [
            "Producto",
            "Color",
            "Talla",
            "Cant.",
            "Precio",
          ],
          data: productos.map((item) {
            return [
              item['nombre'] ?? '',
              item['colorSeleccionado'] ?? '',
              item['tallaSeleccionada'] ?? '',
              item['cantidad'].toString(),
              "S/ ${item['precio']}",
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          "Total: S/ ${pedido['total'] ?? 0}",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          ),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          "Estado: ${pedido['estadoEntrega'] ?? ''}",
        ),

        pw.SizedBox(height: 50),

        pw.Center(
          child: pw.Text(
            "Firma del repartidor",
          ),
        ),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();

  final file = io.File(
    '${dir.path}/pedido_$pedidoId.pdf',
  );

  await file.writeAsBytes(await pdf.save());

  return file;
}
Future<void> descargarPdfPedido({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) async {
  try {
    final archivo = await generarPdfPedido(
      pedidoId: pedidoId,
      pedido: pedido,
    );

    await OpenFilex.open(archivo.path);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Error al abrir PDF: $e"),
      ),
    );
  }
}
Future<void> compartirPdfPedido({
  required String pedidoId,
  required Map<String, dynamic> pedido,
}) async {
  try {
    final archivo = await generarPdfPedido(
      pedidoId: pedidoId,
      pedido: pedido,
    );

    await Share.shareXFiles(
      [XFile(archivo.path)],
      text: "Pedido $pedidoId - Inversiones Isabella",
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Error al compartir PDF: $e",
        ),
      ),
    );
  }
}
  void abrirDetallePedido(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final productos = List<Map<String, dynamic>>.from(data['productos'] ?? []);
    final estadoEntrega = data['estadoEntrega'] ?? 'pendiente';
    final clienteNombre = data['clienteNombre'] ?? 'Cliente';
    final direccion = data['clienteDireccion'] ?? 'Sin dirección';
    final celular = data['clienteCelular'] ?? 'Sin celular';
    final dni = data['clienteDni'] ?? 'Sin DNI';
    final correo = data['clienteCorreo'] ?? 'Sin correo';
    final total = double.tryParse(data['total'].toString()) ?? 0;
    final metodoPago = data['metodoPago'] ?? 'No definido';
    final metodoEntrega = data['metodoEntrega'] ?? 'delivery';
    final costoDelivery = double.tryParse(data['costoDelivery'].toString()) ?? 0;
    final fotoEntregaUrl = data['fotoEntregaUrl'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F6FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.90,
          maxChildSize: 0.96,
          minChildSize: 0.55,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "Pedido #${doc.id.substring(0, 8).toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('pedidos')
      .doc(doc.id)
      .snapshots(),
  builder: (context, snapshot) {
    String estadoEntregaActual = estadoEntrega.toString();

    if (snapshot.hasData && snapshot.data!.exists) {
      final pedidoActualizado =
          snapshot.data!.data() as Map<String, dynamic>;

      estadoEntregaActual =
          (pedidoActualizado['estadoEntrega'] ?? estadoEntrega).toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorEstado(estadoEntregaActual).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        textoEstado(estadoEntregaActual),
        style: TextStyle(
          color: colorEstado(estadoEntregaActual),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  },
),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
  const Text(
    "Datos del cliente",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
    ),
    onPressed: () {
  descargarPdfPedido(
    pedidoId: doc.id,
    pedido: data,
  );
},
    icon: const Icon(
      Icons.picture_as_pdf,
      color: Colors.white,
    ),
    label: const Text(
      "Descargar PDF",
      style: TextStyle(color: Colors.white),
    ),
  ),
),

const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
    ),
    onPressed: () {
      compartirPdfPedido(
        pedidoId: doc.id,
        pedido: data,
      );
    },
    icon: const Icon(
      Icons.share,
      color: Colors.white,
    ),
    label: const Text(
      "Compartir PDF",
      style: TextStyle(color: Colors.white),
    ),
  ),
),

  const SizedBox(height: 12),

  datoDetalle("Cliente", clienteNombre, Icons.person),
  datoDetalle("Celular", celular, Icons.phone),
  datoDetalle("DNI", dni, Icons.badge),
  datoDetalle("Correo", correo, Icons.email),
  datoDetalle("Dirección", direccion, Icons.location_on),

  const SizedBox(height: 12),

  Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            llamarCliente(celular.toString());
          },
          icon: const Icon(Icons.phone, color: Colors.white),
          label: const Text(
            "Llamar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            abrirWhatsAppCliente(celular.toString());
          },
          icon: const Icon(Icons.message, color: Colors.white),
          label: const Text(
            "WhatsApp",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ],
  ),
],
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Información del pedido",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      datoDetalle(
                        "Entrega",
                        metodoEntrega == 'delivery' ? "Delivery" : "Recojo en tienda",
                        Icons.local_shipping,
                      ),
                      datoDetalle("Método de pago", metodoPago, Icons.payments),
                      datoDetalle(
                        "Costo delivery",
                        "S/ ${costoDelivery.toStringAsFixed(2)}",
                        Icons.delivery_dining,
                      ),
                      datoDetalle(
                        "Fecha",
                        formatearFecha(data['fechaPedido']),
                        Icons.calendar_month,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Productos del pedido",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),

                const SizedBox(height: 10),

                ...productos.map(productoItem),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Total del pedido",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "S/ ${total.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('pedidos')
      .doc(doc.id)
      .snapshots(),
  builder: (context, snapshot) {
    String fotoActual = fotoEntregaUrl.toString();

    if (snapshot.hasData && snapshot.data!.exists) {
      final pedidoActualizado =
          snapshot.data!.data() as Map<String, dynamic>;

      fotoActual =
          (pedidoActualizado['fotoEntregaUrl'] ?? '').toString();
    }

    if (fotoActual.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          "Evidencia de entrega",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            fotoActual,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  },
),

                const SizedBox(height: 18),

                StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('pedidos')
      .doc(doc.id)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || !snapshot.data!.exists) {
      return const SizedBox();
    }

    final pedidoActualizado =
        snapshot.data!.data() as Map<String, dynamic>;

    final estadoEntregaActual =
        pedidoActualizado['estadoEntrega'] ?? 'pendiente';

    return botonesAccionPedido(
      pedidoId: doc.id,
      estadoEntrega: estadoEntregaActual.toString(),
    );
  },
),
const SizedBox(height: 20),

const Text(
  "Historial del pedido",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
  ),
),

const SizedBox(height: 10),

historialPedidoWidget(doc.id),

                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }

  Widget pedidoCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final estadoEntrega = data['estadoEntrega'] ?? 'pendiente';
    final clienteNombre = data['clienteNombre'] ?? 'Cliente';
    final direccion = data['clienteDireccion'] ?? 'Sin dirección';
    final celular = data['clienteCelular'] ?? 'Sin celular';
    final total = double.tryParse(data['total'].toString()) ?? 0;
    final productos = List<Map<String, dynamic>>.from(data['productos'] ?? []);

    return InkWell(
      onTap: () => abrirDetallePedido(doc),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('usuarios')
      .doc(data['clienteId'])
      .get(),
  builder: (context, snapshot) {
    String fotoUrl = "";

    if (snapshot.hasData && snapshot.data!.exists) {
      final clienteData =
          snapshot.data!.data() as Map<String, dynamic>;

      fotoUrl = clienteData['fotoUrl'] ?? '';
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: colorEstado(estadoEntrega).withValues(alpha: 0.12),
      backgroundImage:
          fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
      child: fotoUrl.isEmpty
          ? Icon(
              Icons.person,
              color: colorEstado(estadoEntrega),
            )
          : null,
    );
  },
),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pedido #${doc.id.substring(0, 6).toUpperCase()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        clienteNombre,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Text(
                  "S/ ${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(celular, style: TextStyle(color: Colors.grey[700])),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    direccion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorEstado(estadoEntrega).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    textoEstado(estadoEntrega.toString()),
                    style: TextStyle(
                      color: colorEstado(estadoEntrega),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${productos.length} producto(s)",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Repartidor no autenticado")),
      );
    }

    return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    await confirmarSalidaApp();
  },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
  elevation: 0,
  backgroundColor: primaryColor,
  foregroundColor: Colors.white,
  title: StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      String nombre = "Repartidor";
      String fotoUrl = "";

      if (snapshot.hasData && snapshot.data!.exists) {
        final data = snapshot.data!.data() as Map<String, dynamic>;
        nombre = data['nombre'] ?? 'Repartidor';
        fotoUrl = data['fotoUrl'] ?? '';
      }

      return Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage:
                fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
            child: fotoUrl.isEmpty
                ? Icon(Icons.person, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: confirmarCerrarSesion,
    ),
  ],
),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pedidos')
              .where('repartidorId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error al cargar entregas:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pedidos = snapshot.data!.docs;

            if (pedidos.isEmpty) {
              return const Center(
                child: Text(
                  "No tienes pedidos asignados",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .snapshots(),
  builder: (context, userSnapshot) {
    final repartidorData = userSnapshot.hasData && userSnapshot.data!.exists
        ? userSnapshot.data!.data() as Map<String, dynamic>
        : <String, dynamic>{};

    final porEntregar = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final estado = data['estadoEntrega'] ?? '';
      return estado == "en_proceso" || estado == "en_camino";
    }).length;

    final entregados = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final estado = data['estadoEntrega'] ?? '';
      return estado == "entregado";
    }).length;
    final incidencias = pedidos.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  final estado = data['estadoEntrega'] ?? '';

  return estado == "incidencia";
}).length;

    final pedidosFiltrados = pedidos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final estado = data['estadoEntrega'] ?? '';

      if (filtroPedidos == "por_entregar") {
        return estado == "en_proceso" || estado == "en_camino";
      }

      if (filtroPedidos == "entregados") {
        return estado == "entregado";
      }
      if (filtroPedidos == "incidencias") {
  return estado == "incidencia";
}

      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        cabeceraRepartidor(
  repartidorData: repartidorData,
  porEntregar: porEntregar,
  entregados: entregados,
  incidencias: incidencias,
),

const SizedBox(height: 16),
        Row(
          children: [
            menuCard(
              titulo: "Configuración",
              subtitulo: "Editar perfil",
              icono: Icons.settings,
              color: primaryColor,
              onTap: () {
                mostrarConfiguracionRepartidor(repartidorData);
              },
            ),
            const SizedBox(width: 10),
            menuCard(
              titulo: "Por entregar",
              subtitulo: "$porEntregar pedido(s)",
              icono: Icons.local_shipping,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  filtroPedidos = "por_entregar";
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
  children: [
    menuCard(
      titulo: "Entregados",
      subtitulo: "$entregados pedido(s)",
      icono: Icons.check_circle,
      color: Colors.green,
      onTap: () {
        setState(() {
          filtroPedidos = "entregados";
        });
      },
    ),

    const SizedBox(width: 10),

    menuCard(
      titulo: "Incidencias",
      subtitulo: "$incidencias pedido(s)",
      icono: Icons.report_problem,
      color: Colors.redAccent,
      onTap: () {
        setState(() {
          filtroPedidos = "incidencias";
        });
      },
    ),

    const SizedBox(width: 10),

    menuCard(
      titulo: "Todos",
      subtitulo: "${pedidos.length} pedido(s)",
      icono: Icons.list_alt,
      color: primaryColor,
      onTap: () {
        setState(() {
          filtroPedidos = "todos";
        });
      },
    ),
  ],
),

        const SizedBox(height: 16),

        Text(
  filtroPedidos == "por_entregar"
      ? "Pedidos por entregar"
      : filtroPedidos == "entregados"
          ? "Pedidos entregados"
          : filtroPedidos == "incidencias"
              ? "Pedidos con incidencias"
              : "Todos los pedidos",
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

        const SizedBox(height: 12),

        if (pedidosFiltrados.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text("No hay pedidos en esta sección"),
            ),
          ),

        ...pedidosFiltrados.map((doc) => pedidoCard(doc)),
      ],
    );
  },
);
          },
        ),
      ),
    );
  }
}