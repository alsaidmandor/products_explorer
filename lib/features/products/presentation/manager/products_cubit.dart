import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/product.dart';
import '../../data/repositories/products_repository.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(
    this._repository, {
    this.searchDebounce = const Duration(milliseconds: 400),
  }) : super(const ProductsInitial());

  final ProductsRepository _repository;
  final Duration searchDebounce;
  Timer? _debounce;
  int _requestId = 0;
  String _latestQuery = '';

  Future<void> loadProducts() => _fetch(state.query);

  void onQueryChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _latestQuery = query;

    if (query == state.query && state is! ProductsLoading) {
      return;
    }

    final currentProducts = _extractCurrentProducts();

    emit(ProductsLoading(
      query: query,
      previousProducts: currentProducts,
      isDebouncing: true,
    ));

    _debounce = Timer(searchDebounce, () => _fetch(query));
  }

  Future<void> retry() {
    _debounce?.cancel();
    return _fetch(_latestQuery);
  }

  Future<void> loadMoreProducts() async {
    final currentState = state;
    if (currentState is! ProductsSuccess ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await _repository.fetchProducts(
      query: currentState.query,
      skip: currentState.products.length,
    );

    if (isClosed || state != currentState.copyWith(isLoadingMore: true)) {
      return;
    }

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (paginated) => emit(
        ProductsSuccess(
          products: [...currentState.products, ...paginated.products],
          query: currentState.query,
          hasMore: paginated.hasMore,
          total: paginated.total,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _fetch(String query) async {
    final requestId = ++_requestId;
    final currentProducts = _extractCurrentProducts();

    if (state is! ProductsLoading || state.query != query) {
      emit(ProductsLoading(
        query: query,
        previousProducts: currentProducts,
        isDebouncing: false,
      ));
    }

    final result = await _repository.fetchProducts(query: query, skip: 0);

    if (isClosed || requestId != _requestId || query != _latestQuery) {
      return;
    }

    result.fold(
      (failure) =>
          emit(ProductsFailure(message: failure.message, query: query)),
      (paginated) => paginated.products.isEmpty
          ? emit(ProductsEmpty(query: query))
          : emit(ProductsSuccess(
              products: paginated.products,
              query: query,
              hasMore: paginated.hasMore,
              total: paginated.total,
            )),
    );
  }

  List<Product> _extractCurrentProducts() {
    return switch (state) {
      ProductsSuccess(:final products) => products,
      ProductsLoading(:final previousProducts) => previousProducts,
      _ => const <Product>[],
    };
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
