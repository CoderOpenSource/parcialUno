import 'package:dio/dio.dart';

class TrafficInterceptor extends Interceptor {
  final accessToken =
      'pk.eyJ1IjoibW9zaXRvIiwiYSI6ImNsaHJqNDJsbjJwZzgzZ2xyZWIxanVhbDYifQ.bGYenrxVb9doEFL2NoTxfQ';
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters.addAll({
      'alternatives': true,
      'geometries': 'polyline6',
      'overview': 'simplified',
      'steps': false,
      'access_token': accessToken,
    });
    super.onRequest(options, handler);
  }
}
