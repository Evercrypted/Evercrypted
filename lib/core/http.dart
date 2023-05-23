import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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

initializeDio() {
  dio
    ..options.baseUrl = 'http://localhost:3000'
    // ..interceptors.add(CertificatePinningInterceptor(
    //     allowedSHAFingerprints: allowedSHAFingerprints))
    ..interceptors.add(PrettyDioLogger())
    ..interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 3, // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
}

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
