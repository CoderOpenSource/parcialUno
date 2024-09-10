import 'package:mapas_api/models/global_data.dart';
import 'package:mapas_api/models/user/sucursal_model.dart';
import 'package:mapas_api/screens/taller/loading_taller_screen4.dart';
import 'package:mapas_api/widgets/appbar2.dart';
import 'package:mapas_api/widgets/product_detail.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

bool _hasShownDialog = false;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ExploreScreen> {
  int? selectedSubcategory;
  List<dynamic> subcategories = []; // Esta mantendrá las subcategorías
  bool isLoading = true;
  List<dynamic> categories = [];
  int? selectedCategory;
  List<dynamic> products = []; // Esta mantendrá todos los productos
  List<dynamic> displayedProducts =
      []; // Esta mostrará los productos filtrados o todos
  int? selectedSucursalId;
  // Agregamos un dummy de categoría "Todos" al principio de la lista.
  @override
  void initState() {
    super.initState();
    selectedSucursalId = GlobalData().selectedSucursalId;

    if (selectedSucursalId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasShownDialog) {
          _mostrarSucursales(context);
          _hasShownDialog = true;
        }
      });
    } else {
      _filterProductsBySucursal();
    }
    // Agrega "Todos" al inicio de la lista de categorías.
    categories = [
      {
        'nombre': 'Todos',
        'id': -1, // Un ID que no debería existir en tu base de datos
      }
    ];

    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    await fetchCategories();
    fetchSubcategories();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCategories() async {
    final response = await http
        .get(Uri.parse('http://137.184.190.92/productos/categorias/'));
    if (response.statusCode == 200) {
      setState(() {
        categories.addAll(
            json.decode(response.body)); // Aquí usamos addAll en lugar de =
        selectedCategory ??= categories[0]['id'];
      });
    } else {
      print('Error al obtener las categorías');
    }
  }

  Future<void> fetchSubcategories() async {
    final response = await http
        .get(Uri.parse('http://137.184.190.92/productos/subcategorias/'));

    if (response.statusCode == 200) {
      setState(() {
        subcategories = json.decode(response.body);
      });
    } else {
      print('Error al obtener las subcategorías');
    }
  }

  void _filterProductsBySucursal() async {
    print('Sucursal seleccionada: $selectedSucursalId');
    if (selectedSucursalId != null) {
      // Paso 1: Obtener los productos de una sucursal específica
      final inventoryResponse = await http
          .get(Uri.parse('http://137.184.190.92/sucursales/inventarios/'));
      if (inventoryResponse.statusCode == 200) {
        var allInventory = json.decode(inventoryResponse.body) as List;
        var filteredInventory = allInventory.where((inventoryItem) {
          return inventoryItem['sucursal'] == selectedSucursalId;
        }).toList();

        final productDetailsResponse = await http.get(
            Uri.parse('http://137.184.190.92/productos/productosdetalle/'));
        var allProductDetails =
            json.decode(productDetailsResponse.body) as List;

        var relevantProductDetails = allProductDetails.where((productDetail) {
          return filteredInventory
              .map((inventoryItem) => inventoryItem['productodetalle'])
              .contains(productDetail['id']);
        }).toList();

        List<int> productIdsFromDetails =
            relevantProductDetails.map<int>((productDetail) {
          return productDetail['producto']['id'];
        }).toList();

        // Paso 2: Obtener todos los productos sin filtrar por descuento_porcentaje
        final productsResponse = await http
            .get(Uri.parse('http://137.184.190.92/productos/productos/'));
        if (productsResponse.statusCode == 200) {
          var allProducts = json.decode(productsResponse.body) as List;

          var relevantProducts = allProducts.where((product) {
            return productIdsFromDetails.contains(product['id']);
          }).toList();

          // Paso 3 y 4: Asignar a products y displayedProducts
          setState(() {
            products = relevantProducts;
            displayedProducts = List.from(relevantProducts);
          });
        } else {
          print('Error al obtener los productos');
        }
      } else {
        print('Error al obtener el inventario');
      }
    } else {
      print('No hay sucursal seleccionada');
    }
  }

  Future<void> _mostrarSucursales(BuildContext context) async {
    // Hacer la solicitud a la API
    final response = await http
        .get(Uri.parse('http://137.184.190.92/sucursales/sucursales/'));

    if (response.statusCode == 200) {
      // Si la llamada a la API es exitosa, parsear el JSON.
      List<Sucursal> sucursales = (json.decode(response.body) as List)
          .map((data) => Sucursal.fromJson(data))
          .toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          // Utiliza MediaQuery para obtener la altura y anchura de la pantalla
          double screenHeight = MediaQuery.of(context).size.height;
          double screenWidth = MediaQuery.of(context).size.width;
          return Dialog(
            backgroundColor: const Color(0xFF1E272E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Bordes redondeados
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: screenWidth * 0.9, // Ocupa un 90% del ancho de la pantalla
              height: screenHeight *
                  0.8, // Ocupa un 80% de la altura de la pantalla
              child: Column(
                children: [
                  const Text(
                    "STYLO STORE",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "UBICACIONES",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(), // Línea divisoria
                  Expanded(
                    child: ListView.builder(
                      itemCount: sucursales.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            ListTile(
                              onTap: () {
                                setState(() {
                                  selectedSucursalId = sucursales[index].id;
                                  GlobalData().selectedSucursalId =
                                      selectedSucursalId; // Aquí actualizamos el valor static
                                  _filterProductsBySucursal();
                                });
                                Navigator.pop(context);
                              },
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              title: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white),
                                  children: <TextSpan>[
                                    const TextSpan(
                                        text: 'Sucursal: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: sucursales[index].nombre),
                                  ],
                                ),
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white),
                                  children: <TextSpan>[
                                    const TextSpan(
                                        text: 'Dirección: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: sucursales[index].direccion),
                                  ],
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TallerLoadingScreen4(
                                        tallerId: sucursales[index].id,
                                        // Aquí pasas los parámetros que necesita LocationScreen, si los hay.
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Ver en el mapa",
                                  style: TextStyle(color: Color(0xFF1E272E)),
                                ),
                              ),
                            ),
                            const Divider(), // Línea divisoria
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
      );
    } else {
      // Si la llamada a la API falla, muestra un error.
      throw Exception('Failed to load sucursales');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 249, 249),
      appBar: AppBarActiTone2(
        onStoreIconPressed: () => _mostrarSucursales(context),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E272E),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 40.0, color: Colors.white), // Icono de juguete
                  SizedBox(width: 10.0),
                  Text('STYLO STORE',
                      style: TextStyle(fontSize: 24.0, color: Colors.white)),
                ],
              ),
            ),
            ...subcategories
                .where((sub) => selectedCategory == -1
                    ? true
                    : sub['categoria']['id'] == selectedCategory)
                .map((subcategory) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.directions_boat_filled_sharp,
                        color: Color(
                            0xFF1E272E)), // Icono representativo de juguete
                    title: Text(subcategory['nombre'].replaceAll('Ã±', 'ñ'),
                        style: const TextStyle(fontSize: 18.0)),
                    onTap: () {
                      setState(() {
                        selectedSubcategory = subcategory['id'];
                        displayedProducts = products.where((product) {
                          if (selectedCategory == -1) {
                            // Si es "Todos"
                            return product['subcategoria'] ==
                                selectedSubcategory;
                          } else {
                            return product['categoria'] == selectedCategory &&
                                product['subcategoria'] == selectedSubcategory;
                          }
                        }).toList();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Divider(color: Colors.grey.shade400) // Línea divisora
                ],
              );
            }).toList(),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(
                    height: 15,
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
                                selectedCategory = category['id'];
                                if (selectedCategory == -1) {
                                  // Si la categoría seleccionada es "Todos"
                                  displayedProducts = List.from(products);
                                } else {
                                  // Filtrado por categoría específica
                                  displayedProducts = products.where((product) {
                                    return product['categoria'] ==
                                        selectedCategory;
                                  }).toList();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical:
                                      10.0), // Ampliado el padding vertical
                              child: Row(
                                children: [
                                  // Aquí hacemos una elección del ícono basado en la categoría
                                  categoryIcon(
                                      category['nombre'].replaceAll('Ã±', 'ñ')),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    category['nombre'].replaceAll('Ã±', 'ñ'),
                                    style: TextStyle(
                                      fontSize: 22,
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
                      childAspectRatio: 1 /
                          1.5, // Modificado para permitir más espacio vertical
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

                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: const Color(0xFF1E272E), // Fondo morado oscuro
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
                                        productId: displayedProducts[index]
                                            ['id']),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    displayedProducts[index]['imagenes'][0]
                                        ['ruta_imagen'],
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Título en blanco
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (descuento > 0) ...[
                                    Text(
                                      'Antes: Bs${displayedProducts[index]['precio']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.white, // Texto en blanco
                                      ),
                                    ),
                                    Text(
                                      'Ahora: Bs${discountedPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors
                                            .yellow, // Precio actual en amarillo
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Precio: Bs${displayedProducts[index]['precio']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Texto en blanco
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

  Widget categoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Todos':
        return const Icon(Icons.list, color: Colors.white);
      case 'Hombres':
        return const Icon(Icons.boy,
            color: Colors
                .white); // Aquí puedes usar cualquier ícono representativo para niños
      case 'Mujeres':
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
}
