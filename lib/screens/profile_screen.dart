import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/products_api.dart';
import '../services/rental_orders_api.dart';
import '../services/storage_api.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'my_listings_screen.dart';
import 'rentals_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showChrome = true,
    this.onNavigate,
    this.onAvatarChanged,
  });

  final bool showChrome;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onAvatarChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _primary = Color(0xFF30578F);
  static const _primaryContainer = Color(0xFF4A70A9);
  static const _background = Color(0xFFF5F5F7);
  static const _card = Colors.white;
  static const _text = Color(0xFF1B1B1B);
  static const _muted = Color(0xFF434750);
  static const _outline = Color(0xFFC3C6D1);
  static const _secondary = Color(0xFF446085);
  static const _secondaryContainer = Color(0xFFB7D3FE);
  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD8aP--B20lEnuJhRoH2FnPsbEBgh3Q6Xjixj-YpTcYmcOBDZ8sTny9EzSN46Bz62-7rk6lzIYexOLa_5PN0OSjSpds_9-mhFDha_rHQ-TD9W4Ud6PuYTdTxNmgfedSviWiz_9bMPhJO4qCuj0du2OpMVPGfmYfeSyG60AfkXETwErp2gXPIHHQozlWvCWkgTVfJPI_qGh4Yk7btCDD-KmUyivwldgX0AAk0P6xrPR0Op8hmbIEart4HgI-aa4HF_BYVNw0jjSl1no';

  final _authApi = AuthApi();
  final _productsApi = ProductsApi();
  final _rentalOrdersApi = RentalOrdersApi();
  final _storageApi = StorageApi();
  bool _uploadingAvatar = false;
  late Future<_ProfileData> _profileFuture = _loadProfileData();

  Future<_ProfileData> _loadProfileData() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      throw AuthApiException('Trebuie sa fii autentificat.');
    }

    final user = await _authApi.me(token);
    final listings = await _productsApi.findMine(token);
    final rentals = await _rentalOrdersApi.findMine(token);

    return _ProfileData(user: user, listings: listings, rentals: rentals);
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = _loadProfileData();
    });
  }

  Future<void> _uploadAvatar() async {
    if (_uploadingAvatar) {
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes ?? await _readPickedFileBytes(file);

    if (file == null || bytes == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).choose(
              'Nu am putut citi imaginea aleasa.',
              'Could not read the selected image.',
            ),
          ),
        ),
      );
      return;
    }

    final contentType = _avatarContentType(file.extension);
    if (contentType == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).choose(
              'Alege o imagine JPG, PNG sau WebP.',
              'Choose a JPG, PNG, or WebP image.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _uploadingAvatar = true;
    });

    try {
      final token = await AuthSessionStore.getToken();

      if (token == null) {
        throw AuthApiException('Trebuie sa fii autentificat.');
      }

      final uploaded = await _storageApi.uploadMedia(
        accessToken: token,
        fileName: file.name,
        contentType: contentType,
        bytes: bytes,
        alt: 'Profile avatar',
      );

      await _authApi.updateAvatar(
        accessToken: token,
        avatarUrl: uploaded.url,
        avatarKey: uploaded.key,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profileFuture = _loadProfileData();
      });
      widget.onAvatarChanged?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  String? _avatarContentType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  Future<Uint8List?> _readPickedFileBytes(PlatformFile? file) async {
    final path = file?.path;

    if (path == null || path.isEmpty) {
      return null;
    }

    return File(path).readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                if (widget.showChrome)
                  const SliverToBoxAdapter(
                    child: LendTopBar(
                      title: 'BorrowIt',
                      avatarUrl: _ProfileScreenState._avatarUrl,
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 106)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    widget.showChrome ? 24 : 0,
                    20,
                    widget.showChrome ? 128 : 6,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: FutureBuilder<_ProfileData>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 320,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _ProfileScreenState._text,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _ProfileMessage(
                            icon: Icons.cloud_off_rounded,
                            title: AppLocalizations.of(context).choose(
                              'Nu am putut incarca profilul',
                              'Could not load profile',
                            ),
                            body: AppLocalizations.of(context).choose(
                              'Verifica backendul si incearca din nou.',
                              'Check the backend and try again.',
                            ),
                            actionLabel: AppLocalizations.of(context).retry,
                            onAction: _reloadProfile,
                          );
                        }

                        final data = snapshot.data!;

                        return Column(
                          children: [
                            _ProfileHeader(
                              data: data,
                              uploadingAvatar: _uploadingAvatar,
                              onAvatarPressed: _uploadAvatar,
                            ),
                            const SizedBox(height: 32),
                            _ProfileSidebar(onLogout: _logout),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showChrome)
              Align(
                alignment: Alignment.bottomCenter,
                child: LendBottomNavigation(
                  currentIndex: 3,
                  onSelected: _handleNavigation,
                  onAddListing: _openAddListing,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    if (index == 0) {
      _replaceWith(context, const ExploreScreen());
    }
    if (index == 1) {
      _replaceWith(context, const MyListingsScreen());
    }
    if (index == 2) {
      _replaceWith(context, const RentalsScreen());
    }
  }

  void _openAddListing() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddListingScreen()));
  }

  Future<void> _logout() async {
    await AuthSessionStore.clear();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  static void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _ProfileData {
  const _ProfileData({
    required this.user,
    required this.listings,
    required this.rentals,
  });

  final AuthUser user;
  final List<LendProduct> listings;
  final List<RentalOrder> rentals;

  int get earnedTotal {
    return rentals
        .where((order) => order.status == 'completed')
        .fold<int>(0, (sum, order) => sum + order.subtotal);
  }

  String get ratingLabel {
    if (listings.isEmpty) {
      return '-';
    }

    final rating =
        listings.fold<double>(0, (sum, product) => sum + product.rating) /
        listings.length;
    return rating.toStringAsFixed(1);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.data,
    required this.uploadingAvatar,
    required this.onAvatarPressed,
  });

  final _ProfileData data;
  final bool uploadingAvatar;
  final VoidCallback onAvatarPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final avatarUrl = data.user.avatarUrl ?? _ProfileScreenState._avatarUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _EditableProfileAvatar(
              imageUrl: avatarUrl,
              uploading: uploadingAvatar,
              onPressed: onAvatarPressed,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                strings.choose('Profilul meu', 'My profile'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfileScreenState._text,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              data.user.fullName,
              style: const TextStyle(
                color: _ProfileScreenState._muted,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _ProfileScreenState._secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: _ProfileScreenState._secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      strings.choose(
                        '${data.ratingLabel} (${data.listings.length} anunturi)',
                        '${data.ratingLabel} (${data.listings.length} listings)',
                      ),
                      style: const TextStyle(
                        color: _ProfileScreenState._secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: strings.choose('Obiecte oferite', 'Lent items'),
                value: '${data.listings.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: strings.choose('Castigat', 'Earned'),
                value: '${data.earnedTotal} RON',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.imageUrl,
    required this.uploading,
    required this.onPressed,
  });

  final String imageUrl;
  final bool uploading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: strings.choose('Schimba poza de profil', 'Change profile photo'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: uploading ? null : onPressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFFE2E2E2),
                          child: Icon(
                            Icons.person_rounded,
                            color: _ProfileScreenState._muted,
                            size: 42,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _ProfileScreenState._text,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: uploading
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 18,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF737781),
                fontSize: 11,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProfileScreenState._text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSidebar extends StatelessWidget {
  const _ProfileSidebar({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccountCard(onLogout: onLogout),
        const SizedBox(height: 20),
        const _TrustBadge(),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.choose('CONT & SIGURANTA', 'ACCOUNT & SAFETY'),
              style: const TextStyle(
                color: Color(0xFF737781),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _ActionRow(
              icon: Icons.verified_user_outlined,
              label: strings.choose('Verificare', 'Verification'),
            ),
            _ActionRow(
              icon: Icons.payments_outlined,
              label: strings.choose('Metode de plata', 'Payment methods'),
            ),
            _ActionRow(
              icon: Icons.contact_support_outlined,
              label: strings.choose('Suport', 'Support'),
            ),
            const Divider(height: 24, color: _ProfileScreenState._outline),
            _ActionRow(
              icon: Icons.logout_rounded,
              label: strings.choose('Deconectare', 'Sign out'),
              color: const Color(0xFFBA1A1A),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.color = _ProfileScreenState._text,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color == _ProfileScreenState._text
                  ? _ProfileScreenState._outline
                  : color,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ProfileScreenState._primaryContainer, Color(0xFF8FABD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 42),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            ).choose('Utilizator verificat', 'Verified user'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).choose(
              'Datele sunt sincronizate cu profilul tau din baza de date.',
              'Data is synchronized with your database profile.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _profileCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: _ProfileScreenState._text),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileScreenState._text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileScreenState._muted,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileScreenState._primary,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

final _profileCardDecoration = BoxDecoration(
  color: _ProfileScreenState._card,
  border: Border.all(color: _ProfileScreenState._outline),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 20,
      offset: const Offset(0, 2),
    ),
  ],
);
