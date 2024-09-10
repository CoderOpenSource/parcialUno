import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/screens/workshop/services.dart';
import 'dart:io';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';
import 'package:mapas_api/helpers/helpers.dart';
import 'package:mapas_api/main.dart';
import 'package:mapas_api/helpers/tarjeta.dart';
import 'package:mapas_api/widgets/stripe/tarjeta_pago.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

Future<void> generatePdf(
    BuildContext context,
    String patientName,
    String serviceName,
    String doctorName,
    String shift,
    String price,
    String date,
    String startTime) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Detalles de la Cita', style: pw.TextStyle(fontSize: 24)),
            pw.Divider(),
            pw.Text('Paciente: $patientName'),
            pw.Text('Servicio: $serviceName'),
            pw.Text('Doctor: $doctorName'),
            pw.Text('Turno: $shift'),
            pw.Text('Fecha: $date'), // Añadir la fecha seleccionada
            pw.Text('Hora de Inicio: $startTime'), // Añadir la hora de inicio
            pw.Text('Precio: $price'),
            pw.Divider(),
            pw.Text(
              'Gracias por elegir nuestra clínica',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ],
        );
      },
    ),
  );

  // Guardar el PDF en un archivo y mostrarlo
  final output = await getTemporaryDirectory();
  final file = File("${output.path}/Cita.pdf");
  await file.writeAsBytes(await pdf.save());
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}

class DetailScreen extends StatefulWidget {
  final Service service;

  DetailScreen({required this.service});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<List<Schedule>> schedules;
  String? selectedShift;
  Schedule? selectedSchedule;
  DateTime? selectedDate; // Añade este campo

