import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingConsultationsScreen extends StatefulWidget {
  @override
  _PendingConsultationsScreenState createState() =>
      _PendingConsultationsScreenState();
}

class _PendingConsultationsScreenState
    extends State<PendingConsultationsScreen> {
  late Future<List<Consultation>> consultations;
  late int userId;
  String? firstName;
  String? photoUrl;
  @override
  void initState() {
    super.initState();
    consultations = _loadUserIdAndFetchConsultations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // Aquí lo recuperamos como entero

    if (userId != null) {
      final response = await http
          .get(Uri.parse('http://161.35.16.6/usuarios/patients/$userId/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          firstName = data['user']['first_name'];
          photoUrl = data['user']['photo'];
        });
      } else {
        // Manejar error de respuesta de la API
        print('Error en la respuesta de la API: ${response.statusCode}');
      }
    } else {
      // Manejar caso donde userId no está disponible
      print('User ID no disponible en SharedPreferences');
    }
  }

  Future<List<Consultation>> _loadUserIdAndFetchConsultations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // Aquí lo recuperamos como entero
    print(userId);
    return fetchConsultations(userId!);
  }

  Future<List<Consultation>> fetchConsultations(int userId) async {
    final response = await http.get(
      Uri.parse('http://161.35.16.6/consultations/consultations/'),
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<Consultation> allConsultations = jsonResponse
          .map((consultation) => Consultation.fromJson(consultation))
          .toList();

      // Filtrar las consultas para el usuario actual
      List<Consultation> userConsultations = allConsultations
          .where((consultation) => consultation.patientId == userId)
          .toList();

      // Obtener detalles adicionales para cada consulta
      for (var consultation in userConsultations) {
        await fetchAdditionalDetails(consultation);
      }

      return userConsultations;
    } else {
      throw Exception('Failed to load consultations');
    }
  }

  Future<void> fetchAdditionalDetails(Consultation consultation) async {
    // Obtener detalles del doctor
    final doctorResponse = await http.get(
      Uri.parse(
          'http://161.35.16.6/scheduling/schedules/${consultation.scheduleId}/'),
    );

    if (doctorResponse.statusCode == 200) {
      var doctorJson = json.decode(doctorResponse.body);
      consultation.doctorName = doctorJson['doctor']['user']['first_name'] +
          ' ' +
          doctorJson['doctor']['user']['last_name'];
      consultation.scheduleTime = doctorJson['start_time'];
    } else {
      throw Exception('Failed to load doctor details');
    }

    // Obtener detalles del servicio
    final serviceResponse = await http.get(
      Uri.parse(
          'http://161.35.16.6/medical/services/${consultation.serviceId}/'),
    );

    if (serviceResponse.statusCode == 200) {
      var serviceJson = json.decode(serviceResponse.body);
      consultation.serviceName = serviceJson['name'];
    } else {
      throw Exception('Failed to load service details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consultas Pendientes'),
        backgroundColor: const Color(0xFF1E272E), // Lila oscuro
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 43, 29, 45), // Lila oscuro
              Color.fromARGB(255, 201, 187, 187), // Lila claro
            ],
          ),
        ),
        child: FutureBuilder<List<Consultation>>(
          future: consultations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white70, // Color de fondo de la tarjeta
                    margin: EdgeInsets.all(10),
                    elevation: 5, // Sombra de la tarjeta
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15), // Bordes redondeados
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      title: Text(
                        'Doctor: ${snapshot.data![index].doctorName}',
                        style: TextStyle(
                          color: Colors
                              .deepPurple[800], // Color del texto del título
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Servicio: ${snapshot.data![index].serviceName}\n'
                        'Horario: ${snapshot.data![index].scheduleTime}\n'
                        'Fecha: ${snapshot.data![index].date}',
                        style: TextStyle(
                          color: Colors
                              .black54, // Color del texto de la descripción
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E272E), // Lila oscuro
              Colors.white, // Blanco
            ],
          ),
        ),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                  color: const Color(
                      0xFF1E272E) // Lila oscuro para el DrawerHeader
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    firstName ?? 'Nombre no disponible',
                    style: const TextStyle(color: Colors.white, fontSize: 24.0),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'Home', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }),
            _buildDrawerItem(Icons.calendar_today, 'Generar Consulta Medica',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServicesScreen()),
              );
            }),
            _buildDrawerItem(Icons.schedule, 'Consultas Pendientes', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PendingConsultationsScreen()),
              );
            }),
            _buildDrawerItem(Icons.history, 'Historial Médico', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicalHistoryScreen()),
              );
            }),
            _buildCustomDrawerItem(
              Icons.local_pharmacy,
              'Farmacia',
              [
                {
                  'title': 'Productos en Oferta',
                  'onTap': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeFarmaciaScreen()),
                    );
                  },
                },
                {
                  'title': 'Productos en General',
                  'onTap': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GeneralProductsScreen()),
                    );
                  },
                },
                {
                  'title': 'Ver Carrito',
                  'onTap': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartScreen()),
                    );
                  },
                },
                {
                  'title': 'Ver Pagos Realizados',
                  'onTap': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentsScreen()),
                    );
                  },
                },
                // Agrega más opciones según sea necesario
              ],
            ),
            _buildDrawerItem(Icons.local_hospital, 'Solicitar Laboratorio', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LaboratoryScreen()),
              );
            }),
            _buildDrawerItem(Icons.settings, 'Configuración', () {}),
            _buildDrawerItem(Icons.help, 'Ayuda', () {
              // Implementar navegación a la pantalla de ayuda
            }),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => _showLogoutConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1E272E), // Lila oscuro para el botón
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Cerrar sesión",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildCustomDrawerItem(
      IconData icon, String title, List<Map<String, dynamic>> subItems) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      children: subItems.map((subItem) {
        return ListTile(
          title: Text(subItem['title'],
              style: const TextStyle(color: Colors.black87)),
          onTap: subItem['onTap'],
        );
      }).toList(),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('¿Quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
}

void _logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // Remove the stored preferences
  prefs.remove('accessToken');
  prefs.remove('accessRefresh');
  prefs.remove('userId');

  // Navigate to the login page and remove all other screens from the navigation stack
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (BuildContext context) =>
          const LoginView(), // Assuming your login view is named LoginView
    ),
    (Route<dynamic> route) => false, // This will remove all other screens
  );
}

class Consultation {
  final int id;
  final String date;
  final int patientId;
  final int doctorId;
  final int serviceId;
  final int consultingRoomId;
  final int scheduleId;
  String? doctorName;
  String? serviceName;
  String? scheduleTime;

  Consultation({
    required this.id,
    required this.date,
    required this.patientId,
    required this.doctorId,
    required this.serviceId,
    required this.consultingRoomId,
    required this.scheduleId,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'],
      date: json['date'],
      patientId: json['patient'],
      doctorId: json['doctor'],
      serviceId: json['service'],
      consultingRoomId: json['consulting_room'],
      scheduleId: json['schedule'],
    );
  }
}
