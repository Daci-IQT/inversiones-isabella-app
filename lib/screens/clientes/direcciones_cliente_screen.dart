import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// DIRECCIONES CLIENTE
////////////////////////////////////////////

class DireccionesClienteScreen extends StatefulWidget {
  final String uid;

  const DireccionesClienteScreen({
    super.key,
    required this.uid,
  });

  @override
  State<DireccionesClienteScreen> createState() =>
      _DireccionesClienteScreenState();
}

class _DireccionesClienteScreenState extends State<DireccionesClienteScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);
  final Color orangeColor = const Color(0xFFFF7A00);

  CollectionReference get direccionesRef => FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .collection('direcciones');

  void mensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> eliminarDireccion(String id) async {
    await direccionesRef.doc(id).delete();
    mensaje("Dirección eliminada", Colors.redAccent);
  }

  Future<void> marcarPredeterminada(String id) async {
    final direcciones = await direccionesRef.get();

    for (final doc in direcciones.docs) {
      await direccionesRef.doc(doc.id).update({
        'predeterminada': doc.id == id,
      });
    }

    mensaje("Dirección predeterminada actualizada", Colors.green);
  }

  void abrirFormularioDireccion({
    String? direccionId,
    Map<String, dynamic>? dataEditar,
  }) {
    final formKey = GlobalKey<FormState>();

    final paisController =
        TextEditingController(text: dataEditar?['pais'] ?? 'Perú');
    final nombreController =
        TextEditingController(text: dataEditar?['nombre'] ?? '');
    final apellidosController =
        TextEditingController(text: dataEditar?['apellidos'] ?? '');
    final direccionController =
        TextEditingController(text: dataEditar?['direccionExacta'] ?? '');
    final departamentoController =
        TextEditingController(text: dataEditar?['departamento'] ?? '');
    final provinciaController =
        TextEditingController(text: dataEditar?['provincia'] ?? '');
    final distritoController =
        TextEditingController(text: dataEditar?['distrito'] ?? '');
    final contactoController =
        TextEditingController(text: dataEditar?['numeroContacto'] ?? '');
    final dniController =
        TextEditingController(text: dataEditar?['dni'] ?? '');

    bool predeterminada = dataEditar?['predeterminada'] ?? false;
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
            Future<void> guardarDireccion() async {
              if (!formKey.currentState!.validate()) return;

              setModalState(() {
                guardando = true;
              });

              final datos = {
                'pais': paisController.text.trim(),
                'nombre': nombreController.text.trim(),
                'apellidos': apellidosController.text.trim(),
                'direccionExacta': direccionController.text.trim(),
                'departamento': departamentoController.text.trim(),
                'provincia': provinciaController.text.trim(),
                'distrito': distritoController.text.trim(),
                'numeroContacto': contactoController.text.trim(),
                'dni': dniController.text.trim(),
                'predeterminada': predeterminada,
                'fechaActualizacion': FieldValue.serverTimestamp(),
              };

              if (predeterminada) {
                final docs = await direccionesRef.get();
                for (final doc in docs.docs) {
                  await direccionesRef.doc(doc.id).update({
                    'predeterminada': false,
                  });
                }
              }

              if (direccionId == null) {
                await direccionesRef.add({
                  ...datos,
                  'fechaRegistro': FieldValue.serverTimestamp(),
                });
              } else {
                await direccionesRef.doc(direccionId).update(datos);
              }

              if (context.mounted) {
                Navigator.pop(context);
                mensaje(
                  direccionId == null
                      ? "Dirección guardada correctamente"
                      : "Dirección actualizada correctamente",
                  Colors.green,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
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
                      direccionId == null
                          ? "Agregar nueva dirección"
                          : "Editar dirección",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Estos datos serán usados para registrar tus pedidos.",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),

                    campoFormulario(
                      "País",
                      Icons.flag,
                      paisController,
                    ),
                    campoFormulario(
                      "Nombre",
                      Icons.person,
                      nombreController,
                    ),
                    campoFormulario(
                      "Apellidos",
                      Icons.person_outline,
                      apellidosController,
                    ),
                    campoFormulario(
                      "Dirección exacta",
                      Icons.location_on,
                      direccionController,
                    ),
                    campoFormulario(
                      "Departamento",
                      Icons.map,
                      departamentoController,
                    ),
                    campoFormulario(
                      "Provincia",
                      Icons.location_city,
                      provinciaController,
                    ),
                    campoFormulario(
                      "Distrito",
                      Icons.place,
                      distritoController,
                    ),
                    campoFormulario(
                      "Número de contacto",
                      Icons.phone,
                      contactoController,
                      keyboardType: TextInputType.phone,
                    ),
                    campoFormulario(
                      "DNI",
                      Icons.badge,
                      dniController,
                      keyboardType: TextInputType.number,
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: predeterminada,
                      activeColor: primaryColor,
                      title: const Text(
                        "Usar como dirección predeterminada",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          predeterminada = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: guardando ? null : guardarDireccion,
                        icon: guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          guardando ? "Guardando..." : "Guardar dirección",
                          style: const TextStyle(
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

  Widget campoFormulario(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Este campo es obligatorio";
          }

          if (label == "DNI" && value.trim().length < 8) {
            return "Ingrese un DNI válido";
          }

          if (label == "Número de contacto" && value.trim().length < 9) {
            return "Ingrese un número válido";
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void abrirDetalleDireccion(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            shrinkWrap: true,
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
              const Text(
                "Detalle de dirección",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              itemDetalle("País", data['pais']),
              itemDetalle("Nombre", data['nombre']),
              itemDetalle("Apellidos", data['apellidos']),
              itemDetalle("Dirección exacta", data['direccionExacta']),
              itemDetalle("Departamento", data['departamento']),
              itemDetalle("Provincia", data['provincia']),
              itemDetalle("Distrito", data['distrito']),
              itemDetalle("Número de contacto", data['numeroContacto']),
              itemDetalle("DNI", data['dni']),

              const SizedBox(height: 18),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    abrirFormularioDireccion(
                      direccionId: id,
                      dataEditar: data,
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    "Editar dirección",
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
      },
    );
  }

  Widget itemDetalle(String titulo, dynamic valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget direccionCard(String id, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? '';
    final apellidos = data['apellidos'] ?? '';
    final contacto = data['numeroContacto'] ?? '';
    final direccion = data['direccionExacta'] ?? '';
    final distrito = data['distrito'] ?? '';
    final provincia = data['provincia'] ?? '';
    final departamento = data['departamento'] ?? '';
    final pais = data['pais'] ?? '';
    final predeterminada = data['predeterminada'] == true;

    return InkWell(
      onTap: () => abrirDetalleDireccion(id, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (predeterminada)
              Container(
                margin: const EdgeInsets.only(left: 0, bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: orangeColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  "Usada recientemente",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "$nombre $apellidos",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    contacto,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                direccion,
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "$distrito, $provincia, $departamento, $pais",
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: const Color(0xFFF7F7F7),
              child: Row(
                children: [
                  Icon(
                    predeterminada
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: predeterminada ? Colors.black : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => marcarPredeterminada(id),
                    child: Text(
                      predeterminada ? "Predeterminado" : "Elegir",
                      style: TextStyle(
                        color: predeterminada ? Colors.grey[600] : primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => eliminarDireccion(id),
                    child: const Text("Eliminar"),
                  ),
                  const Text("|"),
                  TextButton(
                    onPressed: () {
                      abrirFormularioDireccion(
                        direccionId: id,
                        dataEditar: data,
                      );
                    },
                    child: const Text("Editar"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 14),
            const Text(
              "No tienes direcciones registradas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Agrega una dirección para poder realizar tus pedidos.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 54,
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Direcciones",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Todos los datos están protegidos",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: direccionesRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return estadoVacio();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return direccionCard(doc.id, data);
                    },
                  );
                },
              ),
            ),

            Container(
              color: const Color(0xFFF3F3F3),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => abrirFormularioDireccion(),
                  child: const Text(
                    "Agregar una nueva dirección",
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
    );
  }
}