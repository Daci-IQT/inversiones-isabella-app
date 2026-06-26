import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/admin_dashboard.dart';
import '../auth/register_screen.dart';
import '../repartidor/repartidor_panel_screen.dart';
import '../clientes/panel_cliente.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  final bool volverAlAnterior;

  const LoginScreen({
    super.key,
    this.volverAlAnterior = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final Color primaryColor = const Color.fromARGB(255, 243, 33, 96);

  bool cargando = false;
  bool ocultarPassword = true;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      mensaje("Completa correo y contraseña", Colors.redAccent);
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final usuarioAuth = userCredential.user!;

if (!usuarioAuth.emailVerified) {
  await usuarioAuth.sendEmailVerification();
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  mensaje(
    "Debes verificar tu correo. Te enviamos nuevamente el enlace de verificación.",
    Colors.orange,
  );

  return;
}

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) {
        mensaje("Usuario no registrado en la base de datos", Colors.redAccent);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final rol = data['rol'] ?? 'cliente';

      if (!mounted) return;

      if (widget.volverAlAnterior && rol == 'cliente') {
        Navigator.pop(context, true);
        return;
      }

      if (rol == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
          (route) => false,
        );
      } else if (rol == 'repartidor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RepartidorPanelScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ClientePanel()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String texto = "Error al iniciar sesión";

      if (e.code == 'user-not-found') {
        texto = "No existe una cuenta con ese correo";
      } else if (e.code == 'wrong-password') {
        texto = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        texto = "Correo electrónico inválido";
      } else if (e.code == 'invalid-credential') {
        texto = "Correo o contraseña incorrectos";
      }

      mensaje(texto, Colors.redAccent);
    } catch (e) {
      mensaje("Ocurrió un error inesperado", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> recuperarPassword() async {
    if (emailController.text.trim().isEmpty) {
      mensaje("Ingresa tu correo para recuperar contraseña", Colors.orange);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      mensaje(
        "Te enviamos un correo para restablecer tu contraseña",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String texto = "No se pudo enviar el correo";

      if (e.code == 'invalid-email') {
        texto = "Correo electrónico inválido";
      } else if (e.code == 'user-not-found') {
        texto = "No existe una cuenta con ese correo";
      }

      mensaje(texto, Colors.redAccent);
    }
  }

Future<void> loginConGoogle() async {
  setState(() {
    cargando = true;
  });

  try {
    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      setState(() {
        cargando = false;
      });
      return;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;

    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);

    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set({
        'uid': user.uid,
        'nombre': user.displayName ?? 'Cliente',
        'correo': user.email ?? '',
        'fotoUrl': user.photoURL ?? '',
        'rol': 'cliente',
        'proveedor': 'google',
        'fechaRegistro': FieldValue.serverTimestamp(),
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    if (widget.volverAlAnterior) {
      Navigator.pop(context, true);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ClientePanel()),
      (route) => false,
    );
  } on FirebaseAuthException catch (e) {
    mensaje(
      e.message ?? "No se pudo iniciar sesión con Google",
      Colors.redAccent,
    );
  } catch (e) {
    mensaje(
      "Error al iniciar sesión con Google",
      Colors.redAccent,
    );
  } finally {
    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }
}

  void mensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(
          texto,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget logoNegocio() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('configuracion')
          .doc('negocio')
          .snapshots(),
      builder: (context, snapshot) {
        String nombreNegocio = "Inversiones Isabella";
        String subtitulo = "E-commerce móvil";
        String logoUrl = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          nombreNegocio = data['nombreNegocio'] ?? nombreNegocio;
          subtitulo = data['subtitulo'] ?? subtitulo;
          logoUrl = data['logoUrl'] ?? "";
        }

        return Column(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
              child: logoUrl.isEmpty
                  ? Icon(
                      Icons.storefront,
                      color: primaryColor,
                      size: 48,
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              nombreNegocio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logoNegocio(),

                    const SizedBox(height: 30),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: ocultarPassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultarPassword = !ocultarPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: recuperarPassword,
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: cargando ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.login,
                                color: Colors.white,
                              ),
                        label: Text(
                          cargando ? "Ingresando..." : "Ingresar",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "o",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: cargando ? null : loginConGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 32),
                        label: const Text(
                          "Continuar con Google",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "¿No tienes cuenta? Crear cuenta",
                        style: TextStyle(
                          color: primaryColor,
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