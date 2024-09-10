import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PantallaPagoQR extends StatefulWidget {
  final int tipoPagoId;

  const PantallaPagoQR({Key? key, required this.tipoPagoId}) : super(key: key);

  @override
  _PantallaPagoQRState createState() => _PantallaPagoQRState();
}

class _PantallaPagoQRState extends State<PantallaPagoQR> {
  String _nombreTipoPago = '';
  String _urlImagenQR = '';

  @override
  void initState() {
    super.initState();
    _obtenerDetallesTipoPago();
  }

  Future<void> _obtenerDetallesTipoPago() async {
    final uri = Uri.parse(
        'http://165.227.68.145/transacciones/tipos_pago/${widget.tipoPagoId}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _nombreTipoPago = data['nombre'];
        _urlImagenQR = data['imagen_qr'];
      });
    } else {
      // Manejo de errores
      print('Solicitud fallida con estado: ${response.statusCode}.');
    }
  }

  Future<void> descargarYGaurdarImagen(String url) async {
    // Descargar la imagen
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Obtener un directorio temporal donde guardar la imagen
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/descarga_imagen.jpg';
      final imageFile = File(imagePath);
      // Escribir la imagen en un archivo
      await imageFile.writeAsBytes(response.bodyBytes);

      // Guardar la imagen en la galería
      final result = await ImageGallerySaver.saveFile(imagePath);
      if (result['isSuccess']) {
        print("Imagen guardada en la galería");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Imagen guardada en la galería"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      print("Error al guardar la imagen en la galería");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al guardar la imagen en la galería"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 224, 175, 236),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 59, 9, 59),
        title: Text(
          'Pago con $_nombreTipoPago',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _urlImagenQR.isNotEmpty
                ? Image.network(_urlImagenQR)
                : const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 59, 9, 59),
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5, // Agrega esta línea para dar sombra al botón
              ),
              child: const Text(
                'Descargar QR',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                descargarYGaurdarImagen(_urlImagenQR);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 59, 9, 59),
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5, // Agrega esta línea para dar sombra al botón
              ),
              child: const Text(
                'Enviar comprobante por WhatsApp',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _abrirWhatsApp(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirWhatsApp(BuildContext context) async {
    const String numeroWhatsApp = '+59179068578'; // Número de WhatsApp
    const String mensaje = 'Aquí está el comprobante de mi pago';
    final Uri uriWhatsApp =
        Uri.parse("https://wa.me/$numeroWhatsApp?text=$mensaje");

    if (await canLaunchUrl(uriWhatsApp)) {
      await launchUrl(uriWhatsApp);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
    }
  }
}
