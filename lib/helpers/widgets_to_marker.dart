import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapas_api/markers/markers.dart';

Future<BitmapDescriptor> getStartCustomMarker(
    int minutes, String destination) async {
  final recoder = ui.PictureRecorder();
  final canvas = ui.Canvas(recoder);
  const size = ui.Size(350, 150);

  final startMarker =
      StartMarkerPainter(minutes: minutes, destination: destination);
  startMarker.paint(canvas, size);

  final picture = recoder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

Future<BitmapDescriptor> getEndCustomMarker(
    int kilometers, String destination) async {
  final recoder = ui.PictureRecorder();
  final canvas = ui.Canvas(recoder);
  const size = ui.Size(350, 150);

  final startMarker =
      EndMarkerPainter(kilometers: kilometers, destination: destination);
  startMarker.paint(canvas, size);

  final picture = recoder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

Future<BitmapDescriptor> createCustomMarkerBitmap() async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()
    ..color = Colors.black; // Color del contorno del marcador

  // Define el tamaño del marcador
  const double width = 80;
  const double height = 100;

  // Dibuja el contorno del marcador
  Path path = Path()
    ..addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: const Offset(width / 2, height / 2),
          width: width,
          height: height),
      topLeft: const Radius.circular(width / 2),
      topRight: const Radius.circular(width / 2),
      bottomLeft: const Radius.circular(width / 6),
      bottomRight: const Radius.circular(width / 6),
    ));

  // Crea la punta del marcador
  path.moveTo(width / 2, height * 0.75);
  path.lineTo(width / 2, height);
  path.lineTo(width / 4, height * 0.75);
  path.close();

  canvas.drawPath(path, paint);

  // Dibuja el círculo interior
  paint.color = Colors.white; // Color del interior del marcador
  canvas.drawCircle(
    const Offset(width / 2, height / 3),
    width / 4,
    paint,
  );

  // Finaliza el dibujo y convierte en imagen
  final img = await pictureRecorder
      .endRecording()
      .toImage(width.toInt(), height.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}
