import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> transactions = [];
  String? userName;
  String? firstName;
  String? photoUrl;
  @override
  void initState() {
    super.initState();
    fetchTransactions();
    fetchUserName();
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

  Future<void> fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId != null) {
        final response = await http.get(
          Uri.parse('http://161.35.16.6/usuarios/users/$userId/'),
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          setState(() {
            userName = '${userData['first_name']} ${userData['last_name']}';
          });
        } else {
          throw Exception('Failed to load user data');
        }
      }
    } catch (error) {
      print('Error al obtener el nombre del usuario: $error');
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId != null) {
        final response = await http.get(
          Uri.parse('http://161.35.16.6/transaccciones/transacciones/'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          setState(() {
            transactions = data
                .where((transaction) => transaction['usuario'] == userId)
                .map((transaction) => transaction as Map<String, dynamic>)
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load transactions');
        }
      }
    } catch (error) {
      print('Error al obtener las transacciones: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<void> generatePdf(BuildContext context, int transactionId) async {
    final pdf = pw.Document();
    final date = DateTime.now().toString().split(' ')[0];

    // Obtener los detalles del carrito para la transacción
    final transactionResponse = await http.get(
      Uri.parse(
          'http://161.35.16.6/transaccciones/transacciones/$transactionId'),
    );
    final transactionData = json.decode(transactionResponse.body);
    final carritoId = transactionData['carrito'];

    final cartResponse = await http.get(
      Uri.parse('http://161.35.16.6/transaccciones/carritos/$carritoId'),
    );
    final cartData = json.decode(cartResponse.body);

    List<Map<String, dynamic>> productsDetails = [];
    for (var item in cartData['productos_detalle']) {
      final productId = item['producto'];
      final productResponse = await http.get(
        Uri.parse('http://161.35.16.6/productos/productos/$productId'),
      );
      final productData = json.decode(productResponse.body);
      productData['cantidad'] = item['cantidad'];
      productsDetails.add(productData);
    }

    // Cargar las imágenes
    final images = await Future.wait(productsDetails.map((product) async {
      final imageUrl = product['imagenes'][0]['ruta_imagen'];
      return _downloadImage(imageUrl);
    }).toList());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Comprobante de Pago', style: pw.TextStyle(fontSize: 24)),
              pw.Divider(),
              pw.Text('Nombre: $userName'),
              pw.Text('Fecha: $date'),
              pw.Text('No. Pedido: $transactionId'),
              pw.Divider(),
              pw.Text('Productos:', style: pw.TextStyle(fontSize: 18)),
              pw.ListView.builder(
                itemCount: productsDetails.length,
                itemBuilder: (context, index) {
                  final product = productsDetails[index];
                  final imageBytes = images[index];

                  double precio = double.parse(product['precio'].toString());
                  double descuento =
                      double.parse(product['descuento_porcentaje'].toString());
                  double discountedPrice =
                      precio - (precio * (descuento / 100));

                  return pw.Row(
                    children: [
                      if (product['imagenes'] != null &&
                          product['imagenes'].isNotEmpty)
                        pw.Container(
                          width: 50,
                          height: 50,
                          child: pw.Image(
                            pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              product['nombre'].replaceAll('Ã±', 'ñ'),
                              style: pw.TextStyle(
                                  fontSize: 18, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Precio: Bs$discountedPrice',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#000000'),
                              ),
                            ),
                            pw.Text(
                              'Cantidad: ${product['cantidad']}',
                              style: const pw.TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              pw.Divider(),
              pw.Text(
                'Total a Pagar: Bs${calcularTotal(productsDetails).toStringAsFixed(2)}',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Gracias por su preferencia',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Pedido.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => file.readAsBytes());
  }

  double calcularTotal(List<Map<String, dynamic>> productsDetails) {
    double total = 0.0;
    for (var product in productsDetails) {
      double precio = double.parse(product['precio'].toString());
      double descuento =
          double.parse(product['descuento_porcentaje'].toString());
      int cantidad = int.parse(product['cantidad'].toString());
      final discountedPrice = precio - (precio * (descuento / 100));
      total += discountedPrice * cantidad;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text('Pagos Realizados'),
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final transactionDate = DateTime.parse(transaction['fecha']);
                final formattedDate =
                    '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';

                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  child: ListTile(
                    title: Text('Transacción: ${transaction['id']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: $formattedDate'),
                        FutureBuilder(
                          future: fetchTipoPago(transaction['tipo_pago']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Cargando tipo de pago...');
                            } else if (snapshot.hasError) {
                              return const Text('Error al cargar tipo de pago');
                            } else {
                              return Text('Tipo de Pago: ${snapshot.data}');
                            }
                          },
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        await generatePdf(context, transaction['id']);
                      },
                    ),
                  ),
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

  Future<String> fetchTipoPago(int tipoPagoId) async {
    final response = await http.get(
      Uri.parse('http://161.35.16.6/transaccciones/tipos_pago/$tipoPagoId'),
    );

    if (response.statusCode == 200) {
      final tipoPagoData = json.decode(response.body);
      return tipoPagoData['nombre'];
    } else {
      throw Exception('Failed to load tipo de pago');
    }
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
