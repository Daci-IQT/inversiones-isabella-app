import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../clientes/panel_cliente.dart';
import '../admin/admin_dashboard.dart';
import '../repartidor/repartidor_panel_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return const ClientePanel();
        }

        final user = authSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.data!.exists) {
              return LoginScreen();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final rol = data['rol'] ?? 'cliente';

            if (rol == 'admin') {
              return AdminDashboard();
            }

            if (rol == 'repartidor') {
              return const RepartidorPanelScreen();
            }

            return const ClientePanel();
          },
        );
      },
    );
  }
}