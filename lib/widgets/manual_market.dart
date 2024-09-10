import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/helpers/show_loading_message.dart';
import 'package:mapas_api/models/global_marcar_ubicacion.dart';
import 'package:mapas_api/themes/light_theme.dart';

class ManualMarker extends StatelessWidget {
  const ManualMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(builder: (context, state) {
      if (state.displayManualMarker) {
        return const _ManualMarkerBody();
      } else {
        return const SizedBox();
      }
    });
  }
}

class _ManualMarkerBody extends StatelessWidget {
  const _ManualMarkerBody();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final searchBloc = BlocProvider.of<SearchBloc>(context);
    final locationBloc = BlocProvider.of<LocationBloc>(context);
    final mapBloc = BlocProvider.of<MapBloc>(context);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(children: [
        const Positioned(top: 70, left: 20, child: _btnBackButton()),
        Center(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: BounceInDown(
                from: 100,
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 60,
                )),
          ),
        ),
        if (GlobalData().marcarUbicacion)
          Positioned(
              bottom: 70,
              left: 40,
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: MaterialButton(
                    color: Colors.black,
                    minWidth: size.width - 120,
                    height: 50,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    child: const Text(
                      'Confirmar destino',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w300),
                    ),
                    onPressed: () async {
                      final start = locationBloc.state.lastKnownLocation;
                      if (start == null) return;
                      final end = mapBloc.mapCenter;
                      if (end == null) return;
                      showLoadingMessage(context);
                      final destination =
                          await searchBloc.getCoorsStartToEnd(start, end);
                      await mapBloc.drawRoutePolyline(destination);
                      searchBloc.add(OnDeactivateManualMarkerEvent());
                      Navigator.pop(context);
                    }),
              )),
        if (!GlobalData().marcarUbicacion)
          Positioned(
              bottom: 70,
              left: 40,
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: MaterialButton(
                    color: lightUberTheme.primaryColor,
                    minWidth: size.width - 120,
                    height: 50,
                    shape: const StadiumBorder(),
                    elevation: 0,
                    child: const Text(
                      'Confirmar Ubicación',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w300),
                    ),
                    onPressed: () async {
                      final end = mapBloc.mapCenter;
                      if (end == null) return;
                      searchBloc.add(OnDeactivateManualMarkerEvent());
                      GlobalData().marcarUbicacion = true;
                      GlobalData().ubicacion_marcador = end;
                      Navigator.pop(context);
                    }),
              ))
      ]),
    );
  }
}

class _btnBackButton extends StatelessWidget {
  const _btnBackButton();

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 300),
      child: CircleAvatar(
        maxRadius: 30,
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () {
            BlocProvider.of<SearchBloc>(context)
                .add(OnDeactivateManualMarkerEvent());
          },
        ),
      ),
    );
  }
}
