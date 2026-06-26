import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// CONFIGURACIÓN CLIENTE
////////////////////////////////////////////

class ConfiguracionClienteScreen extends StatefulWidget {
  final String uid;

  const ConfiguracionClienteScreen({
    super.key,
    required this.uid,
  });

  @override
  State<ConfiguracionClienteScreen> createState() =>
      _ConfiguracionClienteScreenState();
}

class _ConfiguracionClienteScreenState
    extends State<ConfiguracionClienteScreen> {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String region = 'Perú';
  String idioma = 'Español';
  String moneda = 'PEN - Sol peruano';
  bool notificarPedidos = true;
bool notificarOfertas = true;
bool notificarDelivery = true;


@override

void initState() {
  super.initState();
  cargarConfiguracion();
}

Future<void> cargarConfiguracion() async {
  final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(widget.uid)
      .get();

  if (!doc.exists) return;

  final data = doc.data();

  if (data == null || data['configuracion'] == null) return;

  final config = data['configuracion'];

  if (!mounted) return;

  setState(() {
    region = config['region'] ?? region;
    idioma = config['idioma'] ?? idioma;
    moneda = config['moneda'] ?? moneda;

    notificarPedidos = config['notificarPedidos'] ?? true;
    notificarOfertas = config['notificarOfertas'] ?? true;
    notificarDelivery = config['notificarDelivery'] ?? true;
  });
}

  Future<void> guardarConfiguracion() async {
    await FirebaseFirestore.instance.collection('usuarios').doc(widget.uid).set({
      'configuracion': {
        'region': region,
        'idioma': idioma,
        'moneda': moneda,
        'notificarPedidos': notificarPedidos,
'notificarOfertas': notificarOfertas,
'notificarDelivery': notificarDelivery,
      },
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configuración guardada")),
    );
  }

Future<void> cambiarPassword() async {
  final passwordController = TextEditingController();
  final confirmarController = TextEditingController();

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Cambiar contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmarController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmar contraseña",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Actualizar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  final nuevaPassword = passwordController.text.trim();
  final confirmarPassword = confirmarController.text.trim();

  if (nuevaPassword.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("La contraseña debe tener mínimo 6 caracteres"),
      ),
    );
    return;
  }

  if (nuevaPassword != confirmarPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Las contraseñas no coinciden"),
      ),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.currentUser!.updatePassword(nuevaPassword);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Contraseña actualizada correctamente"),
      ),
    );
  } on FirebaseAuthException catch (e) {
    String mensaje = "No se pudo actualizar la contraseña";

    if (e.code == 'requires-recent-login') {
      mensaje = "Por seguridad, vuelve a iniciar sesión e intenta nuevamente";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(mensaje),
      ),
    );
  }
}

Future<void> eliminarCuenta() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final confirmarPrimero = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Eliminar cuenta"),
        content: const Text(
          "¿Seguro que deseas eliminar tu cuenta? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Continuar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmarPrimero != true) return;

  final confirmarTextoController = TextEditingController();

  final confirmarSegundo = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Confirmación final"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Escribe ELIMINAR para confirmar la eliminación de tu cuenta.",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmarTextoController,
              decoration: const InputDecoration(
                labelText: "Escribe ELIMINAR",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Eliminar cuenta",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmarSegundo != true) return;

  if (confirmarTextoController.text.trim().toUpperCase() != "ELIMINAR") {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Confirmación incorrecta"),
      ),
    );
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .delete();

    await user.delete();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    String mensaje = "No se pudo eliminar la cuenta";

    if (e.code == 'requires-recent-login') {
      mensaje = "Por seguridad, vuelve a iniciar sesión e intenta nuevamente";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(mensaje),
      ),
    );
  }
}


  Future<void> cerrarSesion() async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text("Cerrar sesión"),
        content: const Text(
          "¿Seguro que quieres cerrar sesión?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              "Salir",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  Navigator.of(context).pushNamedAndRemoveUntil(
    '/',
    (route) => false,
  );
}


void mostrarAcercaDeApp() {
  showAboutDialog(
    context: context,
    applicationName: "Inversiones Isabella",
    applicationVersion: "1.0.0",
    applicationIcon: Icon(
      Icons.store,
      color: primaryColor,
      size: 36,
    ),
    children: const [
      Text(
        "Aplicación móvil para la gestión de ventas, pedidos, clientes y delivery de Inversiones Isabella.",
      ),
    ],
  );
}

