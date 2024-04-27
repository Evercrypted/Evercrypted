import 'dart:async';

import 'package:dio/dio.dart';
import 'package:evercrypted/core/auth.dart';
// import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:evercrypted/core/services/app_state_riverpod.dart';
import 'package:evercrypted/core/services/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:retry/retry.dart';

final dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 3),
  ),
);

initializeDio() {
  dio
    ..options.baseUrl = 'http://localhost:3001'
    ..interceptors.add(PrettyDioLogger());
  // ..interceptors.add(RetryInterceptor(
  //   dio: dio,
  //   logPrint: print, // specify log function (optional)
  //   retries: 3, // retry count (optional)
  //   retryDelays: const [
  //     // set delays between retries (optional)
  //     Duration(seconds: 1), // wait 1 sec before first retry
  //     Duration(seconds: 2), // wait 2 sec before second retry
  //     Duration(seconds: 3), // wait 3 sec before third retry
  //   ],
  // ));
}
