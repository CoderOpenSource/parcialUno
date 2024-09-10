import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/widgets/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import 'package:mime/mime.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  File? _selectedImage;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController direccionController = TextEditingController();

  bool _isCreatingUser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text("Registro",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E272E))),
                const SizedBox(height: 20),
                _customTextField(usernameController, 'Nombre de Usuario:',
                    'Ingresa un nombre de Usuario único',
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(nameController, 'Nombre Completo:',
                    'Ingresa tu nombre completo',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(emailController, 'Correo Electronico:',
                    'Ingresa tu correo electronico',
                    prefixIcon:
                        const Icon(Icons.email, color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(
                    passwordController, 'Contraseña:', 'Ingresa tu contraseña',
                    obscure: true,
                    prefixIcon:
                        const Icon(Icons.lock, color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(confirmPasswordController,
                    'Confirmar Contraseña:', 'Confirma tu contraseña',
                    obscure: true,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(phoneController, 'Número de teléfono:',
                    'Ingresa tu número de telefono',
                    prefixIcon:
                        const Icon(Icons.phone, color: Color(0xFF1E272E))),
                const SizedBox(height: 10),
                _customTextField(
                    direccionController, 'Direccion', 'Ingresa tu direccion:',
                    prefixIcon: const Icon(Icons.maps_home_work_sharp)),
                ImagePickerWidget(
                  onImagePicked: (image) {
                    setState(() {
                      _selectedImage = image;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _handleRegistration();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E272E),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Registrarse",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          if (_isCreatingUser) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Espere por favor...",
                style: TextStyle(color: Color.fromARGB(255, 59, 9, 59))),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hintText,
      [Icon? prefixIcon]) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF1E272E)),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF1E272E)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF1E272E)),
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF1E272E)),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF1E272E)),
        borderRadius: BorderRadius.circular(20),
      ),
      filled: true,
      fillColor: Colors.white,
      focusColor: Colors.transparent,
    );
  }

  Widget _customTextField(
      TextEditingController controller, String label, String hintText,
      {bool obscure = false, Icon? prefixIcon}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1E272E)),
      cursorColor: const Color(0xFF1E272E),
      decoration: _inputDecoration(label, hintText, prefixIcon),
    );
  }

  Future<void> registerWithDjango() async {
    const url = 'http://137.184.190.92//users/usuarios-cliente/';

    // Creamos un Map para el cuerpo de la petición
    Map<String, String> requestBody = {
      'username': usernameController.text.trim(),
      'first_name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'telefono': phoneController.text.trim(),
      'password': passwordController.text.trim(),
      'address': direccionController.text.trim(),
    };

    late http.Response response; // La respuesta se procesará más tarde

    if (_selectedImage != null) {
      String? mimeType = lookupMimeType(_selectedImage!.path);
      MediaType mediaType = MediaType.parse(mimeType!);

      // Usar MultipartRequest para manejar la imagen
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields.addAll(requestBody)
        ..files.add(await http.MultipartFile.fromPath(
          'foto_perfil',
          _selectedImage!.path,
          contentType: mediaType,
        ));

      var streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } else {
      // Realizamos la petición POST sin imagen
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
    }

    // Evaluamos la respuesta
    if (response.statusCode == 201) {
      // HTTP 201 significa que se creó correctamente
      _showSnackBar('Usuario registrado con éxito');
    } else {
      var errorMessage = 'Error al registrar el usuario';
      try {
        var responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
        }
      } catch (e) {
        print('Error al decodificar la respuesta: $e');
      }
      _showSnackBar(errorMessage);
    }
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isCreatingUser = true;
    });

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        direccionController.text.trim().isEmpty) {
      setState(() {
        _isCreatingUser = false;
      });
      _showSnackBar("Por favor completa todos los campos");
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() {
        _isCreatingUser = false;
      });
      _showSnackBar("Las contraseñas no coinciden");
      return;
    }

    // Implement your function to connect with Django and register the user
    // For example: await registerWithDjango(...);
    // Llama a la función para registrar con Django
    await registerWithDjango();

    setState(() {
      _isCreatingUser = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _customTextField2(
      TextEditingController controller, String label, String hintText,
      {bool obscure = false}) {
    return TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: obscure,
        style: const TextStyle(color: Color.fromARGB(255, 59, 9, 59)),
        cursorColor: const Color.fromARGB(255, 59, 9, 59),
        decoration: _inputDecoration(label, hintText));
  }
}
