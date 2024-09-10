import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/taller/loading_taller_screen4.dart';

class PostulacionDetalleScreen extends StatefulWidget {
  final int postulacionId;
  final int tallerId;
  final bool aceptado;

  const PostulacionDetalleScreen(
      {Key? key,
      required this.postulacionId,
      required this.tallerId,
      required this.aceptado})
      : super(key: key);

  @override
  _PostulacionDetalleScreenState createState() =>
      _PostulacionDetalleScreenState();
}

class _PostulacionDetalleScreenState extends State<PostulacionDetalleScreen> {
  late Future<dynamic> solicitudData;
  bool isProcessing = false;
  String _firstName = '';
  int? _idUsuario;

  @override
  void initState() {
    super.initState();
    solicitudData = fetchSolicitud();
    obtenerYMostrarDatosDelTaller(widget.tallerId);
  }

  Future<void> obtenerYMostrarDatosDelTaller(int tallerId) async {
    final String clienteUrl =
        'http://174.138.68.210/usuarios/talleres/$tallerId';
    const String usuarioUrl = 'http://174.138.68.210/usuarios/users/';

    try {
      // Obtener los detalles del cliente
      final clienteResponse = await http.get(Uri.parse(clienteUrl));
      if (clienteResponse.statusCode == 200) {
        final clienteData = json.decode(clienteResponse.body);
        final userId = clienteData[
            'user']; // Asumiendo que 'user' es un campo en la respuesta

        // Con el userId, obtener los detalles del usuario
        final usuarioResponse = await http.get(Uri.parse('$usuarioUrl$userId'));
        if (usuarioResponse.statusCode == 200) {
          final usuarioData = json.decode(usuarioResponse.body);

          // Aquí tienes los datos del usuario, puedes mostrarlos en la pantalla
          print(
              'El cliente ${usuarioData['first_name']} te ha enviado una postulación');
          setState(() {
            // Aquí actualizamos el estado del widget con los nuevos datos
            _firstName = usuarioData['first_name'];
            _idUsuario = usuarioData['id'];
          });
          // Actualiza el estado de tu aplicación con esta información
          // Por ejemplo, usando setState() si estás en un StatefulWidget
          // o actualizando tu modelo de datos si estás usando algún tipo de gestión de estado como Provider, BLoC, etc.
        } else {
          print(
              'Error al obtener los datos del usuario: ${usuarioResponse.statusCode}');
        }
      } else {
        print(
            'Error al obtener los detalles del cliente: ${clienteResponse.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud HTTP: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSolicitud() async {
    final solicitudResponse = await http.get(
      Uri.parse(
          'http://174.138.68.210/solicitudes_asistencia/postulaciones/${widget.postulacionId}'),
    );

    if (solicitudResponse.statusCode == 200) {
      print(
          'Postulacion: ${solicitudResponse.body}'); // Imprime la respuesta de la solicitud

      return {
        'postulacion': jsonDecode(solicitudResponse.body),
      };
    } else {
      throw Exception('Failed to load imagenes');
    }
  }

  void handleAccept() {
    // Implementar lógica para aceptar solicitud
    setState(() {
      isProcessing = true;
    });

    // Simulación de una llamada a la API y espera
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isProcessing = false;
      });
    });
  }

  void handleReject() {
    // Implementar lógica para rechazar solicitud
    setState(() {
      isProcessing = true;
    });

    // Simulación de una llamada a la API y espera
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isProcessing = false;
      });
      // Aquí puedes cerrar la pantalla o redireccionar al usuario
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la Postulacion'),
      ),
      body: FutureBuilder<dynamic>(
        future: solicitudData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              isProcessing) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return buildSolicitudData(context, snapshot.data);
          } else {
            return const Center(child: Text('No hay datos disponibles.'));
          }
        },
      ),
      bottomNavigationBar: isProcessing
          ? const LinearProgressIndicator()
          : widget.aceptado // Aquí utilizas la propiedad aceptado para determinar qué mostrar
              ? const SizedBox.shrink() // Si aceptado es true, no se muestra nada
              : Padding(
                  // Si aceptado es false, se muestra el Padding con los botones
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handleAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text("Aceptar",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handleReject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text("Rechazar",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildSolicitudData(BuildContext context, dynamic data) {
    final Color primaryColor =
        Theme.of(context).primaryColor; // Color primario del tema
    final TextStyle titleStyle = Theme.of(context)
        .textTheme
        .titleLarge!
        .copyWith(
            color: primaryColor,
            fontWeight:
                FontWeight.bold); // Estilo personalizado para los títulos
    final TextStyle subtitleStyle = Theme.of(context)
        .textTheme
        .titleMedium!
        .copyWith(
            color: primaryColor); // Estilo personalizado para los subtítulos
    final String tiempoEstimadoLabel = data['postulacion']['tiempo_estimado'];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_firstName.isNotEmpty) ...[
              Text(
                'El Taller: $_firstName te ha enviado una Postulación',
                style:
                    titleStyle, // Usando el estilo personalizado para el título
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'El Mecanico llegaria en: $tiempoEstimadoLabel',
              style: titleStyle,
            ),
            const SizedBox(height: 20),
            Text(
              'El taller se encuentra a una distancia de : ${data['postulacion']['distancia_estimada']}',
              style: titleStyle,
            ),
            const SizedBox(height: 20),
            Text(
              'Ubicación recibida:',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.8, // 80% del ancho de la pantalla
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TallerLoadingScreen4(
                          tallerId: widget.tallerId,
                          // Aquí pasas los parámetros que necesita LocationScreen, si los hay.
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(
                    Icons.location_on, // Icono de ubicación
                    color: Colors.white,
                    size: 25,
                  ),
                  label: const Text(
                    'Ver Ubicación',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Costo Estimado: ${data['postulacion']['costo_estimado']} Bs',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Comentarios Adicionales: ${data['postulacion']['comentarios']}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
