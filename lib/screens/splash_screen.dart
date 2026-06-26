import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'clientes/panel_cliente.dart';
import 'admin/admin_dashboard.dart';
import 'repartidor/repartidor_panel_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  late AnimationController controller;
  late Animation<double> scaleAnimation;

  String logoUrl = '';
  String nombreNegocio = 'IsabellaStore';

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    scaleAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    controller.forward();

    cargarDatosYRedirigir();
  }

  Future<void> cargarDatosYRedirigir() async {
    await cargarLogo();

    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientePanel()),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (!doc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientePanel()),
      );
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final rol = data['rol'] ?? 'cliente';

    if (rol == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
    } else if (rol == 'repartidor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RepartidorPanelScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientePanel()),
      );
    }
  }

  Future<void> cargarLogo() async {
    final doc = await FirebaseFirestore.instance
        .collection('configuracion')
        .doc('negocio')
        .get();

    if (!doc.exists) return;

    final data = doc.data();

    if (data == null) return;

    if (!mounted) return;

    setState(() {
      logoUrl = data['logoUrl'] ?? '';
      nombreNegocio = data['nombreNegocio'] ?? 'IsabellaStore';
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              const Color.fromARGB(255, 120, 0, 40),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 62,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                  child: logoUrl.isEmpty
                      ? Icon(
                          Icons.storefront,
                          color: primaryColor,
                          size: 64,
                        )
                      : null,
                ),

                const SizedBox(height: 24),

                Text(
                  nombreNegocio,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Moda • Estilo • Elegancia",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 34),

                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}