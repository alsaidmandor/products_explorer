import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/failure.dart';
import '../models/paginated_products.dart';

class ProductsRepository {
  ProductsRepository(this._api);

  final ApiClient _api;

  static const defaultLimit = 20;

  Future<Either<Failure, PaginatedProducts>> fetchProducts({
    String query = '',
    int limit = defaultLimit,
    int skip = 0,
  }) async {
    final normalizedQuery = query.trim();

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'skip': skip,
      };
      if (normalizedQuery.isNotEmpty) {
        queryParams['q'] = normalizedQuery;
      }

      final response = await _api.get(
        normalizedQuery.isEmpty
            ? ApiEndpoints.products
            : ApiEndpoints.searchProducts,
        queryParameters: queryParams,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        final payload = response.data;
        if (payload is! Map) {
          return const Left(
            ParsingFailure('Unexpected response format from server.'),
          );
        }

        return Right(
          PaginatedProducts.fromJson(Map<String, dynamic>.from(payload)),
        );
      }

      return Left(
        ServerFailure.fromResponse(
          statusCode,
          response.data,
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
