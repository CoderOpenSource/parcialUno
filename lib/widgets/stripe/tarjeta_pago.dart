import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

import 'package:mapas_api/blocs/pagar/pagar_bloc.dart';

import 'package:mapas_api/widgets/total_pay.dart';

class TarjetaPage extends StatelessWidget {
  const TarjetaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tarjeta = BlocProvider.of<PagarBloc>(context).state.tarjeta;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Pagar'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                BlocProvider.of<PagarBloc>(context).add(OnDesactivarTarjeta());
                Navigator.pop(context);
              }),
        ),
        body: Stack(
          children: [
            Container(),
            Hero(
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
            Positioned(bottom: 0, child: TotalPayButton())
          ],
        ));
  }
}
