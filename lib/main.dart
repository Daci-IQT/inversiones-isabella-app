// 🔹 IMPORTACIONES
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Inicializar Firebase
import 'package:firebase_auth/firebase_auth.dart'; // Login / Registro
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de datos';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';




// 🚀 FUNCIÓN PRINCIPAL
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para async
  await Firebase.initializeApp(); // Inicializa Firebase
  runApp(MyApp());
}

// 📱 APP PRINCIPAL
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Inicia en login
    );
  }
}

////////////////////////////////////////////////////////
/// 🔐 PANTALLA LOGIN DISEÑADA
////////////////////////////////////////////////////////
class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🔹 FUNCIÓN LOGIN
  Future<void> login(BuildContext context) async {
    try {
      // 🔐 Autenticación con Firebase
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = user.user!.uid;

      // 🔍 Buscar rol del usuario en Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      String rol = doc['rol'];

      // 🔀 Redirección según rol
      if (rol == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ClientePanel()),
        );
      }
    } catch (e) {
      print("ERROR LOGIN: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al iniciar sesión"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎨 Fondo degradado rojo/rosado/negro
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 243, 33, 96),
              Color.fromARGB(255, 120, 0, 40),
              Colors.black,
            ],
          ),
        ),

        // 📌 Centra el login en pantalla
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),

              // 🧾 Tarjeta principal del login
              child: Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🛍️ Icono de tienda
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Color.fromARGB(255, 243, 33, 96),
                      child: Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),

                    SizedBox(height: 18),

                    // 🏷️ Nombre de la app
                    Text(
                      "Inversiones Isabella",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "E-commerce móvil",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),

                    SizedBox(height: 30),

                    // 📧 Campo email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // 🔑 Campo contraseña
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    // 🔘 Botón ingresar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 243, 33, 96),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Ingresar",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // 🔘 Ir a registro
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        "¿No tienes cuenta? Crear cuenta",
                        style: TextStyle(
                          color: Color.fromARGB(255, 243, 33, 96),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// 🧾 REGISTRO DE USUARIO
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
/// 🧾 REGISTRO DE USUARIO (DISEÑO MODERNO)
////////////////////////////////////////////////////////
class RegisterScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🔹 FUNCIÓN REGISTRO
  Future<void> registrar(BuildContext context) async {
    try {
      // 🔐 Crear usuario
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = user.user!.uid;

      // ☁️ Guardar en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'email': emailController.text.trim(),
        'rol': 'cliente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Usuario registrado correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      print("ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar usuario"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //////////////////////////////////////////////////////
      /// 🎨 FONDO DEGRADADO
      //////////////////////////////////////////////////////
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 243, 33, 96),
              Color.fromARGB(255, 120, 0, 40),
              Colors.black,
            ],
          ),
        ),

        //////////////////////////////////////////////////////
        /// 📌 CONTENIDO CENTRADO
        //////////////////////////////////////////////////////
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),

              //////////////////////////////////////////////////
              /// 🧾 TARJETA DE REGISTRO
              //////////////////////////////////////////////////
              child: Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    //////////////////////////////////////////////////
                    /// 👤 ICONO
                    //////////////////////////////////////////////////
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color.fromARGB(255, 243, 33, 96),
                      child: Icon(Icons.person_add,
                          color: Colors.white, size: 40),
                    ),

                    SizedBox(height: 15),

                    //////////////////////////////////////////////////
                    /// 🏷️ TÍTULO
                    //////////////////////////////////////////////////
                    Text(
                      "Crear Cuenta",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Regístrate para continuar",
                      style: TextStyle(color: Colors.grey),
                    ),

                    SizedBox(height: 25),

                    //////////////////////////////////////////////////
                    /// 📧 EMAIL
                    //////////////////////////////////////////////////
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    //////////////////////////////////////////////////
                    /// 🔑 PASSWORD
                    //////////////////////////////////////////////////
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    //////////////////////////////////////////////////
                    /// 🔘 BOTÓN REGISTRAR
                    //////////////////////////////////////////////////
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => registrar(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color.fromARGB(255, 243, 33, 96),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "Registrar",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    //////////////////////////////////////////////////
                    /// 🔙 VOLVER A LOGIN
                    //////////////////////////////////////////////////
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "¿Ya tienes cuenta? Inicia sesión",
                        style: TextStyle(
                          color: Color.fromARGB(255, 243, 33, 96),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


////////////////////////////////////////////////////////
/// 🚀 PANTALLA PRINCIPAL ADMIN - DISEÑO MODERNO
////////////////////////////////////////////////////////
class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
final FirebaseAuth auth = FirebaseAuth.instance;
final usuariosRef = FirebaseFirestore.instance.collection('usuarios');

User? get usuarioActual => auth.currentUser;
  
  // 🔹 CONTROL DE SECCIÓN ACTIVA
  String selectedMenu = "dashboard";
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  // 🔹 COLOR PRINCIPAL DE LA MARCA
  final Color colorPrincipal = Color.fromARGB(255, 243, 33, 96);

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      ////////////////////////////////////////////////////////
      /// 📌 APPBAR SUPERIOR
      ////////////////////////////////////////////////////////
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorPrincipal,
        title: Text(
          "INVERSIONES ISABELLA",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: StreamBuilder<DocumentSnapshot>(
      stream: usuariosRef.doc(usuarioActual?.uid).snapshots(),
      builder: (context, snapshot) {
        String nombre = "Admin";
        String fotoUrl = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nombre = data['nombre'] ?? "Admin";
          fotoUrl = data['fotoUrl'] ?? "";
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white,
              backgroundImage:
                  fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
              child: fotoUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      color: primaryColor,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    ),
  ),
],
      ),

      ////////////////////////////////////////////////////////
      /// 📌 MENÚ LATERAL
      ////////////////////////////////////////////////////////
      drawer: SizedBox(
        width: 270,
        child: Drawer(
          child: Column(
            children: [
              ////////////////////////////////////////////////////
              /// 🔵 HEADER DEL MENÚ
              ////////////////////////////////////////////////////
              StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('configuracion')
      .doc('negocio')
      .snapshots(),
  builder: (context, snapshot) {
    String nombreNegocio = "Inversiones Isabella";
    String subtitulo = "Panel Administrativo";
    String logoUrl = "";

    if (snapshot.hasData && snapshot.data!.exists) {
      final data = snapshot.data!.data() as Map<String, dynamic>;
      nombreNegocio = data['nombreNegocio'] ?? nombreNegocio;
      subtitulo = data['subtitulo'] ?? subtitulo;
      logoUrl = data['logoUrl'] ?? "";
    }

    return Container(
      height: 145,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage:
                logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
            child: logoUrl.isEmpty
                ? Icon(
                    Icons.store,
                    color: primaryColor,
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            nombreNegocio,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  },
),

              ////////////////////////////////////////////////////
              /// 📊 OPCIONES DEL MENÚ
              ////////////////////////////////////////////////////
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  children: [
                    menuItem("Dashboard", Icons.dashboard, "dashboard"),
                    menuItem("Productos", Icons.inventory_2, "productos"),
                    menuItem("Categorías", Icons.category, "categorias"),
                    menuItem("Pedidos", Icons.shopping_cart, "pedidos"),
                    menuItem("Clientes", Icons.people, "clientes"),
                    menuItem("Reclamos", Icons.report_problem, "reclamos"),
                    menuItem("Reportes", Icons.bar_chart, "reportes"),
                    menuItem("Configuración", Icons.settings, "config"),
                  ],
                ),
              ),

              ////////////////////////////////////////////////////
              /// 🚪 CERRAR SESIÓN
              ////////////////////////////////////////////////////
             /* Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ),*/
            ],
          ),
        ),
      ),

      ////////////////////////////////////////////////////////
      /// 📌 CONTENIDO DINÁMICO SEGÚN MENÚ
      ////////////////////////////////////////////////////////
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        child: getSelectedScreen(),
      ),
    );
  }

  //////////////////////////////////////////////////////////
  /// 🔹 WIDGET PARA CREAR OPCIONES DEL MENÚ
  //////////////////////////////////////////////////////////

  Widget menuItem(String title, IconData icon, String key) {
    final bool activo = selectedMenu == key;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selected: activo,
        selectedTileColor: colorPrincipal.withOpacity(0.12),
        leading: Icon(
          icon,
          color: activo ? colorPrincipal : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: activo ? colorPrincipal : Colors.black87,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: activo
            ? Icon(Icons.arrow_right, color: colorPrincipal)
            : null,
        onTap: () {
          setState(() {
            selectedMenu = key;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  //////////////////////////////////////////////////////////
  /// 🔹 CAMBIO DE PANTALLA SEGÚN MENÚ
  //////////////////////////////////////////////////////////
  Widget getSelectedScreen() {
    switch (selectedMenu) {
      case "dashboard":
        return DashboardScreen();
      case "productos":
        return const AdminProductosScreen();
      case "pedidos":
        return const AdminPedidosScreen();
      case "clientes":
        return const AdminClientesScreen();
      case "reclamos":
        return const AdminReclamosScreen();
      case "reportes":
        return const AdminReportesScreen();
      case "config":
        return const AdminConfiguracionScreen();
      case "categorias":
        return AdminCategoriasScreen();
      default:
        return DashboardScreen();
    }
  }
}




////////////////////////////////////////////////////////
/// 🚀 PANTALLA PRINCIPAL CLIENTE (CON NAVEGACIÓN)
////////////////////////////////////////////////////////
class ClientePanel extends StatefulWidget {
  @override
  _ClientePanelState createState() => _ClientePanelState();
}

class _ClientePanelState extends State<ClientePanel> {

  ////////////////////////////////////////////////////////
  /// 🔹 CONTROL DE PESTAÑAS
  ////////////////////////////////////////////////////////
  int index = 0;

  final screens = [
    InicioScreen(),
    CategoriasScreen(),
    CarritoScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      ////////////////////////////////////////////////////////
      /// 📌 CONTENIDO SEGÚN TAB
      ////////////////////////////////////////////////////////
      body: screens[index],

      ////////////////////////////////////////////////////////
      /// 📌 BARRA INFERIOR
      ////////////////////////////////////////////////////////
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: index,
  onTap: (i) {
    setState(() {
      index = i;
    });
  },

  backgroundColor: Colors.white, // 👈 fondo
  selectedItemColor: Colors.blue, // 👈 color activo
  unselectedItemColor: Colors.grey, // 👈 color inactivo
  showUnselectedLabels: true, // 👈 mostrar texto

  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
    BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categorías"),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Carrito"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
  ],
),
    );
  }
}

////////////////////////////////////////////////////////
/// 🏠 PANTALLA INICIO (TIPO E-COMMERCE)
////////////////////////////////////////////////////////
class InicioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ////////////////////////////////////////////////////
          /// 🔝 HEADER SUPERIOR
          ////////////////////////////////////////////////////
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.store, size: 40),
                  SizedBox(width: 10),
                  Text("Mi Empresa App",
                      style: TextStyle(fontSize: 18)),
                ],
              ),
              Row(
                children: [
                  Text("Hola, Juan!"),
                  SizedBox(width: 5),
                  Icon(Icons.person),
                ],
              )
            ],
          ),

          SizedBox(height: 20),

          ////////////////////////////////////////////////////
          /// 💳 TARJETAS (PUNTOS / PEDIDO / CUPÓN)
          ////////////////////////////////////////////////////
          Row(
            children: [

              tarjeta("Tus Puntos", "1,250", Colors.blue),
              SizedBox(width: 10),
              tarjeta("Último Pedido", "#1024", Colors.grey),
              SizedBox(width: 10),
              tarjeta("Cupón", "-15%", Colors.orange),

            ],
          ),

          SizedBox(height: 20),

          ////////////////////////////////////////////////////
          /// 🎁 BANNER PROMOCIÓN
          ////////////////////////////////////////////////////
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "-15% en tu próximo pedido",
              style: TextStyle(color: Colors.white),
            ),
          ),

          SizedBox(height: 20),

          ////////////////////////////////////////////////////
          /// 🏷️ CATEGORÍAS RÁPIDAS
          ////////////////////////////////////////////////////
          Text("Descubre nuestros productos",
              style: TextStyle(fontSize: 18)),

          SizedBox(height: 10),

          Row(
            children: [
              chip("Ofertas"),
              chip("Ropa"),
              chip("Electrónica"),
            ],
          ),

          SizedBox(height: 20),

          ////////////////////////////////////////////////////
          /// 🛍️ LISTA DE PRODUCTOS
          ////////////////////////////////////////////////////
          Row(
            children: [
              Expanded(child: productoCard("Audífonos", "\$45", Icons.headphones)),
              SizedBox(width: 10),
              Expanded(child: productoCard("Camisa", "\$22", Icons.checkroom)),
              SizedBox(width: 10),
              Expanded(child: productoCard("Zapatillas", "\$65", Icons.directions_run)),
            ],
          ),

        ],
      ),
    );
  }

