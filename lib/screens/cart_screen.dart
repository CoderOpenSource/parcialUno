import 'package:mapas_api/screens/workshop/home_farmacia_screen.dart';
import 'package:mapas_api/widgets/pagos_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  int? cartId;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      print('Usuario logueado $userId');

      final response = await http
          .get(Uri.parse('http://161.35.16.6/transaccciones/carritos/'));
      final data = json.decode(response.body) as List;

      final userCart = data.firstWhere(
          (cart) => cart['usuario'] == userId && cart['disponible'] == true,
          orElse: () => null);

      if (userCart != null) {
        List<Map<String, dynamic>> productsDetails = [];
        for (var item in userCart['productos_detalle']) {
          final productId = item['producto'];
          final productResponse = await http.get(
              Uri.parse('http://161.35.16.6/productos/productos/$productId'));
          final productData = json.decode(productResponse.body);
          productData['cantidad'] = item['cantidad'];
          productData['detalle_id'] = item['id'];
          productsDetails.add(productData);
        }
        setState(() {
          displayedProducts = productsDetails;
          cartId = userCart['id'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error al obtener los productos del carrito: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateProductQuantity(int detalleId, int cantidad) async {
    final response = await http.patch(
      Uri.parse(
          'http://161.35.16.6/transaccciones/carritos_productos_detalle/$detalleId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'cantidad': cantidad,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cantidad del producto actualizada en el carrito.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      print('Cantidad actualizada exitosamente');
    } else {
      print('Error al actualizar la cantidad: ${response.statusCode}');
    }
  }

  Future<void> removeProductFromCart(int detalleId) async {
    final response = await http.delete(
      Uri.parse(
          'http://161.35.16.6/transaccciones/carritos_productos_detalle/$detalleId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 204) {
      print('Producto eliminado exitosamente');
    } else {
      print('Error al eliminar el producto: ${response.statusCode}');
    }
  }

  double calcularTotal() {
    double total = 0.0;
    for (var product in displayedProducts) {
      double precio = double.parse(product['precio'].toString());
      double descuento =
          double.parse(product['descuento_porcentaje'].toString());
      int cantidad = product['cantidad'];
      final discountedPrice = precio - (precio * (descuento / 100));
      total += discountedPrice * cantidad;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Center(
          child: Text(
            'Mi Carrito',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.shopping_cart,
                        size: 100,
                        color: Colors.grey,
                      ),
                      Text(
                        'Carrito vacío',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayedProducts.length,
                  itemBuilder: (context, index) {
                    double precio = double.parse(
                        displayedProducts[index]['precio'].toString());
                    double descuento = double.parse(displayedProducts[index]
                            ['descuento_porcentaje']
                        .toString());
                    final discountedPrice =
                        precio - (precio * (descuento / 100));

                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: <Widget>[
                            // Imagen del producto
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                displayedProducts[index]['imagenes'][0]
                                        ['ruta_imagen']
                                    .toString(),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayedProducts[index]['nombre']
                                          .replaceAll('Ã±', 'ñ'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    if (descuento > 0)
                                      Text(
                                        'Antes: Bs$precio',
                                        style: const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough),
                                      ),
                                    Text(
                                      descuento > 0
                                          ? 'Ahora: Bs$discountedPrice'
                                          : 'Precio: Bs$precio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: descuento > 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: ${displayedProducts[index]['cantidad']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      displayedProducts[index]['cantidad']++;
                                    });
                                    updateProductQuantity(
                                      displayedProducts[index]['detalle_id'],
                                      displayedProducts[index]['cantidad'],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      if (displayedProducts[index]['cantidad'] >
                                          1) {
                                        displayedProducts[index]['cantidad']--;
                                        updateProductQuantity(
                                          displayedProducts[index]
                                              ['detalle_id'],
                                          displayedProducts[index]['cantidad'],
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  removeProductFromCart(
                                    displayedProducts[index]['detalle_id'],
                                  );
                                  displayedProducts.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text("Bs${calcularTotal()}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const HomeFarmaciaScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        child: const Text("Seguir comprando"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PantallaPago()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E272E),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: const Text(
                        "Tramitar Pedido",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
