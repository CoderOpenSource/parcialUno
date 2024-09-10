import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapas_api/screens/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map? product;
  List? imageUrls;
  bool isLoading = true;
  int cantidad = 1;

  TextStyle headerStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  TextStyle regularStyle = const TextStyle(
    fontSize: 18,
    color: Colors.black87,
  );

  TextStyle descriptionStyle = const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  TextStyle discountStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );

  double getDiscountedPrice(dynamic originalPrice, dynamic discount) {
    double price =
        (originalPrice is String) ? double.parse(originalPrice) : originalPrice;
    double discountPercentage =
        (discount is String) ? double.parse(discount) : discount;
    return price * (1 - discountPercentage / 100);
  }

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  fetchProduct() async {
    final response = await http.get(Uri.parse(
        'http://161.35.16.6/productos/productos/${widget.productId}'));
    if (response.statusCode == 200) {
      var decodedData = json.decode(response.body);
      setState(() {
        product = decodedData;
        imageUrls = product!['imagenes']
            .map((imagen) => imagen['ruta_imagen'])
            .toList();
        isLoading = false; // Desactiva el estado de carga
      });
    } else {
      // Puedes manejar errores aquí si la petición no fue exitosa.
      print('Error al obtener datos: ${response.statusCode}');
    }
  }

  Future<void> handleAddToCart(
      int productId, int cantidad, BuildContext context) async {
    const String baseUrl = "http://161.35.16.6/transaccciones";

    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    try {
      int? carritoId;

      // Obtener todos los carritos
      print('Obteniendo todos los carritos...');
      final response = await http.get(
        Uri.parse('$baseUrl/carritos/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      final List<dynamic> carritosData = json.decode(response.body);

      // Buscar un carrito que pertenezca al usuario
      final carritoUsuario = carritosData.firstWhere(
        (carrito) =>
            carrito['usuario'] == userId && carrito['disponible'] == true,
        orElse: () => null,
      );

      // Si se encuentra un carrito del usuario, usar ese carrito
      if (carritoUsuario != null) {
        carritoId = carritoUsuario['id'] as int;
        print('Carrito existente encontrado: $carritoId');
      } else {
        // Si no, crear un nuevo carrito
        print('No se encontró carrito, creando uno nuevo...');
        final newCarritoResponse = await http.post(
          Uri.parse('$baseUrl/carritos/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'usuario': userId,
          }),
        );

        print('New carrito response status: ${newCarritoResponse.statusCode}');
        print('New carrito response body: ${newCarritoResponse.body}');
        final Map<String, dynamic> newCarritoData =
            json.decode(newCarritoResponse.body);
        carritoId = newCarritoData['id'] as int;
        print('Nuevo carrito creado con ID: $carritoId');
      }

      // Comprobar si el productId ya está en el carrito
      print('Comprobando si el producto ya está en el carrito...');
      final detallesResponse = await http.get(
        Uri.parse('$baseUrl/carritos_productos_detalle/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Detalles response status: ${detallesResponse.statusCode}');
      print('Detalles response body: ${detallesResponse.body}');
      final List<dynamic> todosLosDetalles = json.decode(detallesResponse.body);

      // Filtrar para obtener solo los detalles que corresponden al carritoId
      final detallesData = todosLosDetalles.where((detalle) {
        return detalle['carrito'] == carritoId;
      }).toList();

      print('Detalles del carrito encontrado: ${detallesData.length}');
      bool productoEncontrado = false;
      for (var detalle in detallesData) {
        print('Detalle encontrado: ${detalle['producto']}');
        if (detalle['producto'] == productId) {
          // Si el producto ya está en el carrito, actualizar la cantidad
          productoEncontrado = true;
          int nuevaCantidad = detalle['cantidad'] + cantidad;
          final responseUpdate = await http.patch(
            Uri.parse('$baseUrl/carritos_productos_detalle/${detalle['id']}/'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'cantidad': nuevaCantidad,
            }),
          );
          print(
              'Actualizar cantidad response status: ${responseUpdate.statusCode}');
          print('Actualizar cantidad response body: ${responseUpdate.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cantidad del producto actualizada en el carrito.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          print('Cantidad del producto actualizada en el carrito.');
          return; // Termina la ejecución de la función
        }
      }

      if (!productoEncontrado) {
        // Añadir el producto al carrito
        print('Añadiendo producto al carrito...');
        final responseDetalle = await http.post(
          Uri.parse('$baseUrl/carritos_productos_detalle/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'carrito': carritoId,
            'producto': productId,
            'cantidad': cantidad,
          }),
        );

        print('Añadir producto response status: ${responseDetalle.statusCode}');
        print('Añadir producto response body: ${responseDetalle.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto añadido al carrito exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('Hubo un error al añadir el producto al carrito: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error al añadir el producto al carrito.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Si está cargando, muestra un indicador de carga
      return const Scaffold(
        backgroundColor: Color(0xFF1E272E),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // De lo contrario, muestra el contenido
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Detalles del Producto",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF1E272E),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                // Aquí el Carousel
                CarouselSlider(
                  options: CarouselOptions(
                    height: MediaQuery.of(context).size.height * 0.4,
                    autoPlay: true,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    pauseAutoPlayOnTouch: true,
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {});
                    },
                  ),
                  items: imageUrls!.map((url) {
                    return Container(
                      margin: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
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
                const SizedBox(height: 20),
                Text(product!['nombre'].replaceAll('Ã±', 'ñ'),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  children: [
                    if (double.parse(product!['descuento_porcentaje']) > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio original: Bs${product!['precio']}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey),
                          ),
                          Text(
                            'Precio con descuento: Bs${getDiscountedPrice(product!['precio'], product!['descuento_porcentaje']).toStringAsFixed(2)}',
                            style: discountStyle,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Precio: Bs${product!['precio']}',
                        style: regularStyle,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Descripción: ${product!['descripcion'].replaceAll('Ã±', 'ñ')}',
                      style: descriptionStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Cantidad: ",
                      style: TextStyle(fontSize: 18.0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (cantidad > 1) {
                            cantidad--;
                          }
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        cantidad.toString(),
                        style: const TextStyle(fontSize: 18.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          cantidad++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF1E272E),
                  width: 2.0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E272E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () async {
                      await handleAddToCart(
                          widget.productId, cantidad, context);
                    },
                    child: const Text(
                      'AÑADIR AL CARRO',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
