import 'package:google_maps_flutter/google_maps_flutter.dart';

class GlobalData {
  static final GlobalData _singleton = GlobalData._internal();

  factory GlobalData() {
    return _singleton;
  }

  GlobalData._internal();

  // Aquí está tu variable booleana
  bool marcarUbicacion = true;
  LatLng? ubicacion_marcador;
}
