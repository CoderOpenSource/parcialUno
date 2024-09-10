import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/helpers/show_loading_message.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:mapas_api/views/views.dart';
import 'package:mapas_api/widgets/btn_toggle_user_route.dart';
import 'package:mapas_api/widgets/widgets.dart';

class PostulacionMapScreen extends StatefulWidget {
  final int tallerId;
  const PostulacionMapScreen({Key? key, required this.tallerId})
      : super(key: key);

  @override
  State<PostulacionMapScreen> createState() => _PostulacionMapScreenState();
}

class _PostulacionMapScreenState extends State<PostulacionMapScreen> {
  late LocationBloc locationBloc;
  Map<String, dynamic> solicitudData = {};

  bool showRoute = false;
  @override
  void initState() {
    super.initState();

    locationBloc = BlocProvider.of<LocationBloc>(context);
    // locationBloc.getCurrentPosition();
    locationBloc.startFollowingUser();
    fetchSolicitud();
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
            'http://165.227.68.145/sucursales/sucursales/${widget.tallerId}'),
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
              location, 'initial-location', 'Ubicación del Taller');
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
                            final start = locationBloc.state.lastKnownLocation;
                            if (start == null) return;
                            print(solicitudData);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          BtnToggleUserRoute(),
          BtnFollowUser(),
          BtnCurrentLocation(),
        ],
      ),
    );
  }
}