////////////////////////////////////////////////////////
/// 🔹 TARJETAS SUPERIORES
////////////////////////////////////////////////////////
  Widget tarjeta(String titulo, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(titulo),
            SizedBox(height: 5),
            Text(valor,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

////////////////////////////////////////////////////////
/// 🔹 CHIP DE CATEGORÍA
////////////////////////////////////////////////////////
  Widget chip(String texto) {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: Chip(label: Text(texto)),
    );
  }

////////////////////////////////////////////////////////
/// 🔹 CARD DE PRODUCTO
////////////////////////////////////////////////////////
  Widget productoCard(String nombre, String precio, IconData icono) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icono, size: 40),
            SizedBox(height: 10),
            Text(nombre),
            Text(precio),
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// 🏷️ CATEGORÍAS
////////////////////////////////////////////////////////
class CategoriasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Categorías"));
  }
}

////////////////////////////////////////////////////////
/// 🛒 CARRITO
////////////////////////////////////////////////////////
class CarritoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Carrito"));
  }
}

////////////////////////////////////////////////////////
/// 👤 PERFIL
////////////////////////////////////////////////////////
class PerfilScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Perfil"));
  }
}

////////////////////////////////////////////////////////
/// PANTALLA CATEGORIA ADMIN
////////////////////////////////////////////////////////


