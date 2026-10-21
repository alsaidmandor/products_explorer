import 'package:flutter/material.dart';

import '../../features/products/data/models/product.dart';
import '../../features/products/presentation/screens/product_details_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';

abstract final class AppRouter {
  static const products = '/';
  static const productDetails = '/product-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case products:
        return MaterialPageRoute<void>(
          builder: (_) => const ProductsScreen(),
          settings: settings,
        );
      case productDetails:
        final arguments = settings.arguments;
        if (arguments is ProductDetailsArguments) {
          return MaterialPageRoute<void>(
            builder: (_) => ProductDetailsScreen(product: arguments.product),
            settings: settings,
          );
        }
    }

    return MaterialPageRoute<void>(
      builder: (_) => const _UnknownRouteScreen(),
      settings: settings,
    );
  }
}

class ProductDetailsArguments {
  const ProductDetailsArguments(this.product);

  final Product product;
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: const Center(child: Text('This page does not exist.')),
    );
  }
}
