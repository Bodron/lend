import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/realtime_socket_service.dart';
import '../services/reviews_api.dart';
import 'lend_toast.dart';

class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({super.key, required this.product});
  final LendProduct product;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ReviewDraft {
  const _ReviewDraft({required this.rating, required this.comment});

  final int rating;
  final String comment;
}

class _ReviewBottomSheet extends StatefulWidget {
  const _ReviewBottomSheet();

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  final _textController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(
      context,
    ).pop(_ReviewDraft(rating: _rating, comment: _textController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Lasă un review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _ReviewRatingSelector(
              rating: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Scrie câteva cuvinte despre experiența ta...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFD7DCE6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFD7DCE6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF4A70A9), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anulează'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4A70A9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Trimite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsCacheEntry {
  const _ReviewsCacheEntry({required this.reviews, required this.loadedAt});

  final List<ProductReview> reviews;
  final DateTime loadedAt;
}

class _ReviewRatingSelector extends StatelessWidget {
  const _ReviewRatingSelector({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$rating ${rating == 1 ? 'stea' : 'stele'}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var value = 1; value <= 5; value++)
              _AnimatedReviewStar(
                key: ValueKey(value),
                value: value,
                selected: value <= rating,
                onTap: () => onChanged(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedReviewStar extends StatelessWidget {
  const _AnimatedReviewStar({
    super.key,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$value ${value == 1 ? 'stea' : 'stele'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: selected ? 1 : 0),
          duration: Duration(milliseconds: 220 + value * 35),
          curve: Curves.easeOutBack,
          builder: (context, animationValue, child) {
            final color = Color.lerp(
              const Color(0xFFB9C0CC),
              const Color(0xFFFFC107),
              animationValue,
            );

            return Transform.scale(
              scale: 0.82 + (animationValue * 0.18),
              child: Icon(
                Icons.star_rounded,
                size: 38,
                color: color,
                shadows: animationValue > 0.5
                    ? const [Shadow(color: Color(0x35F59E0B), blurRadius: 8)]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  static const _cacheLifetime = Duration(minutes: 2);
  static final Map<String, _ReviewsCacheEntry> _cache = {};

  final _api = ReviewsApi();
  final _realtime = RealtimeSocketService.instance;
  List<ProductReview> _reviews = const [];
  String? _eligibleOrderId;
  RealtimeSubscription? _reviewSubscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _connectRealtime();
  }

  @override
  void dispose() {
    _reviewSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    final token = await AuthSessionStore.getToken();
    if (!mounted || token == null) return;

    try {
      final subscription = await _realtime.subscribeToEvents(
        accessToken: token,
        apiBaseUrl: AuthApi.baseUrl,
        events: RealtimeEvents.reviewEvents,
        onData: (_, data) => _handleRealtimeReview(data),
      );
      if (!mounted) {
        subscription.cancel();
        return;
      }
      _reviewSubscription = subscription;
    } catch (_) {
      // Reviews remain available through the REST fallback.
    }
  }

  void _handleRealtimeReview(dynamic data) {
    if (!mounted || data is! Map) return;

    final payload = Map<String, dynamic>.from(data);
    final rawReview = payload['review'];
    final reviewPayload = rawReview is Map
        ? Map<String, dynamic>.from(rawReview)
        : payload;
    final productId =
        (reviewPayload['productId'] ??
                payload['productId'] ??
                (reviewPayload['product'] is Map
                    ? reviewPayload['product']['id']
                    : null))
            ?.toString();
    if (productId != widget.product.id) return;

    final review = ProductReview.fromJson(reviewPayload);
    if (review.id.isEmpty || _reviews.any((item) => item.id == review.id)) {
      return;
    }

    final reviews = [review, ..._reviews];
    setState(() => _reviews = reviews);
    _cache[widget.product.id] = _ReviewsCacheEntry(
      reviews: reviews,
      loadedAt: DateTime.now(),
    );
  }

  Future<void> _load() async {
    final token = await AuthSessionStore.getToken();
    final cached = _cache[widget.product.id];
    if (cached != null &&
        DateTime.now().difference(cached.loadedAt) < _cacheLifetime) {
      if (mounted) {
        setState(() {
          _reviews = cached.reviews;
          _loading = false;
        });
      }
      await _loadEligibleOrder(token);
      return;
    }

    try {
      final reviews = await _api.findForProduct(widget.product.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loading = false;
        });
      }
      _cache[widget.product.id] = _ReviewsCacheEntry(
        reviews: reviews,
        loadedAt: DateTime.now(),
      );
      await _loadEligibleOrder(token);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEligibleOrder(String? token) async {
    final eligible = await _findEligibility(token);

    if (mounted) {
      setState(
        () => _eligibleOrderId = eligible?.canReview == true
            ? eligible!.rentalOrderId
            : null,
      );
    }
  }

  Future<ReviewEligibility?> _findEligibility(String? token) async {
    if (token == null) return null;

    try {
      return await _api.findEligibility(
        token: token,
        productId: widget.product.id,
      );
    } catch (_) {
      // The review button remains hidden when the current session cannot be
      // verified by the reviews endpoint.
    }

    return null;
  }

  Future<void> _review() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) return;

    // Revalidate on tap so a stale product cache or an account switch cannot
    // submit another user's rental order.
    final eligibility = await _findEligibility(token);
    if (!mounted) return;
    if (eligibility?.canReview != true || eligibility?.rentalOrderId == null) {
      setState(() => _eligibleOrderId = null);
      LendToast.error(
        context,
        message: 'Nu există o închiriere finalizată eligibilă pentru review.',
      );
      return;
    }

    final draft = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F6FD),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ReviewBottomSheet(),
    );
    if (draft == null || draft.comment.length < 2) return;
    try {
      final review = await _api.create(
        token: token,
        productId: widget.product.id,
        rating: draft.rating,
        comment: draft.comment,
      );
      if (mounted) {
        setState(() {
          _reviews = [review, ..._reviews];
          _eligibleOrderId = null;
        });
      }
      _cache[widget.product.id] = _ReviewsCacheEntry(
        reviews: [review, ..._reviews],
        loadedAt: DateTime.now(),
      );
    } catch (error) {
      if (mounted) {
        LendToast.error(context, message: error.toString());
      }
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
            if (_eligibleOrderId != null)
              FilledButton.icon(
                onPressed: _review,
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Lasă review'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE7F0FD),
                  foregroundColor: const Color(0xFF30578F),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
