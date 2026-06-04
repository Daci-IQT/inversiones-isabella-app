
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

///PANTALLA CLIENTES ADMIN
///////////////////////////////////


class AdminClientesScreen extends StatefulWidget {
  const AdminClientesScreen({super.key});

  @override
  State<AdminClientesScreen> createState() => _AdminClientesScreenState();
}

class _AdminClientesScreenState extends State<AdminClientesScreen> {
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');

  final buscadorController = TextEditingController();

  String textoBusqueda = "";
  String estadoFiltro = "todos";

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  Future<void> cambiarEstadoCliente(String clienteId, bool estadoActual) async {
    await usuariosRef.doc(clienteId).update({
      'activo': !estadoActual,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estadoActual
                ? "Cliente inhabilitado correctamente"
                : "Cliente habilitado correctamente",
          ),
        ),
      );
    }
  }

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    final DateTime fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year} "
        "${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}";
  }

  Widget etiquetaEstadoCliente(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activo
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? "Activo" : "Inactivo",
        style: TextStyle(
          color: activo ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filtrosClientes() {
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
            hintText: "Buscar cliente por nombre, correo o teléfono...",
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
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: estadoFiltro,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Filtrar por estado",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "todos",
              child: Text("Todos los clientes"),
            ),
            DropdownMenuItem(
              value: "activos",
              child: Text("Clientes activos"),
            ),
            DropdownMenuItem(
              value: "inactivos",
              child: Text("Clientes inactivos"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              estadoFiltro = value ?? "todos";
            });
          },
        ),
      ],
    );
  }

  void mostrarDetalleCliente({
    required String clienteId,
    required Map<String, dynamic> cliente,
  }) {
    final activo = cliente['activo'] ?? true;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Detalle del cliente",
                          style: TextStyle(
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
                        Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: primaryColor.withOpacity(0.12),
                            child: Icon(
                              Icons.person,
                              size: 45,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Center(
                          child: Text(
                            cliente['nombre'] ?? 'Cliente sin nombre',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: etiquetaEstadoCliente(activo),
                        ),

                        const SizedBox(height: 22),

                        infoItem(
                          icon: Icons.email,
                          title: "Correo",
                          value: cliente['correo'] ?? 'Sin correo',
                        ),

                        infoItem(
                          icon: Icons.phone,
                          title: "Teléfono",
                          value: cliente['telefono'] ?? 'Sin teléfono',
                        ),

                        infoItem(
                          icon: Icons.location_on,
                          title: "Dirección",
                          value: cliente['direccion'] ?? 'Sin dirección',
                        ),

                        infoItem(
                          icon: Icons.verified_user,
                          title: "Rol",
                          value: cliente['rol'] ?? 'cliente',
                        ),

                        infoItem(
                          icon: Icons.calendar_month,
                          title: "Fecha de registro",
                          value: formatearFecha(cliente['fechaRegistro']),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            "Nota: No se recomienda eliminar clientes porque pueden tener pedidos, reclamos o historial dentro del sistema.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cerrar"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activo ? Colors.red : Colors.green,
                        ),
                        onPressed: () async {
                          await cambiarEstadoCliente(clienteId, activo);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          activo ? "Inhabilitar" : "Habilitar",
                          style: const TextStyle(color: Colors.white),
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
  }

  Widget infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget clienteCard({
    required String clienteId,
    required Map<String, dynamic> cliente,
  }) {
    final activo = cliente['activo'] ?? true;

    return Opacity(
      opacity: activo ? 1 : 0.55,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.12),
            child: Icon(
              Icons.person,
              color: primaryColor,
            ),
          ),
          title: Text(
            cliente['nombre'] ?? 'Cliente sin nombre',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text("Correo: ${cliente['correo'] ?? 'Sin correo'}"),
              Text("Teléfono: ${cliente['telefono'] ?? 'Sin teléfono'}"),
              Text("Registro: ${formatearFecha(cliente['fechaRegistro'])}"),
              const SizedBox(height: 6),
              etiquetaEstadoCliente(activo),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "detalle") {
                mostrarDetalleCliente(
                  clienteId: clienteId,
                  cliente: cliente,
                );
              }

              if (value == "estado") {
                cambiarEstadoCliente(clienteId, activo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "detalle",
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Ver detalle"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "estado",
                child: Row(
                  children: [
                    Icon(
                      activo ? Icons.visibility_off : Icons.visibility,
                      color: activo ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(activo ? "Inhabilitar" : "Habilitar"),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            mostrarDetalleCliente(
              clienteId: clienteId,
              cliente: cliente,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Clientes",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Visualiza, busca y administra el estado de los clientes registrados.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 18),

            filtrosClientes(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usuariosRef
                    .where('rol', isEqualTo: 'cliente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar clientes"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay clientes registrados"),
                    );
                  }

                  final clientesFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final nombre =
                        (data['nombre'] ?? '').toString().toLowerCase();

                    final correo =
                        (data['correo'] ?? '').toString().toLowerCase();

                    final telefono =
                        (data['telefono'] ?? '').toString().toLowerCase();

                    final activo = data['activo'] ?? true;

                    final coincideBusqueda =
                        nombre.contains(textoBusqueda) ||
                            correo.contains(textoBusqueda) ||
                            telefono.contains(textoBusqueda);

                    final coincideEstado = estadoFiltro == "todos"
                        ? true
                        : estadoFiltro == "activos"
                            ? activo == true
                            : activo == false;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  if (clientesFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron clientes"),
                    );
                  }

                  return ListView(
                    children: clientesFiltrados.map((doc) {
                      final cliente = doc.data() as Map<String, dynamic>;

                      return clienteCard(
                        clienteId: doc.id,
                        cliente: cliente,
                      );
                    }).toList(),
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
