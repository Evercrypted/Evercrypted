import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/offline/action_queue/allowed_for_queue.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/main.dart';
import 'package:flutter/foundation.dart';
import 'package:rhttp/rhttp.dart';

class AppHttpClient {
  AppHttpClient._();

  static late RhttpClient client;

  static String _getBaseUrl() {
    // Use different URLs based on platform and debug mode
    // if (kDebugMode) {
    //   if (Platform.isAndroid) {
    //     return 'http://10.0.2.2:3001'; // Android emulator
    //   } else if (Platform.isIOS) {
    //     return 'http://localhost:3001'; // iOS simulator
    //   } else {
    //     return 'http://localhost:3001'; // Desktop/Web
    //   }
    // } else {
    //   return 'http://10.0.2.2:3001'; // Production
    //   // return 'https://test-api.evercrypted.com'; // Production
    // }
    return 'https://api.evercrypted.com';
  }

  static initialize() async {
    final baseUrl = _getBaseUrl();
    debugPrint('AppHttpClient: Initializing with baseUrl: $baseUrl');

    client = await RhttpClient.create(
        settings: ClientSettings(
      baseUrl: baseUrl,
      tlsSettings: TlsSettings(verifyCertificates: false),
    ));
  }

  static addAuth() async {
    try {
      client.dispose();
    } catch (e) {
      debugPrint('AppHttpClient: Error disposing client: $e');
    }

    final authToken = await Auth.getToken;
    final otpToken = await Auth.getOtpToken;

    // Validate that we have the necessary components
    if (ChatSocket.key == null) {
      throw Exception('ChatSocket key is null, cannot initialize HTTP client');
    }

    List<SimpleInterceptor> interceptorsList = [];

    try {
      final cryptedToken = await encodePayload(authToken, ChatSocket.key, true);
      final cryptedOtpToken =
          await encodePayload(otpToken, ChatSocket.key, true);
      final from = Auth.getUser?.uid;

      if (cryptedToken != null) {
        interceptorsList.add(SimpleInterceptor(
            beforeRequest: (request) async => Interceptor.next(
                request.addHeader(
                    name: HttpHeaderName.authorization,
                    value: jsonEncode(cryptedToken).toString()))));
      }
      if (cryptedOtpToken != null) {
        interceptorsList.add(SimpleInterceptor(
            beforeRequest: (request) async => Interceptor.next(
                request.addHeader(
                    name: HttpHeaderName.proxyAuthorization,
                    value: jsonEncode(cryptedOtpToken).toString()))));
      }
      if (from != null) {
        interceptorsList.add(SimpleInterceptor(
            beforeRequest: (request) async => Interceptor.next(
                request.addHeader(name: HttpHeaderName.from, value: from))));
      }

      client = await RhttpClient.create(
        settings: ClientSettings(
          baseUrl: _getBaseUrl(),
          tlsSettings: TlsSettings(verifyCertificates: false),
          throwOnStatusCode: false, // Don't throw on HTTP errors
        ),
        interceptors: interceptorsList,
      );

      debugPrint('AppHttpClient: Successfully initialized with auth headers');
    } catch (e) {
      debugPrint('AppHttpClient: Error creating client with auth: $e');
      throw Exception('Failed to create HTTP client: $e');
    }
  }

  static Future<dynamic> message({
    required String channel,
    required String type,
    dynamic payload,
    bool isFromQueue = false,
  }) async {
    Future<int> saveActionForLater() async {
      final writingToQueueCompleter = Completer<int>();
      final action = ActionQueue(
          channel: channel,
          type: type,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final int id = obx.actionQueues.put(action);
      writingToQueueCompleter.complete(id);
      return writingToQueueCompleter.future;
    }

    final respCompleter = Completer<dynamic>();

    // Skip connection check if processing from queue
    // The queue processor should only run when connected
    if (!isFromQueue &&
        (ChatSocket.socket?.connected != true ||
            ChatSocket.isConnected == null ||
            !ChatSocket.isConnected!)) {
      if (allowedForQueue.contains('$channel/$type')) {
        final int queuedItemId = await saveActionForLater();
        respCompleter
            .complete({'status': 'queued', 'queuedItemId': queuedItemId});
      } else {
        respCompleter.completeError(
            'Could not connect to server, please check your internet connection.');
      }
    } else {
      // Ensure we have a valid key
      if (ChatSocket.key == null) {
        debugPrint('AppHttpClient: No encryption key available');
        respCompleter.completeError('No encryption key available');
        return respCompleter.future;
      }

      try {
        final crypted = await encodePayload(
            {'channel': channel, 'type': type, 'payload': payload},
            ChatSocket.key,
            true);

        final response = await client.post('/socket/handle-message',
            body: HttpBody.json(crypted));

        final decodedPayload = await decodePayload(
          response.bodyToJson['crypted'],
          response.bodyToJson['iv'],
          ChatSocket.key,
          true,
        );

        debugPrint(decodedPayload.toString());

        if (decodedPayload['error'] != null) {
          respCompleter.completeError(decodedPayload['error']);
        } else if (decodedPayload['status'] == 'ok') {
          respCompleter.complete(decodedPayload['payload']);
        } else {
          respCompleter.complete(decodedPayload);
        }
      } catch (error) {
        debugPrint('AppHttpClient error: $error');
        respCompleter.completeError(error);
      }
    }
    return respCompleter.future;
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
