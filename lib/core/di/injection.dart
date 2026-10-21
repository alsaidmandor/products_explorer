import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../../features/products/data/repositories/products_repository.dart';
import '../../features/products/presentation/manager/products_cubit.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all core and feature dependencies.
Future<void> initDependencies() async {
  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------
  if (!sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ApiClient>(() => ApiClient());
  }

  // ---------------------------------------------------------------------------
  // Features: Products
  // ---------------------------------------------------------------------------
  if (!sl.isRegistered<ProductsRepository>()) {
    sl.registerLazySingleton<ProductsRepository>(
      () => ProductsRepository(sl<ApiClient>()),
    );
  }

  if (!sl.isRegistered<ProductsCubit>()) {
    sl.registerFactory<ProductsCubit>(
      () => ProductsCubit(sl<ProductsRepository>()),
    );
  }
}
