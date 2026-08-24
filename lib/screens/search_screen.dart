import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/products_api.dart';
import '../widgets/product_media_preview.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialProducts = const []});

  final List<LendProduct> initialProducts;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _primary = Color(0xFF30578F);
  static const _accent = Color(0xFF0B8FE8);
  static const _background = Color(0xFFF6F7FB);
  static const _field = Color(0xFFF0F2F7);
  static const _text = Color(0xFF20242A);
  static const _muted = Color(0xFF67717E);
  static const _line = Color(0xFFE1E4EA);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late Future<List<LendProduct>> _productsFuture;
  String _query = '';
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.initialProducts.isEmpty
        ? ProductsApi().findAll()
        : Future.value(widget.initialProducts);
    _controller.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: _background,
            child: FutureBuilder<List<LendProduct>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                final products = snapshot.data ?? widget.initialProducts;
                final results = _matchingProducts(products);
                final suggestions = _suggestionsFor(products);
                final Widget searchBody;

                if (_query.trim().isEmpty) {
                  searchBody = const SizedBox.expand();
                } else if (_hasSubmitted) {
                  searchBody = _SearchResults(
                    query: _query,
                    products: results,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                    onSelected: _openProduct,
                  );
                } else {
                  searchBody = _SuggestionList(
                    suggestions: suggestions,
                    onSelected: _selectSuggestion,
                  );
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        _SearchHeader(
                          controller: _controller,
                          focusNode: _focusNode,
                          hasText: _query.trim().isNotEmpty,
                          onClear: _controller.clear,
                          onClose: () => Navigator.of(context).pop(),
                          onSubmitted: _submitSearch,
                        ),
                        Expanded(child: searchBody),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                      child: _VisualSearchActions(
                        onCamera: () => _showUnavailable(
                          AppLocalizations.of(context).choose(
                            'Cautarea cu camera va fi disponibila curand.',
                            'Camera search will be available soon.',
                          ),
                        ),
                        onImage: () => _showUnavailable(
                          AppLocalizations.of(context).choose(
                            'Cautarea cu imagine va fi disponibila curand.',
                            'Image search will be available soon.',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleQueryChanged() {
    setState(() {
      _query = _controller.text;
      _hasSubmitted = false;
    });
  }

  void _selectSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submitSearch(value);
  }

  void _submitSearch(String value) {
    setState(() {
      _hasSubmitted = value.trim().isNotEmpty;
    });
    _focusNode.unfocus();
  }

  void _openProduct(LendProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<LendProduct> _matchingProducts(List<LendProduct> products) {
    final query = _normalize(_query);
    if (query.isEmpty) {
      return const [];
    }

    return products.where((product) {
      final haystack = _normalize(
        '${product.title} ${product.category} ${product.description} '
        '${product.city} ${product.address}',
      );
      return haystack.contains(query);
    }).toList();
  }

  List<_SearchSuggestion> _suggestionsFor(List<LendProduct> products) {
    final query = _normalize(_query);
    final values = <_SearchSuggestion>[];
    final seen = <String>{};

    void add(String title, [String subtitle = '']) {
      final cleanTitle = title.trim();
      if (cleanTitle.isEmpty) {
        return;
      }

      final key = _normalize('$cleanTitle $subtitle');
      if (seen.contains(key)) {
        return;
      }

      if (query.isNotEmpty && !key.contains(query)) {
        return;
      }

      seen.add(key);
      values.add(_SearchSuggestion(cleanTitle, subtitle.trim()));
    }

    if (query.isNotEmpty) {
      add(_query.trim().toLowerCase());
      add(_query.trim().toLowerCase(), 'Aproape de tine');
      add('${_query.trim().toLowerCase()} de inchiriat');
    }

    for (final product in products) {
      add(product.title, product.category);
      add(product.category);
      add(product.city);
    }

    for (final fallback in const [
      'Bicicleta',
      'Camera foto',
      'GoPro',
      'Masina de gaurit',
      'Cort',
      'Scule electrice',
      'Laptop',
      'Boxa portabila',
    ]) {
      add(fallback);
    }

    return values.take(8).toList();
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onClear,
    required this.onClose,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _SearchScreenState._field,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search_rounded,
                      color: _SearchScreenState._text,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: onSubmitted,
                        cursorColor: _SearchScreenState._accent,
                        style: const TextStyle(
                          color: _SearchScreenState._text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: strings.choose(
                            'Incepe o cautare',
                            'Start a search',
                          ),
                          hintStyle: const TextStyle(
                            color: _SearchScreenState._muted,
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (hasText)
                      IconButton(
                        onPressed: onClear,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.cancel_rounded),
                        color: _SearchScreenState._muted,
                        iconSize: 20,
                      ),
                    IconButton(
                      onPressed: () {},
                      tooltip: strings.choose(
                        'Cauta cu imagine',
                        'Search by image',
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFF2787E8), Color(0xFFB84CDC)],
                        ).createShader(rect),
                        child: const Icon(
                          Icons.center_focus_strong_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _SearchScreenState._field,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: _SearchScreenState._text,
                iconSize: 26,
                padding: const EdgeInsets.all(9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.suggestions, required this.onSelected});

  final List<_SearchSuggestion> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.expand();
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        indent: 66,
        color: _SearchScreenState._line,
      ),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];

        return InkWell(
          onTap: () => onSelected(suggestion.title),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 13, 20, 13),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: _SearchScreenState._muted,
                  size: 24,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _SearchScreenState._accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (suggestion.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          suggestion.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _SearchScreenState._muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.north_west_rounded,
                  color: Color(0xFF757575),
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.products,
    required this.isLoading,
    required this.onSelected,
  });

  final String query;
  final List<LendProduct> products;
  final bool isLoading;
  final ValueChanged<LendProduct> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _SearchScreenState._primary),
      );
    }

    if (products.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 42, 20, 148),
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: _SearchScreenState._muted,
          ),
          const SizedBox(height: 12),
          Text(
            strings.choose(
              'Nu am gasit produse pentru "$query".',
              'No items found for "$query".',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SearchScreenState._text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 148),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _SearchProductTile(
          product: products[index],
          onTap: () => onSelected(products[index]),
        );
      },
    );
  }
}

