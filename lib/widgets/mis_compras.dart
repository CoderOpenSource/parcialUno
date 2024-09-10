import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/reserva_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SettingsView2 extends StatelessWidget {
  const SettingsView2({Key? key}) : super(key: key);

  Future<List<dynamic>> fetchTransacciones() async {
    final prefs = await SharedPreferences.getInstance();
    final String userIdString = prefs.getString('userId') ??
        '0'; // Asumimos '0' como valor por defecto si no existe
    int userId = int.tryParse(userIdString) ??
        0; // Convertir a entero, o 0 si no es un número válido

    final response = await http
        .get(Uri.parse('http://137.184.190.92/transacciones/transacciones/'));
    if (response.statusCode == 200) {
      List<dynamic> allTransacciones = json.decode(response.body);
      // Filtrar las transacciones donde el campo usuario sea igual a userId
      List<dynamic> filteredTransacciones =
          allTransacciones.where((transaccion) {
        // Asumimos que el campo 'usuario' en la transacción también es un entero
        return transaccion['usuario'] == userId;
      }).toList();
      return filteredTransacciones;
    } else {
      throw Exception('Failed to load transacciones');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text("Compras realizadas",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchTransacciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No hay transacciones disponibles.'));
          } else {
            final transacciones = snapshot.data!;
            return ListView.builder(
              itemCount: transacciones.length,
              itemBuilder: (context, index) {
                final transaccion = transacciones[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text('Transacción No. ${transaccion['id']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Fecha de compra: ${formatReservaDate(transaccion['fecha'].toString())}'),
                          Text(
                              'Tipo de pago: ${transaccion['tipo_pago'] == 2 ? 'Pago en Línea' : 'Otro tipo'}'),
                        ],
                      ),
                      trailing: Image.network(
                        'https://res.cloudinary.com/dkpuiyovk/image/upload/v1704291994/icons8-raya-500_zbrsqc.png',
                        width: 100, // Puedes ajustar el ancho según necesites
                        fit: BoxFit
                            .cover, // Esto asegura que la imagen mantenga sus proporciones
                      ),
                      onTap: () {
                        // Acción al tocar la transacción, si es necesario
                      },
                    ),
                    Divider(), // Divider widget added here
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
