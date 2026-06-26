import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_productos_screen.dart';
import 'admin_pedidos_screen.dart';
import 'admin_clientes_screen.dart';
import 'admin_reclamos_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_configuracion_screen.dart';
import 'admin_categorias_screen.dart';
import 'dashboard_screen.dart';
import 'admin_repartidores_screen.dart';
import 'admin_historial_inventario_screen.dart';
import 'mesa_ayuda_admin_screen.dart';

///PANTALLA PRINCIPAL ADMIN 
////////////////////////////////////////////////////////
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

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
    return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Usa cerrar sesión para salir del panel administrador",
        ),
      ),
    );
  },
  child: Scaffold(
    backgroundColor: Colors.grey[100],

    appBar: AppBar(
      elevation: 0,
      backgroundColor: colorPrincipal,
      title: const Text(
        "INVERSIONES ISABELLA",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
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

    drawer: SizedBox(
      width: 270,
      child: Drawer(
        child: Column(
          children: [
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  menuItem("Dashboard", Icons.dashboard, "dashboard"),
                  menuItem("Productos", Icons.inventory_2, "productos"),
                  menuItem("Historial Inventario", Icons.history, "historial_inventario"),
                  menuItem("Categorías", Icons.category, "categorias"),
                  menuItem("Pedidos", Icons.shopping_cart, "pedidos"),
                  menuItem("Clientes", Icons.people, "clientes"),
                  menuItem("Reclamos", Icons.report_problem, "reclamos"),
                  menuItem("Mesa de Ayuda", Icons.support_agent, "mesa_ayuda"),
                  menuItem("Reportes", Icons.bar_chart, "reportes"),
                  menuItem("Repartidores", Icons.delivery_dining,"repartidores"),
                  menuItem("Configuración", Icons.settings, "config")
                 
                ],
              ),
            ),
          ],
        ),
      ),
    ),

    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: getSelectedScreen(),
    ),
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
        selectedTileColor: colorPrincipal.withValues(alpha: 0.12),
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
      case "historial_inventario":
        return const AdminHistorialInventarioScreen();
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
      case "mesa_ayuda":
        return const MesaAyudaAdminScreen();
      case "categorias":
        return AdminCategoriasScreen();
      case "repartidores":
        return const AdminRepartidoresScreen();
      default:
        return DashboardScreen();
    }
  }
}