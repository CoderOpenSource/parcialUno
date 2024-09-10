import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/main.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';
import 'package:mapas_api/helpers/helpers.dart';
import 'package:mapas_api/helpers/tarjeta.dart';
import 'package:mapas_api/widgets/stripe/tarjeta_pago.dart';

class HomePage extends StatefulWidget {
  final int total;
  final String usuario;
  final String carritoId;
  final String tipoPagoId;

  const HomePage({
    Key? key,
    required this.total,
    required this.usuario,
    required this.carritoId,
    required this.tipoPagoId,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  List<Map<String, dynamic>> displayedProducts = [];
  String? transactionId;
  bool done = false;
  String? userName;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      final response = await http.get(
        Uri.parse('http://161.35.16.6/usuarios/users/${widget.usuario}/'),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          userName = '${userData['first_name']} ${userData['last_name']}';
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error al obtener el nombre del usuario: $error');
    }
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      final response = await http
          .get(Uri.parse('http://161.35.16.6/transaccciones/carritos/'));
      final data = json.decode(response.body) as List;

      final userCart = data.firstWhere(
        (cart) => cart['usuario'] == userId && cart['disponible'] == true,
        orElse: () => null,
      );

      if (userCart != null) {
        List<Map<String, dynamic>> productsDetails = [];
        for (var item in userCart['productos_detalle']) {
          final productId = item['producto'];
          final productResponse = await http.get(
            Uri.parse('http://161.35.16.6/productos/productos/$productId'),
          );
          final productData = json.decode(productResponse.body);
          productData['cantidad'] = item['cantidad'];
          productData['detalle_id'] = item['id'];
          productsDetails.add(productData);
        }
        setState(() {
          displayedProducts = productsDetails;
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

  Future<void> createTransaction() async {
    try {
      // Crear la transacción
      final response = await http.post(
        Uri.parse('http://161.35.16.6/transaccciones/transacciones/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario': widget.usuario,
          'carrito': widget.carritoId,
          'tipo_pago': widget.tipoPagoId,
        }),
      );

      if (response.statusCode == 201) {
        final transactionData = json.decode(response.body);
        setState(() {
          transactionId = transactionData['id'].toString();
        });

        // Marcar el carrito actual como no disponible
        final updateCartResponse = await http.patch(
          Uri.parse(
              'http://161.35.16.6/transaccciones/carritos/${widget.carritoId}/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'disponible': false}),
        );

        if (updateCartResponse.statusCode != 200) {
          print('Error al actualizar el carrito: ${updateCartResponse.body}');
        }

        // Crear un nuevo carrito vacío para el usuario
        final newCartResponse = await http.post(
          Uri.parse('http://161.35.16.6/transaccciones/carritos/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usuario': widget.usuario,
            'disponible': true,
          }),
        );

        if (newCartResponse.statusCode != 201) {
          print('Error al crear el nuevo carrito: ${newCartResponse.body}');
        }
      } else {
        print('Error al crear la transacción: ${response.body}');
      }
    } catch (error) {
      print('Error en createTransaction: $error');
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

  Future<void> generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final date = DateTime.now().toString().split(' ')[0];

    // Cargar las imágenes
    final images = await Future.wait(displayedProducts.map((product) async {
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
                itemCount: displayedProducts.length,
                itemBuilder: (context, index) {
                  final product = displayedProducts[index];
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
                'Total a Pagar: Bs${calcularTotal().toStringAsFixed(2)}',
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
  }

  double calcularTotal() {
    double total = 0.0;
    for (var product in displayedProducts) {
      double precio = double.parse(product['precio'].toString());
      double descuento =
          double.parse(product['descuento_porcentaje'].toString());
      int cantidad = int.parse(product['cantidad'].toString());
      final discountedPrice = precio - (precio * (descuento / 100));
      total += discountedPrice * cantidad;
    }
    return total;
  }

  Future<void> makePayment(int total) async {
    try {
      final paymentIntent = await createPaymentIntent(total);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.light,
          merchantDisplayName: 'Tu Farmacia',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await createTransaction();

      setState(() {
        done = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Compra realizada con éxito'),
            content:
                Text('Puede pasar a recoger sus productos a nuestra farmacia.'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await generatePdf(context);
                  final output = await getTemporaryDirectory();
                  final file = File("${output.path}/Pedido.pdf");
                  await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async =>
                          file.readAsBytes());
                },
                child: Row(
                  children: <Widget>[
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Descargar Comprobante'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyApp()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error al realizar el pago: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Ocurrió un error al procesar su pago. Intente nuevamente.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer sk_test_51OM6g0A7qrAo0IhR79BHknFXkoeVL7M3yF9UYYnRlTEbGLQhc90La5scbYs2LAkHbh6dYQCw8CbqsTgNAgYvLBNn00I1QqzLDj',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toString(),
          'currency': 'USD',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      print('Error creating payment intent: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Stripe.publishableKey =
        'pk_test_51OM6g0A7qrAo0IhR3dbWDmmwmpyZ6fu5WcwDQ9kSNglvbcqlPKy4xXSlwltVkGOkQgWh12T7bFJgjCQq3B7cGaFV007JonVDPp';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E272E),
        title: const Text('Datos del Pedido'),
      ),
      body: Stack(
        children: [
          Positioned(
            width: size.width,
            height: size.height,
            top: 200,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              physics: const BouncingScrollPhysics(),
              itemCount: tarjetas.length,
              itemBuilder: (_, i) {
                final tarjeta = tarjetas[i];

                return GestureDetector(
                  onTap: () {
                    BlocProvider.of<PagarBloc>(context)
                        .add(OnSeleccionarTarjeta(tarjeta));
                    Navigator.push(
                        context, navegarFadeIn(context, const TarjetaPage()));
                  },
                  child: Hero(
                    tag: tarjeta.cardNumber,
                    child: CreditCardWidget(
                      cardNumber: tarjeta.cardNumberHidden,
                      expiryDate: tarjeta.expiracyDate,
                      cardHolderName: tarjeta.cardHolderName,
                      cvvCode: tarjeta.cvv,
                      showBackView: false,
                      onCreditCardWidgetChange: (CreditCardBrand) {},
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Monto a Pagar: Bs${widget.total}',
                  style: TextStyle(
                    color: Color(0xFF1E272E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 20),
                MaterialButton(
                  onPressed: () async {
                    await makePayment(widget.total);

                    if (done) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Compra realizada con éxito"),
                            content: Text(
                                "Puede pasar a recoger sus productos a nuestra farmacia."),
                            actions: <Widget>[
                              TextButton(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.download),
                                    SizedBox(width: 8),
                                    Text("Descargar"),
                                  ],
                                ),
                                onPressed: () async {
                                  await generatePdf(context);
                                  final output = await getTemporaryDirectory();
                                  final file =
                                      File("${output.path}/Pedido.pdf");
                                  await Printing.layoutPdf(
                                      onLayout: (PdfPageFormat format) async =>
                                          file.readAsBytes());
                                },
                              ),
                              TextButton(
                                child: Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => MyApp()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  height: 45,
                  minWidth: 150,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  color: Colors.black,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Platform.isAndroid
                            ? FontAwesomeIcons.google
                            : FontAwesomeIcons.apple,
                        color: Colors.white,
                      ),
                      const Text(
                        ' Pagar',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