void mostrarCentroAyuda() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 35,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Icon(
                  Icons.support_agent,
                  color: primaryColor,
                  size: 40,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Centro de Ayuda",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "¿En qué podemos ayudarte?",
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              ayudaItem(
                icono: Icons.shopping_cart_outlined,
                titulo: "Problemas con pedidos",
                subtitulo: "Consultas sobre compras y pedidos.",
              ),

              ayudaItem(
                icono: Icons.local_shipping_outlined,
                titulo: "Seguimiento de delivery",
                subtitulo: "Información sobre entregas.",
              ),

              ayudaItem(
                icono: Icons.payment_outlined,
                titulo: "Pagos y facturación",
                subtitulo: "Problemas con pagos o comprobantes.",
              ),

              ayudaItem(
                icono: Icons.account_circle_outlined,
                titulo: "Mi cuenta",
                subtitulo: "Contraseña, acceso y configuración.",
              ),

              ayudaItem(
                icono: Icons.chat_outlined,
                titulo: "Contactar soporte",
                subtitulo: "Próximamente disponible.",
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

Widget seccionConfig({
  required String titulo,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}
Widget itemConfig({
  required IconData icono,
  required String titulo,
  required String subtitulo,
  required Color color,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icono, color: color),
    ),
    title: Text(
      titulo,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Text(subtitulo),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );
}

Widget ayudaItem({
  required IconData icono,
  required String titulo,
  required String subtitulo,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: primaryColor.withValues(alpha: 0.10),
      child: Icon(icono, color: primaryColor),
    ),
    title: Text(
      titulo,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(subtitulo),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$titulo próximamente disponible"),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
  padding: const EdgeInsets.all(18),
  children: [
    Container(
  margin: const EdgeInsets.only(bottom: 20),
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        primaryColor,
        primaryColor.withValues(alpha: 0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.30),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: const Column(
    children: [
      CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.settings,
          size: 40,
          color: Colors.pink,
        ),
      ),

      SizedBox(height: 14),

      Text(
        "Configuración",
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      SizedBox(height: 6),

      Text(
        "Personaliza tu experiencia en Inversiones Isabella",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    ],
  ),
),
    seccionConfig(
      titulo: "Cuenta",
      children: [
        itemConfig(
          icono: Icons.lock_reset,
          titulo: "Cambiar contraseña",
          subtitulo: "Actualiza tu clave de acceso",
          color: primaryColor,
          onTap: cambiarPassword,
        ),
        itemConfig(
          icono: Icons.delete_forever,
          titulo: "Eliminar cuenta",
          subtitulo: "Borrar cuenta y datos del usuario",
          color: Colors.red,
          onTap: eliminarCuenta,
        ),
      ],
    ),

    seccionConfig(
      titulo: "Preferencias",
      children: [
        DropdownButtonFormField<String>(
          initialValue: region,
          decoration: const InputDecoration(
            labelText: "Región",
            prefixIcon: Icon(Icons.public),
            border: OutlineInputBorder(),
          ),
          items: ['Perú', 'Colombia', 'Ecuador', 'Chile']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => region = value!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: idioma,
          decoration: const InputDecoration(
            labelText: "Idioma",
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          items: ['Español', 'Inglés']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => idioma = value!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: moneda,
          decoration: const InputDecoration(
            labelText: "Moneda",
            prefixIcon: Icon(Icons.payments),
            border: OutlineInputBorder(),
          ),
          items: ['PEN - Sol peruano', 'USD - Dólar']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => moneda = value!),
        ),
      ],
    ),

    seccionConfig(
      titulo: "Notificaciones",
      children: [
        SwitchListTile(
          value: notificarPedidos,
          activeColor: primaryColor,
          title: const Text("Estado de pedidos"),
          subtitle: const Text("Avisos cuando cambie tu pedido"),
          secondary: const Icon(Icons.receipt_long),
          onChanged: (value) {
            setState(() => notificarPedidos = value);
          },
        ),
        SwitchListTile(
          value: notificarOfertas,
          activeColor: primaryColor,
          title: const Text("Ofertas y promociones"),
          subtitle: const Text("Novedades y descuentos"),
          secondary: const Icon(Icons.local_offer),
          onChanged: (value) {
            setState(() => notificarOfertas = value);
          },
        ),
        SwitchListTile(
          value: notificarDelivery,
          activeColor: primaryColor,
          title: const Text("Delivery"),
          subtitle: const Text("Avisos sobre el reparto"),
          secondary: const Icon(Icons.delivery_dining),
          onChanged: (value) {
            setState(() => notificarDelivery = value);
          },
        ),
      ],
    ),

    seccionConfig(
      titulo: "Información",
      children: [
        itemConfig(
          icono: Icons.help_outline,
          titulo: "Centro de ayuda",
          subtitulo: "Preguntas frecuentes y soporte",
          color: primaryColor,
          onTap: mostrarCentroAyuda,
        ),
        itemConfig(
          icono: Icons.info_outline,
          titulo: "Acerca de la app",
          subtitulo: "Versión y descripción del sistema",
          color: primaryColor,
          onTap: mostrarAcercaDeApp,
        ),
      ],
    ),

    seccionConfig(
      titulo: "Sesión",
      children: [
        OutlinedButton.icon(
          onPressed: cerrarSesion,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            "Cerrar sesión",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: guardarConfiguracion,
      icon: const Icon(Icons.save, color: Colors.white),
      label: const Text(
        "Guardar configuración",
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
),
    );
  }
}