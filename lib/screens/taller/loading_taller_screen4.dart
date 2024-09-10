import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/screens/screens.dart';
import 'package:mapas_api/screens/workshop/postulacion_mapa_screen.dart';

class TallerLoadingScreen4 extends StatelessWidget {
  final int tallerId;
  const TallerLoadingScreen4({Key? key, required this.tallerId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<GpsBloc, GpsState>(
      builder: (context, state) {
        return state.isAllGranted
            ? PostulacionMapScreen(tallerId: tallerId)
            : const GpsAccessScreen();
      },
    ));
  }
}
