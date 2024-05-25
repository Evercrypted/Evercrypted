import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
