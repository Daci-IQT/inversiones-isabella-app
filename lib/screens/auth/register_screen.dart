import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/// 🧾 REGISTRO DE USUARIO
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