import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:mapas_api/screens/client/loading_client_screen.dart';
import 'package:mapas_api/widgets/image_picker.dart';
import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:mapas_api/themes/light_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/src/source.dart' as audio;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

late Timer timer;

enum ButtonState { idle, recording, paused, playing }

class AssistanceRequestScreen extends StatefulWidget {
  const AssistanceRequestScreen({Key? key}) : super(key: key);

  @override
  _AssistanceRequestScreenState createState() =>
      _AssistanceRequestScreenState();
}

class _AssistanceRequestScreenState extends State<AssistanceRequestScreen> {
  TextEditingController descripcionController = TextEditingController();
  String? tipoProblemaSeleccionado;
  //grabar audio
  ButtonState buttonState = ButtonState.idle;
  bool hasRecorded = false;
  bool isRecording = false;
  Stopwatch stopwatch = Stopwatch();
  String? audioPath = '';
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  Duration audioDuration = const Duration(seconds: 0);
  bool isTextFieldEnabled = true;
  bool isPlaying = false;
  //
  String? nombre;
  String? fotoPerfil;
  double? valoracion;
  List<Map<String, dynamic>> dropdownItems = [
    {'value': 'bateria', 'label': 'Problemas con la batería'},
    {'value': 'llanta_pinchada', 'label': 'Se pinchó alguna llanta'},
    {
      'value': 'sin_combustible',
      'label': 'El vehículo se queda sin combustible'
    },
    {'value': 'no_arranca', 'label': 'El vehículo no arranca'},
    {'value': 'pierde_llave', 'label': 'Perder la llave del vehículo'},
    {'value': 'llave_adentro', 'label': 'Dejar llave dentro del vehículo'},
    {'value': 'otros', 'label': 'Otros'},
  ];
  Color primaryColor = lightUberTheme.primaryColor;
  //imagenes
  final List<File> _selectedImages = [];
  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  void _addNewImage(File image) {
    setState(() {
      _selectedImages.add(image);
    });
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
        });
        stopwatch.start();
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(
              () {}); // Reconstruir para actualizar el tiempo mostrado en la UI.
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      if (path != null) {
        audioDuration =
            stopwatch.elapsed; // Guarda la duración antes de resetear
        setState(() {
          isRecording = false;
          audioPath = path;
          hasRecorded = true; // Indica que hay una grabación
          buttonState = ButtonState.idle; // Restablece el estado del botón
        });
        stopwatch.stop();
        stopwatch.reset();
        timer.cancel();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void cancelar() {
    if (audioPath != null && File(audioPath!).existsSync()) {
      File(audioPath!).deleteSync();
    }
    setState(() {
      audioPath = '';
      audioDuration = Duration.zero;
      hasRecorded = false;
      isTextFieldEnabled = true;
      isPlaying = false; // Asegúrate de que no esté en estado de reproducción
      buttonState = ButtonState.idle; // Restablece el estado del botón
    });
  }

  Future<void> playRecording() async {
    try {
      audio.Source urlSource = UrlSource(audioPath!);
      print('este es el url $urlSource');
      await audioPlayer.play(urlSource);
      setState(() {
        isPlaying = true;
        buttonState = ButtonState
            .playing; // Actualiza el estado para reflejar que está reproduciendo
      });
    } catch (e) {
      print('ERROR $e');
    }
  }

  void pauseRecording() {
    audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> guardarAudioLocalmente(File audioFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${audioFile.path.split('/').last}';
      await audioFile.copy(newPath);
      return newPath; // Devuelve la ruta del archivo guardado
    } catch (e) {
      print('Error al guardar el archivo de audio: $e');
      return null;
    }
  }

  Future<int?> obtenerClienteIdPorUserId(int userId) async {
    var url = Uri.parse('http://174.138.68.210/usuarios/clientes/');

    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> clientes = json.decode(response.body);
        // Encuentra el cliente con el userId correspondiente
        var cliente = clientes.firstWhere(
          (cliente) => cliente['user'] == userId,
          orElse: () => null,
        );
        return cliente != null ? cliente['id'] : null;
      } else {
        print('Error al obtener la lista de clientes: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener la lista de clientes: $e');
      return null;
    }
  }

  Future<void> enviarSolicitudAsistencia({
    required String tipoProblema,
    required List<File> imagenes,
  }) async {
    String descripcion = descripcionController.text;
    File? audio = audioPath != null ? File(audioPath!) : null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final clienteId = await obtenerClienteIdPorUserId(userId ?? 0);

    if (clienteId == null) {
      print('No se pudo obtener el ID del cliente.');
      return;
    }
    // Obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition();
    var uri = Uri.parse(
        'http://174.138.68.210/solicitudes_asistencia/solicitudes-asistencia/');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cliente'] = clienteId.toString()
      ..fields['latitud'] = position.latitude.toString()
      ..fields['longitud'] = position.longitude.toString()
      ..fields['tipo_problema'] = tipoProblema
      ..fields['descripcion'] = descripcion;

    if (audio != null) {
      var audioMultipartFile = await http.MultipartFile.fromPath(
          'audio', // Nombre del campo para el audio
          audio.path,
          contentType: MediaType.parse('audio/m4a'));
      request.files.add(audioMultipartFile);
    }
    for (var imagen in _selectedImages) {
      var imageMultipartFile = await http.MultipartFile.fromPath(
        'imagenes', // El nombre del campo para las imágenes
        imagen.path,
        contentType: MediaType.parse(
            'image/jpeg'), // Si necesitas especificar el tipo de contenido
      );
      request.files.add(imageMultipartFile);
    }
    print('Campos a enviar: ${request.fields}');
    print(
        'Archivos a enviar: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}');

    try {
      var response = await request.send();

      // Si la solicitud fue exitosa, imprime un mensaje de éxito
      if (response.statusCode == 201) {
        print('Solicitud enviada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia Vehicular enviada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si la solicitud falló, intenta leer el cuerpo de la respuesta para obtener el mensaje de error
        String responseBody = await response.stream.bytesToString();
        print('Error al enviar la solicitud: ${response.statusCode}');
        print('Detalles del error: $responseBody');
      }
    } catch (e) {
      // Si hubo un error en el envío de la solicitud, imprime el error
      print('Error al enviar la solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Vuelve a la pantalla anterior
          },
        ),
        title: const Text('Solicitudes de Asistencia'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tipo de problema',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                items: dropdownItems
                    .map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    tipoProblemaSeleccionado = newValue;
                  });
                },
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 10),
              _buildRecordButton(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ImagePickerWidget(onImagePicked: _addNewImage);
                    },
                  );
                },
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
                label: const Text(
                  'Subir Fotos',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              // TODO: Implement map view showing current location
              ElevatedButton(
                onPressed: () async {
                  await enviarSolicitudAsistencia(
                      tipoProblema: tipoProblemaSeleccionado!,
                      imagenes: _selectedImages);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) =>
                            const ClienteLoadingScreen()), // Reemplaza PantallaDeInicio con el widget de tu pantalla de inicio
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Enviar Solicitud',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              /*Center(
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% del ancho de la pantalla
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TallerLoadingScreen3(
                            solicitudId: 86,
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
              ),*/
              const SizedBox(
                height: 10,
              ),
              GridView.builder(
                shrinkWrap:
                    true, // Esto es crucial para que funcione dentro de un SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Evita que el GridView tenga su propio scroll
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (BuildContext context, int index) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor, // Color primario del tema
                          borderRadius: BorderRadius.circular(
                              30), // Radio de la esquina redondeada
                        ),
                        child: IconButton(
                          iconSize: 20, // Tamaño del icono más pequeño
                          padding: const EdgeInsets.all(
                              5), // Padding más pequeño para reducir el tamaño total
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedImages.removeAt(
                                  index); // Elimina la imagen de la lista
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    if (isRecording) {
      String displayTime =
          '${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      return Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centrar en la pantalla
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              await stopRecording();
            },
            icon: const Icon(Icons.stop, color: Colors.white),
            label: Text(
              'Detener ($displayTime)',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          if (stopwatch
              .isRunning) // Si quieres mostrar el tiempo transcurrido en tiempo real
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                displayTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      );
    } else if (hasRecorded && !isPlaying) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center, // Centrar los iconos
        children: [
          ElevatedButton.icon(
            onPressed: playRecording,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text(
              'Reproducir Grabación',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 10), // Espacio entre botones
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              cancelar();
              setState(() {
                hasRecorded = false;
                // Restablece otros estados si es necesario
              });
            },
          ),
        ],
      );
    } else if (isPlaying) {
      return ElevatedButton.icon(
        onPressed: pauseRecording,
        icon: const Icon(Icons.pause, color: Colors.white),
        label:
            const Text('Pausar Reproducción', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor),
      );
    } else {
      // Botón para iniciar la grabación
      return ElevatedButton.icon(
        onPressed: startRecording,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text(
          'Grabar audio de voz',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }
}
