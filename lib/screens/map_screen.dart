import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/helpers/show_loading_message.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:mapas_api/views/views.dart';

import 'package:mapas_api/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  final int solicitudId;
  const MapScreen({Key? key, required this.solicitudId}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LocationBloc locationBloc;
  Map<String, dynamic> solicitudData = {};
  Map<String, dynamic> tallerData = {};
  LatLng? _locationTaller;
  bool showRoute = false;
  @override
  void initState() {
    super.initState();

    locationBloc = BlocProvider.of<LocationBloc>(context);
    // locationBloc.getCurrentPosition();
    locationBloc.startFollowingUser();
    fetchSolicitud();
    fetchSolicitudTaller();
  }

  @override
  void dispose() {
    locationBloc.stopFollowingUser();
    super.dispose();
  }

  Future<void> fetchSolicitud() async {
    try {
      final solicitudResponse = await http.get(
        Uri.parse(
            'http://174.138.68.210/solicitudes_asistencia/solicitudes-asistencia/${widget.solicitudId}'),
      );

      if (solicitudResponse.statusCode == 200) {
        final data = json.decode(solicitudResponse.body);
        setState(() {
          solicitudData = data;
        });

        // Asegúrate de que latitud y longitud están disponibles
        if (solicitudData.containsKey('latitud') &&
            solicitudData.containsKey('longitud')) {
          final location =
              LatLng(solicitudData['latitud'], solicitudData['longitud']);
          final mapBloc = BlocProvider.of<MapBloc>(context);
          await mapBloc.addMarker(
              location, 'initial-location', 'Ubicación Inicial');
        }
      } else {
        print('Error al obtener la solicitud: ${solicitudResponse.statusCode}');
      }
    } catch (e) {
      print('Error al hacer fetch de la solicitud: $e');
    }
  }

  Future<void> fetchSolicitudTaller() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      print('usuario id $userId');
      final tallerId = await obtenerClienteIdPorUserId(userId ?? 0);
      print('taller id $tallerId');
      final solicitudResponse = await http.get(
        Uri.parse('http://174.138.68.210/usuarios/talleres/$tallerId'),
      );

      if (solicitudResponse.statusCode == 200) {
        final data = json.decode(solicitudResponse.body);
        setState(() {
          tallerData = data;
        });

        // Asegúrate de que latitud y longitud están disponibles
        if (tallerData.containsKey('latitud') &&
            tallerData.containsKey('longitud')) {
          _locationTaller =
              LatLng(tallerData['latitud'], tallerData['longitud']);
        }
      } else {
        print('Error al obtener la solicitud: ${solicitudResponse.statusCode}');
      }
    } catch (e) {
      print('Error al hacer fetch de la solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          if (locationState.lastKnownLocation == null) {
            return const Center(child: Text('Espere por favor...'));
          }

          return BlocBuilder<MapBloc, MapState>(
            builder: (context, mapState) {
              Map<String, Polyline> polylines = Map.from(mapState.polylines);
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
                    if (!showRoute) ...[
                      Positioned(
                        bottom: 20.0,
                        right: 20.0,
                        child: FloatingActionButton.extended(
                          onPressed: () async {
                            final searchBloc =
                                BlocProvider.of<SearchBloc>(context);
                            final mapBloc = BlocProvider.of<MapBloc>(context);
                            final start = _locationTaller!;
                            final end = LatLng(solicitudData['latitud'],
                                solicitudData['longitud']);
                            showLoadingMessage(context);
                            final destination =
                                await searchBloc.getCoorsStartToEnd(start, end);
                            await mapBloc.drawRoutePolyline(destination);
                            setState(() {
                              showRoute = true;
                            });
                            Navigator.pop(context);
                          },
                          label: const Text(
                            '¿Como llegar? :O',
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: const Icon(
                            Icons.route_rounded,
                            color: Colors.white,
                          ),
                          backgroundColor: lightUberTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 70,
                        left: 20,
                        child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.arrow_back_sharp,
                                color: lightUberTheme.primaryColor)),
                      ),
                    ],
                    if (showRoute)
                      Positioned(
                        top: 70,
                        left: 20,
                        child: IconButton(
                            onPressed: () async {
                              final mapBloc = BlocProvider.of<MapBloc>(context);
                              mapBloc.clearMap();
                              setState(() {
                                showRoute = false;
                              });
                            },
                            icon: Icon(Icons.arrow_back_ios_new,
                                color: lightUberTheme.primaryColor)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<int?> obtenerClienteIdPorUserId(int userId) async {
    var url = Uri.parse('http://174.138.68.210/usuarios/talleres/');

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> talleres = json.decode(response.body);
        // Encuentra el cliente con el userId correspondiente
        print('talleres  $talleres');
        var taller = talleres.firstWhere(
          (taller) => taller['user'] == userId,
          orElse: () => null,
        );
        return taller != null ? taller['id'] : null;
      } else {
        print('Error al obtener la lista de talleres: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener la lista de clientes: $e');
      return null;
    }
  }
}
