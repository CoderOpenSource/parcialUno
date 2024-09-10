import 'package:carousel_slider/carousel_slider.dart';
import 'package:mapas_api/screens/cart_screen.dart';
import 'package:mapas_api/screens/home_screen.dart';
import 'package:mapas_api/screens/user/login_user.dart';
import 'package:mapas_api/screens/workshop/consultas_screen.dart';
import 'package:mapas_api/screens/workshop/general_product_screen.dart';
import 'package:mapas_api/screens/workshop/historial_medical.dart';
import 'package:mapas_api/screens/workshop/laboratorio_screen.dart';
import 'package:mapas_api/screens/workshop/laboratorio_solicitado.dart';
import 'package:mapas_api/screens/workshop/payment_screen.dart';
import 'package:mapas_api/screens/workshop/services.dart';
import 'package:mapas_api/widgets/appbar.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeFarmaciaScreen extends StatefulWidget {
  const HomeFarmaciaScreen({super.key});

  @override
  _HomeFarmaciaScreenState createState() => _HomeFarmaciaScreenState();
}

class _HomeFarmaciaScreenState extends State<HomeFarmaciaScreen> {
  // Lista de imágenes de ejemplo
  List<String> imageUrls = [
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1/productos/imagenes/WhatsApp_Image_2024-07-03_at_17.17.08_drapup',
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1/productos/imagenes/paracetamol2_ycylof',
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1/productos/imagenes/WhatsApp_Image_2024-07-03_at_17.03.58_h4ci2m',
    'https://res.cloudinary.com/dkpuiyovk/image/upload/v1/productos/imagenes/tph-complejo-b-600x429_m7qwoz',
    // Agrega más URLs de imágenes según tus necesidades
  ];

  String? firstName;
  String? photoUrl;
  bool isLoading = true;
  List<dynamic> categories = [];
  String? selectedCategory;
  List<dynamic> products = []; // Esta mantendrá todos los productos
  List<dynamic> displayedProducts =
      []; // Esta mostrará los productos filtrados o todos

  @override
  void initState() {
    super.initState();
    categories = [
      {
        'nombre': 'Todos',
        'id': -1, // Un ID que no debería existir en tu base de datos
      }
    ];
    fetchData();
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
      List<dynamic> categoriesWithDiscounts = allCategories.where((category) {
        return products.any((product) {
          return product['categoria'] == category['id'] &&
              double.parse(product['descuento_porcentaje'].toString()) > 0;
        });
      }).toList();
      setState(() {
        categories = [
          {
            'nombre': 'Todos',
            'id': -1
          }, // Agrega la categoría "Todos" al principio
          ...categoriesWithDiscounts
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
        displayedProducts = products.where((product) {
          double descuento =
              double.parse(product['descuento_porcentaje'].toString());
          return descuento > 0;
        }).toList();
      });
    } else {
      print('Error al obtener los productos');
    }
  }

  void filterProductsByCategory(String? categoryName) {
    if (categoryName == "Todos") {
      setState(() {
        displayedProducts = products.where((product) {
          double descuento =
              double.parse(product['descuento_porcentaje'].toString());
          return descuento > 0;
        }).toList();
      });
    } else {
      setState(() {
        displayedProducts = products.where((product) {
          double descuento =
              double.parse(product['descuento_porcentaje'].toString());
          return product['categoria'] ==
                  categories.firstWhere(
                      (cat) => cat['nombre'] == categoryName)['id'] &&
              descuento > 0;
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
                  const SizedBox(
                    height:
                        10, // Espacio entre las recomendaciones y el carrusel
                  ),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200, // Cambia esto para modificar la altura
                      autoPlay: true, // Autoplay para el carrusel
                      viewportFraction:
                          1.0, // Esto hará que la imagen ocupe toda la pantalla en ancho
                      enableInfiniteScroll: true,
                      pauseAutoPlayOnTouch: true,
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          // Aquí puedes actualizar algún estado relacionado con el índice de la imagen actual si es necesario
                        });
                      },
                    ),
                    items: imageUrls.map((url) {
                      return Container(
                        margin: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0), // Añadimos bordes redondeados
                          boxShadow: const [
                            BoxShadow(
                              color: Colors
                                  .black26, // Cambia este color para la sombra
                              offset: Offset(0.0, 4.0),
                              blurRadius: 5.0,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                          child: Image.network(
                            url,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                  child: Text('Error al cargar la imagen.'));
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(
                    height:
                        20, // Aumenté el espacio entre el carrusel y el título
                  ),
                  const Text(
                    "🎉 Productos con Descuento 🎉",
                    style: TextStyle(
                      fontSize: 24, // Reducido el tamaño de la fuente
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E272E),
                    ),
                  ),
                  const SizedBox(
                    height:
                        15, // Aumenté el espacio entre el título y lo que sigue
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(15.0), // Bordes redondeados
                      color: const Color(0xFF1E272E),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: categories.map((category) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category['nombre'];
                                filterProductsByCategory(selectedCategory);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical:
                                      10.0), // Ampliado el padding vertical
                              child: Row(
                                children: [
                                  categoryIcon(
                                      category['nombre'].replaceAll('Ã±', 'ñ')),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    category['nombre'].replaceAll('Ã±', 'ñ'),
                                    style: TextStyle(
                                      fontSize:
                                          18, // Reducido el tamaño de la fuente
                                      color: Colors.white,
                                      fontWeight:
                                          selectedCategory == category['nombre']
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
                      childAspectRatio:
                          1 / 1.6, // Ajustado para más espacio vertical
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
                            padding:
                                const EdgeInsets.all(8.0), // Reducido a 8.0
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
                                    width: 100, // Reducido a 80
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      displayedProducts[index]['nombre']
                                          .replaceAll('Ã±', 'ñ'),
                                      style: const TextStyle(
                                        fontSize: 10, // Reducido a 10
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
                                        fontSize: 8, // Reducido a 8
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Ahora: Bs${discountedPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 8, // Reducido a 8
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Precio: Bs${displayedProducts[index]['precio']}',
                                      style: const TextStyle(
                                        fontSize: 8, // Reducido a 8
                                        fontWeight: FontWeight.bold,
                                      ),
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

  Widget categoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Todos':
        return const Icon(Icons.list, color: Colors.white);
      case 'Niños':
        return const Icon(Icons.boy,
            color: Colors
                .white); // Aquí puedes usar cualquier ícono representativo para niños
      case 'Niñas':
        return const Icon(Icons.girl,
            color: Colors.white); // Y aquí uno para niñas
      case 'Bebes':
        return const Icon(Icons.baby_changing_station,
            color: Colors.white); // Aquí uno para bebés
      default:
        return const SizedBox
            .shrink(); // No muestra ningún ícono si no coincide con las categorías anteriores
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
