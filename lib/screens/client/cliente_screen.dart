import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapas_api/blocs/location/location_bloc.dart';
import 'package:mapas_api/blocs/map/map_bloc.dart';

import 'package:mapas_api/screens/client/loading_client_screen.dart';
import 'package:mapas_api/screens/solicitudes_servicio.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:mapas_api/views/map_view.dart';
import 'package:mapas_api/widgets/btn_follow_user.dart';
import 'package:mapas_api/widgets/btn_location.dart';
import 'package:mapas_api/widgets/btn_toggle_user_route.dart';
import 'package:mapas_api/widgets/manual_market.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  _ClienteScreenState createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  late LocationBloc locationBloc;
  Color primaryColor = lightUberTheme.primaryColor;
  String? nombre;
  String? fotoPerfil;
  double? valoracion;
  @override
  void initState() {
    super.initState();
    locationBloc = BlocProvider.of<LocationBloc>(context);
    locationBloc.startFollowingUser();
    _fetchUserData();
  }

  @override
  void dispose() {
    locationBloc.stopFollowingUser();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Obtén el userId guardado, usa 0 o null como valor por defecto
    final userId = prefs.getInt('userId').toString();
    var url = Uri.parse(
        'http://174.138.68.210/usuarios/users/$userId/'); // Asegúrate de usar tu URL correcta
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
        setState(() {
          nombre = data['first_name'];
          // Suponiendo que 'foto' es la llave para la foto de perfil
          fotoPerfil = data['foto'];
          print(fotoPerfil);
          // Aquí agrega la lógica para valoracion si es necesario
          // valoracion = ...;
        });
      } else {
        // Maneja el caso en que la petición no fue exitosa
        print('Failed to load user data');
      }
    } catch (e) {
      // Maneja cualquier excepción
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locationstate) {
        if (locationstate.lastKnownLocation == null) {
          return const Center(
            child: Text('Espere por favor!'),
          );
        }

        return BlocBuilder<MapBloc, MapState>(
          builder: (context, mapstate) {
            Map<String, Polyline> polylines = Map.from(mapstate.polylines);
            if (!mapstate.showMyRoute) {
              polylines.removeWhere((key, value) => key == 'myRoute');
            }
            return SingleChildScrollView(
              child: Stack(
                children: [
                  MapView(
                    initialLocation: locationstate.lastKnownLocation!,
                    polylines: polylines.values.toSet(),
                    markers: mapstate.markers.values.toSet(),
                  ),
                  const ManualMarker(),
                  Positioned(
                    top: 20.0,
                    left: 10.0,
                    child: Builder(
                      builder: (innerContext) => IconButton(
                        icon: Icon(
                          Icons.menu,
                          size: 30.0,
                          color: lightUberTheme.primaryColor,
                        ),
                        onPressed: () {
                          Scaffold.of(innerContext).openDrawer();
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20.0,
                    right: 20.0,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        // Acción al presionar el botón
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AssistanceRequestScreen()),
                        );
                      },
                      label: const Text(
                        'Nueva Solicitud',
                        style: TextStyle(color: Colors.white),
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      backgroundColor: lightUberTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ],

                // Aquí agregamos el Card
              ),
            );
          },
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
              decoration: BoxDecoration(
                color: lightUberTheme.primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (fotoPerfil != null)
                    GestureDetector(
                      onTap: () {
                        _showImagePreview(context, fotoPerfil!);
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(fotoPerfil!),
                        radius:
                            50, // Controla el tamaño del avatar. Puedes ajustar este valor si es necesario.
                      ),
                    )
                  else
                    CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person,
                            size: 50, color: Colors.grey[800])),
                  Text(nombre ?? 'Nombre no disponible',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 24.0)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: primaryColor),
              title: Text(
                'Inicio',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la pantalla de inicio
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) =>
                          const ClienteLoadingScreen()), // Reemplaza PantallaDeInicio con el widget de tu pantalla de inicio
                  (Route<dynamic> route) => false,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: primaryColor),
              title: Text(
                'Mis Solicitudes',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la pantalla que muestra el historial de solicitudes
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: primaryColor),
              title: Text(
                'Talleres Favoritos',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la lista de talleres favoritos
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car, color: primaryColor),
              title: Text(
                'Perfil del Vehículo',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la pantalla de gestión de vehículos del usuario
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: primaryColor),
              title: Text(
                'Configuración',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la pantalla de configuraciones de la cuenta
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: primaryColor),
              title: Text(
                'Ayuda y Soporte',
                style: TextStyle(color: primaryColor),
              ),
              onTap: () {
                // Navegar a la pantalla de ayuda y soporte
              },
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightUberTheme.primaryColor,
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
                    onPressed: () {
                      _logout(context);
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

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the stored preferences
    prefs.remove('accessToken');
    prefs.remove('accessRefresh');
    prefs.remove('userId');
    prefs.remove('userType');
    // Navigate to the login page and remove all other screens from the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            const LoginView(), // Assuming your login view is named LoginView
      ),
      (Route<dynamic> route) => false, // This will remove all other screens
    );
  }
}
