import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../../config/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConstants.baseUrl}/${AppConstants.apiVersion}',
        connectTimeout:
            Duration(seconds: AppConstants.connectionTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConstants.receiveTimeoutSeconds),
      ),
    );

    // Interceptores para token de autenticación, logging, etc.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Logger.info('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.info(
              'API Response: ${response.statusCode} for ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          Logger.error(
            'API Error: ${e.message} for ${e.requestOptions.path}',
            error: e,
          );
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path,
          queryParameters: queryParameters, options: options);
    } catch (e) {
      Logger.error('GET Error: $path', error: e);
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path,
          data: data, queryParameters: queryParameters, options: options);
    } catch (e) {
      Logger.error('POST Error: $path', error: e);
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(path,
          data: data, queryParameters: queryParameters, options: options);
    } catch (e) {
      Logger.error('PUT Error: $path', error: e);
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path,
          data: data, queryParameters: queryParameters, options: options);
    } catch (e) {
      Logger.error('DELETE Error: $path', error: e);
      rethrow;
    }
  }

  // Método para establecer el token de autenticación
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Método para limpiar el token de autenticación
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