class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  final categoriasRef = FirebaseFirestore.instance.collection('categorias');

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
  }

  Future<void> guardarCategoria({String? categoriaId}) async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingrese el nombre de la categoría"),
        ),
      );
      return;
    }

    final data = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };

    if (categoriaId == null) {
      await categoriasRef.add({
        ...data,
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    } else {
      await categoriasRef.doc(categoriaId).update(data);
    }

    limpiarCampos();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            categoriaId == null
                ? "Categoría registrada correctamente"
                : "Categoría actualizada correctamente",
          ),
        ),
      );
    }
  }

  Future<void> cambiarEstadoCategoria({
    required String categoriaId,
    required bool estadoActual,
  }) async {
    await categoriasRef.doc(categoriaId).update({
      'activo': !estadoActual,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estadoActual
                ? "Categoría inhabilitada correctamente"
                : "Categoría habilitada correctamente",
          ),
        ),
      );
    }
  }

  void mostrarFormularioCategoria({
    String? categoriaId,
    Map<String, dynamic>? categoria,
  }) {
    if (categoria != null) {
      nombreController.text = categoria['nombre'] ?? '';
      descripcionController.text = categoria['descripcion'] ?? '';
    } else {
      limpiarCampos();
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            categoriaId == null ? "Nueva Categoría" : "Editar Categoría",
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre de categoría *",
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                limpiarCampos();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: () => guardarCategoria(categoriaId: categoriaId),
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => mostrarFormularioCategoria(),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestión de Categorías",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Administra categorías activas e inactivas sin eliminar datos del sistema.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: categoriasRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar categorías"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay categorías registradas"),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final bool activo = data['activo'] ?? true;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),

                          leading: CircleAvatar(
                            backgroundColor: activo
                                ? primaryColor.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.20),
                            child: Icon(
                              activo
                                  ? Icons.category
                                  : Icons.category_outlined,
                              color: activo ? primaryColor : Colors.grey,
                            ),
                          ),

                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['nombre'] ?? 'Sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: activo
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: activo
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.red.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  activo ? "Activa" : "Inactiva",
                                  style: TextStyle(
                                    color:
                                        activo ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data['descripcion'] == null ||
                                      data['descripcion'].toString().isEmpty
                                  ? "Sin descripción"
                                  : data['descripcion'],
                              style: TextStyle(
                                color: activo
                                    ? Colors.grey[700]
                                    : Colors.grey,
                              ),
                            ),
                          ),

                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "editar") {
                                mostrarFormularioCategoria(
                                  categoriaId: doc.id,
                                  categoria: data,
                                );
                              }

                              if (value == "estado") {
                                cambiarEstadoCategoria(
                                  categoriaId: doc.id,
                                  estadoActual: activo,
                                );
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
                                      activo
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: activo
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      activo
                                          ? "Inhabilitar"
                                          : "Habilitar",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

//////////
///PANTALLA PRODUCTOS ADMIN
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

  String? categoriaId;
  String? categoriaNombre;
  bool categoriaActivaActual = true;

  String textoBusqueda = "";
  String? categoriaFiltroId;

  File? imagenSeleccionada;
  String imagenActualUrl = "";

  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  void limpiarCampos() {
    nombreController.clear();
    descripcionController.clear();
    precioController.clear();
    stockController.clear();
    categoriaId = null;
    categoriaNombre = null;
    categoriaActivaActual = true;
    imagenSeleccionada = null;
    imagenActualUrl = "";
  }

  Future<String> subirImagen() async {
    if (imagenSeleccionada == null) return imagenActualUrl;

    final nombreArchivo =
        "productos/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance.ref().child(nombreArchivo);
    await ref.putFile(imagenSeleccionada!);

    return await ref.getDownloadURL();
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

    final imagenUrl = await subirImagen();

    final data = {
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'precio': double.tryParse(precioController.text.trim()) ?? 0,
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'imagenUrl': imagenUrl,
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
      builder: (_) {
        return AlertDialog(
          title: const Text("Eliminar producto"),
          content: const Text(
            "⚠ Esta acción es permanente.\n\n"
            "Solo elimina el producto si fue creado por error y no tiene pedidos, ventas ni historial.\n\n"
            "¿Deseas eliminarlo definitivamente?",
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
                "Eliminar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await productosRef.doc(id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Producto eliminado definitivamente"),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> obtenerCategoriaPorId(String id) async {
    final doc = await categoriasRef.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
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
      imagenActualUrl = producto['imagenUrl'] ?? '';
      imagenSeleccionada = null;

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
            Future<void> seleccionarImagenModal() async {
              final XFile? imagen = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 75,
              );

              if (imagen != null) {
                setModalState(() {
                  imagenSeleccionada = File(imagen.path);
                });
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: seleccionarImagenModal,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: imagenSeleccionada != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          imagenSeleccionada!,
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : imagenActualUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imagenActualUrl,
                                              width: double.infinity,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 42,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text("Seleccionar imagen"),
                                            ],
                                          ),
                              ),
                            ),

                            const SizedBox(height: 14),

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
                                labelText: "Stock *",
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

                                      setModalState(() {
                                        categoriaId = doc.first.id;
                                        categoriaNombre = data['nombre'];
                                        categoriaActivaActual = true;
                                      });
                                    }
                                  },
                                );
                              },
                            ),

                            if (categoriaId != null &&
                                categoriaActivaActual == false)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
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

  Widget imagenProducto(String imagenUrl) {
    if (imagenUrl.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: primaryColor.withOpacity(0.12),
        child: Icon(Icons.inventory_2, color: primaryColor),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imagenUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.12),
            child: Icon(Icons.broken_image, color: primaryColor),
          );
        },
      ),
    );
  }

  Widget etiquetaEstadoProducto(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activo
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? "Producto activo" : "Producto inactivo",
        style: TextStyle(
          color: activo ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget etiquetaCategoria(bool activa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activa
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activa ? "Categoría activa" : "Categoría inactiva",
        style: TextStyle(
          color: activa ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget alertaBajoStock(int stock) {
    if (stock >= 4) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        "⚠ Bajo stock",
        style: TextStyle(
          color: Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
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
              borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(14),
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

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    stockController.dispose();
    buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Administra productos, precios, stock, imágenes, estados y categorías.",
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

                  return ListView(
                    children: productosFiltrados.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final stock = data['stock'] ?? 0;
                      final imagenUrl = data['imagenUrl'] ?? '';
                      final productoCategoriaId = data['categoriaId'];
                      final productoCategoriaNombre =
                          data['categoriaNombre'] ?? 'Sin categoría';
                      final bool productoActivo = data['activo'] ?? true;

                      return FutureBuilder<DocumentSnapshot>(
                        future: productoCategoriaId != null
                            ? categoriasRef.doc(productoCategoriaId).get()
                            : null,
                        builder: (context, categoriaSnapshot) {
                          bool categoriaActiva = true;

                          if (categoriaSnapshot.hasData &&
                              categoriaSnapshot.data!.exists) {
                            final categoriaData = categoriaSnapshot.data!
                                .data() as Map<String, dynamic>;

                            categoriaActiva =
                                categoriaData['activo'] ?? true;
                          }

                          return Opacity(
                            opacity: productoActivo ? 1 : 0.55,
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),

                                leading: imagenProducto(imagenUrl),

                                title: Text(
                                  data['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),

                                    Text(
                                      data['descripcion'] ?? 'Sin descripción',
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      "Categoría: $productoCategoriaNombre",
                                    ),

                                    const SizedBox(height: 4),

                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        etiquetaEstadoProducto(productoActivo),
                                        etiquetaCategoria(categoriaActiva),
                                      ],
                                    ),

                                    const SizedBox(height: 5),

                                    Text("Precio: S/ ${data['precio'] ?? 0}"),

                                    Text(
                                      "Stock: $stock",
                                      style: TextStyle(
                                        color: stock < 4
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    alertaBajoStock(stock),
                                  ],
                                ),

                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == "editar") {
                                      mostrarFormularioProducto(
                                        productoId: doc.id,
                                        producto: data,
                                      );
                                    } else if (value == "estado") {
                                      cambiarEstadoProducto(
                                        doc.id,
                                        productoActivo,
                                      );
                                    } else if (value == "eliminar") {
                                      eliminarProductoSeguro(doc.id);
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
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

/////////////////////////////////
///PANTALLA PEDIDOS ADMIN
////////////////////////////////////

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');

  final buscadorController = TextEditingController();

  String textoBusqueda = "";
  String estadoFiltro = "todos";

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final List<String> estados = [
    "pendiente",
    "confirmado",
    "enviado",
    "entregado",
    "cancelado",
  ];

  Future<void> cambiarEstadoPedido(String pedidoId, String nuevoEstado) async {
    await pedidosRef.doc(pedidoId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pedido actualizado a $nuevoEstado"),
        ),
      );
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "confirmado":
        return Colors.blue;
      case "enviado":
        return Colors.purple;
      case "entregado":
        return Colors.green;
      case "cancelado":
        return Colors.red;
      default:
        return Colors.grey;
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

  Widget etiquetaEstado(String estado) {
    final color = colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filtrosPedidos() {
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
            hintText: "Buscar por cliente, correo o código de pedido...",
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
              child: Text("Todos los pedidos"),
            ),
            DropdownMenuItem(
              value: "pendiente",
              child: Text("Pendientes"),
            ),
            DropdownMenuItem(
              value: "confirmado",
              child: Text("Confirmados"),
            ),
            DropdownMenuItem(
              value: "enviado",
              child: Text("Enviados"),
            ),
            DropdownMenuItem(
              value: "entregado",
              child: Text("Entregados"),
            ),
            DropdownMenuItem(
              value: "cancelado",
              child: Text("Cancelados"),
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

  void mostrarDetallePedido({
    required String pedidoId,
    required Map<String, dynamic> pedido,
  }) {
    final productos = List<Map<String, dynamic>>.from(
      pedido['productos'] ?? [],
    );

    final estadoActual = pedido['estado'] ?? 'pendiente';

    showDialog(
      context: context,
      builder: (_) {
        String estadoTemporal = estadoActual;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Detalle del pedido",
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
                            Text(
                              "Código: $pedidoId",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Cliente: ${pedido['clienteNombre'] ?? 'Sin nombre'}",
                            ),
                            Text(
                              "Correo: ${pedido['clienteCorreo'] ?? 'Sin correo'}",
                            ),
                            Text(
                              "Fecha: ${formatearFecha(pedido['fechaPedido'])}",
                            ),

                            const SizedBox(height: 12),

                            etiquetaEstado(estadoTemporal),

                            const SizedBox(height: 18),

                            DropdownButtonFormField<String>(
                              value: estadoTemporal,
                              decoration: const InputDecoration(
                                labelText: "Cambiar estado del pedido",
                                border: OutlineInputBorder(),
                              ),
                              items: estados.map((estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(estado.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  estadoTemporal = value ?? estadoTemporal;
                                });
                              },
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              "Productos del pedido",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (productos.isEmpty)
                              const Text("Este pedido no tiene productos."),

                            ...productos.map((producto) {
                              final imagenUrl = producto['imagenUrl'] ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: imagenUrl.toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            imagenUrl,
                                            width: 55,
                                            height: 55,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : CircleAvatar(
                                          backgroundColor:
                                              primaryColor.withOpacity(0.12),
                                          child: Icon(
                                            Icons.shopping_bag,
                                            color: primaryColor,
                                          ),
                                        ),
                                  title: Text(
                                    producto['nombre'] ?? 'Producto',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Cantidad: ${producto['cantidad'] ?? 0}",
                                      ),
                                      Text(
                                        "Precio: S/ ${producto['precio'] ?? 0}",
                                      ),
                                      Text(
                                        "Subtotal: S/ ${producto['subtotal'] ?? 0}",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 18),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                "Total del pedido: S/ ${pedido['total'] ?? 0}",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () async {
                              await cambiarEstadoPedido(
                                pedidoId,
                                estadoTemporal,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Guardar estado",
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

  Widget pedidoCard({
    required String pedidoId,
    required Map<String, dynamic> pedido,
  }) {
    final estado = pedido['estado'] ?? 'pendiente';
    final total = pedido['total'] ?? 0;
    final productos = pedido['productos'] ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: colorEstado(estado).withOpacity(0.12),
          child: Icon(
            Icons.receipt_long,
            color: colorEstado(estado),
          ),
        ),
        title: Text(
          pedido['clienteNombre'] ?? 'Cliente sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Código: $pedidoId"),
            Text("Correo: ${pedido['clienteCorreo'] ?? 'Sin correo'}"),
            Text("Fecha: ${formatearFecha(pedido['fechaPedido'])}"),
            Text("Productos: ${productos.length}"),
            Text(
              "Total: S/ $total",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            etiquetaEstado(estado),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "detalle") {
              mostrarDetallePedido(
                pedidoId: pedidoId,
                pedido: pedido,
              );
            }

            if (value.startsWith("estado_")) {
              final nuevoEstado = value.replaceFirst("estado_", "");
              cambiarEstadoPedido(pedidoId, nuevoEstado);
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
            const PopupMenuDivider(),
            ...estados.map(
              (estado) => PopupMenuItem(
                value: "estado_$estado",
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: colorEstado(estado),
                    ),
                    const SizedBox(width: 8),
                    Text("Marcar $estado"),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          mostrarDetallePedido(
            pedidoId: pedidoId,
            pedido: pedido,
          );
        },
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
              "Gestión de Pedidos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Visualiza, filtra y actualiza el estado de los pedidos.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 18),

            filtrosPedidos(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: pedidosRef
                    .orderBy('fechaPedido', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar pedidos"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay pedidos registrados"),
                    );
                  }

                  final pedidosFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final clienteNombre =
                        (data['clienteNombre'] ?? '').toString().toLowerCase();

                    final clienteCorreo =
                        (data['clienteCorreo'] ?? '').toString().toLowerCase();

                    final codigoPedido = doc.id.toLowerCase();

                    final estado = data['estado'] ?? 'pendiente';

                    final coincideBusqueda =
                        clienteNombre.contains(textoBusqueda) ||
                            clienteCorreo.contains(textoBusqueda) ||
                            codigoPedido.contains(textoBusqueda);

                    final coincideEstado =
                        estadoFiltro == "todos" ? true : estado == estadoFiltro;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  if (pedidosFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron pedidos"),
                    );
                  }

                  return ListView(
                    children: pedidosFiltrados.map((doc) {
                      final pedido = doc.data() as Map<String, dynamic>;

                      return pedidoCard(
                        pedidoId: doc.id,
                        pedido: pedido,
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

//////////////////////////////////
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

//////////////////////////////
///PANTALLA RECLAMOS ADMIN
/////////////////////////////////

class AdminReclamosScreen extends StatefulWidget {
  const AdminReclamosScreen({super.key});

  @override
  State<AdminReclamosScreen> createState() => _AdminReclamosScreenState();
}

class _AdminReclamosScreenState extends State<AdminReclamosScreen> {
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final buscadorController = TextEditingController();
  final respuestaController = TextEditingController();

  String textoBusqueda = "";
  String estadoFiltro = "todos";

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  final List<String> estados = [
    "pendiente",
    "en_revision",
    "respondido",
    "cerrado",
  ];

  Future<void> cambiarEstadoReclamo(
    String reclamoId,
    String nuevoEstado,
  ) async {
    await reclamosRef.doc(reclamoId).update({
      'estado': nuevoEstado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reclamo actualizado a $nuevoEstado")),
      );
    }
  }

  Future<void> responderReclamo(String reclamoId) async {
    if (respuestaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese una respuesta para el cliente")),
      );
      return;
    }

    await reclamosRef.doc(reclamoId).update({
      'respuestaAdmin': respuestaController.text.trim(),
      'estado': 'respondido',
      'fechaRespuesta': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    respuestaController.clear();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Respuesta enviada correctamente")),
      );
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "en_revision":
        return Colors.blue;
      case "respondido":
        return Colors.green;
      case "cerrado":
        return Colors.grey;
      default:
        return Colors.black45;
    }
  }

  Color colorTipo(String tipo) {
    switch (tipo) {
      case "reclamo":
        return Colors.red;
      case "sugerencia":
        return Colors.purple;
      default:
        return primaryColor;
    }
  }

  String textoEstado(String estado) {
    switch (estado) {
      case "en_revision":
        return "EN REVISIÓN";
      default:
        return estado.toUpperCase();
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

  Widget etiquetaEstado(String estado) {
    final color = colorEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        textoEstado(estado),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget etiquetaTipo(String tipo) {
    final color = colorTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget filtrosReclamos() {
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
            hintText: "Buscar por cliente, correo, asunto o descripción...",
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
              child: Text("Todos los reclamos"),
            ),
            DropdownMenuItem(
              value: "pendiente",
              child: Text("Pendientes"),
            ),
            DropdownMenuItem(
              value: "en_revision",
              child: Text("En revisión"),
            ),
            DropdownMenuItem(
              value: "respondido",
              child: Text("Respondidos"),
            ),
            DropdownMenuItem(
              value: "cerrado",
              child: Text("Cerrados"),
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

  void mostrarDetalleReclamo({
    required String reclamoId,
    required Map<String, dynamic> reclamo,
  }) {
    final estadoActual = reclamo['estado'] ?? 'pendiente';
    final respuestaActual = reclamo['respuestaAdmin'] ?? '';

    respuestaController.text = respuestaActual;

    showDialog(
      context: context,
      builder: (_) {
        String estadoTemporal = estadoActual;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Detalle del reclamo",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              respuestaController.clear();
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                etiquetaTipo(reclamo['tipo'] ?? 'reclamo'),
                                etiquetaEstado(estadoTemporal),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Text(
                              reclamo['asunto'] ?? 'Sin asunto',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Cliente: ${reclamo['clienteNombre'] ?? 'Sin nombre'}",
                            ),
                            Text(
                              "Correo: ${reclamo['clienteCorreo'] ?? 'Sin correo'}",
                            ),
                            Text(
                              "Fecha: ${formatearFecha(reclamo['fechaRegistro'])}",
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "Descripción",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                reclamo['descripcion'] ?? 'Sin descripción',
                              ),
                            ),

                            const SizedBox(height: 18),

                            DropdownButtonFormField<String>(
                              value: estadoTemporal,
                              decoration: const InputDecoration(
                                labelText: "Cambiar estado",
                                border: OutlineInputBorder(),
                              ),
                              items: estados.map((estado) {
                                return DropdownMenuItem<String>(
                                  value: estado,
                                  child: Text(textoEstado(estado)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  estadoTemporal = value ?? estadoTemporal;
                                });
                              },
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "Respuesta del administrador",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              controller: respuestaController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText:
                                    "Escribe aquí la respuesta para el cliente...",
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (reclamo['fechaRespuesta'] != null)
                              Text(
                                "Fecha de respuesta: ${formatearFecha(reclamo['fechaRespuesta'])}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
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
                              respuestaController.clear();
                              Navigator.pop(context);
                            },
                            child: const Text("Cerrar"),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () async {
                              await cambiarEstadoReclamo(
                                reclamoId,
                                estadoTemporal,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              "Guardar estado",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                            ),
                            onPressed: () => responderReclamo(reclamoId),
                            child: const Text(
                              "Responder",
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

  Widget reclamoCard({
    required String reclamoId,
    required Map<String, dynamic> reclamo,
  }) {
    final estado = reclamo['estado'] ?? 'pendiente';
    final tipo = reclamo['tipo'] ?? 'reclamo';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: colorTipo(tipo).withOpacity(0.12),
          child: Icon(
            tipo == "sugerencia" ? Icons.lightbulb : Icons.report_problem,
            color: colorTipo(tipo),
          ),
        ),
        title: Text(
          reclamo['asunto'] ?? 'Sin asunto',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Cliente: ${reclamo['clienteNombre'] ?? 'Sin nombre'}"),
            Text("Correo: ${reclamo['clienteCorreo'] ?? 'Sin correo'}"),
            Text("Fecha: ${formatearFecha(reclamo['fechaRegistro'])}"),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                etiquetaTipo(tipo),
                etiquetaEstado(estado),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == "detalle") {
              mostrarDetalleReclamo(
                reclamoId: reclamoId,
                reclamo: reclamo,
              );
            }

            if (value.startsWith("estado_")) {
              final nuevoEstado = value.replaceFirst("estado_", "");
              cambiarEstadoReclamo(reclamoId, nuevoEstado);
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
            const PopupMenuDivider(),
            ...estados.map(
              (estado) => PopupMenuItem(
                value: "estado_$estado",
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: colorEstado(estado),
                    ),
                    const SizedBox(width: 8),
                    Text("Marcar ${textoEstado(estado)}"),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          mostrarDetalleReclamo(
            reclamoId: reclamoId,
            reclamo: reclamo,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    buscadorController.dispose();
    respuestaController.dispose();
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
              "Gestión de Reclamos",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Visualiza, responde y actualiza el estado de reclamos y sugerencias.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 18),

            filtrosReclamos(),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: reclamosRef
                    .orderBy('fechaRegistro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error al cargar reclamos"),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No hay reclamos registrados"),
                    );
                  }

                  final reclamosFiltrados = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final clienteNombre =
                        (data['clienteNombre'] ?? '').toString().toLowerCase();

                    final clienteCorreo =
                        (data['clienteCorreo'] ?? '').toString().toLowerCase();

                    final asunto =
                        (data['asunto'] ?? '').toString().toLowerCase();

                    final descripcion =
                        (data['descripcion'] ?? '').toString().toLowerCase();

                    final estado = data['estado'] ?? 'pendiente';

                    final coincideBusqueda =
                        clienteNombre.contains(textoBusqueda) ||
                            clienteCorreo.contains(textoBusqueda) ||
                            asunto.contains(textoBusqueda) ||
                            descripcion.contains(textoBusqueda);

                    final coincideEstado =
                        estadoFiltro == "todos" ? true : estado == estadoFiltro;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  if (reclamosFiltrados.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron reclamos"),
                    );
                  }

                  return ListView(
                    children: reclamosFiltrados.map((doc) {
                      final reclamo = doc.data() as Map<String, dynamic>;

                      return reclamoCard(
                        reclamoId: doc.id,
                        reclamo: reclamo,
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

/////////////////////////////////////
///PANTALLA REPORTES ADMIN
///////////////////////////


class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  final productosRef = FirebaseFirestore.instance.collection('productos');
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  String filtroTiempo = "mes";

  bool estaEnFiltro(DateTime fecha) {
    final ahora = DateTime.now();

    if (filtroTiempo == "hoy") {
      return fecha.year == ahora.year &&
          fecha.month == ahora.month &&
          fecha.day == ahora.day;
    }

    if (filtroTiempo == "semana") {
      final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      return fecha.isAfter(inicioSemana.subtract(const Duration(days: 1))) &&
          fecha.isBefore(ahora.add(const Duration(days: 1)));
    }

    return fecha.year == ahora.year && fecha.month == ahora.month;
  }

  String nombreMesActual() {
    final meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];

    final ahora = DateTime.now();
    return "${meses[ahora.month - 1]} ${ahora.year}";
  }

  Widget filtroBoton(String texto, String valor) {
    final seleccionado = filtroTiempo == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          filtroTiempo = valor;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: seleccionado ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget resumenCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icono, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget seccionCard({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget graficoVentas(Map<int, double> ventasPorDia) {
    final spots = ventasPorDia.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (spots.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("No hay ventas para mostrar")),
      );
    }

    final maxY = ventasPorDia.values.isEmpty
        ? 100.0
        : ventasPorDia.values.reduce((a, b) => a > b ? a : b) + 50;

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 31,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: primaryColor,
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withValues(alpha: 0.15),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget graficoTopProductos(Map<String, int> topProductos) {
    if (topProductos.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("No hay productos vendidos")),
      );
    }

    final entries = topProductos.entries.take(5).toList();

    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= entries.length) {
                    return const SizedBox();
                  }

                  final nombre = entries[index].key;

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      nombre.length > 8 ? "${nombre.substring(0, 8)}..." : nombre,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: primaryColor,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget pedidoEstadoItem(String titulo, int cantidad, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            cantidad.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case "pendiente":
        return Colors.orange;
      case "confirmado":
        return Colors.blue;
      case "enviado":
        return Colors.purple;
      case "entregado":
        return Colors.green;
      case "cancelado":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: productosRef.snapshots(),
        builder: (context, productosSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: pedidosRef.snapshots(),
            builder: (context, pedidosSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: usuariosRef.where('rol', isEqualTo: 'cliente').snapshots(),
                builder: (context, clientesSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: reclamosRef.snapshots(),
                    builder: (context, reclamosSnapshot) {
                      if (!productosSnapshot.hasData ||
                          !pedidosSnapshot.hasData ||
                          !clientesSnapshot.hasData ||
                          !reclamosSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final productos = productosSnapshot.data!.docs;
                      final pedidos = pedidosSnapshot.data!.docs;
                      final clientes = clientesSnapshot.data!.docs;
                      final reclamos = reclamosSnapshot.data!.docs;

                      final pedidosFiltrados = pedidos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        if (data['fechaPedido'] == null) return false;

                        final fecha =
                            (data['fechaPedido'] as Timestamp).toDate();

                        return estaEnFiltro(fecha);
                      }).toList();

                      double ventasTotales = 0;
                      int pedidosTotales = pedidosFiltrados.length;

                      int pendientes = 0;
                      int confirmados = 0;
                      int enviados = 0;
                      int entregados = 0;
                      int cancelados = 0;

                      Map<int, double> ventasPorDia = {};
                      Map<String, int> productosVendidos = {};

                      for (final doc in pedidosFiltrados) {
                        final data = doc.data() as Map<String, dynamic>;
                        final estado = data['estado'] ?? 'pendiente';

                        if (estado == "pendiente") pendientes++;
                        if (estado == "confirmado") confirmados++;
                        if (estado == "enviado") enviados++;
                        if (estado == "entregado") entregados++;
                        if (estado == "cancelado") cancelados++;

                        if (estado == "entregado") {
                          final total = (data['total'] ?? 0).toDouble();
                          ventasTotales += total;

                          final fecha =
                              (data['fechaPedido'] as Timestamp).toDate();

                          ventasPorDia[fecha.day] =
                              (ventasPorDia[fecha.day] ?? 0) + total;

                          final productosPedido =
                              List<Map<String, dynamic>>.from(
                            data['productos'] ?? [],
                          );

                          for (final producto in productosPedido) {
                            final nombre = producto['nombre'] ?? 'Producto';
                            final cantidad = producto['cantidad'] ?? 0;

                            productosVendidos[nombre] =
                                (productosVendidos[nombre] ?? 0) +
                                    (cantidad as num).toInt();
                          }
                        }
                      }

                      final productosActivos = productos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['activo'] ?? true;
                      }).length;

                      final bajoStock = productos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final stock = data['stock'] ?? 0;
                        final activo = data['activo'] ?? true;
                        return activo == true && stock < 4;
                      }).length;

                      final reclamosPendientes = reclamos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final estado = data['estado'] ?? 'pendiente';
                        return estado == 'pendiente' ||
                            estado == 'en_revision';
                      }).length;

                      final topProductosOrdenado = Map.fromEntries(
                        productosVendidos.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)),
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reportes",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Resumen ejecutivo de ventas y actividad del sistema.",
                              style: TextStyle(color: Colors.grey[600]),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      nombreMesActual(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                filtroBoton("HOY", "hoy"),
                                const SizedBox(width: 6),
                                filtroBoton("SEMANA", "semana"),
                                const SizedBox(width: 6),
                                filtroBoton("MES", "mes"),
                              ],
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Resumen General",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                              children: [
                                resumenCard(
                                  titulo: "Ventas Totales",
                                  valor:
                                      "S/ ${ventasTotales.toStringAsFixed(2)}",
                                  subtitulo: "Pedidos entregados",
                                  icono: Icons.payments,
                                  color: Colors.green,
                                ),
                                resumenCard(
                                  titulo: "Pedidos",
                                  valor: pedidosTotales.toString(),
                                  subtitulo: "Según filtro",
                                  icono: Icons.receipt_long,
                                  color: Colors.orange,
                                ),
                                resumenCard(
                                  titulo: "Clientes",
                                  valor: clientes.length.toString(),
                                  subtitulo: "Registrados",
                                  icono: Icons.people,
                                  color: Colors.blue,
                                ),
                                resumenCard(
                                  titulo: "Productos Activos",
                                  valor: productosActivos.toString(),
                                  subtitulo: "Disponibles",
                                  icono: Icons.inventory_2,
                                  color: primaryColor,
                                ),
                                resumenCard(
                                  titulo: "Bajo Stock",
                                  valor: bajoStock.toString(),
                                  subtitulo: "Stock menor a 4",
                                  icono: Icons.warning,
                                  color: Colors.red,
                                ),
                                resumenCard(
                                  titulo: "Reclamos",
                                  valor: reclamosPendientes.toString(),
                                  subtitulo: "Pendientes/revisión",
                                  icono: Icons.report_problem,
                                  color: Colors.deepOrange,
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            seccionCard(
                              titulo: "Evolución de Ventas",
                              child: graficoVentas(ventasPorDia),
                            ),

                            seccionCard(
                              titulo: "Top Productos",
                              child: graficoTopProductos(topProductosOrdenado),
                            ),

                            seccionCard(
                              titulo: "Pedidos por Estado",
                              child: Column(
                                children: [
                                  pedidoEstadoItem(
                                    "Pendientes",
                                    pendientes,
                                    colorEstado("pendiente"),
                                  ),
                                  pedidoEstadoItem(
                                    "Confirmados",
                                    confirmados,
                                    colorEstado("confirmado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Enviados",
                                    enviados,
                                    colorEstado("enviado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Entregados",
                                    entregados,
                                    colorEstado("entregado"),
                                  ),
                                  pedidoEstadoItem(
                                    "Cancelados",
                                    cancelados,
                                    colorEstado("cancelado"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////
/// PANTALLA CONFIGURACION ADMIN
class AdminConfiguracionScreen extends StatefulWidget {
  const AdminConfiguracionScreen({super.key});

  @override
  State<AdminConfiguracionScreen> createState() =>
      _AdminConfiguracionScreenState();
}

class _AdminConfiguracionScreenState extends State<AdminConfiguracionScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final configuracionRef =FirebaseFirestore.instance.collection('configuracion');

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final cargoController = TextEditingController();

  final nombreNegocioController = TextEditingController();
  final subtituloController = TextEditingController();

  File? logoSeleccionado;
  String logoActualUrl = "";

  File? fotoAdminSeleccionada;
  String fotoAdminUrl = "";


  final ImagePicker picker = ImagePicker();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  User? get usuarioActual => auth.currentUser;

  Future<void> seleccionarLogoNegocio() async {
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (imagen != null) {
      setState(() {
        logoSeleccionado = File(imagen.path);
      });
    }
  }

  Future<String> subirLogoNegocio() async {
    if (logoSeleccionado == null) return logoActualUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child("configuracion/logo_negocio.jpg");

    await ref.putFile(logoSeleccionado!);

    return await ref.getDownloadURL();
  }

  Future<void> guardarConfiguracionNegocio() async {
    final logoUrl = await subirLogoNegocio();
    
    await configuracionRef.doc('negocio').set({
      'nombreNegocio': nombreNegocioController.text.trim().isEmpty
          ? 'Inversiones Isabella'
          : nombreNegocioController.text.trim(),
      'subtitulo': subtituloController.text.trim().isEmpty
          ? 'Panel Administrativo'
          : subtituloController.text.trim(),
      'logoUrl': logoUrl,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configuración del negocio actualizada"),
        ),
      );
    }
  }

Future<void> seleccionarFotoAdmin() async {
  final XFile? imagen = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 75,
  );

  if (imagen != null) {
    setState(() {
      fotoAdminSeleccionada = File(imagen.path);
    });
  }
}

Future<String> subirFotoAdmin() async {
  if (fotoAdminSeleccionada == null) return fotoAdminUrl;

  final ref = FirebaseStorage.instance
      .ref()
      .child("usuarios/${usuarioActual!.uid}.jpg");

  await ref.putFile(fotoAdminSeleccionada!);

  return await ref.getDownloadURL();
}


Future<void> actualizarDatosAdmin() async {
  if (usuarioActual == null) return;

  final fotoUrl = await subirFotoAdmin();

  await usuariosRef.doc(usuarioActual!.uid).set({
    'nombre': nombreController.text.trim(),
    'telefono': telefonoController.text.trim(),
    'cargo': cargoController.text.trim(),
    'correo': usuarioActual!.email,
    'rol': 'admin',
    'activo': true,
    'fotoUrl': fotoUrl,
    'fechaActualizacion': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Datos actualizados")),
  );
}

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Deseas cerrar sesión como administrador?"),
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
                "Cerrar sesión",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await auth.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  Widget campoTexto({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget infoCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String formatearFecha(dynamic timestamp) {
    if (timestamp == null) return "Sin fecha";

    final DateTime fecha = (timestamp as Timestamp).toDate();

    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year}";
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    cargoController.dispose();
    nombreNegocioController.dispose();
    subtituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usuarioActual == null) {
      return const Center(
        child: Text("No hay administrador autenticado"),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: usuariosRef.doc(usuarioActual!.uid).snapshots(),
        builder: (context, snapshotAdmin) {
          if (!snapshotAdmin.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> dataAdmin = {};

          if (snapshotAdmin.data!.exists) {
  dataAdmin = snapshotAdmin.data!.data() as Map<String, dynamic>;

  nombreController.text = dataAdmin['nombre'] ?? '';
  telefonoController.text = dataAdmin['telefono'] ?? '';
  cargoController.text = dataAdmin['cargo'] ?? 'Administrador';

  fotoAdminUrl = dataAdmin['fotoUrl'] ?? "";
} else {
  nombreController.text = usuarioActual!.displayName ?? '';
  telefonoController.text = '';
  cargoController.text = 'Administrador';

  fotoAdminUrl = "";
}

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configuración",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Administra la información del negocio y del usuario administrador.",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 22),

                const Text(
                  "Datos del negocio",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                StreamBuilder<DocumentSnapshot>(
                  stream: configuracionRef.doc('negocio').snapshots(),
                  builder: (context, snapshotNegocio) {
                    if (snapshotNegocio.hasData &&
                        snapshotNegocio.data!.exists) {
                      final data =
                          snapshotNegocio.data!.data() as Map<String, dynamic>;

                      nombreNegocioController.text =
                          data['nombreNegocio'] ?? 'Inversiones Isabella';

                      subtituloController.text =
                          data['subtitulo'] ?? 'Panel Administrativo';

                      logoActualUrl = data['logoUrl'] ?? '';
                    } else {
                      nombreNegocioController.text = 'Inversiones Isabella';
                      subtituloController.text = 'Panel Administrativo';
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: seleccionarLogoNegocio,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor:
                                  primaryColor.withOpacity(0.12),
                              backgroundImage: logoSeleccionado != null
                                  ? FileImage(logoSeleccionado!)
                                  : logoActualUrl.isNotEmpty
                                      ? NetworkImage(logoActualUrl)
                                          as ImageProvider
                                      : null,
                              child: logoSeleccionado == null &&
                                      logoActualUrl.isEmpty
                                  ? Icon(
                                      Icons.add_a_photo,
                                      color: primaryColor,
                                      size: 38,
                                    )
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Toca la imagen para cambiar el logo",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          campoTexto(
                            label: "Nombre del negocio",
                            icon: Icons.store,
                            controller: nombreNegocioController,
                          ),

                          const SizedBox(height: 12),

                          campoTexto(
                            label: "Subtítulo del panel",
                            icon: Icons.dashboard,
                            controller: subtituloController,
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: guardarConfiguracionNegocio,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text(
                                "Guardar datos del negocio",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  "Datos del administrador",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Center(
  child: GestureDetector(
    onTap: seleccionarFotoAdmin,
    child: CircleAvatar(
      radius: 50,
      backgroundColor: primaryColor.withValues(alpha: 0.12),
      backgroundImage: fotoAdminSeleccionada != null
          ? FileImage(fotoAdminSeleccionada!)
          : fotoAdminUrl.isNotEmpty
              ? NetworkImage(fotoAdminUrl) as ImageProvider
              : null,
      child: fotoAdminSeleccionada == null && fotoAdminUrl.isEmpty
          ? Icon(
              Icons.add_a_photo,
              color: primaryColor,
              size: 35,
            )
          : null,
    ),
  ),

),
                ),

                const SizedBox(height: 22),

                infoCard(
                  titulo: "Correo administrador",
                  valor: usuarioActual!.email ?? 'Sin correo',
                  icono: Icons.email,
                  color: Colors.blue,
                ),

                infoCard(
                  titulo: "Rol del usuario",
                  valor: dataAdmin['rol'] ?? 'admin',
                  icono: Icons.verified_user,
                  color: Colors.green,
                ),

                infoCard(
                  titulo: "Fecha de registro",
                  valor: formatearFecha(dataAdmin['fechaRegistro']),
                  icono: Icons.calendar_month,
                  color: Colors.orange,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Nombre del administrador",
                  icon: Icons.person,
                  controller: nombreController,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Teléfono",
                  icon: Icons.phone,
                  controller: telefonoController,
                ),

                const SizedBox(height: 12),

                campoTexto(
                  label: "Cargo",
                  icon: Icons.badge,
                  controller: cargoController,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: actualizarDatosAdmin,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "Guardar cambios del administrador",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: cerrarSesion,
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////////
/// 📊 DASHBOARD PRINCIPAL
////////////////////////////////////////////////////////

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final productosRef = FirebaseFirestore.instance.collection('productos');
  final pedidosRef = FirebaseFirestore.instance.collection('pedidos');
  final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
  final reclamosRef = FirebaseFirestore.instance.collection('reclamos');

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  Widget dashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: productosRef.snapshots(),
      builder: (context, productosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: pedidosRef.snapshots(),
          builder: (context, pedidosSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: usuariosRef.where('rol', isEqualTo: 'cliente').snapshots(),
              builder: (context, clientesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: reclamosRef.snapshots(),
                  builder: (context, reclamosSnapshot) {
                    if (!productosSnapshot.hasData ||
                        !pedidosSnapshot.hasData ||
                        !clientesSnapshot.hasData ||
                        !reclamosSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final productos = productosSnapshot.data!.docs;
                    final pedidos = pedidosSnapshot.data!.docs;
                    final clientes = clientesSnapshot.data!.docs;
                    final reclamos = reclamosSnapshot.data!.docs;

                    final productosActivos = productos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['activo'] ?? true;
                    }).length;

                    final bajoStock = productos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final stock = data['stock'] ?? 0;
                      final activo = data['activo'] ?? true;
                      return activo == true && stock < 4;
                    }).length;

                    final pedidosPendientes = pedidos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['estado'] == 'pendiente';
                    }).length;

                    final reclamosPendientes = reclamos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final estado = data['estado'] ?? 'pendiente';
                      return estado == 'pendiente' || estado == 'en_revision';
                    }).length;

                    double ventasEntregadas = 0;

                    for (final doc in pedidos) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['estado'] == 'entregado') {
                        ventasEntregadas += (data['total'] ?? 0).toDouble();
                      }
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Panel de Administración",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Resumen general de Inversiones Isabella",
                            style: TextStyle(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 25),

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.25,
                            children: [
                              dashboardCard(
                                title: "Productos activos",
                                value: productosActivos.toString(),
                                icon: Icons.inventory_2,
                                color: Colors.blue,
                              ),
                              dashboardCard(
                                title: "Pedidos pendientes",
                                value: pedidosPendientes.toString(),
                                icon: Icons.shopping_cart,
                                color: Colors.orange,
                              ),
                              dashboardCard(
                                title: "Clientes",
                                value: clientes.length.toString(),
                                icon: Icons.people,
                                color: Colors.green,
                              ),
                              dashboardCard(
                                title: "Bajo stock",
                                value: bajoStock.toString(),
                                icon: Icons.warning,
                                color: Colors.red,
                              ),
                              dashboardCard(
                                title: "Reclamos pendientes",
                                value: reclamosPendientes.toString(),
                                icon: Icons.report_problem,
                                color: Colors.deepOrange,
                              ),
                              dashboardCard(
                                title: "Ventas entregadas",
                                value: "S/ ${ventasEntregadas.toStringAsFixed(2)}",
                                icon: Icons.payments,
                                color: primaryColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          const Text(
                            "Alertas importantes",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (bajoStock > 0)
                            activityItem(
                              icon: Icons.warning,
                              title: "Productos con bajo stock",
                              subtitle:
                                  "$bajoStock producto(s) tienen stock menor a 4.",
                              color: Colors.red,
                            ),

                          if (pedidosPendientes > 0)
                            activityItem(
                              icon: Icons.receipt_long,
                              title: "Pedidos pendientes",
                              subtitle:
                                  "$pedidosPendientes pedido(s) necesitan atención.",
                              color: Colors.orange,
                            ),

                          if (reclamosPendientes > 0)
                            activityItem(
                              icon: Icons.report_problem,
                              title: "Reclamos por atender",
                              subtitle:
                                  "$reclamosPendientes reclamo(s) están pendientes o en revisión.",
                              color: Colors.deepOrange,
                            ),

                          if (bajoStock == 0 &&
                              pedidosPendientes == 0 &&
                              reclamosPendientes == 0)
                            activityItem(
                              icon: Icons.check_circle,
                              title: "Todo está en orden",
                              subtitle:
                                  "No hay alertas importantes por atender.",
                              color: Colors.green,
                            ),

                          const SizedBox(height: 20),

                          const Text(
                            "Resumen rápido",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          activityItem(
                            icon: Icons.inventory,
                            title: "Productos registrados",
                            subtitle:
                                "Tienes ${productos.length} producto(s) registrados en total.",
                            color: Colors.blue,
                          ),

                          activityItem(
                            icon: Icons.shopping_bag,
                            title: "Pedidos registrados",
                            subtitle:
                                "Tienes ${pedidos.length} pedido(s) registrados en el sistema.",
                            color: Colors.purple,
                          ),

                          activityItem(
                            icon: Icons.people,
                            title: "Clientes registrados",
                            subtitle:
                                "Tienes ${clientes.length} cliente(s) registrados.",
                            color: Colors.green,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}