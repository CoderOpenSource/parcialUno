import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mapas_api/auth/register_chofer.dart';
import 'package:mapas_api/models/user_model.dart' as MyUser;
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/widgets/image_picker.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final CollectionReference _usersCollection = _firestore.collection('Usuarios');
final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

Future<String> registerUser({
  required String email,
  required String password,
  required MyUser.User user, // Asumiendo que 'User' es tu modelo
}) async {
  try {
    // Registra al usuario con firebase_auth
    auth.UserCredential userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);

    // Una vez registrado, añade su perfil a Firestore
    await _usersCollection.doc(userCredential.user!.uid).set({
      'email': user.email,
      'fotoPerfil': user.fotoPerfil,
      'modo': user.modo,
      'nombre': user.nombre,
      'telefono': user.telefono,
      //... Añade más campos si es necesario
    });

    return userCredential.user!.uid;
  } catch (e) {
    print("Error al registrar: $e");
    rethrow;
  }
}

Future<String> uploadImageToFirebase(File imageFile) async {
// Crear una referencia al lugar donde queremos guardar la imagen
  final storageReference = FirebaseStorage.instance
      .ref()
      .child('imagesPerfil/${DateTime.now().toIso8601String()}.jpg');

  // Subir el archivo a Firebase Storage
  await storageReference.putFile(imageFile);

  // Una vez que la imagen ha sido subida, recuperar su URL
  String imageUrl = await storageReference.getDownloadURL();

  return imageUrl;
}

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
  String? _selectedRole;
  bool _isCreatingUser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 134, 234, 138),
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
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 20),
                _customTextField(nameController, 'Nombre Completo:',
                    'Ingresa tu nombre completo',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                _customTextField(emailController, 'Correo Electronico:',
                    'Ingresa tu correo electronico',
                    prefixIcon: const Icon(Icons.email,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                _customTextField(
                    passwordController, 'Contraseña:', 'Ingresa tu contraseña',
                    obscure: true,
                    prefixIcon: const Icon(Icons.lock,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                _customTextField(confirmPasswordController,
                    'Confirmar Contraseña:', 'Confirma tu contraseña',
                    obscure: true,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                _customTextField(phoneController, 'Número de teléfono:',
                    'Ingresa tu número de telefono',
                    prefixIcon: const Icon(Icons.phone,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 16.0), // Margen arriba y abajo
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    hint: const Text(
                      "Selecciona un Rol",
                      style: TextStyle(
                        color: Color.fromARGB(255, 41, 76, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    items:
                        <String>['Pasajero', 'Conductor'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 41, 76, 1),
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: Container(
                      height: 2,
                      color: Colors.green,
                    ),
                  ),
                ),
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
                    backgroundColor: const Color.fromARGB(255, 41, 76, 1),
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
      labelStyle: const TextStyle(color: Color.fromARGB(255, 41, 76, 1)),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 41, 76, 1)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 76, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 76, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 76, 1)),
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
      style: const TextStyle(color: Color.fromARGB(255, 41, 76, 1)),
      cursorColor: const Color.fromARGB(255, 41, 76, 1),
      decoration: _inputDecoration(label, hintText, prefixIcon),
    );
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isCreatingUser = true;
    });

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        _selectedRole == null) {
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

    // Verificación de correo electrónico existente en Firestore
    QuerySnapshot emailSnapshot = await _usersCollection
        .where('email', isEqualTo: emailController.text.trim())
        .get();

    if (emailSnapshot.docs.isNotEmpty) {
      setState(() {
        _isCreatingUser = false;
      });
      _showSnackBar("Este correo electrónico ya está registrado.");
      return;
    }

    try {
      String profileImageUrl;

      if (_selectedImage != null) {
        profileImageUrl = await uploadImageToFirebase(_selectedImage!);
      } else {
        profileImageUrl =
            "URL predeterminada"; // Usa una URL predeterminada si la tienes
      }

      String userId = await registerUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        user: MyUser.User(
          email: emailController.text.trim(),
          fotoPerfil: profileImageUrl,
          modo: _selectedRole!,
          nombre: nameController.text.trim(),
          telefono: phoneController.text.trim(),
        ),
      );

      _showSnackBar("Usuario registrado con éxito", Colors.green);
      setState(() {
        _isCreatingUser = false;
      });
      await FirebaseAuth.instance.signOut();

      if (_selectedRole == 'Conductor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  CompleteDriverRegistrationView(userId: userId)),
        );
      } else if (_selectedRole == 'Pasajero') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingUser = false;
      });
      _showSnackBar("Error al intentar registrarse: ${e.toString()}");
    }
  }

  void _showSnackBar(String message, [Color backgroundColor = Colors.red]) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _customTextField2(
      TextEditingController controller, String label, String hintText,
      {bool obscure = false}) {
    return TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: obscure,
        style: const TextStyle(color: Color.fromARGB(255, 2, 65, 30)),
        cursorColor: const Color.fromARGB(255, 41, 76, 1),
        decoration: _inputDecoration(label, hintText));
  }
}
