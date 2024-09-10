import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/themes/light_theme.dart';

class BtnToggleUserRoute extends StatelessWidget {
  const BtnToggleUserRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final mapBloc = BlocProvider.of<MapBloc>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: CircleAvatar(
          backgroundColor: lightUberTheme.primaryColor,
          maxRadius: 25,
          child: IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              mapBloc.add(OnToggleUserRoute());
            },
          )),
    );
  }
}
