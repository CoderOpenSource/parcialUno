import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/detail_screen.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_solicitado.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServicesScreen extends StatefulWidget {
  ServicesScreen({Key? key}) : super(key: key);

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late Future<List<Service>> services;
  String? firstName;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    services = fetchServices();
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

  // Realiza una petición para obtener los servicios y médicos disponibles para el servicio
  Future<List<Service>> fetchServices() async {
    final response =
        await http.get(Uri.parse('http://161.35.16.6/medical/services/'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((service) => Service.fromJson(service)).toList();
    } else {
      throw Exception('Failed to load services');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Servicios Médicos'),
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
        child: FutureBuilder<List<Service>>(
          future: services,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              // Dividir los servicios en dos listas: con descuento y sin descuento
              List<Service> servicesWithDiscount = [];
              List<Service> servicesWithoutDiscount = [];

              snapshot.data!.forEach((service) {
                if (service.discount > 0) {
                  servicesWithDiscount.add(service);
                } else {
                  servicesWithoutDiscount.add(service);
                }
              });

              return ListView(
                children: [
                  _buildServiceSection(
                    context,
                    'Servicios en Oferta',
                    servicesWithDiscount,
                  ),
                  _buildServiceSection(
                    context,
                    'Servicios Sin Descuento',
                    servicesWithoutDiscount,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildServiceSection(
      BuildContext context, String title, List<Service> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...services
            .map((service) => _buildServiceCard(context, service))
            .toList(),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Service service) {
    final double originalPrice = double.parse(service.price);
    final double discountedPrice =
        originalPrice - (originalPrice * (service.discount / 100));

    return Card(
      color: Colors.white70, // Color de fondo de la tarjeta
      margin: EdgeInsets.all(10),
      elevation: 5, // Sombra de la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bordes redondeados
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        leading: Image.network(
          service.image!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
        title: Text(
          service.name,
          style: TextStyle(
            color: Colors.deepPurple[800], // Color del texto del título
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.description,
              style: TextStyle(
                color: Colors.black54, // Color del texto de la descripción
              ),
            ),
            SizedBox(height: 5),
            if (service.discount > 0) ...[
              Text(
                'Precio Antes: Bs$originalPrice',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.red,
                ),
              ),
              Text(
                'Precio Ahora: Bs$discountedPrice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ] else ...[
              Text(
                'Precio: Bs$originalPrice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DetailScreen(service: service)),
          );
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

class Service {
  final int id;
  final String name;
  final String description;
  final String price;
  final String? image;
  final double discount;
  final List<int> doctorIds;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.discount,
    required this.doctorIds,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toString(),
      image: json['image'] as String?,
      discount: json['discount'] != null
          ? double.parse(json['discount'].toString())
          : 0.0,
      doctorIds:
          List<int>.from(json['doctors'].map((doctor) => doctor['user']['id'])),
    );
  }
}
