// import 'package:dio/dio.dart';

// import '../http.dart';

// void addAuthInterceptor(token) {
//   dio.interceptors.add(InterceptorsWrapper(
//     onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
//       options.headers['authorization'] = 'Bearer $token';

//       return handler.next(options);
//     },
//     onError: (DioException e, ErrorInterceptorHandler handler) {
//       // Do something with response error.
//       // If you want to resolve the request with some custom data,
//       // you can resolve a `Response` object using `handler.resolve(response)`.
//       return handler.next(e);
//     },
//   ));
// }
