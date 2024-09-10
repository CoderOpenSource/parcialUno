import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/screens/screens.dart';
import 'package:mapas_api/screens/taller/taller_screen.dart';

class TallerLoadingScreen2 extends StatelessWidget {
  const TallerLoadingScreen2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<GpsBloc, GpsState>(
      builder: (context, state) {
        return state.isAllGranted
            ? const TallerScreen2()
            : const GpsAccessScreen();
      },
    ));
  }
}
