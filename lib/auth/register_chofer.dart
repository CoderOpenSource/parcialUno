import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mapas_api/widgets/image_picker.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final CollectionReference _usersCollection = _firestore.collection('Usuarios');
final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

Future<DocumentReference> createLicencia({
  required String categoria,
  required Timestamp fechaExpiracion,
  required int nroLicencia,
  required String fotoFrontal,
  required String fotoTrasera,
  required String choferId, // ID del chofer al que pertenece esta licencia
}) async {
  try {
    DocumentReference licenciaRef =
        await FirebaseFirestore.instance.collection('Licencias').add({
      'categoria': categoria,
      'fechaExpiracion': fechaExpiracion,
      'nroLicencia': nroLicencia,
      'fotoFrontal': fotoFrontal,
      'fotoTrasera': fotoTrasera,
      'chofer': FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(choferId), // referencia al documento del chofer
    });
    return licenciaRef;
  } catch (e) {
    print("Error al crear la licencia: $e");
    rethrow;
  }
}

Future<DocumentReference> createCartera({
  required double balance,
  required String choferId, // ID del chofer al que pertenece esta cartera
}) async {
  try {
    DocumentReference carteraRef =
        await FirebaseFirestore.instance.collection('Carteras').add({
      'balance': balance,
      'historialTransacciones':
          [], // Inicializa un array vacío para el historial de transacciones
      'chofer': FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(choferId), // referencia al documento del chofer
    });
    return carteraRef;
  } catch (e) {
    print("Error al crear la cartera: $e");
    rethrow;
  }
}

