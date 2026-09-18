import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/roommate_posts_api.dart';
import '../widgets/lend_screen_frame.dart';
import '../widgets/lend_toast.dart';

class RoommatePostsScreen extends StatefulWidget {
  const RoommatePostsScreen({super.key});

  @override
  State<RoommatePostsScreen> createState() => _RoommatePostsScreenState();
}

class _RoommatePostsScreenState extends State<RoommatePostsScreen> {
  static const _primary = Color(0xFF30578F);
  static const _background = Color(0xFFF5F5F7);
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);

  final _api = RoommatePostsApi();
  late Future<List<RoommatePost>> _postsFuture = _api.findAll();

  void _reload() {
    setState(() {
      _postsFuture = _api.findAll();
    });
  }

  Future<void> _sendInterest(RoommatePost post) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _InterestSheet(post: post),
    );

    if (message == null) {
      return;
    }

    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) {
        throw RoommatePostsApiException('Trebuie sa fii autentificat.');
      }

      await _api.sendInterest(
        accessToken: token,
        postId: post.id,
        message: message,
      );

      if (!mounted) return;
      LendToast.info(context, message: 'Cererea a fost trimisa.');
    } catch (error) {
      if (!mounted) return;
      LendToast.info(context, message: error.toString());
    }
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
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: LendScreenFrame(
            backgroundColor: _background,
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _postsFuture;
              },
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _RoommateTopBar()),
                  FutureBuilder<List<RoommatePost>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: _text),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          child: _RoommateError(onRetry: _reload),
                        );
                      }

                      final posts = snapshot.data ?? const <RoommatePost>[];
                      if (posts.isEmpty) {
                        return const SliverFillRemaining(
                          child: _EmptyRoommatePosts(),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
                        sliver: SliverList.separated(
                          itemCount: posts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return _RoommatePostCard(
                              post: post,
                              onInterest: () => _sendInterest(post),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateRoommatePostScreen extends StatefulWidget {
  const CreateRoommatePostScreen({super.key, required this.product});

  final LendProduct product;

  @override
  State<CreateRoommatePostScreen> createState() =>
      _CreateRoommatePostScreenState();
}

class _CreateRoommatePostScreenState extends State<CreateRoommatePostScreen> {
  static const _primary = _RoommatePostsScreenState._primary;
  static const _background = _RoommatePostsScreenState._background;

  final _api = RoommatePostsApi();
  late final TextEditingController _titleController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _budgetController;
  late final TextEditingController _moveInController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _preferencesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(
      text: 'Caut coleg pentru ${product.title}',
    );
    _cityController = TextEditingController(text: product.city);
    _areaController = TextEditingController(text: product.address);
    _budgetController = TextEditingController(
      text: product.pricePerMonth?.toString() ?? '',
    );
    _moveInController = TextEditingController();
    _descriptionController = TextEditingController();
    _preferencesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _moveInController.dispose();
    _descriptionController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final title = _titleController.text.trim();
    final city = _cityController.text.trim();
    final area = _areaController.text.trim();
    final budget = int.tryParse(_budgetController.text.trim()) ?? 0;
    final moveIn = _moveInController.text.trim();
    final description = _descriptionController.text.trim();
    final preferences = _preferencesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (title.isEmpty || city.isEmpty || budget <= 0 || description.isEmpty) {
      LendToast.info(
        context,
        message: 'Completeaza titlul, orasul, bugetul si descrierea.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) {
        throw RoommatePostsApiException('Trebuie sa fii autentificat.');
      }

      await _api.create(
        accessToken: token,
        input: RoommatePostInput(
          productId: widget.product.id,
          title: title,
          city: city,
          area: area,
          budgetPerMonth: budget,
          moveInDate: moveIn,
          description: description,
          preferences: preferences,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      LendToast.info(context, message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: LendScreenFrame(
            backgroundColor: _background,
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _CreateRoommateTopBar()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 132),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _AttachedProductCard(product: widget.product),
                          const SizedBox(height: 20),
                          _RoommateField(
                            controller: _titleController,
                            label: 'Titlu',
                            hint: 'Caut coleg/colega in Cluj',
                          ),
                          _RoommateField(
                            controller: _cityController,
                            label: 'Oras',
                            hint: 'Bucuresti',
                          ),
                          _RoommateField(
                            controller: _areaController,
                            label: 'Zona',
                            hint: 'Unirii, Marasti, Copou...',
                          ),
                          _RoommateField(
                            controller: _budgetController,
                            label: 'Buget lunar',
                            hint: '1500',
                            suffix: 'RON',
                            keyboardType: TextInputType.number,
                          ),
                          _RoommateField(
                            controller: _moveInController,
                            label: 'Mutare',
                            hint: 'Octombrie / cat mai repede',
                          ),
                          _RoommateField(
                            controller: _preferencesController,
                            label: 'Preferinte',
                            hint: 'nefumator, student, pet friendly',
                          ),
                          _RoommateField(
                            controller: _descriptionController,
                            label: 'Descriere',
                            hint: 'Spune cum esti ca viitor coleg si ce cauti.',
                            maxLines: 5,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      MediaQuery.paddingOf(context).bottom + 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: _RoommatePostsScreenState._outline.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.group_add_rounded),
                        label: Text(
                          _submitting ? 'Se publica...' : 'Publica anuntul',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoommateTopBar extends StatelessWidget {
  const _RoommateTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _RoommatePostsScreenState._background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: _RoommatePostsScreenState._outline.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _RoommatePostsScreenState._text,
          ),
          const Expanded(
            child: Text(
              'Caut coleg',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _RoommatePostsScreenState._text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateRoommateTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _RoommatePostsScreenState._background.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: _RoommatePostsScreenState._outline.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: _RoommatePostsScreenState._text,
          ),
          const Expanded(
            child: Text(
              'Anunt de coleg',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _RoommatePostsScreenState._text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoommatePostCard extends StatelessWidget {
  const _RoommatePostCard({required this.post, required this.onInterest});

  final RoommatePost post;
  final VoidCallback onInterest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _roommateCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD5E3FF),
                  foregroundColor: _RoommatePostsScreenState._text,
                  backgroundImage: post.authorAvatarUrl == null
                      ? null
                      : NetworkImage(post.authorAvatarUrl!),
                  child: post.authorAvatarUrl == null
                      ? Text(post.authorName.isEmpty ? '?' : post.authorName[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _RoommatePostsScreenState._text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          post.city,
                          post.area,
                        ].where((value) => value.isNotEmpty).join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _RoommatePostsScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _BudgetPill(text: post.budgetLabel),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.title,
              style: const TextStyle(
                color: _RoommatePostsScreenState._text,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(
                color: _RoommatePostsScreenState._muted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (post.preferences.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preference in post.preferences)
                    _PreferenceChip(text: preference),
                ],
              ),
            ],
            if (post.product != null) ...[
              const SizedBox(height: 14),
              _RoommateProductStrip(product: post.product!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onInterest,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Sunt interesat'),
                style: FilledButton.styleFrom(
                  backgroundColor: _RoommatePostsScreenState._primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoommateProductStrip extends StatelessWidget {
  const _RoommateProductStrip({required this.product});

  final RoommatePostProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 58,
              height: 58,
              child: product.imageUrl.isEmpty
                  ? const ColoredBox(color: Color(0xFFD5E3FF))
                  : Image.network(product.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _RoommatePostsScreenState._text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceLabel,
                  style: const TextStyle(
                    color: _RoommatePostsScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachedProductCard extends StatelessWidget {
  const _AttachedProductCard({required this.product});

  final LendProduct product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _roommateCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 70,
                child: product.imageUrl.isEmpty
                    ? const ColoredBox(color: Color(0xFFD5E3FF))
                    : Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apartament atasat',
                    style: TextStyle(
                      color: _RoommatePostsScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RoommatePostsScreenState._text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestSheet extends StatefulWidget {
  const _InterestSheet({required this.post});

  final RoommatePost post;

  @override
  State<_InterestSheet> createState() => _InterestSheetState();
}

class _InterestSheetState extends State<_InterestSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scrie-i lui ${widget.post.authorName}',
              style: const TextStyle(
                color: _RoommatePostsScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: _roommateInputDecoration(
                'Salut! Sunt interesat de anuntul tau...',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              style: FilledButton.styleFrom(
                backgroundColor: _RoommatePostsScreenState._primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Trimite cererea'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoommateField extends StatelessWidget {
  const _RoommateField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffix;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _RoommatePostsScreenState._muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: _roommateInputDecoration(
              hint,
            ).copyWith(suffixText: suffix),
          ),
        ],
      ),
    );
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _RoommatePostsScreenState._primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _RoommatePostsScreenState._primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD5E3FF).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _RoommatePostsScreenState._text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoommateError extends StatelessWidget {
  const _RoommateError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nu am putut incarca anunturile de colegi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RoommatePostsScreenState._muted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _RoommatePostsScreenState._primary,
              ),
              child: const Text('Reincearca'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoommatePosts extends StatelessWidget {
  const _EmptyRoommatePosts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nu exista inca anunturi de colegi. Fii primul care publica unul.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RoommatePostsScreenState._muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

InputDecoration _roommateInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RoommatePostsScreenState._outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RoommatePostsScreenState._outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: _RoommatePostsScreenState._text,
        width: 1.4,
      ),
    ),
  );
}

final _roommateCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);
