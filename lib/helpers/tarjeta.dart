import '../models/tarjeta_credito.dart';

final List<TarjetaCredito> tarjetas = <TarjetaCredito>[
  TarjetaCredito(
      cardNumberHidden: '4218',
      cardNumber: '4218281008744688',
      brand: 'Visa',
      cvv: '891',
      expiracyDate: '03/27',
      cardHolderName: 'Samuel Huanca'),
];

void agregarNuevaTarjeta({
  required String cardNumber,
  required String brand,
  required String cvv,
  required String expiracyDate,
  required String cardHolderName,
}) {
  // Ocultar el número de la tarjeta excepto los últimos 4 dígitos
  String cardNumberHidden = cardNumber.substring(cardNumber.length - 4);

  // Crear una nueva instancia de la tarjeta de crédito
  TarjetaCredito nuevaTarjeta = TarjetaCredito(
    cardNumberHidden: cardNumberHidden,
    cardNumber: cardNumber,
    brand: brand,
    cvv: cvv,
    expiracyDate: expiracyDate,
    cardHolderName: cardHolderName,
  );

  // Agregar la nueva tarjeta a la lista
  tarjetas.add(nuevaTarjeta);
}
