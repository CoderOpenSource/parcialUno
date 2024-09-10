import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapas_api/screens/taller/loading_taller_screen2.dart';
import 'package:mapas_api/screens/taller/solicitud_detalle_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapas_api/blocs/blocs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrearPostulacionScreen extends StatefulWidget {
  final int solicitudId;
  final int clienteId;
  final int userId;

  const CrearPostulacionScreen(
      {Key? key,
      required this.solicitudId,
      required this.clienteId,
      required this.userId})
      : super(key: key);

  @override
  _CrearPostulacionScreenState createState() => _CrearPostulacionScreenState();
}

class _CrearPostulacionScreenState extends State<CrearPostulacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tiempoEstimadoController = TextEditingController();
  final _costoEstimadoController = TextEditingController();
  final _distanciaEstimadaController = TextEditingController();
  String _estadoPostulacion = 'pendiente';
  final _comentariosController = TextEditingController();
  Map<String, dynamic> solicitudData = {};
  Map<String, dynamic> tallerData = {};
  late LocationBloc locationBloc;
  LatLng? _locationTaller;
  @override
  void initState() {
    super.initState();

    locationBloc = BlocProvider.of<LocationBloc>(context);
    // locationBloc.getCurrentPosition();
    locationBloc.startFollowingUser();
    fetchSolicitudTaller();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Postulación'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListView(
            children: [
              // Aquí podrías poner otros campos relacionados con la solicitud, si es necesario
              DropdownButtonFormField<String>(
                value: _estadoPostulacion,
                onChanged: (String? newValue) {
                  setState(() {
                    _estadoPostulacion = newValue!;
                  });
                },
                items: <String>['pendiente']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Estado de la Postulación',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _tiempoEstimadoController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo Estimado',
                  border: OutlineInputBorder(),
                  disabledBorder: OutlineInputBorder(
                    // Definir el borde cuando está deshabilitado
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  labelStyle: TextStyle(
                    // Estilo del texto cuando está deshabilitado
                    color:
                        Colors.black, // Usa el color que quieras para el texto
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tiempo estimado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _distanciaEstimadaController,
                decoration: const InputDecoration(
                  labelText: 'Distancia Estimada',
                  border: OutlineInputBorder(),
                  disabledBorder: OutlineInputBorder(
                    // Definir el borde cuando está deshabilitado
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  labelStyle: TextStyle(
                    // Estilo del texto cuando está deshabilitado
                    color:
                        Colors.black, // Usa el color que quieras para el texto
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la distancia estimada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _costoEstimadoController,
                decoration: const InputDecoration(
                  labelText: 'Costo Estimado',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el costo estimado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _comentariosController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Suponiendo que tienes controladores de texto para cada uno de estos valores
                    String tiempoEstimado = _tiempoEstimadoController.text;
                    double costoEstimado = double.parse(_costoEstimadoController
                        .text); // Asegúrate de que sea convertible a double
                    String estadoPostulacion =
                        _estadoPostulacion; // O el valor que corresponda
                    String comentarios = _comentariosController.text;
                    int solicitudId =
                        widget.solicitudId; // Suponiendo que tienes este valor
                    int usuarioId = widget
                        .userId; // Debes obtener este valor de alguna parte
                    String distanciaEstimada =
                        _distanciaEstimadaController.text;
                    // Aquí llamas a la función enviarPostulacion
                    try {
                      await enviarPostulacion(
                        tiempoEstimado: tiempoEstimado,
                        costoEstimado: costoEstimado,
                        estadoPostulacion: estadoPostulacion,
                        comentarios: comentarios,
                        solicitudId: solicitudId,
                        usuarioId: usuarioId,
                        distanciaEstimada: distanciaEstimada,
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) =>
                                const TallerLoadingScreen2()), // Reemplaza PantallaDeInicio con el widget de tu pantalla de inicio
                        (Route<dynamic> route) => false,
                      );
                      // Si todo va bien, puedes mostrar un mensaje de éxito o actualizar la UI
                    } catch (e) {
                      // Si algo sale mal, puedes mostrar un mensaje de error
                      print('Error al enviar la postulación: $e');
                    }
                  }
                },
                child: const Text(
                  'Crear Postulación',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 10.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolicitudDetalleScreen(
                        solicitudId: widget.solicitudId,
                        clienteId: widget.userId,
                        aceptado: true,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Ver Solicitud',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchSolicitudTaller() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      print('usuario id $userId');
      final tallerId = await obtenerClienteIdPorUserId(userId ?? 0);
      print('taller id $tallerId');
      final solicitudResponse = await http.get(
        Uri.parse('http://174.138.68.210/usuarios/talleres/$tallerId/'),
      );

      if (solicitudResponse.statusCode == 200) {
        final data = json.decode(solicitudResponse.body);
        setState(() {
          tallerData = data;
        });

        // Asegúrate de que latitud y longitud están disponibles
        print('taller data $tallerData');
        if (tallerData.containsKey('latitud') &&
            tallerData.containsKey('longitud')) {
          _locationTaller =
              LatLng(tallerData['latitud'], tallerData['longitud']);
          fetchSolicitud();
        }
      } else {
        print('Error al obtener la solicitud: ${solicitudResponse.statusCode}');
      }
    } catch (e) {
      print('Error al hacer fetch de la solicitud: $e');
    }
  }

  Future<void> fetchSolicitud() async {
    print('hola mundo');
    final searchBloc = BlocProvider.of<SearchBloc>(context);
    print('ESTA ES LA ID DE LA SOLICITUD ${widget.solicitudId}');
    final solicitudResponse = await http.get(
      Uri.parse(
          'http://174.138.68.210/solicitudes_asistencia/solicitudes-asistencia/${widget.solicitudId}/'),
    );
    print('f en la vida xd');
    if (solicitudResponse.statusCode == 200) {
      final data = json.decode(solicitudResponse.body);
      setState(() {
        solicitudData = data;
        print('solicitud data $solicitudData');
      });

      // Asegúrate de que latitud y longitud están disponibles
      if (solicitudData.containsKey('latitud') &&
          solicitudData.containsKey('longitud')) {
        print('dentro');
        final start =
            LatLng(solicitudData['latitud'], solicitudData['longitud']);
        final end = _locationTaller!;

        final destination = await searchBloc.getCoorsStartToEnd(start, end);
        print('Ubicación Inicial: $start');
        print('Ubicacion Final: $end');
        _tiempoEstimadoController.text =
            "${(destination.duration / 60).floorToDouble().toInt()} Minutos";
        _distanciaEstimadaController.text =
            '${(destination.distance / 1000).toStringAsFixed(2)} Kms';
      } else {
        print('Error al obtener la solicitud: ${solicitudResponse.statusCode}');
      }
    }
  }

  Future<void> enviarPostulacion({
    required String tiempoEstimado,
    required double costoEstimado, // Usa double si necesitas decimales
    required String estadoPostulacion,
    required String comentarios,
    required int solicitudId,
    required int usuarioId,
    required String distanciaEstimada,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    print('usuario id $userId');
    final tallerId = await obtenerClienteIdPorUserId(userId ?? 0);

    if (tallerId == null) {
      print('No se pudo obtener el ID del cliente.');
      return;
    }
    final url = Uri.parse(
        'http://174.138.68.210/solicitudes_asistencia/postulaciones/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tiempo_estimado': tiempoEstimado,
        'costo_estimado': costoEstimado, // Aquí envías el costo como un número
        'estado_postulacion': estadoPostulacion,
        'comentarios': comentarios,
        'solicitud': solicitudId,
        'taller': tallerId,
        'usuario_id': usuarioId,
        'distancia_estimada': distanciaEstimada,
      }),
    );

    if (response.statusCode == 201) {
      print('Solicitud enviada con éxito');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia creada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Error al enviar la postulación: ${response.body}');
    }
  }

  Future<int?> obtenerClienteIdPorUserId(int userId) async {
    var url = Uri.parse('http://174.138.68.210/usuarios/talleres/');

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> talleres = json.decode(response.body);
        // Encuentra el cliente con el userId correspondiente
        print('talleres  $talleres');
        var taller = talleres.firstWhere(
          (taller) => taller['user'] == userId,
          orElse: () => null,
        );
        return taller != null ? taller['id'] : null;
      } else {
        print('Error al obtener la lista de talleres: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener la lista de clientes: $e');
      return null;
    }
  }
}
