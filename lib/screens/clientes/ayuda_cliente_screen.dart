import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// CENTRO DE SOPORTE CLIENTE
////////////////////////////////////////////

class AyudaClienteScreen extends StatefulWidget {
  const AyudaClienteScreen({super.key});

  @override
  State<AyudaClienteScreen> createState() => _AyudaClienteScreenState();
}

class _AyudaClienteScreenState extends State<AyudaClienteScreen> {
  final motivoController = TextEditingController();
  final detalleController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String tipoSolicitud = 'Problema con pedido';

  final List<String> tiposSolicitud = [
    'Problema con pedido',
    'Problema con delivery',
    'Pago o facturación',
    'Devolución o reembolso',
    'Cambio de producto',
    'Otros',
  ];

  Future<void> enviarSolicitud() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (motivoController.text.trim().isEmpty ||
        detalleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Completa el motivo y detalle de la solicitud"),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('solicitudes_ayuda').add({
      'uidCliente': user.uid,
      'correo': user.email,
      'tipo': tipoSolicitud,
      'motivo': motivoController.text.trim(),
      'detalle': detalleController.text.trim(),
      'estado': 'pendiente',
      'respuestaAdmin': '',
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Solicitud enviada correctamente"),
      ),
    );

    motivoController.clear();
    detalleController.clear();

    setState(() {
      tipoSolicitud = 'Problema con pedido';
    });
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_revision':
        return Colors.blue;
      case 'resuelto':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'resuelto':
        return 'Resuelto';
      case 'rechazado':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  IconData iconoTipo(String tipo) {
    switch (tipo) {
      case 'Problema con pedido':
        return Icons.shopping_cart_outlined;
      case 'Problema con delivery':
        return Icons.local_shipping_outlined;
      case 'Pago o facturación':
        return Icons.payment_outlined;
      case 'Devolución o reembolso':
        return Icons.replay_circle_filled_outlined;
      case 'Cambio de producto':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  Widget formularioSoporte() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nueva solicitud",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Describe tu problema para que podamos ayudarte.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: tipoSolicitud,
            decoration: const InputDecoration(
              labelText: "Tipo de solicitud",
              prefixIcon: Icon(Icons.support_agent),
              border: OutlineInputBorder(),
            ),
            items: tiposSolicitud
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                tipoSolicitud = value!;
              });
            },
          ),

          const SizedBox(height: 14),

          TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: "Motivo",
              prefixIcon: Icon(Icons.help_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: detalleController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Detalle de la solicitud",
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
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
              onPressed: enviarSolicitud,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                "Enviar solicitud",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget historialSolicitudes() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes_ayuda')
          .where('uidCliente', isEqualTo: user.uid)
          .orderBy('fechaRegistro', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final solicitudes = snapshot.data!.docs;

        if (solicitudes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              "Aún no tienes solicitudes registradas.",
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mis solicitudes",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...solicitudes.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final tipo = data['tipo'] ?? 'Solicitud';
              final motivo = data['motivo'] ?? '';
              final estado = data['estado'] ?? 'pendiente';
              final respuesta = data['respuestaAdmin'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withValues(alpha: 0.10),
                      child: Icon(
                        iconoTipo(tipo),
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            motivo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado(estado).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              textoEstado(estado),
                              style: TextStyle(
                                color: colorEstado(estado),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (respuesta.toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                "Respuesta: $respuesta",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    motivoController.dispose();
    detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      appBar: AppBar(
        title: const Text("Centro de Soporte"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 14),
                Text(
                  "¿Necesitas ayuda?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Registra tus solicitudes y revisa el estado de atención.",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          formularioSoporte(),

          const SizedBox(height: 24),

          historialSolicitudes(),
        ],
      ),
    );
  }
}