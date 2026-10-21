import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../manager/products_state.dart';
import 'products_grid.dart';
import 'searching_toast.dart';

class ProductsBody extends StatelessWidget {
  const ProductsBody({
    super.key,
    required this.state,
    required this.onRetry,
    this.onLoadMore,
  });

  final ProductsState state;
  final VoidCallback onRetry;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ProductsInitial() => const Center(child: CircularProgressIndicator()),
      ProductsLoading(:final previousProducts, :final query) =>
        previousProducts.isNotEmpty
            ? Stack(
                children: [
                  ProductsGrid(products: previousProducts),
                  if (query.isNotEmpty)
                    Positioned(
                      top: AppSpacing.md,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SearchingToast(query: query),
                      ),
                    ),
                ],
              )
            : Stack(
                children: [
                  const Center(child: CircularProgressIndicator()),
                  if (query.isNotEmpty)
                    Positioned(
                      top: AppSpacing.md,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SearchingToast(query: query),
                      ),
                    ),
                ],
              ),
      ProductsFailure(:final message) => AppErrorView(
        message: message,
        onRetry: onRetry,
      ),
      ProductsEmpty(:final query) => AppEmptyView(query: query),
      ProductsSuccess(:final products, :final isLoadingMore) => ProductsGrid(
        products: products,
        isLoadingMore: isLoadingMore,
        onLoadMore: onLoadMore,
      ),
    };
  }
}
