import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:mapas_api/ui/ui.dart';

class BtnCurrentLocation extends StatelessWidget {
  const BtnCurrentLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final locationBloc = BlocProvider.of<LocationBloc>(context);
    final mapBloc = BlocProvider.of<MapBloc>(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: CircleAvatar(
        backgroundColor: lightUberTheme.primaryColor,
        maxRadius: 25,
        child: IconButton(
          icon: const Icon(
            Icons.my_location_outlined,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            final userLocation = locationBloc.state.lastKnownLocation;

            if (userLocation == null) {
              final snack =
                  CustomSnackbar(message: 'No hay ubicación en este momento');
              ScaffoldMessenger.of(context).showSnackBar(snack);
              return;
            }
            mapBloc.moveCamera(userLocation);
          },
        ),
      ),
    );
  }
}
