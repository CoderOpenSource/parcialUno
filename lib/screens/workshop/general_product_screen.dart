import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:mapas_api/widgets/appbar.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeneralProductsScreen extends StatefulWidget {
  const GeneralProductsScreen({super.key});

  @override
  _GeneralProductsScreenState createState() => _GeneralProductsScreenState();
}

class _GeneralProductsScreenState extends State<GeneralProductsScreen> {
  String? firstName;
  String? photoUrl;
  bool isLoading = true;
  List<dynamic> categories = [];
  String? selectedCategory;
  String? selectedSubcategory;
  List<dynamic> products = [];
  List<dynamic> displayedProducts = [];

  @override
  void initState() {
    super.initState();
    categories = [
      {'nombre': 'Todos', 'id': -1, 'subcategorias': []}
    ];
    fetchData();
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

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    await fetchProducts();
    await fetchCategories();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCategories() async {
    final response =
        await http.get(Uri.parse('http://161.35.16.6/productos/categorias/'));
    if (response.statusCode == 200) {
      List<dynamic> allCategories = json.decode(response.body);
      setState(() {
        categories = [
          {'nombre': 'Todos', 'id': -1, 'subcategorias': []},
          ...allCategories
        ];
        selectedCategory ??= categories[0]['nombre'];
      });
    } else {
      print('Error al obtener las categorías');
    }
  }

  Future<void> fetchProducts() async {
    final response =
        await http.get(Uri.parse('http://161.35.16.6/productos/productos/'));
    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
        displayedProducts = products;
      });
    } else {
      print('Error al obtener los productos');
    }
  }

  void filterProductsByCategory(String? categoryName) {
    if (categoryName == "Todos") {
      setState(() {
        displayedProducts = products;
        selectedSubcategory = null;
      });
    } else {
      setState(() {
        displayedProducts = products.where((product) {
          return product['categoria'] ==
              categories
                  .firstWhere((cat) => cat['nombre'] == categoryName)['id'];
        }).toList();
      });
    }
  }

  void filterProductsBySubcategory(String? subcategoryName) {
    if (subcategoryName == "Todos") {
      filterProductsByCategory(selectedCategory);
    } else {
      setState(() {
        displayedProducts = products.where((product) {
          return product['subcategoria'] ==
              categories
                  .firstWhere((cat) => cat['nombre'] == selectedCategory)[
                      'subcategorias']
                  .firstWhere((sub) => sub['nombre'] == subcategoryName)['id'];
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 250),
      appBar: AppBarActiTone(),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  const Text(
                    "🎉 Productos Disponibles 🎉",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E272E),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: const Color(0xFF1E272E),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: categories.map((category) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category['nombre'];
                                    selectedSubcategory = null;
                                    filterProductsByCategory(selectedCategory);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 10.0),
                                  child: Row(
                                    children: [
                                      categoryIcon(category['nombre']
                                          .replaceAll('Ã±', 'ñ')),
                                      const SizedBox(width: 5.0),
                                      Text(
                                        category['nombre']
                                            .replaceAll('Ã±', 'ñ'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: selectedCategory ==
                                                  category['nombre']
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (category['nombre'] == selectedCategory &&
                                  category['subcategorias'] != null &&
                                  category['subcategorias'].isNotEmpty)
                                Column(
                                  children: category['subcategorias']
                                      .map<Widget>((subcategory) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedSubcategory =
                                              subcategory['nombre'];
                                          filterProductsBySubcategory(
                                              selectedSubcategory);
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 5.0),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 5.0),
                                            Text(
                                              subcategory['nombre']
                                                  .replaceAll('Ã±', 'ñ'),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white70,
                                                fontWeight:
                                                    selectedSubcategory ==
                                                            subcategory[
                                                                'nombre']
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1 / 1.6,
                    ),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      double precio = double.parse(
                          displayedProducts[index]['precio'].toString());
                      double descuento = double.parse(displayedProducts[index]
                              ['descuento_porcentaje']
                          .toString());
                      final discountedPrice =
                          precio - (precio * (descuento / 100));
                      var imagenes =
                          displayedProducts[index]['imagenes'] as List;
                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: const Color(0xFF1E272E),
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      productId: displayedProducts[index]['id'],
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    imagenes.isNotEmpty
                                        ? imagenes[0]['ruta_imagen']
                                        : 'default_image_url',
                                    fit: BoxFit.cover,
                                    height: 90,
                                    width: 100,
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      displayedProducts[index]['nombre']
                                          .replaceAll('Ã±', 'ñ'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (descuento > 1) ...[
                                    Text(
                                      'Antes: Bs${displayedProducts[index]['precio']}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Ahora: Bs${discountedPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Precio: Bs${displayedProducts[index]['precio']}',
                                      style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                ],
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
              Color(0xFF1E272E),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E272E)),
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
                          builder: (context) => const HomeFarmaciaScreen()),
                    );
                  },
                },
                {
                  'title': 'Productos en General',
                  'onTap': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GeneralProductsScreen()),
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
            _buildDrawerItem(Icons.settings, 'Configuración', () {}),
            _buildDrawerItem(Icons.help, 'Ayuda', () {
              // Implementar navegación a la pantalla de ayuda
            }),
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

  Widget categoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Todos':
        return const Icon(Icons.list, color: Colors.white);
      case 'Niños':
        return const Icon(Icons.boy, color: Colors.white);
      case 'Niñas':
        return const Icon(Icons.girl, color: Colors.white);
      case 'Bebes':
        return const Icon(Icons.baby_changing_station, color: Colors.white);
      default:
        return const SizedBox.shrink();
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

  prefs.remove('accessToken');
  prefs.remove('accessRefresh');
  prefs.remove('userId');

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (BuildContext context) => const LoginView(),
    ),
    (Route<dynamic> route) => false,
  );
}
