import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical_detail.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_solicitado.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalHistoryScreen extends StatefulWidget {
  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late Future<List<MedicalHistory>> _medicalHistories;
  String? firstName;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _medicalHistories = _fetchMedicalHistory();
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

  Future<List<MedicalHistory>> _fetchMedicalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      throw Exception('User ID not found in SharedPreferences');
    }

    final response = await http.get(
      Uri.parse('http://1192.168.0.17/historical_medical/medical_histories/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      List<MedicalHistory> allHistories = jsonResponse
          .map((history) => MedicalHistory.fromJson(history))
          .toList();

      // Filtrar los historiales médicos basados en el paciente
      List<MedicalHistory> patientHistories =
          allHistories.where((history) => history.patient == userId).toList();

      return patientHistories;
    } else {
      throw Exception('Failed to load medical history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Médico'),
        backgroundColor: const Color(0xFF1E272E),
      ),
      drawer: _buildDrawer(),
      body: FutureBuilder<List<MedicalHistory>>(
        future: _medicalHistories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay historial médico disponible.'));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final history = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  child: ListTile(
                    title: Text('Fecha: ${history.date}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Síntomas: ${history.symptoms}'),
                        Text('Diagnóstico: ${history.diagnosis}'),
                        Text('Tratamiento: ${history.treatment}'),
                        Text('Notas: ${history.notes}'),
                        Text('Fecha de seguimiento: ${history.followUpDate}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MedicalHistoryDetailScreen(history: history),
                          ),
                        );
                      },
                    ),
                  ),
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
            _buildDrawerItem(Icons.local_hospital, 'Laboratorios Solicitados',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LaboratoryRequestedScreen()),
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

class MedicalHistory {
  final int id;
  final String date;
  final String symptoms;
  final String diagnosis;
  final String treatment;
  final String followUpDate;
  final String notes;
  final int patient;
  final int doctor;
  final int prescription;

  MedicalHistory({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.diagnosis,
    required this.treatment,
    required this.followUpDate,
    required this.notes,
    required this.patient,
    required this.doctor,
    required this.prescription,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['id'],
      date: json['date'],
      symptoms: json['symptoms'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      followUpDate: json['follow_up_date'],
      notes: json['notes'],
      patient: json['patient'],
      doctor: json['doctor'],
      prescription: json['prescription'],
    );
  }
}
