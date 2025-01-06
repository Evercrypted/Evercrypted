import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rhttp/rhttp.dart';

class HttpClient {
  HttpClient._();

  static late RhttpClient client;

  static initialize() async {
    client = await RhttpClient.create(
        settings: ClientSettings(
      baseUrl: 'http://10.0.2.2:3001',
      // baseUrl: 'http://localhost:3001',
      // baseUrl: 'https://188.245.154.95',
      tlsSettings: TlsSettings(verifyCertificates: false),
    ));
  }

  static addAuth(token) async {
    client.dispose();
    client = await RhttpClient.create(
      settings: ClientSettings(
        baseUrl: 'http://10.0.2.2:3001',
        // baseUrl: 'http://localhost:3001',
        // baseUrl: 'https://188.245.154.95',
        tlsSettings: TlsSettings(verifyCertificates: false),
      ),
      interceptors: [
        SimpleInterceptor(
            beforeRequest: (request) async => Interceptor.next(
                request.addHeader(
                    name: HttpHeaderName.authorization,
                    value: 'Bearer $token'))),
      ],
    );
  }
}

// import 'package:dio/dio.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// final dio = Dio(
//   BaseOptions(
//     connectTimeout: const Duration(seconds: 3),
//   ),
// );

// initializeDio() {
//   dio
//     ..options.baseUrl = 'http://localhost:3001'
//     // ..options.baseUrl = 'http://49.13.136.216'
//     ..interceptors.add(PrettyDioLogger());
//   // ..interceptors.add(RetryInterceptor(
//   //   dio: dio,
//   //   logPrint: print, // specify log function (optional)
//   //   retries: 3, // retry count (optional)
//   //   retryDelays: const [
//   //     // set delays between retries (optional)
//   //     Duration(seconds: 1), // wait 1 sec before first retry
//   //     Duration(seconds: 2), // wait 2 sec before second retry
//   //     Duration(seconds: 3), // wait 3 sec before third retry
//   //   ],
//   // ));
// }
