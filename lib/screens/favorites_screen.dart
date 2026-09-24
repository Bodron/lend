import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';

import '../l10n/generated_localizations.dart';
import '../services/favorites_service.dart';
import '../services/products_api.dart';
import 'product_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = GeneratedLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: LendBackTopBar.height,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: LendBackTopBar(title: strings.favorites),
      ),
      body: FutureBuilder<List<LendProduct>>(
        future: _load(),
        builder: (context, snapshot) {
          final products = snapshot.data ?? const <LendProduct>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (products.isEmpty) {
            return Center(child: Text(strings.emptyFavorites));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(product.imageUrl),
                ),
                title: Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(product.pricePerDayLabel),
                trailing: const Icon(Icons.favorite, color: Colors.red),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(product: product),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<LendProduct>> _load() async {
    final ids = await FavoritesService.getIds();
    final products = await ProductsApi().findAll();
    return products.where((product) => ids.contains(product.id)).toList();
  }
}
