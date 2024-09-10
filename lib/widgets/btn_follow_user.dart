import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/themes/light_theme.dart';

class BtnFollowUser extends StatelessWidget {
  const BtnFollowUser({super.key});

  @override
  Widget build(BuildContext context) {
    final mapBloc = BlocProvider.of<MapBloc>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: CircleAvatar(
        backgroundColor: lightUberTheme.primaryColor,
        maxRadius: 25,
        child: BlocBuilder<MapBloc, MapState>(builder: (context, state) {
          return IconButton(
            icon: Icon(
              state.isFollowingUser
                  ? Icons.directions_run_rounded
                  : Icons.hail_rounded,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () {
              mapBloc.add(OnStartFollowingUserEvent());
            },
          );
        }),
      ),
    );
  }
}
