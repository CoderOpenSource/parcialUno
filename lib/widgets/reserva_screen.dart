import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

void initializeTimeZones() {
  tz.initializeTimeZones();
}

class ReservaScreen extends StatefulWidget {
  const ReservaScreen({super.key});

  @override
  _ReservaScreenState createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchReservas();
  }

  Future<bool> eliminarReserva(int idReserva) async {
    final url =
        Uri.parse('http://137.184.190.92/reservas/reservas/$idReserva/');
    try {
      final response = await http.delete(url);
      return response.statusCode ==
          204; // Suponiendo que 204 es el código de estado de éxito
    } catch (e) {
      print('Error al intentar eliminar la reserva: $e');
      return false;
    }
  }

  Future<void> fetchReservas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '0';
      final response =
          await http.get(Uri.parse('http://137.184.190.92/reservas/reservas/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        List<Map<String, dynamic>> userReservas = data
            .where((reserva) => reserva['usuario'].toString() == userId)
            .toList()
            .cast<
                Map<String,
                    dynamic>>(); // Asegúrate de que es una lista de mapas.

        for (int i = 0; i < userReservas.length; i++) {
          final prodDetalleId = userReservas[i]['producto_detalle'];
          final prodResponse = await http.get(
            Uri.parse(
                'http://137.184.190.92/productos/productosdetalle/$prodDetalleId'),
          );

          if (prodResponse.statusCode == 200) {
            final prodData = json.decode(prodResponse.body);
            userReservas[i]['producto_detalle_data'] =
                prodData; // Guardar los datos del producto en una nueva clave.
          } else {
            print(
                'Solicitud para detalles del producto_detalle fallida con estado: ${prodResponse.statusCode}.');
          }
        }

        setState(() {
          displayedProducts = userReservas;
          isLoading = false;
          print('Displayed Products: $displayedProducts');
        });
      } else {
        print(
            'Solicitud de reservas fallida con estado: ${response.statusCode}.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error al obtener las reservas: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mis Reservas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Las reservas solo duran 24 horas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: displayedProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.event_note,
                          size: 60,
                          color: Color(0xFF1E272E),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No tienes reservas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E272E),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final reserva = displayedProducts[index];
                      final productoDetalle = reserva['producto_detalle_data'];
                      final primeraImagen = productoDetalle['producto']
                          ['imagenes'][0]['ruta_imagen'];
                      final precioProducto =
                          double.parse(productoDetalle['producto']['precio']);
                      final descuentoProducto = double.parse(
                          productoDetalle['producto']['descuento_porcentaje']);
                      final cantidad = reserva['cantidad'];
                      final idReserva = reserva['id'];
                      final fechaActual = DateTime.now();
                      final String fechaReservaStr = reserva['fecha_reserva'];
                      final fechaReserva = DateTime.parse(fechaReservaStr);
                      final diferenciaDias =
                          fechaActual.difference(fechaReserva).inDays;
                      final estadoReserva = diferenciaDias > 1;

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    primeraImagen,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            productoDetalle['producto']
                                                    ['nombre']
                                                .replaceAll('Ã±', 'ñ'),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                              'Fecha de reserva: ${formatReservaDate(fechaReservaStr)}'),
                                          Text('Cantidad: $cantidad'),
                                          Row(
                                            children: [
                                              const Text('Precio: '),
                                              if (descuentoProducto > 0) ...[
                                                Text(
                                                  'Bs$precioProducto ',
                                                  style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                                Text(
                                                  'Bs${calcularPrecioConDescuento(precioProducto, descuentoProducto)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'Bs$precioProducto',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                          Text(
                                            'Estado de la Reserva: ${estadoReserva ? "Expirada" : "Activa"}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: estadoReserva
                                                  ? Colors.red
                                                  : Colors
                                                      .green, // Rojo si está expirada, verde si está activa.
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'Eliminar') {
                                        _deleteReservaConfirmation(
                                            context, idReserva);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'Eliminar',
                                        child: Text('Cancelar Reserva'),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_vert),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Bs${calcularTotal()}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double calcularPrecioConDescuento(double precio, double descuentoPorcentaje) {
    return precio - (precio * descuentoPorcentaje / 100);
  }

  String formatReservaDate(String isoDate) {
    initializeTimeZones();
    try {
      // Parsear la fecha ISO 8601 a un objeto DateTime.
      DateTime dateTime = DateTime.parse(isoDate);
      // Obtener la zona horaria de Santa Cruz, Bolivia
      final location = tz.getLocation('America/La_Paz');
      // Convertir la hora UTC a la hora local de Santa Cruz, Bolivia
      final localDateTime = tz.TZDateTime.from(dateTime, location);
      // Formatear fecha a un formato legible con dos dígitos para horas y minutos.
      String formattedDate =
          "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')} ${localDateTime.day}/${localDateTime.month}/${localDateTime.year}";
      return formattedDate;
    } catch (e) {
      // Si hay un error al parsear la fecha, imprimir el error y devolver una cadena vacía o un mensaje de error.
      print('Error al formatear la fecha de reserva: $e');
      return 'Fecha inválida';
    }
  }

  double calcularTotal() {
    double total = 0.0;
    for (var reserva in displayedProducts) {
      final productoDetalle = reserva['producto_detalle_data'];
      final precio = double.parse(productoDetalle['producto']['precio']);
      final descuentoPorcentaje =
          double.parse(productoDetalle['producto']['descuento_porcentaje']);
      final cantidad = reserva['cantidad'];

      final precioFinal = descuentoPorcentaje > 0
          ? calcularPrecioConDescuento(precio, descuentoPorcentaje)
          : precio;

      total += precioFinal * cantidad;
    }
    return total;
  }

  void _deleteReservaConfirmation(BuildContext context, int idReserva) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Quieres cancelar la Reserva?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                bool eliminado = await eliminarReserva(idReserva);
                Navigator.pop(context);
                if (eliminado) {
                  fetchReservas();
                }
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
}
