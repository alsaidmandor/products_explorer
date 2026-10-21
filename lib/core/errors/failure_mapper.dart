import 'package:dio/dio.dart';

import 'failure.dart';

/// Maps a [DioException] into a domain [Failure] (specifically [ServerFailure]).
Failure mapDioFailure(DioException error) {
  return ServerFailure.fromDioException(error);
}
