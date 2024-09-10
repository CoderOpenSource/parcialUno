import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/views/views.dart';

import 'package:mapas_api/widgets/btn_toggle_user_route.dart';

import 'package:mapas_api/widgets/widgets.dart';
import 'package:photo_view/photo_view.dart';

class TallerScreen2 extends StatefulWidget {
  const TallerScreen2({Key? key}) : super(key: key);

  @override
  State<TallerScreen2> createState() => _LocationTallerScreenState2();
}

class _LocationTallerScreenState2 extends State<TallerScreen2>
    with SingleTickerProviderStateMixin {
  late LocationBloc locationBloc;
  Position? position;
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
      body: Column(children: [
        Expanded(
          child: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              if (locationState.lastKnownLocation == null) {
                return const Center(child: Text('Espere por favor...'));
              }

              return BlocBuilder<MapBloc, MapState>(
                builder: (context, mapState) {
                  Map<String, Polyline> polylines =
                      Map.from(mapState.polylines);

                  if (!mapState.showMyRoute) {
                    polylines.removeWhere((key, value) => key == 'myRoute');
                  }

                  return SingleChildScrollView(
                    child: Stack(
                      children: [
                        MapView(
                          initialLocation: locationState.lastKnownLocation!,
                          polylines: polylines.values.toSet(),
                          markers: mapState.markers.values.toSet(),
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
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
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
              leading: Icon(
                Icons.dashboard_customize,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Tablero de Control',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla del tablero de control del taller
              },
            ),
            ListTile(
              leading: Icon(
                Icons.construction,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Asistencias Activas',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla de asistencias activas
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Historial de Asistencias',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar al historial de asistencias
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: lightUberTheme.primaryColor),
              title: Text('Gestionar Técnicos',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla de gestión de técnicos
              },
            ),
            ListTile(
              leading: Icon(Icons.money, color: lightUberTheme.primaryColor),
              title: Text('Finanzas y Facturación',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla de finanzas y facturación
              },
            ),
            ListTile(
              leading: Icon(
                Icons.analytics,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Análisis y Reportes',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla de análisis y reportes
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Configuración',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
              onTap: () {
                // Navegar a la pantalla de configuración
              },
            ),
            ListTile(
              leading: Icon(
                Icons.help,
                color: lightUberTheme.primaryColor,
              ),
              title: Text('Ayuda y Soporte',
                  style: TextStyle(color: lightUberTheme.primaryColor)),
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
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endDocked, // Alineación con el dock
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(right: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BtnToggleUserRoute(),
            SizedBox(height: 10),
            BtnFollowUser(),
            SizedBox(height: 10),
            BtnCurrentLocation(),
            SizedBox(
                height:
                    60), // Espacio adicional para evitar solapamiento con los botones de abajo
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
