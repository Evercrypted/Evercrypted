import 'dart:async';
import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/offline/action_queue/allowed_for_queue.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/main.dart';
import 'package:flutter/material.dart';
import 'package:rhttp/rhttp.dart';

class AppHttpClient {
  AppHttpClient._();

  static late RhttpClient client;

  static initialize() async {
    client = await RhttpClient.create(
        settings: ClientSettings(
      baseUrl: 'http://10.0.2.2:3001',
      // baseUrl: 'http://localhost:3001',
      // baseUrl: 'https://test-api.evercrypted.com',
      tlsSettings: TlsSettings(verifyCertificates: false),
    ));
  }

  static addAuth() async {
    client.dispose();
    final authToken = await Auth.getToken;
    final otpToken = await Auth.getOtpToken;
    List<SimpleInterceptor> interceptorsList = [];
    final cryptedToken = await encodePayload(authToken, ChatSocket.key);
    final cryptedOtpToken = await encodePayload(otpToken, ChatSocket.key);
    final from = Auth.getUser?.uid;
    if (cryptedToken != null) {
      interceptorsList.add(SimpleInterceptor(
          beforeRequest: (request) async => Interceptor.next(request.addHeader(
              name: HttpHeaderName.authorization,
              value: jsonEncode(cryptedToken).toString()))));
    }
    if (cryptedOtpToken != null) {
      interceptorsList.add(SimpleInterceptor(
          beforeRequest: (request) async => Interceptor.next(request.addHeader(
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
        baseUrl: 'http://10.0.2.2:3001',
        // baseUrl: 'http://localhost:3001',
        // baseUrl: 'https://test-api.evercrypted.com',
        tlsSettings: TlsSettings(verifyCertificates: false),
      ),
      interceptors: interceptorsList,
    );
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
    if (ChatSocket.socket?.connected != true ||
        ChatSocket.isConnected == null ||
        !ChatSocket.isConnected!) {
      if (!isFromQueue && allowedForQueue.contains('$channel/$type')) {
        final int queuedItemId = await saveActionForLater();
        respCompleter
            .complete({'status': 'queued', 'queuedItemId': queuedItemId});
      } else {
        respCompleter.completeError(
            'Could not connect to server, please check your internet connection.');
      }
    } else {
      final crypted = await encodePayload(
          {'channel': channel, 'type': type, 'payload': payload},
          ChatSocket.key);
      client
          .post('/socket/handle-message', body: HttpBody.json(crypted))
          .then((resp) async {
        final payload = await decodePayload(
          resp.bodyToJson['crypted'],
          resp.bodyToJson['iv'],
          resp.bodyToJson['mac'],
          ChatSocket.key,
        );
        debugPrint(payload.toString());
        if (payload['error'] != null) {
          respCompleter.completeError(payload['error']);
        } else if (payload['status'] == 'ok') {
          respCompleter.complete(payload['payload']);
        }
      }).catchError((error) {
        debugPrint(error.toString());
        respCompleter.completeError(error);
      });
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
