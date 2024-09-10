import 'dart:io';
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';

import 'package:mapas_api/services/stripe_service.dart';

class TotalPayButton extends StatelessWidget {
  final StripeService stripeService = StripeService();

  Map<String, dynamic>? paymentIntent;

  TotalPayButton({super.key});

  void makePayment() async {
    print('Estoy dentro de la funcion');
    displayPaymentSheet();
    try {
      paymentIntent = await createPaymentIntent();

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

      displayPaymentSheet();
    } catch (e) {
      print('Error en makePayment: $e');
    }
  }

  void displayPaymentSheet() async {
    print('F');
    try {
      await Stripe.instance.presentPaymentSheet();
      print("DONE");
    } catch (e) {
      print('FAILED');
    }
  }

  createPaymentIntent() async {
    try {
      Map<String, dynamic> body = {
        "amount":
            "1000000", // aqui es el monto a pagar por el objeto, para que ingreses el monto de cada juguete ponle un parametro
        "currency": "USD", //en el void makePayment
      };
      http.Response response = await http.post(
          Uri.parse("https://api.stripe.com/v1/payment_intents"),
          body: body,
          headers: {
            "Authorization":
                "sk_test_51OM6g0A7qrAo0IhR79BHknFXkoeVL7M3yF9UYYnRlTEbGLQhc90La5scbYs2LAkHbh6dYQCw8CbqsTgNAgYvLBNn00I1QqzLDj",
            "Content-Type": "application/x-www-form-urlencoded",
          });
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final pagarBloc = BlocProvider.of<PagarBloc>(context).state;

    return Container(
      width: width,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          )),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${pagarBloc.montoPagar} ${pagarBloc.moneda}',
                  style: const TextStyle(fontSize: 20))
            ],
          ),
          _BtnPay(
            onPaymentPressed: makePayment,
          )
        ],
      ),
    );
  }
}

class _BtnPay extends StatelessWidget {
  final VoidCallback onPaymentPressed;

  const _BtnPay({Key? key, required this.onPaymentPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 45,
      minWidth: 150,
      shape: const StadiumBorder(),
      elevation: 0,
      color: Colors.black,
      onPressed: onPaymentPressed,
      child: Row(
        children: [
          Icon(
            Platform.isAndroid
                ? FontAwesomeIcons.google
                : FontAwesomeIcons.apple,
            color: Colors.white,
          ),
          const Text(' Pagar', style: TextStyle(color: Colors.white, fontSize: 22)),
        ],
      ),
    );
  }
}
