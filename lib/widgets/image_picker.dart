import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImagePicked;

  const ImagePickerWidget({super.key, required this.onImagePicked});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      List<int> originalBytes = await pickedFile.readAsBytes();
      Uint8List uint8list = Uint8List.fromList(originalBytes);
      img.Image? image = img.decodeImage(uint8list);

      // Comprime la imagen
      if (image != null) {
        img.Image resizedImage = img.copyResize(image,
            width: 600, height: 600); // Cambia las dimensiones si es necesario
        Uint8List compressedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: 88));

        // Guarda los bytes comprimidos en un archivo temporal
        File tempFile =
            File('${(await getTemporaryDirectory()).path}/temp.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        setState(() {
          _image = tempFile;
          widget.onImagePicked(_image!);
        });
      } else {
        // Mostrar error si no se pudo decodificar la imagen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al decodificar la imagen.')),
        );
      }
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Por favor, selecciona una imagen',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E272E), // Azul oscuro de Messenger
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(
                Icons.camera,
                color: Color.fromARGB(255, 59, 9, 59),
              ),
              label: const Text(
                "Cámara",
                style: TextStyle(
                  color: Color(0xFF1E272E),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(
                Icons.photo_library,
                color: Color(0xFF1E272E),
              ),
              label: const Text(
                "Galería",
                style: TextStyle(
                  color: Color(0xFF1E272E),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ],
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(_image!),
          ),
      ],
    );
  }
}
