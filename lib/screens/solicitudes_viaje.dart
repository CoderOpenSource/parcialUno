import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mapas_api/screens/loading_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<DocumentSnapshot> fetchUserData() async {
  final user = _auth.currentUser;
  if (user != null) {
    return await _firestore.collection('Usuarios').doc(user.uid).get();
  }
  throw ("No user logged in");
}

class ViajesScreen extends StatefulWidget {
  const ViajesScreen({super.key});

  @override
  State<ViajesScreen> createState() => _ViajesScreenState();
}

class _ViajesScreenState extends State<ViajesScreen> {
  String? nombre;
  String? fotoPerfil;
  double? valoracion;
  late Stream<QuerySnapshot> _viajesStream;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUserData().then((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          nombre = docSnapshot['nombre'];
          fotoPerfil = docSnapshot['fotoPerfil'];
          valoracion = docSnapshot['valoracion']?.toDouble() ?? 0.0;
        });
      }
    });
    // Supongamos que este es el ID del chofer actual:
    final user = _auth.currentUser;
    String choferId = user!.uid;
    _viajesStream = _firestore
        .collection('Viajes')
        .where('chofer', isEqualTo: _firestore.doc('Usuarios/$choferId'))
        .snapshots();
  }

  Future<void> updateModeToPasajero() async {
    final user = FirebaseAuth.instance.currentUser; // Obtener el usuario actual

    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('Usuarios').doc(user.uid);

      // Actualizar el campo 'modo' del documento del usuario a 'Conductor'
      await userDoc.update({'modo': 'Pasajero'});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asumiendo que la cartera tiene un campo "ingresos"
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 134, 234, 138),
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 2, 70, 5),
          leading: Builder(
            builder: (innerContext) => IconButton(
              icon: const Icon(
                Icons.menu,
                size: 30.0,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(innerContext).openDrawer();
              },
            ),
          ),
          title: const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Esto centrará tus botones
              mainAxisSize:
                  MainAxisSize.max, // Esto toma el espacio mínimo necesario
              children: [
                Text(
                  'Solicitudes de viaje',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ])),
      body: StreamBuilder<QuerySnapshot>(
        stream: _viajesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Si hay datos pero la lista de documentos está vacía
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.car_repair, // Icono de auto
                      size: 200, // Ajusta el tamaño según prefieras
                      color: Colors.white, // Ajusta el color según prefieras
                    ),
                    Text(
                      "No hay viajes pendientes",
                      style: TextStyle(
                          fontSize:
                              20, // Ajusta el tamaño de fuente según prefieras
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold // Ajusta el color según prefieras
                          ),
                    ),
                  ],
                ),
              );
            }

            // Si hay datos y la lista de documentos no está vacía
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot viaje = snapshot.data!.docs[index];
                // Aquí retornas un widget para mostrar la información del viaje
                return ListTile(title: Text(viaje["origen"].toString()));
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Mientras se cargan los datos, muestra un indicador de carga
          return const Center(child: CircularProgressIndicator());
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              padding: const EdgeInsets.all(
                  5.0), // Aumentar o reducir según necesites
              // Aumentar o reducir según necesites
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 41, 76, 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      // Avatar
                      if (fotoPerfil != null)
                        GestureDetector(
                          onTap: () {
                            _showImagePreview(context, fotoPerfil!);
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(fotoPerfil!),
                            radius: 50,
                          ),
                        )
                      else
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person,
                              size: 50, color: Colors.grey[800]),
                        ),
                      const SizedBox(width: 15), // Espacio entre Avatar y Texto
                      // Nombre
                      Expanded(
                        child: Text(
                          nombre ?? 'Nombre no disponible',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24.0),
                        ),
                      ),
                    ],
                  ),
                  RatingBar.builder(
                    initialRating: valoracion ??
                        1, // Suponiendo que 'valoracion' es un double con el valor actual de la valoración.
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      print(
                          rating); // Puedes usar este callback si deseas hacer algo cuando se actualice la valoración.
                    },
                  ),
                ],
              ),
            ),
            const ListTile(
              leading: Icon(Icons.car_rental), // Icono de coche
              title: Text('Ciudad'),
            ),
            const ListTile(
              leading:
                  Icon(Icons.watch_later_outlined), // Icono que parece reloj
              title: Text('Mis Viajes'),
            ),
            const ListTile(
              leading: Icon(Icons.map), // Icono del mundo
              title: Text('Guía a Ciudad'),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configuraciones'),
            ),
            const ListTile(
              leading: Icon(Icons.help),
              title: Text('Ayuda'),
            ),
            ElevatedButton(
              onPressed: () async {
                await updateModeToPasajero();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoadingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 41, 76, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Modo Conductor',
                  style: TextStyle(color: Colors.white)),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 8, 45, 101),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.power_settings_new, color: Colors.white),
                    SizedBox(width: 5),
                    Text("Cerrar sesión",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
          },
          child: Container(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "😲 ¿Estás seguro?",
                style: TextStyle(
                  color: Color.fromARGB(255, 8, 45, 101),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Color.fromARGB(255, 8, 45, 101)),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginView()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Sí",
                      style: TextStyle(color: Color.fromARGB(255, 8, 45, 101)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    // Cerrar sesión con Firebase
    await _auth.signOut();

    // Actualizar SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('loggedIn', false);
  }
}
