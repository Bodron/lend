import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../services/reviews_api.dart';

class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({super.key, required this.product});
  final LendProduct product;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final _api = ReviewsApi();
  List<ProductReview> _reviews = const [];
  RentalOrder? _eligibleOrder;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reviews = await _api.findForProduct(widget.product.id);
      final token = await AuthSessionStore.getToken();
      RentalOrder? eligible;
      if (token != null) {
        final orders = await RentalOrdersApi().findMine(token);
        for (final order in orders) {
          if (order.productId == widget.product.id &&
              order.status == 'completed') {
            eligible = order;
            break;
          }
        }
      }
      if (mounted)
        setState(() {
          _reviews = reviews;
          _eligibleOrder = eligible;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review() async {
    final order = _eligibleOrder;
    final token = await AuthSessionStore.getToken();
    if (order == null || token == null) return;
    var rating = 5;
    final text = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lasă un review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: rating,
                items: [1, 2, 3, 4, 5]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value stele'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => rating = value ?? 5),
              ),
              TextField(
                controller: text,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Cum a fost închirierea?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, text.text.trim()),
              child: const Text('Trimite'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
    if (comment == null || comment.length < 2) return;
    try {
      final review = await _api.create(
        token: token,
        productId: widget.product.id,
        orderId: order.id,
        rating: rating,
        comment: comment,
      );
      if (mounted)
        setState(() {
          _reviews = [review, ..._reviews];
          _eligibleOrder = null;
        });
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = _reviews.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recenzii',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            if (_eligibleOrder != null)
              TextButton(onPressed: _review, child: const Text('Lasă review')),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (first == null)
          const Text('Nu există review-uri încă.')
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Utilizator verificat',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${first.rating}.0',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    first.comment,
                    style: const TextStyle(
                      color: Color(0xFF434750),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
