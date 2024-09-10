import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/screens/map_screen.dart';
import 'package:mapas_api/screens/screens.dart';

class TallerLoadingScreen3 extends StatelessWidget {
  final int solicitudId;
  const TallerLoadingScreen3({Key? key, required this.solicitudId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<GpsBloc, GpsState>(
      builder: (context, state) {
        return state.isAllGranted
            ? MapScreen(
                solicitudId: solicitudId,
              )
            : const GpsAccessScreen();
      },
    ));
  }
}
