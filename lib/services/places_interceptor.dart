import 'package:dio/dio.dart';

class PlacesInterceptor extends Interceptor {
  final accessToken =
      'pk.eyJ1IjoibW9zaXRvIiwiYSI6ImNsaHJqNDJsbjJwZzgzZ2xyZWIxanVhbDYifQ.bGYenrxVb9doEFL2NoTxfQ';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters
        .addAll({'access_token': accessToken, 'language': 'es'});

    super.onRequest(options, handler);
  }
}
