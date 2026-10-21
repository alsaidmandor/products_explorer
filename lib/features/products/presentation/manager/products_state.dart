import 'package:equatable/equatable.dart';

import '../../data/models/product.dart';

sealed class ProductsState extends Equatable {
  const ProductsState({this.query = ''});

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

final class ProductsLoading extends ProductsState {
  const ProductsLoading({
    super.query,
    this.previousProducts = const [],
    this.isDebouncing = false,
  });

  final List<Product> previousProducts;
  final bool isDebouncing;

  @override
  List<Object?> get props => [query, previousProducts, isDebouncing];
}

final class ProductsSuccess extends ProductsState {
  const ProductsSuccess({
    required this.products,
    super.query,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });

  final List<Product> products;
  final bool hasMore;
  final bool isLoadingMore;
  final int total;

  ProductsSuccess copyWith({
    List<Product>? products,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) {
    return ProductsSuccess(
      products: products ?? this.products,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [query, products, hasMore, isLoadingMore, total];
}

final class ProductsEmpty extends ProductsState {
  const ProductsEmpty({super.query});
}

final class ProductsFailure extends ProductsState {
  const ProductsFailure({required this.message, super.query});

  final String message;

  @override
  List<Object?> get props => [query, message];
}
