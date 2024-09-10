import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:mapas_api/models/models.dart';
import 'package:mapas_api/search/search_destination_delegate.dart';

class SearchBarMap extends StatelessWidget {
  const SearchBarMap({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(builder: (context, state) {
      return state.displayManualMarker
          ? const SizedBox()
          : FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: const _SearchBarMapBody());
    });
  }
}

class _SearchBarMapBody extends StatelessWidget {
  const _SearchBarMapBody();
  void onSearchResults(BuildContext context, SearchResult result) async {
    final searchBloc = BlocProvider.of<SearchBloc>(context);
    final mapBloc = BlocProvider.of<MapBloc>(context);
    final locationBloc = BlocProvider.of<LocationBloc>(context);
    if (result.manual == true) {
      searchBloc.add(OnActivateManualMarkerEvent());
      return;
    }
    if (result.position != null) {
      final destination = await searchBloc.getCoorsStartToEnd(
          locationBloc.state.lastKnownLocation!, result.position!);
      await mapBloc.drawRoutePolyline(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, mapstate) {
          final mapBloc = BlocProvider.of<MapBloc>(context);
          return Container(
            margin: const EdgeInsets.only(top: 10),
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                final result = await showSearch(
                    context: context, delegate: SearchDestinationDelegate());
                if (result == null) return;
                onSearchResults(context, result);
              },
              child: FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 5),
                        )
                      ]),
                  child: Text(
                    mapBloc.addesDestination ?? '¿A dónde quieres ir?',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 114, 111, 111),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
