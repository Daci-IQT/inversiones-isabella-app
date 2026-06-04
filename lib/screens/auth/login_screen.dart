import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_dashboard.dart';
import '../auth/register_screen.dart';
class LoginScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // FUNCIÓN LOGIN
  Future<void> login(BuildContext context) async {
    try {
      // Autenticación con Firebase
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = user.user!.uid;

      // Buscar rol del usuario en Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      String rol = doc['rol'];

      // 🔀 Redirección según rol
      if (rol == 'admin') {
  Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => AdminDashboard()),
  (route) => false,
);
} else {
  Navigator.pop(context, true);
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