import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../manager/products_cubit.dart';
import '../manager/products_state.dart';
import '../widgets/products_body.dart';
import '../widgets/products_search_field.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Explorer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ProductsSearchField(
              onChanged: (value) {
                context.read<ProductsCubit>().onQueryChanged(value);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                return ProductsBody(
                  state: state,
                  onRetry: () {
                    context.read<ProductsCubit>().retry();
                  },
                  onLoadMore: () {
                    context.read<ProductsCubit>().loadMoreProducts();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
