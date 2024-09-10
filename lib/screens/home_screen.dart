import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_solicitado.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<String> imageUrls = [
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1715838788/pngwing.com_3_z7seek.png',
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1715838404/pngwing.com_qavzk7.png',
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1715838478/pngwing.com_1_aklqja.png',
  ];

  String? firstName;
  String? photoUrl;
  bool? mostrarOfertas; // Variable para controlar el estado del modal

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkMostrarOfertas(); // Chequear y mostrar el modal si es necesario
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

  Future<void> _checkMostrarOfertas() async {
    mostrarOfertas = true;

    if (mostrarOfertas == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarOfertasModal(context);
      });
    }
  }

  Future<void> _setMostrarOfertas(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('mostrarOfertas', value);
  }

  void _mostrarOfertasModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E272E), // Fondo del AlertDialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Ofertas Especiales',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://res.cloudinary.com/dkpuiyovk/image/upload/v1720064789/80748037_2192318324397667_7510615259044904960_n_wf0icv.jpg',
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              const Text(
                '¡Aprovecha nuestras ofertas especiales en productos y servicios!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ServicesScreen()),
                );
                _setMostrarOfertas(false); // No mostrar más el modal
                setState(() {
                  mostrarOfertas = false;
                });
              },
              child: const Text('Ver Ofertas de Servicios',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _setMostrarOfertas(false); // No mostrar más el modal
                setState(() {
                  mostrarOfertas = false;
                });
              },
              child:
                  const Text('Cerrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Clínica MediCare"),
        backgroundColor: const Color(0xFF1E272E), // Lila oscuro para el AppBar
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        centerTitle: false,
      ),
      drawer: _buildDrawer(),
      body: Container(
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
        child: _buildBody(),
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
                color:
                    const Color(0xFF1E272E), // Lila oscuro para el DrawerHeader
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

  Widget _buildBody() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    "Bienvenido a Clínica MediCare",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildImageCarousel(),
                  _buildServicesSection(),
                  _buildOpeningHoursSection(),
                  _buildEmergencySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
  }

  Widget _buildImageCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: imageUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: const [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text(
                  "¿Tienes una emergencia?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Comunícate con nosotros de inmediato a través de WhatsApp.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                final Uri whatsappUri = Uri.parse('https://wa.me/+59179068578');
                launch(whatsappUri.toString());
              },
              icon: Image.network(
                'https://res.cloudinary.com/dkpuiyovk/image/upload/v1715840778/whatsapp_g2x7ew.png',
                height: 24,
              ),
              label: const Text("Contactar por WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            "Nuestros Servicios",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 43, 29, 45),
            ),
          ),
          SizedBox(height: 10),
          Text(
            "• Consulta Médica General\n• Pediatría\n• Cardiología\n• Ginecología\n• Dermatología",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            "Horario de Atención",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 43, 29, 45)),
          ),
          SizedBox(height: 10),
          Text(
            "Lunes a Domingo: Atención 24 horas",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
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
