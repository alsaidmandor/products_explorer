import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/api_endpoints.dart';

enum HttpMethod { get, post, put, patch, delete, head, options }

/// Custom Dio interceptor for developer-level logging.
class DioDebuggerInterceptor extends Interceptor {
  const DioDebuggerInterceptor({
    this.logPrint,
    this.enabled = true,
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
  });

  final void Function(String message)? logPrint;
  final bool enabled;
  final bool requestHeader;
  final bool requestBody;
  final bool responseHeader;
  final bool responseBody;
  final bool error;

  bool get _shouldLog => enabled && (kDebugMode || logPrint != null);

  void _log(String message) {
    if (logPrint != null) {
      logPrint!(message);
    } else {
      developer.log(message, name: 'DioDebugger');
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldLog) {
      _log('┌── 🚀 HTTP REQUEST [${options.method}] ──────────────────');
      _log('│ URL: ${options.uri}');
      if (requestHeader && options.headers.isNotEmpty) {
        _log('│ Headers: ${options.headers}');
      }
      if (options.queryParameters.isNotEmpty) {
        _log('│ QueryParameters: ${options.queryParameters}');
      }
      if (requestBody && options.data != null) {
        _log('│ Body: ${options.data}');
      }
      _log('└── ────────────────────────────────────────────────');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldLog) {
      _log('┌── 📥 HTTP RESPONSE [${response.statusCode}] ──────────────────');
      _log('│ URL: ${response.requestOptions.uri}');
      if (responseHeader && response.headers.map.isNotEmpty) {
        _log('│ Headers: ${response.headers.map}');
      }
      if (responseBody && response.data != null) {
        _log('│ Data: ${response.data}');
      }
      _log('└── ────────────────────────────────────────────────');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldLog) {
      final statusCode = err.response?.statusCode;
      _log('┌── ❌ HTTP ERROR [${statusCode ?? err.type}] ─────────');
      _log('│ URL: ${err.requestOptions.uri}');
      _log('│ Message: ${err.message}');
      if (error && err.response?.data != null) {
        _log('│ Response Data: ${err.response?.data}');
      }
      _log('└── ────────────────────────────────────────────────');
    }
    super.onError(err, handler);
  }
}

/// Central API client for sending HTTP requests.
///
/// Features dedicated separated methods for [get], [post], [put], [patch], [delete]
/// and attaches [PrettyDioLogger] and custom interceptors in debug mode.
class ApiClient {
  ApiClient({
    Dio? dio,
    String baseUrl = ApiEndpoints.baseUrl,
    List<Interceptor>? interceptors,
    bool enableDebugger = true,
  }) : _dio = dio ?? _createDefaultDio(baseUrl, interceptors, enableDebugger);

  final Dio _dio;

  Dio get dio => _dio;

  static Dio _createDefaultDio(
    String baseUrl,
    List<Interceptor>? customInterceptors,
    bool enableDebugger,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Accept': 'application/json'},
      ),
    );

    if (customInterceptors != null && customInterceptors.isNotEmpty) {
      dio.interceptors.addAll(customInterceptors);
    }

    if (enableDebugger && kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    return dio;
  }

  // ---------------------------------------------------------------------------
  // Separated HTTP Methods
  // ---------------------------------------------------------------------------

  /// Performs an HTTP GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      HttpMethod.get,
      path,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Performs an HTTP POST request.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      HttpMethod.post,
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Performs an HTTP PUT request.
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      HttpMethod.put,
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Performs an HTTP PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      HttpMethod.patch,
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Performs an HTTP DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      HttpMethod.delete,
      path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Performs a generic HTTP request for any [HttpMethod].
  Future<Response<T>> request<T>(
    HttpMethod method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final requestOptions = (options ?? Options()).copyWith(
      method: method.name.toUpperCase(),
      headers: headers == null ? null : {...?options?.headers, ...headers},
    );

    return _dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
