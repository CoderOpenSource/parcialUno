import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'laboratorio_screen.dart';
import 'services.dart';
import 'consultas_screen.dart';
import 'historial_medical.dart';
import 'home_farmacia_screen.dart';
import 'general_product_screen.dart';
import 'payment_screen.dart';

class LaboratoryRequestedScreen extends StatefulWidget {
  @override
  _LaboratoryRequestedScreenState createState() =>
      _LaboratoryRequestedScreenState();
}

class _LaboratoryRequestedScreenState extends State<LaboratoryRequestedScreen> {
  late Future<List<LabRequest>> _labRequests;
  String? firstName;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _labRequests = _fetchLabRequests();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

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
        print('Error en la respuesta de la API: ${response.statusCode}');
      }
    } else {
      print('User ID no disponible en SharedPreferences');
    }
  }

  Future<List<LabRequest>> _fetchLabRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception('User ID not found in SharedPreferences');
    }

    final response = await http.get(
      Uri.parse('http://161.35.16.6/medical/lab-requests/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      List<LabRequest> allRequests =
          jsonResponse.map((request) => LabRequest.fromJson(request)).toList();

      // Filtrar las solicitudes de laboratorio basadas en el paciente
      List<LabRequest> patientRequests =
          allRequests.where((request) => request.patient == userId).toList();

      return patientRequests;
    } else {
      throw Exception('Failed to load lab requests');
    }
  }

  Future<LabTest> _fetchLabTest(int testId) async {
    final response = await http.get(
      Uri.parse('http://161.35.16.6/medical/lab-tests/$testId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return LabTest.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load lab test');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes de Laboratorio'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: _buildDrawer(),
      body: FutureBuilder<List<LabRequest>>(
        future: _labRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay solicitudes de laboratorio disponibles.'));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final request = snapshot.data![index];
                return FutureBuilder<LabTest>(
                  future: _fetchLabTest(request.test),
                  builder: (context, labTestSnapshot) {
                    if (labTestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (labTestSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${labTestSnapshot.error}'));
                    } else if (!labTestSnapshot.hasData) {
                      return Center(
                          child: Text(
                              'No hay información de la prueba de laboratorio.'));
                    } else {
                      final labTest = labTestSnapshot.data!;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        child: ListTile(
                          title: Text(labTest.name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text('Descripción: ${labTest.description}'),
                              Text(
                                  'Fecha de solicitud: ${request.dateRequested}'),
                              Text('Estado: ${request.status}'),
                            ],
                          ),
                          trailing: Icon(
                            Icons.warning,
                            color: request.status == 'pending'
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
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
              const Color(0xFF1E272E),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: const Color(0xFF1E272E),
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
              ],
            ),
            _buildDrawerItem(Icons.local_hospital, 'Solicitar Laboratorio', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LaboratoryScreen()),
              );
            }),
            _buildDrawerItem(Icons.local_hospital, 'Laboratorios Solicitados',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LaboratoryRequestedScreen()),
              );
            }),
            _buildDrawerItem(Icons.settings, 'Configuración', () {}),
            _buildDrawerItem(Icons.help, 'Ayuda', () {}),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => _showLogoutConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E272E),
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
  prefs.remove('accessToken');
  prefs.remove('accessRefresh');
  prefs.remove('userId');
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (BuildContext context) => LoginView(),
    ),
    (Route<dynamic> route) => false,
  );
}

class LabRequest {
  final int id;
  final int patient;
  final int test;
  final String dateRequested;
  final String status;

  LabRequest({
    required this.id,
    required this.patient,
    required this.test,
    required this.dateRequested,
    required this.status,
  });

  factory LabRequest.fromJson(Map<String, dynamic> json) {
    return LabRequest(
      id: json['id'],
      patient: json['patient'],
      test: json['test'],
      dateRequested: json['date_requested'],
      status: json['status'],
    );
  }
}

class LabTest {
  final int id;
  final String name;
  final String description;

  LabTest({
    required this.id,
    required this.name,
    required this.description,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
