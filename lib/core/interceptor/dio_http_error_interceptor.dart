import 'dart:io';

import 'package:dio/dio.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/exception/server_message_exception.dart';
import 'package:paperless_mobile/core/type/types.dart';

class DioHttpErrorInterceptor extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 400) {
      // try to parse contained error message, otherwise return response
      final dynamic data = err.response?.data;
      if (data is Map<String, dynamic>) {
        return _handlePaperlessValidationError(data, handler, err);
      } else if (data is String) {
        return _handlePlainError(data, handler, err);
      }
    } else if (err.response?.statusCode == 403) {
      var data = err.response!.data;
      if (data is Map && data.containsKey("detail")) {
        handler.reject(
          DioError(
            message: data['detail'],
            requestOptions: err.requestOptions,
            error: ServerMessageException(data['detail']),
            response: err.response,
            type: DioErrorType.unknown,
          ),
        );
        return;
      }
    } else if (err.error is SocketException) {
      final ex = err.error as SocketException;
      if (ex.osError?.errorCode == _OsErrorCodes.serverUnreachable.code) {
        return handler.reject(
          DioError(
            message: "The server could not be reached. Is the device offline?",
            error: const PaperlessServerException(ErrorCode.deviceOffline),
            requestOptions: err.requestOptions,
            type: DioErrorType.connectionTimeout,
          ),
        );
      }
    }
    return handler.reject(err);
  }

  void _handlePaperlessValidationError(
    Map<String, dynamic> json,
    ErrorInterceptorHandler handler,
    DioError err,
  ) {
    final PaperlessValidationErrors errorMessages = {};
    for (final entry in json.entries) {
      if (entry.value is List) {
        errorMessages.putIfAbsent(
          entry.key,
          () => (entry.value as List).cast<String>().first,
        );
      } else if (entry.value is String) {
        errorMessages.putIfAbsent(entry.key, () => entry.value);
      } else {
        errorMessages.putIfAbsent(entry.key, () => entry.value.toString());
      }
    }
    handler.reject(
      DioError(
        error: errorMessages,
        requestOptions: err.requestOptions,
        type: DioErrorType.badResponse,
      ),
    );
  }

  void _handlePlainError(
    String data,
    ErrorInterceptorHandler handler,
    DioError err,
  ) {
    if (data.contains("No required SSL certificate was sent")) {
      handler.reject(
        DioError(
          requestOptions: err.requestOptions,
          type: DioErrorType.badResponse,
          error: const PaperlessServerException(
              ErrorCode.missingClientCertificate),
        ),
      );
    }
  }
}

enum _OsErrorCodes {
  serverUnreachable(101);

  const _OsErrorCodes(this.code);
  final int code;
}
