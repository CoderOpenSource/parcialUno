import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/widgets/stripe/pagos_online.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, String> tiposPagoMap = {
  'paypal': 'PayPal',
  'transferencia': 'Transferencia',
  'efectivo': 'Efectivo',
  'online': 'Pagos en Línea Visa',
};

class TipoPago {
  final int id;
  final String nombre;
  final String? imagenUrl;

  TipoPago({required this.id, required this.nombre, this.imagenUrl});

  factory TipoPago.fromJson(Map<String, dynamic> json) {
    return TipoPago(
      id: json['id'],
      nombre: json['nombre'],
      imagenUrl: json['imagen_qr'],
    );
  }
}

class PantallaPago extends StatefulWidget {
  const PantallaPago({super.key});

  @override
  _PantallaPagoState createState() => _PantallaPagoState();
}

class _PantallaPagoState extends State<PantallaPago> {
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = true;
  int? cartId;
  TipoPago? selectedPaymentMethod;
  int? usuario;
  List<TipoPago> _tiposPago = [];

  @override
  void initState() {
    super.initState();
    _cargarTiposPago();
    _fetchUserData().then((data) {
      setState(() {
        userData = data;
      });
    }).catchError((error) {
      print('Error fetching user data: $error');
    });
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      usuario = userId;
      print('usuario logeado $userId');
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

  Future<void> _cargarTiposPago() async {
    final uri = Uri.parse('http://161.35.16.6/transaccciones/tipos_pago/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> tiposPagoJson = json.decode(response.body);
      setState(() {
        _tiposPago =
            tiposPagoJson.map((json) => TipoPago.fromJson(json)).toList();
        selectedPaymentMethod = _tiposPago.firstWhere((pago) =>
            pago.nombre == 'online'); // Seleccionar "Pagos en Línea Visa"
      });
    } else {
      print('Solicitud fallida con estado: ${response.statusCode}.');
    }
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    print('$userId--------------------------------------');
    if (userId == null) {
      throw Exception("User ID not found");
    }
    final response = await http
        .get(Uri.parse('http://161.35.16.6/usuarios/patients/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user data');
    }
  }

  double calcularTotal() {
    double total = 0.0;
    for (var product in displayedProducts) {
      double precio = double.parse(product['precio'].toString());
      double descuento =
          double.parse(product['descuento_porcentaje'].toString());
      int cantidad = int.parse(product['cantidad'].toString());
      final discountedPrice = precio - (precio * (descuento / 100));
      total += discountedPrice * cantidad; // Multiplicamos por la cantidad aquí
    }
    return double.parse(total.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    double cartTotal = calcularTotal();
    DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Datos del Pedido',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            // Información del usuario
            if (userData.isNotEmpty) ...[
              Text(
                'Nombre: ${userData['user']['first_name']}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Fecha: ${now.day}/${now.month}/${now.year}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Divider(),
            ],

            // Lista de productos
            displayedProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Carrito vacío',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                : Column(
                    children: displayedProducts.map((product) {
                      double precio =
                          double.parse(product['precio'].toString());
                      double descuento = double.parse(
                          product['descuento_porcentaje'].toString());
                      double discountedPrice =
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
                                  product['imagenes'][0]['ruta_imagen'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['nombre'].replaceAll('Ã±', 'ñ'),
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
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        descuento > 0
                                            ? 'Ahora: Bs$discountedPrice'
                                            : 'Precio: Bs$precio',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: descuento > 0
                                              ? const Color(0xFF1E272E)
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Cantidad: ${product['cantidad']}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            if (displayedProducts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Total a Pagar:',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bs${cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E272E),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Selección de método de pago
            if (_tiposPago.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Selecciona un método de pago:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              DropdownButton<TipoPago>(
                value: selectedPaymentMethod,
                hint: const Text('Método de pago'),
                isExpanded: true,
                items: _tiposPago
                    .where((pago) => pago.nombre == 'online')
                    .map<DropdownMenuItem<TipoPago>>((TipoPago method) {
                  return DropdownMenuItem<TipoPago>(
                    value: method,
                    child: Row(
                      children: [
                        if (method.imagenUrl != null)
                          Image.network(
                            method.imagenUrl!,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                color: Colors.red,
                              );
                            },
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tiposPagoMap[method.nombre] ?? method.nombre,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (TipoPago? newValue) {
                  setState(() {
                    selectedPaymentMethod = newValue;
                    print(selectedPaymentMethod!.nombre);
                  });
                },
              ),
              const SizedBox(height: 20),
            ],

            // Botón de confirmación
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E272E),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () {
                if (selectedPaymentMethod != null &&
                    userData['user']['first_name'].isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage(
                              total: cartTotal.toInt(),
                              usuario: usuario.toString(),
                              carritoId: cartId.toString(),
                              tipoPagoId: 2.toString(),
                            )),
                  );
                }
              },
              child: const Text('Confirmar Pago',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
