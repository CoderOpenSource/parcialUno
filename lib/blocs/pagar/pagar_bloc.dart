import 'dart:async';


import 'package:bloc/bloc.dart';

import 'package:meta/meta.dart';


import 'package:mapas_api/models/tarjeta_credito.dart';


part 'pagar_event.dart';

part 'pagar_state.dart';


class PagarBloc extends Bloc<PagarEvent, PagarState> {

  PagarBloc()
      : super(PagarState(
          tarjeta: TarjetaCredito(
              cardNumberHidden: '3782',
              cardNumber: '378282246310005',
              brand: 'american express',
              cvv: '2134',
              expiracyDate: '01/25',
              cardHolderName: 'Eduardo Rios'),
        ));


  Stream<PagarState> mapEventToState(PagarEvent event) async* {

    if (event is OnSeleccionarTarjeta) {

      yield state.copyWith(
          tarjetaActiva: true,
          tarjeta: event.tarjeta,
          montoPagar: 110,
          moneda: 'Bs');

    } else if (event is OnDesactivarTarjeta) {

      yield state.copyWith(
        tarjetaActiva: false,
        montoPagar: 110,
        moneda: '',
        tarjeta: TarjetaCredito(
            cardNumberHidden: '3782',
            cardNumber: '378282246310005',
            brand: 'american express',
            cvv: '2134',
            expiracyDate: '01/25',
            cardHolderName: 'Eduardo Rios'),
      );

    }

  }

}

