import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/taller/loading_taller_screen3.dart';
import 'package:mapas_api/screens/taller/taller_postulacion.dart';
import 'package:mapas_api/widgets/audio_widget.dart';
import 'package:photo_view/photo_view.dart';

class SolicitudDetalleScreen extends StatefulWidget {
  final int solicitudId;
  final int clienteId;
  final bool aceptado;

  const SolicitudDetalleScreen(
      {Key? key,
      required this.solicitudId,
      required this.clienteId,
      required this.aceptado})
      : super(key: key);

  @override
  _SolicitudDetalleScreenState createState() => _SolicitudDetalleScreenState();
}

class _SolicitudDetalleScreenState extends State<SolicitudDetalleScreen> {
  late Future<dynamic> solicitudData;
  bool isProcessing = false;
  String _firstName = '';
  int? _idUsuario;

  final List<Map<String, dynamic>> dropdownItems = [
    {'value': 'bateria', 'label': 'Problemas con la batería'},
    {'value': 'llanta_pinchada', 'label': 'Se pinchó alguna llanta'},
    {
      'value': 'sin_combustible',
      'label': 'El vehículo se quedó sin combustible'
    },
    {'value': 'no_arranca', 'label': 'El vehículo no arranca'},
    {'value': 'pierde_llave', 'label': 'Perdí la llave del vehículo'},
    {'value': 'llave_adentro', 'label': 'Dejé la llave dentro del vehículo'},
    {'value': 'otros', 'label': 'Otros problemas'},
  ];

  @override
  void initState() {
    super.initState();
    solicitudData = fetchSolicitud();
    obtenerYMostrarDatosDelCliente(widget.clienteId);
  }

  Future<void> obtenerYMostrarDatosDelCliente(int clienteId) async {
    final String clienteUrl =
        'http://174.138.68.210/usuarios/clientes/$clienteId/';
    const String usuarioUrl = 'http://174.138.68.210/usuarios/users/';

    try {
      // Obtener los detalles del cliente
      final clienteResponse = await http.get(Uri.parse(clienteUrl));
      if (clienteResponse.statusCode == 200) {
        final clienteData = json.decode(clienteResponse.body);
        final userId = clienteData[
            'user']; // Asumiendo que 'user' es un campo en la respuesta

        // Con el userId, obtener los detalles del usuario
        final usuarioResponse =
            await http.get(Uri.parse('$usuarioUrl$userId/'));
        if (usuarioResponse.statusCode == 200) {
          final usuarioData = json.decode(usuarioResponse.body);

          // Aquí tienes los datos del usuario, puedes mostrarlos en la pantalla
          print(
              'El cliente ${usuarioData['first_name']} ha solicitado una asistencia');
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
          'http://174.138.68.210/solicitudes_asistencia/solicitudes-asistencia/${widget.solicitudId}/'),
    );

    if (solicitudResponse.statusCode == 200) {
      print(
          'Solicitud: ${solicitudResponse.body}'); // Imprime la respuesta de la solicitud

      final imagenesResponse = await http.get(
        Uri.parse(
            'http://174.138.68.210/solicitudes_asistencia/imagenes-solicitud/'),
      );

      if (imagenesResponse.statusCode == 200) {
        print(
            'Imagenes: ${imagenesResponse.body}'); // Imprime la respuesta de las imágenes

        List<dynamic> todasLasImagenes = jsonDecode(imagenesResponse.body);
        List<dynamic> imagenesFiltradas = todasLasImagenes.where((imagen) {
          return imagen['solicitud'] == widget.solicitudId;
        }).toList();

        // Combinar los datos de la solicitud con las imágenes filtradas
        return {
          'solicitud': jsonDecode(solicitudResponse.body),
          'imagenes': imagenesFiltradas,
        };
      } else {
        throw Exception('Failed to load imagenes');
      }
    } else {
      throw Exception('Failed to load solicitud');
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
      // Redirige al usuario a la pantalla de creación de postulaciones
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CrearPostulacionScreen(
            solicitudId: widget.solicitudId,
            clienteId: widget.clienteId,
            userId: _idUsuario!,
          ),
        ),
      );
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
        title: const Text('Detalle de la Solicitud'),
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
    final String problemaLabel = dropdownItems.firstWhere(
      (item) => item['value'] == data['solicitud']['tipo_problema'],
      orElse: () => {'label': 'Problema desconocido'},
    )['label'];
    List<dynamic> imagenes = data['imagenes'] ?? [];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_firstName.isNotEmpty) ...[
              Text(
                'El Cliente: $_firstName ha solicitado una asistencia vehicular',
                style:
                    titleStyle, // Usando el estilo personalizado para el título
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Tipo de problema: $problemaLabel',
              style: titleStyle,
            ),
            const SizedBox(height: 20),
            Text(
              'Descripción: ${data['solicitud']['descripcion']}',
              style: titleStyle,
            ),
            const SizedBox(height: 20),
            Text(
              'Audio Recibido:',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            AudioMessageWidget(
              audioUrl: data['solicitud']['audio']
                  .toString()
                  .replaceFirst('http:', 'https:'),
            ),
            const SizedBox(
              height: 20,
            ),
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
                        builder: (context) => TallerLoadingScreen3(
                          solicitudId: widget.solicitudId,
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

            Text(
              'Fotos:',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 10),
// Este es el GridView.builder que construye la cuadrícula de imágenes
            GridView.builder(
              shrinkWrap:
                  true, // Usar esto para que no sea necesario definir un alto fijo
              physics:
                  const NeverScrollableScrollPhysics(), // Para desactivar el desplazamiento dentro de la GridView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Número de columnas
                crossAxisSpacing: 10, // Espacio horizontal entre las imágenes
                mainAxisSpacing: 10, // Espacio vertical entre las imágenes
              ),
              itemCount: imagenes
                  .length, // La cantidad de elementos que tiene la lista de imágenes
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _showImagePreview(context, data['imagenes'][index]['foto'],
                        data['imagenes']);
                  },
                  child: Image.network(
                    data['imagenes'][index]['foto'],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(
      BuildContext context, String initialImageUrl, List<dynamic> allImages) {
    final int initialIndex =
        allImages.indexWhere((img) => img['foto'] == initialImageUrl);
    showDialog(
      context: context,
      builder: (ctx) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
          },
          child: Container(
            color: Colors.black,
            child: PageView.builder(
              itemCount: allImages.length,
              controller: PageController(
                  initialPage:
                      initialIndex), // Controlador que define la imagen inicial
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: NetworkImage(allImages[index]['foto']),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
