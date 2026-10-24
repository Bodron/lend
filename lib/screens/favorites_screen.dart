import 'package:flutter/material.dart';
import '../widgets/lend_back_top_bar.dart';

import '../l10n/generated_localizations.dart';
import '../services/favorites_service.dart';
import '../services/products_api.dart';
import 'product_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<LendProduct>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

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
        future: _products,
        builder: (context, snapshot) {
          final products = snapshot.data ?? const <LendProduct>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
            ));
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
                onTap: () async {
                  await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailsScreen(product: product),
                  ),
                  );
                  if (mounted) setState(() => _products = _load());
                },
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
