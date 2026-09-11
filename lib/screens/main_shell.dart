import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated_localizations.dart';
import '../services/auth_api.dart';
import '../services/push_notifications.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'my_listings_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _background = Color(0xFFF5F5F7);
  final _authApi = AuthApi();
  late int _currentIndex = widget.initialIndex.clamp(0, 3);
  String _topBarUserName = 'Pinlend';
  String? _topBarAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadTopBarAvatar();
    PushNotifications.instance.sessionStarted();
    PushNotifications.instance.pendingMessage.addListener(_openPushMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPushMessage());
  }

  @override
  void dispose() {
    PushNotifications.instance.pendingMessage.removeListener(_openPushMessage);
    super.dispose();
  }

  Future<void> _openPushMessage() async {
    final message = PushNotifications.instance.pendingMessage.value;
    if (!mounted || message == null) return;
    PushNotifications.instance.pendingMessage.value = null;
    if (message.data['type'] != 'chat_message') return;
    final productId = message.data['productId'];
    if (productId == null || productId.isEmpty) return;
    try {
      final token = await AuthSessionStore.getToken();
      if (token == null) return;
      final user = await _authApi.me(token);
      if (!mounted || user.id != message.data['recipientId']) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductChatScreen(
            productId: productId,
            productTitle: message.data['productTitle'] ?? 'Conversație',
            ownerName: 'Conversație',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nu am putut deschide conversația. Încearcă din Mesaje.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadTopBarAvatar() async {
    final token = await AuthSessionStore.getToken();

    if (token == null) {
      return;
    }

    try {
      final user = await _authApi.me(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _topBarUserName = user.fullName;
        _topBarAvatarUrl = user.avatarUrl;
      });
    } catch (_) {
      // Keep the bundled fallback avatar when the profile cannot be loaded.
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddListing() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddListingScreen()));
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MessagesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 86 + MediaQuery.paddingOf(context).bottom;

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
          child: ColoredBox(
            color: _background,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomNavHeight),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        ExploreScreen(
                          showChrome: false,
                          onNavigate: _selectTab,
                        ),
                        MyListingsScreen(
                          showChrome: false,
                          onNavigate: _selectTab,
                        ),
                        RentalsScreen(
                          showChrome: false,
                          onNavigate: _selectTab,
                        ),
                        ProfileScreen(
                          showChrome: false,
                          onNavigate: _selectTab,
                          onAvatarChanged: _loadTopBarAvatar,
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: LendTopBar(
                    title: _titleFor(context, _currentIndex),
                    userName: _topBarUserName,
                    avatarUrl: _topBarAvatarUrl,
                    hasUnreadNotifications: true,
                    onNotificationPressed: _openNotifications,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LendBottomNavigation(
                    currentIndex: _currentIndex,
                    onSelected: _selectTab,
                    onAddListing: _openAddListing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(BuildContext context, int index) {
    final strings = GeneratedLocalizations.of(context);

    return switch (index) {
      1 => strings.myListings,
      2 => strings.myRentals,
      3 => strings.myProfile,
      _ => strings.appName,
    };
  }
}
