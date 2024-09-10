import 'package:dio/dio.dart';

class StripeService {
  // Singleton
  StripeService._privateConstructor();
  static final StripeService _intance = StripeService._privateConstructor();
  factory StripeService() => _intance;

  final String _paymentApiUrl = 'https://api.stripe.com/v1/payment_intents';
  static const String _secretKey =
      'sk_test_51HIgBqKmrePqgf9DSVeUNw7GfLlNJBlwn2JWDBVdimhHCO7N2fW8vgQBWUBKYontobwkXSWXv3hTUPVtZ5PHVKXz007MjU1qPW';
  final String _apiKey =
      'pk_test_51HIgBqKmrePqgf9DEW9flGs2Sy1ZKBnIYrCnw8DcMnSc5D0rvB13IETHc3mUZoPUePx4eZ50SvVFSn74RaK5WF1B00EcvZTSxb';

  final headerOptions = Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Authorization': 'Bearer ${StripeService._secretKey}'});
}
