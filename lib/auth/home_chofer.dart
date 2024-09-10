import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mapas_api/blocs/location/location_bloc.dart';
import 'package:mapas_api/blocs/map/map_bloc.dart';
import 'package:mapas_api/screens/cartera_screen.dart';
import 'package:mapas_api/screens/loading_screen.dart';
import 'package:mapas_api/screens/solicitudes_viaje.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/views/map_view_chofer.dart';
import 'package:mapas_api/widgets/btn_follow_user.dart';
import 'package:mapas_api/widgets/btn_location.dart';
import 'package:mapas_api/widgets/btn_toggle_user_route.dart';
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

Future<DocumentSnapshot> fetchUserCartera() async {
  final user = _auth.currentUser;
  if (user != null) {
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('Usuarios').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data();
      if (userData != null && userData['cartera'] is DocumentReference) {
        DocumentReference carteraRef = userData['cartera'] as DocumentReference;
        return await carteraRef.get();
      }
    }
  }
  throw ("No se pudo obtener la cartera del usuario");
}

class HomeChofer extends StatefulWidget {
  const HomeChofer({super.key});

  @override
  _HomeChoferState createState() => _HomeChoferState();
}

class _HomeChoferState extends State<HomeChofer> {
  late LocationBloc locationBloc;
  String? nombre;
  String? fotoPerfil;
  double? valoracion;
  @override
  void initState() {
    super.initState();
    locationBloc = BlocProvider.of<LocationBloc>(context);
    locationBloc.startFollowingUser();
    fetchUserData().then((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          nombre = docSnapshot['nombre'];
          fotoPerfil = docSnapshot['fotoPerfil'];
          valoracion = docSnapshot['valoracion']?.toDouble() ?? 0.0;
        });
      }
    });
    fetchUserCartera().then((carteraDoc) {
      if (carteraDoc.exists) {
        // Procesa los datos de la cartera aquí
        // Por ejemplo, si la cartera tiene un campo "balance":
        double? balance = carteraDoc['balance']?.toDouble();
        print("Balance de la cartera: $balance");
      }
    });
  }

  @override
  void dispose() {
    locationBloc.stopFollowingUser();
    super.dispose();
  }

  Future<void> updateEstado(String nuevoEstado, BuildContext context) async {
    // Obtiene el usuario actualmente loggeado
    User? currentUser = FirebaseAuth.instance.currentUser;

    // Verifica que haya un usuario loggeado
    if (currentUser == null) {
      print("No user logged in.");
      return;
    }

    // Referencia a la colección de usuarios y al documento del usuario actual
    CollectionReference users =
        FirebaseFirestore.instance.collection('Usuarios');
    DocumentReference userDoc = users.doc(currentUser.uid);

    // Actualiza el campo 'estado' con el nuevo estado
    await userDoc.update({'estado': nuevoEstado});

    // Muestra un SnackBar con un fondo verde
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado a $nuevoEstado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
    return Scaffold(
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
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Esto centrará tus botones
          mainAxisSize:
              MainAxisSize.max, // Esto toma el espacio mínimo necesario
          children: [
            ElevatedButton(
              onPressed: () async {
                await updateEstado('Disponible', context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green, // Color del texto
              ),
              child: const Text(
                'Disponible',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10), // Espacio entre botones
            ElevatedButton(
              onPressed: () async {
                await updateEstado('Ocupado', context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red, // Color del texto
              ),
              child: const Text(
                'Ocupado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, locationstate) {
              if (locationstate.lastKnownLocation == null) {
                return const Center(
                  child: Text('Espere por favor!'),
                );
              }

              return BlocBuilder<MapBloc, MapState>(
                builder: (context, mapstate) {
                  Map<String, Polyline> polylines =
                      Map.from(mapstate.polylines);
                  if (!mapstate.showMyRoute) {
                    polylines.removeWhere((key, value) => key == 'myRoute');
                  }
                  return SingleChildScrollView(
                    child: Stack(
                      children: [
                        MapViewChofer(
                          initialLocation: locationstate.lastKnownLocation!,
                          polylines: polylines.values.toSet(),
                          markers: mapstate.markers.values.toSet(),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ViajesScreen()),
                  );
                },
                icon: const Icon(Icons.list,
                    color: Colors.white), // Ícono de lista
                label: const Text(
                  'Solicitudes de viaje',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Fondo negro
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 50),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      DocumentSnapshot carteraDoc = await fetchUserCartera();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CarteraScreen(carteraData: carteraDoc),
                        ),
                      );
                    } catch (error) {
                      // Aquí puedes manejar el error, por ejemplo mostrando un mensaje al usuario
                      print("Error obteniendo la cartera: $error");
                    }
                  },
                  icon: const Icon(Icons.monetization_on,
                      color: Colors.white), // Ícono de dinero
                  label: const Text(
                    'Mis ingresos',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Fondo negro
                  ),
                ),
              ),
            ],
          ),
          const Padding(
              padding:
                  EdgeInsets.only(bottom: 30.0)), // Margen inferior de 30.0
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BtnToggleUserRoute(),
          BtnFollowUser(),
          BtnCurrentLocation(),
        ],
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
