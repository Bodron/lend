import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../widgets/lend_bottom_navigation.dart';
import '../widgets/lend_top_bar.dart';
import 'add_listing_screen.dart';
import 'explore_screen.dart';
import 'my_listings_screen.dart';
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
  static const _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAjckt39yhGH_YNEWoUmbXYYMQMctYpenv4ao2wyvCqeIUeKvR_KLOZ2ICz2VXNFVBoWxN3Tk3Y95Eg_PbtaBhRH8vX_vZ4HtStk-hQiK-xTgYACenslrsS991egJa7dNNA21VSeZYxwr6eC9bd1mcpjvb13V7JeJ9DH2YWlHFFMYoGLdsewDMPaYY36MgZ-5ctsmYioywxLYl5q_-pxR5zE3v4A_fnVaDTGQCU2CLBpYxMQ9xhXdfKEtFQuchnrja44C5pVFpxxII';

  late int _currentIndex = widget.initialIndex.clamp(0, 3);

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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                    padding: EdgeInsets.only(bottom: 110 + bottomPadding),
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
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: LendTopBar(
                    title: _titleFor(context, _currentIndex),
                    avatarUrl: _avatarUrl,
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
    final strings = AppLocalizations.of(context);

    return switch (index) {
      1 => strings.choose('Anunturile mele', 'My listings'),
      2 => strings.choose('Inchirierile mele', 'My rentals'),
      3 => strings.choose('Profilul meu', 'My profile'),
      _ => strings.appName,
    };
  }
}
