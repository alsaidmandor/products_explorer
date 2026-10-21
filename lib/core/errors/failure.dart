import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base failure class for the application domain layer.
///
/// Implements [Equatable] so that presentation layers (Bloc, Cubit, etc.)
/// and unit tests can easily compare failure states by value.
class Failure extends Equatable {
  const Failure(
    this.message, {
    this.statusCode,
    this.code,
    this.error,
    this.stackTrace,
  });

  /// User-friendly, localized, or mapped error message.
  final String message;

  /// Optional HTTP or internal error status code (e.g., 404, 500).
  final int? statusCode;

  /// Optional machine-readable error code (e.g., 'UNAUTHORIZED', 'NOT_FOUND').
  final String? code;

  /// The raw underlying exception or error object for debugging/analytics.
  final Object? error;

  /// Optional stack trace associated with the failure.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, statusCode, code];

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode, code: $code)';
}

/// Represents failure when communicating with a remote server or API.
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.statusCode,
    super.code,
    super.error,
    super.stackTrace,
    this.data,
  });

  /// The raw payload returned by the server (useful for field errors or debugging).
  final dynamic data;

  /// Optional custom logger hook.
  ///
  /// Can be set during app initialization to route logs through your logging tool
  /// (e.g. `package:logger`, Firebase Crashlytics, or Sentry).
  ///
  /// ```dart
  /// ServerFailure.onLog = (msg, {error, stackTrace}) => myLogger.d(msg);
  /// ```
  static void Function(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  })? onLog;

  /// Creates a [ServerFailure] from a [DioException].
  ///
  /// Safe against null responses, missing status codes, and diverse API error bodies.
  factory ServerFailure.fromDioException(DioException exception) {
    _log(
      'DioException caught [${exception.type}]: ${exception.message}',
      error: exception,
      stackTrace: exception.stackTrace,
    );

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure(
          'Connection timeout with the server. Please check your internet connection.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.sendTimeout:
        return ServerFailure(
          'Send timeout with the server. Please try again.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.receiveTimeout:
        return ServerFailure(
          'Receive timeout in connection with the server. Please try again.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.transformTimeout:
        return ServerFailure(
          'Data transformation timeout. Please try again.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.badCertificate:
        return ServerFailure(
          'Secure SSL/TLS certificate verification failed.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.badResponse:
        final response = exception.response;
        return ServerFailure.fromResponse(
          response?.statusCode ?? 0,
          response?.data,
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.cancel:
        return ServerFailure(
          'The request to the server was cancelled.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.connectionError:
        return ServerFailure(
          'No internet connection. Please verify your network and try again.',
          error: exception,
          stackTrace: exception.stackTrace,
        );

      case DioExceptionType.unknown:
        final response = exception.response;
        if (response != null && response.data != null) {
          return ServerFailure.fromResponse(
            response.statusCode ?? 0,
            response.data,
            error: exception,
            stackTrace: exception.stackTrace,
          );
        }
        return ServerFailure(
          'An unexpected network error occurred. Please try again.',
          error: exception,
          stackTrace: exception.stackTrace,
        );
    }
  }

  /// Backward-compatible alias for [fromDioException].
  factory ServerFailure.fromDioError(DioException exception) =>
      ServerFailure.fromDioException(exception);

  /// Factory constructor to parse HTTP status codes and response payloads.
  factory ServerFailure.fromResponse(
    int statusCode,
    dynamic response, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('Server error response [$statusCode]: $response');

    // 1. Try to extract a human-readable message from the response payload
    final extractedMessage = _extractMessage(response);
    if (extractedMessage != null && extractedMessage.isNotEmpty) {
      return ServerFailure(
        extractedMessage,
        statusCode: statusCode,
        data: response,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // 2. Fall back to standard HTTP status code description
    final fallbackMessage = _messageForStatusCode(statusCode);
    return ServerFailure(
      fallbackMessage,
      statusCode: statusCode,
      data: response,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Safely extracts a readable message from various backend error schemas:
  /// - Laravel: `{ "message": "...", "errors": { "field": ["first error"] } }`
  /// - NestJS: `{ "message": ["error 1", "error 2"] }`
  /// - Django/DRF: `{ "detail": "..." }` or `{ "non_field_errors": [...] }`
  /// - RFC 7807 (Problem Details): `{ "title": "...", "detail": "..." }`
  /// - OAuth / General: `{ "error": "...", "error_description": "..." }`
  /// - Plain strings (guards against raw HTML error pages).
  static String? _extractMessage(dynamic response) {
    if (response == null) return null;

    if (response is Map) {
      // 1. Laravel / RFC 7807 validation errors: {"errors": {...}}
      final errors = response['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        if (firstValue != null) return firstValue.toString();
      } else if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }

      // 2. NestJS / array messages: {"message": ["email required", ...]}
      final message = response['message'];
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      // 3. Django / DRF / FastAPI "detail"
      final detail = response['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first.containsKey('msg')) {
          return first['msg'].toString();
        }
        return first.toString();
      }

      // 4. OAuth / RFC standard: "error_description" or "error"
      final errorDescription = response['error_description'];
      if (errorDescription is String && errorDescription.trim().isNotEmpty) {
        return errorDescription.trim();
      }

      final error = response['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      if (error is Map && error['message'] is String) {
        return (error['message'] as String).trim();
      }

      // 5. RFC 7807 "title"
      final title = response['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    }

    // 6. Plain string response (ignoring HTML crash pages)
    if (response is String) {
      final trimmed = response.trim();
      if (trimmed.isEmpty) return null;
      // Guard against HTML error pages (e.g., Cloudflare/Nginx 502/504)
      if (trimmed.startsWith('<') ||
          trimmed.contains('<html') ||
          trimmed.contains('<!DOCTYPE html')) {
        return null;
      }
      // If the string is unusually long, it's likely a stack dump or markup
      if (trimmed.length > 250) {
        return null;
      }
      return trimmed;
    }

    return null;
  }

  /// Maps standard HTTP status codes to user-friendly messages.
  static String _messageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please verify your input and try again.';
      case 401:
        return 'Unauthorized. Your session may have expired; please sign in again.';
      case 403:
        return 'Access forbidden. You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found. Please try again later.';
      case 408:
        return 'Request timeout. The server took too long to respond.';
      case 409:
        return 'A conflict occurred with the current state of the resource.';
      case 422:
        return 'Validation failed. Please check the data you entered.';
      case 429:
        return 'Too many requests. Please wait a moment before trying again.';
      case 500:
        return 'Internal server error. There is a problem on the server side.';
      case 502:
        return 'Bad gateway. The server received an invalid response.';
      case 503:
        return 'Service temporarily unavailable. Please try again in a few moments.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        if (statusCode >= 500) {
          return 'Server error ($statusCode). Please try again later.';
        } else if (statusCode >= 400) {
          return 'Request failed with status code $statusCode.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static void _log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (onLog != null) {
      onLog!(message, error: error, stackTrace: stackTrace);
    } else {
      developer.log(
        message,
        name: 'ServerFailure',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Represents failure caused by local device or network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please verify your network.',
    Object? error,
    StackTrace? stackTrace,
  ]) : super(error: error, stackTrace: stackTrace);
}

/// Represents failure during local caching, database, or key-value storage operations.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Failed to load or save data to local storage.',
    Object? error,
    StackTrace? stackTrace,
  ]) : super(error: error, stackTrace: stackTrace);
}

/// Represents failure when parsing/deserializing data schemas.
class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'Failed to parse response data correctly.',
    Object? error,
    StackTrace? stackTrace,
  ]) : super(error: error, stackTrace: stackTrace);
}

/// Represents validation errors on client inputs or forms.
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors = const {},
    super.error,
    super.stackTrace,
  });

  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Represents unexpected or unhandled failures.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'An unexpected error occurred. Please try again.',
    Object? error,
    StackTrace? stackTrace,
  ]) : super(error: error, stackTrace: stackTrace);
}
