import 'package:flutter/material.dart';

class ProductsSearchField extends StatefulWidget {
  const ProductsSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<ProductsSearchField> createState() => _ProductsSearchFieldState();
}

class _ProductsSearchFieldState extends State<ProductsSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      onChanged: _handleChanged,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
    );
  }
}