Future<void> updateChoferData({
  required String choferId,
  required String estado,
  required String tipoVehiculo,
  required DocumentReference licenciaRef,
  required DocumentReference carteraRef,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(choferId)
        .update({
      'estado': estado,
      'tipoVehiculo': tipoVehiculo,
      'licencia': licenciaRef, // referencia al documento de Licencia
      'cartera': carteraRef, // referencia al documento de Cartera
      'historialViajes':
          [], // Inicializa un array vacío para el historial de viajes
    });
  } catch (e) {
    print("Error al actualizar los datos del chofer: $e");
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

class CompleteDriverRegistrationView extends StatefulWidget {
  final String userId;
  const CompleteDriverRegistrationView({super.key, required this.userId});

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<CompleteDriverRegistrationView> {
  // Imágenes
  File? _selectedLicenciaFrontalImage;
  File? _selectedLicenciaTraseraImage;

  // Controladores relacionados con la licencia
  TextEditingController nroLicenciaController = TextEditingController();
  TextEditingController categoriaLicenciaController = TextEditingController();
  DateTime? birthdate;
  // Controlador para el tipo de vehículo del chofer
  String? _vehiculoSeleccionado;

  // Controlador para el balance inicial de la cartera (si es necesario)
  TextEditingController balanceInicialController = TextEditingController();

  bool _isCreatingUser = false;

  @override
  void initState() {
    super.initState();
    // Inicializaciones aquí si es necesario
  }

  @override
  void dispose() {
    nroLicenciaController.dispose();
    categoriaLicenciaController.dispose();
    balanceInicialController.dispose();

    super.dispose();
  }

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
                const Text("Registro de Chofer",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'Escoge tu Vehiculo :',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _vehiculoSeleccionado = 'auto';
                            });
                          },
                          child: Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/driverexpress-ff785.appspot.com/o/image-from-rawpixel-id-12431651-png.png?alt=media&token=ba2c5cd6-b29e-4627-b078-eeb45e19bb72', // Reemplaza con la URL de tu imagen o usa Image.asset si es local
                            width: 80, // Puedes ajustar el tamaño como quieras
                            height: 80,
                          ),
                        ),
                        Container(
                          height: 2,
                          width: 60,
                          color: _vehiculoSeleccionado == 'auto'
                              ? Colors.black
                              : Colors.transparent,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _vehiculoSeleccionado = 'moto';
                            });
                          },
                          child: Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/driverexpress-ff785.appspot.com/o/image-from-rawpixel-id-12431954-png.png?alt=media&token=b56fe3b2-6439-42cb-8c84-338cc1eaa739',
                            width: 80, // Puedes ajustar el tamaño como quieras
                            height: 80,
                          ),
                        ),
                        Container(
                          height: 2,
                          width: 60,
                          color: _vehiculoSeleccionado == 'moto'
                              ? Colors.black
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Licencia:",
                    style:
                        TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _customTextField(nroLicenciaController, 'Nro De Licencia:',
                    'Ingresa tu numero de licencia',
                    prefixIcon: const Icon(Icons.person_outline,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                _customTextField(categoriaLicenciaController, 'Categoria:',
                    'Ingresa tu categoria',
                    prefixIcon: const Icon(Icons.email,
                        color: Color.fromARGB(255, 59, 9, 59))),
                const SizedBox(height: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(
                            2100), // Cambiado para permitir fechas futuras
                      );
                      if (selectedDate != null) {
                        setState(() {
                          birthdate = selectedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration('Fecha de Expiración:',
                          'Escoge la fecha de expiración'),
                      child: birthdate == null
                          ? const Text(
                              'Selecciona la fecha de expiración',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 8, 45, 101),
                                  fontSize: 16),
                            )
                          : Text(DateFormat('dd/MM/yyyy').format(birthdate!)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                    "Toma o sube una foto de tu licencia de la parte frontal",
                    style: TextStyle(fontSize: 16)),
                ImagePickerWidget(
                  onImagePicked: (image) {
                    setState(() {
                      _selectedLicenciaFrontalImage = image;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text("Tómale una foto a tu licencia de la parte trasera",
                    style: TextStyle(fontSize: 16)),
                ImagePickerWidget(
                  onImagePicked: (image) {
                    setState(() {
                      _selectedLicenciaTraseraImage = image;
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

    // Verificación de campos vacíos
    if (nroLicenciaController.text.trim().isEmpty ||
        categoriaLicenciaController.text.trim().isEmpty ||
        birthdate == null ||
        _selectedLicenciaFrontalImage == null ||
        _selectedLicenciaTraseraImage == null ||
        _vehiculoSeleccionado == null) {
      setState(() {
        _isCreatingUser = false;
      });
      _showSnackBar("Por favor completa todos los campos");
      return;
    }

    try {
      // Subida de las imágenes a Firebase
      String licenciaFrontalImageUrl =
          await uploadImageToFirebase(_selectedLicenciaFrontalImage!);
      String licenciaTraseraImageUrl =
          await uploadImageToFirebase(_selectedLicenciaTraseraImage!);

      // Crear Licencia en Firestore
      DocumentReference licenciaRef = await createLicencia(
        categoria: categoriaLicenciaController.text.trim(),
        fechaExpiracion: Timestamp.fromDate(birthdate!),
        nroLicencia: int.parse(nroLicenciaController.text.trim()),
        fotoFrontal: licenciaFrontalImageUrl,
        fotoTrasera: licenciaTraseraImageUrl,
        choferId: widget.userId,
      );

      // Crear Cartera en Firestore con un balance inicial de 0 (o el valor que desees)
      DocumentReference carteraRef = await createCartera(
        balance: 0.0,
        choferId: widget.userId,
      );

      // Actualizar datos del Chofer en Firestore
      await updateChoferData(
        choferId: widget.userId,
        estado:
            'Disponible', // Asumiendo que todos los choferes registrados inicialmente están 'activos'
        tipoVehiculo: _vehiculoSeleccionado!,
        licenciaRef: licenciaRef,
        carteraRef: carteraRef,
      );

      _showSnackBar("Conductor registrado con éxito", Colors.green);
      setState(() {
        _isCreatingUser = false;
      });

      await FirebaseAuth.instance.signOut();
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
