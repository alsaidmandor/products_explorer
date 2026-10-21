import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/products/data/repositories/products_repository.dart';
import 'features/products/presentation/manager/products_cubit.dart';

class ProductsApp extends StatelessWidget {
  const ProductsApp({super.key, this.repository});

  final ProductsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(
        repository ?? sl<ProductsRepository>(),
      )..loadProducts(),
      child: MaterialApp(
        title: 'Products Explorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.light,
        initialRoute: AppRouter.products,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