class _SearchProductTile extends StatelessWidget {
  const _SearchProductTile({required this.product, required this.onTap});

  final LendProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: ProductMediaPreview(product: product),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SearchScreenState._text,
                        fontSize: 16,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product.city} - ${product.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _SearchScreenState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.pricePerDayLabel,
                      style: const TextStyle(
                        color: _SearchScreenState._primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _SearchScreenState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualSearchActions extends StatelessWidget {
  const _VisualSearchActions({required this.onCamera, required this.onImage});

  final VoidCallback onCamera;
  final VoidCallback onImage;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _VisualSearchButton(
            icon: Icons.add_a_photo_rounded,
            label: strings.choose('Cauta cu camera', 'Camera search'),
            onTap: onCamera,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _VisualSearchButton(
            icon: Icons.add_photo_alternate_rounded,
            label: strings.choose('Cauta cu imagine', 'Image search'),
            onTap: onImage,
          ),
        ),
      ],
    );
  }
}

class _VisualSearchButton extends StatelessWidget {
  const _VisualSearchButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0xFF2787E8), Color(0xFFB84CDC)],
                ).createShader(rect),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _SearchScreenState._text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestion {
  const _SearchSuggestion(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ă', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ș', 's')
      .replaceAll('ş', 's')
      .replaceAll('ț', 't')
      .replaceAll('ţ', 't')
      .replaceAll('Äƒ', 'a')
      .replaceAll('Ã¢', 'a')
      .replaceAll('Ã®', 'i')
      .replaceAll('È™', 's')
      .replaceAll('ÅŸ', 's')
      .replaceAll('È›', 't')
      .replaceAll('Å£', 't');
}
