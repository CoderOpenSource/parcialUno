import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/screens/client/cliente_screen.dart';
import 'package:mapas_api/screens/screens.dart';

class ClienteLoadingScreen extends StatelessWidget {
  const ClienteLoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<GpsBloc, GpsState>(
      builder: (context, state) {
        return state.isAllGranted
            ? const ClienteScreen()
            : const GpsAccessScreen();
      },
    ));
  }
}
