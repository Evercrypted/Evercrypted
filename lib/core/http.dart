import 'package:dio/dio.dart';
// import 'package:dio_http2_adapter/dio_http2_adapter.dart';
// import 'package:http_certificate_pinning/http_certificate_pinning.dart';

// List<String> allowedSHAFingerprints = [
//   '5E:F0:3C:83:8E:66:AA:8D:51:7D:A9:CA:0A:9C:12:5A:3A:0D:15:BD:14:17:88:D2:7D:FD:13:44:90:BB:55:25'
// ];

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 3),
  ),
);

// Dio dio() {
//   final dio = Dio();
  
//   // ..httpClientAdapter = Http2Adapter(
//   //   ConnectionManager(
//   //     idleTimeout: const Duration(seconds: 10),
//   //     onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
//   //   ),
//   // );
//   return dio;
// }