  @override
  void initState() {
    super.initState();
    schedules = fetchSchedules();
  }

//se hace una peticion para obtener los horarios del servicio
  Future<List<Schedule>> fetchSchedules() async {
    final response = await http.get(
      Uri.parse('http://161.35.16.6/scheduling/schedules/'),
    );

    if (response.statusCode == 200) {
      // Decodificar la respuesta como UTF-8
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      List<Schedule> allSchedules =
          jsonResponse.map((schedule) => Schedule.fromJson(schedule)).toList();

      // Filtrar los schedules basados en los IDs de los doctores del servicio
      List<Schedule> filteredSchedules = allSchedules.where((schedule) {
        return widget.service.doctorIds.contains(schedule.doctorId);
      }).toList();

      return filteredSchedules;
    } else {
      throw Exception('Failed to load schedules');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double discountedPrice = double.parse(widget.service.price) *
        (1 - widget.service.discount / 100);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Servicio'),
        backgroundColor: Color.fromARGB(255, 43, 29, 45),
      ),
      body: FutureBuilder<List<Schedule>>(
        future: schedules,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            var groupedByShift = groupByShift(snapshot.data!);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple[800],
                            ),
                          ),
                          SizedBox(height: 10),
                          Image.network(
                            widget.service.image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                          SizedBox(height: 10),
                          Text(
                            widget.service.description,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Precio: ${widget.service.price}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Descuento: ${widget.service.discount}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Precio con Descuento: ${discountedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      DropdownButton<String>(
                        hint: Text("Seleccionar Turno"),
                        value: selectedShift,
                        onChanged: (newValue) {
                          setState(() {
                            selectedShift = newValue;
                            selectedSchedule = null; // Reset schedule selection
                          });
                        },
                        items: groupedByShift.keys.map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift,
                            child: Text(shift),
                          );
                        }).toList(),
                      ),
                      if (selectedShift != null)
                        DropdownButton<Schedule>(
                          hint: Text("Seleccionar Doctor"),
                          value: selectedSchedule,
                          onChanged: (newValue) {
                            setState(() {
                              selectedSchedule = newValue;
                            });
                          },
                          items: groupedByShift[selectedShift!]!
                              .map((schedule) => DropdownMenuItem<Schedule>(
                                    value: schedule,
                                    child: Text(schedule.doctorName),
                                  ))
                              .toList(),
                        ),
                      if (selectedShift != null && selectedSchedule != null)
                        Column(
                          children: [
                            ListTile(
                              title: Text(selectedSchedule!.doctorName),
                              subtitle: Text("${selectedSchedule!.start} "),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: Colors.yellow[800]!,
                                  width: 2.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.yellow[800],
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Para confirmar la cita necesita realizar un pago previamente.',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now()
                                          .subtract(Duration(days: 0)),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null &&
                                        picked != selectedDate) {
                                      setState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  icon:
                                      Icon(Icons.schedule, color: Colors.white),
                                  label: Text(
                                    selectedDate == null
                                        ? 'Seleccionar Fecha'
                                        : 'Fecha: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(
                                        255, 43, 29, 45), // Lila oscuro
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 12),
                                    textStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://res.cloudinary.com/dkpuiyovk/image/upload/v1704377815/pagos/codigos_qr/vsisa_wjaysv_ei3c2f.png', // Reemplaza con la URL de la imagen que deseas usar
                                  height: 30,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Pagos en línea VISA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        _showConfirmationDialog(context, discountedPrice),
                    child: Text(
                      'Confirmar Cita',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color.fromARGB(255, 43, 29, 45), // Lila oscuro
                      padding: EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12), // Tamaño del botón
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Map<String, List<Schedule>> groupByShift(List<Schedule> schedules) {
    var grouped = <String, List<Schedule>>{};
    for (var schedule in schedules) {
      grouped.putIfAbsent(schedule.shift, () => []).add(schedule);
    }
    return grouped;
  }

  void _showConfirmationDialog(
      BuildContext context, double discountedPrice) async {
    final prefs = await SharedPreferences.getInstance();
    final patientName = prefs.getString('userName') ?? 'Nombre del Paciente';
    final userId = prefs.getInt('userId');

    if (selectedDate == null) {
      // Muestra un mensaje si no se ha seleccionado una fecha
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Por favor seleccione una fecha para la cita.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cita'),
          content: const Text('¿Desea confirmar esta cita?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfirmationScreen(
                      total: discountedPrice.toInt(),
                      patientName: patientName,
                      serviceName: widget.service.name,
                      doctorName: selectedSchedule!.doctorName,
                      shift: selectedShift!,
                      price: discountedPrice.toStringAsFixed(2),
                      date: selectedDate!
                          .toLocal()
                          .toString()
                          .split(' ')[0], // Fecha seleccionada
                      patientId: userId!,
                      doctorId: selectedSchedule!.doctorId,
                      serviceId: widget.service.id,
                      consultingRoomId: 1, // Set a valid ID for consulting room
                      scheduleId: selectedSchedule!.id,
                      startTime: selectedSchedule!
                          .start, // Hora de inicio del horario del doctor
                    ),
                  ),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}

class Schedule {
  final int id;
  final int doctorId;
  final String doctorName;
  final String start;
  final String end;
  final String shift;

  Schedule({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.start,
    required this.end,
    required this.shift,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      doctorId: json['doctor']['user']['id'],
      doctorName: json['doctor']['user']['first_name'] +
          ' ' +
          json['doctor']['user']['last_name'],
      start: json['start_time'],
      end: json['end_time'],
      shift: json['shift']['name'],
    );
  }
}

class ConfirmationScreen extends StatefulWidget {
  final int total;
  final String patientName;
  final String serviceName;
  final String doctorName;
  final String shift;
  final String price;
  final String date;
  final int patientId;
  final int doctorId;
  final int serviceId;
  final int consultingRoomId;
  final int scheduleId;
  final String startTime; // Añadir campo de hora de inicio

  ConfirmationScreen({
    required this.total,
    required this.patientName,
    required this.serviceName,
    required this.doctorName,
    required this.shift,
    required this.price,
    required this.date,
    required this.patientId,
    required this.doctorId,
    required this.serviceId,
    required this.consultingRoomId,
    required this.scheduleId,
    required this.startTime, // Añadir campo de hora de inicio
  });

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool done = false;
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    super.initState();
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print("DONE");
      setState(() {
        done = true;
      });
    } catch (e) {
      setState(() {
        done = false;
      });
      print('FAILED');
    }
  }

  createPaymentIntent(int total) async {
    try {
      String monto = (total * 100).toString();
      Map<String, dynamic> body = {
        "amount": monto,
        "currency": "USD",
      };
      http.Response response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: body,
        headers: {
          "Authorization":
              "Bearer sk_test_51OM6g0A7qrAo0IhR79BHknFXkoeVL7M3yF9UYYnRlTEbGLQhc90La5scbYs2LAkHbh6dYQCw8CbqsTgNAgYvLBNn00I1QqzLDj",
        },
      );
      print(response.body);
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> createConsultation({
    required String date,
    required int patientId,
    required int doctorId,
    required int serviceId,
    required int consultingRoomId,
    required int scheduleId,
  }) async {
    final response = await http.post(
      Uri.parse('http://161.35.16.6/consultations/consultations/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': date,
        'patient': patientId,
        'doctor': doctorId,
        'service': serviceId,
        'consulting_room': consultingRoomId,
        'schedule': scheduleId,
      }),
    );

    if (response.statusCode == 201) {
      print('Consulta creada exitosamente');
    } else {
      print('Error al crear la consulta: ${response.body}');
    }
  }

  Future<void> makePayment(int total) async {
    try {
      paymentIntent = await createPaymentIntent(total);

      var gpay = const PaymentSheetGooglePay(
        merchantCountryCode: "US",
        currencyCode: "USD",
        testEnv: true,
      );
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentIntent!["client_secret"],
        style: ThemeMode.dark,
        merchantDisplayName: "Prueba",
        googlePay: gpay,
      ));

      await displayPaymentSheet();
      if (done) {
        await createConsultation(
          date: widget.date,
          patientId: widget.patientId,
          doctorId: widget.doctorId,
          serviceId: widget.serviceId,
          consultingRoomId: widget.consultingRoomId,
          scheduleId: widget.scheduleId,
        );
      }
    } catch (e) {
      print('Error en makePayment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Stripe.publishableKey =
        'pk_test_51OM6g0A7qrAo0IhR3dbWDmmwmpyZ6fu5WcwDQ9kSNglvbcqlPKy4xXSlwltVkGOkQgWh12T7bFJgjCQq3B7cGaFV007JonVDPp';

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 43, 29, 45),
          title: const Text('Confirmación de la Cita'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final cardEditController = CardEditController();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Agregar tarjeta'),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width * 1,
                        child: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              CardField(
                                controller: cardEditController,
                                onCardChanged: (card) {
                                  // Puedes manejar los cambios en la tarjeta aquí
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Guardar'),
                          onPressed: () {
                            print(cardEditController.details);
                            agregarNuevaTarjeta(
                                cardNumber: cardEditController.details.last4!,
                                brand: cardEditController.details.brand!,
                                expiracyDate:
                                    '${cardEditController.details.expiryMonth}/${cardEditController.details.expiryYear}',
                                cvv: 123.toString(),
                                cardHolderName: 'MOSITO');
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            )
          ],
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
                        Navigator.push(context,
                            navegarFadeIn(context, const TarjetaPage()));
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
                  }),
            ),
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Monto a Pagar: ${widget.total}',
                    style: TextStyle(
                      color: Color(0xFF1E272E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  MaterialButton(
                    onPressed: () async {
                      await makePayment(widget.total);

                      if (done)
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Compra realizada con éxito"),
                              content: Text("Cita confirmada!"),
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
                                    await generatePdf(
                                      context,
                                      widget.patientName,
                                      widget.serviceName,
                                      widget.doctorName,
                                      widget.shift,
                                      widget.price,
                                      widget
                                          .date, // Pasar la fecha seleccionada
                                      widget.startTime,
                                      // Pasar la hora de inicio del horario del doctor
                                    );
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
                        const Text(' Pagar',
                            style:
                                TextStyle(color: Colors.white, fontSize: 22)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
