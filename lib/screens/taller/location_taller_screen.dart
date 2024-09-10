import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/models/global_marcar_ubicacion.dart';
import 'package:mapas_api/themes/light_theme.dart';

import 'package:mapas_api/views/views.dart';

import 'package:mapas_api/widgets/btn_toggle_user_route.dart';

import 'package:mapas_api/widgets/widgets.dart';

class LocationTallerScreen extends StatefulWidget {
  const LocationTallerScreen({Key? key}) : super(key: key);

  @override
  State<LocationTallerScreen> createState() => _LocationTallerScreenState();
}

class _LocationTallerScreenState extends State<LocationTallerScreen>
    with SingleTickerProviderStateMixin {
  late LocationBloc locationBloc;
  Position? position;
  @override
  void initState() {
    super.initState();

    locationBloc = BlocProvider.of<LocationBloc>(context);

    locationBloc.startFollowingUser();
  }

  @override
  void dispose() {
    locationBloc.stopFollowingUser();

    super.dispose();
  }

  Future<void> _obtenerYRegresarUbicacionActual(BuildContext context) async {
    position = await Geolocator.getCurrentPosition();
    Navigator.pop(context, LatLng(position!.latitude, position!.longitude));
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
                        if (GlobalData().marcarUbicacion)
                          Positioned(
                            bottom:
                                70, // Posición desde el fondo para el primer botón
                            left: 40, // Posición desde la izquierda
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _obtenerYRegresarUbicacionActual(context),
                              icon: const Icon(Icons.location_searching_rounded,
                                  color: Colors.white), // Ícono de ubicación
                              label: const Text(
                                'Marcar la ubicación actual',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightUberTheme
                                    .primaryColor, // Fondo de tema Uber
                              ),
                            ),
                          ),
                        if (GlobalData().marcarUbicacion)
                          Positioned(
                            bottom:
                                40, // Posición desde el fondo para el segundo botón, se reduce para ponerlo debajo del primero.
                            left: 40, // Posición desde la izquierda
                            child: ElevatedButton.icon(
                              onPressed: () {
                                GlobalData().marcarUbicacion = false;
                                setState(() {});
                                final searchBloc =
                                    BlocProvider.of<SearchBloc>(context);
                                searchBloc.add(OnActivateManualMarkerEvent());
                              },
                              icon: const Icon(Icons.location_on_outlined,
                                  color: Colors
                                      .white), // Ícono de ubicación manual
                              label: const Text(
                                'Marcar la ubicación manualmente',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightUberTheme
                                    .primaryColor, // Fondo de tema Uber
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
}
