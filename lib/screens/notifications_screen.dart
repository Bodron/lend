import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _background = Color(0xFFF8FAFC);
  static const _surface = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF16A34A);
  static const _warning = Color(0xFFF59E0B);
  static const _danger = Color(0xFFDC2626);
  static const _violet = Color(0xFF7C3AED);

  bool _showUnreadOnly = false;
  late final List<_NotificationItem> _items = _seedItems();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final visibleItems = _showUnreadOnly
        ? _items.where((item) => !item.isRead).toList()
        : _items;
    final unreadCount = _items.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _NotificationsTopBar(
                unreadCount: unreadCount,
                onMarkAllRead: _markAllRead,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _NotificationSummary(unreadCount: unreadCount),
                  const SizedBox(height: 16),
                  _NotificationFilters(
                    showUnreadOnly: _showUnreadOnly,
                    onChanged: (value) {
                      setState(() {
                        _showUnreadOnly = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (visibleItems.isEmpty)
                    _EmptyNotifications(
                      title: strings.choose(
                        'Nu ai notificari necitite',
                        'No unread notifications',
                      ),
                    )
                  else
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationTile(
                          item: item,
                          onTap: () => _markRead(item.id),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markRead(String id) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) {
        return;
      }

      _items[index] = _items[index].copyWith(isRead: true);
    });
  }

  void _markAllRead() {
    setState(() {
      for (var index = 0; index < _items.length; index++) {
        _items[index] = _items[index].copyWith(isRead: true);
      }
    });
  }

  List<_NotificationItem> _seedItems() {
    return const [
      _NotificationItem(
        id: 'return-ready',
        icon: Icons.qr_code_scanner_rounded,
        color: _primary,
        titleRo: 'Retur pregatit pentru scanare',
        titleEn: 'Return ready to scan',
        bodyRo: 'Apartament Berceni 2 asteapta confirmarea prin cod QR.',
        bodyEn: 'Apartament Berceni 2 is waiting for QR confirmation.',
        timeRo: 'Acum 5 min',
        timeEn: '5 min ago',
      ),
      _NotificationItem(
        id: 'avatar-updated',
        icon: Icons.account_circle_rounded,
        color: _success,
        titleRo: 'Poza de profil a fost actualizata',
        titleEn: 'Profile photo updated',
        bodyRo: 'Avatarul tau este sincronizat in profil si in bara de sus.',
        bodyEn: 'Your avatar is synced in profile and the top bar.',
        timeRo: 'Azi',
        timeEn: 'Today',
      ),
      _NotificationItem(
        id: 'payment-check',
        icon: Icons.payments_rounded,
        color: _warning,
        titleRo: 'Verifica metoda de plata',
        titleEn: 'Check payment method',
        bodyRo: 'Adauga sau confirma cardul inainte de urmatoarea inchiriere.',
        bodyEn: 'Add or confirm your card before the next rental.',
        timeRo: 'Ieri',
        timeEn: 'Yesterday',
        isRead: true,
      ),
      _NotificationItem(
        id: 'listing-live',
        icon: Icons.inventory_2_rounded,
        color: _violet,
        titleRo: 'Anuntul tau este activ',
        titleEn: 'Your listing is live',
        bodyRo: 'Apartament Berceni 2 apare acum in cautari.',
        bodyEn: 'Apartament Berceni 2 now appears in search.',
        timeRo: '2 zile',
        timeEn: '2 days',
        isRead: true,
      ),
      _NotificationItem(
        id: 'security',
        icon: Icons.shield_rounded,
        color: _danger,
        titleRo: 'Sesiune securizata',
        titleEn: 'Secure session',
        bodyRo: 'Daca nu recunosti activitatea, deconecteaza-te din profil.',
        bodyEn: 'If you do not recognize activity, sign out from profile.',
        timeRo: '3 zile',
        timeEn: '3 days',
        isRead: true,
      ),
    ];
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: _NotificationsScreenState._text,
            ),
            Expanded(
              child: Text(
                strings.choose('Notificari', 'Notifications'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _NotificationsScreenState._text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: unreadCount == 0 ? null : onMarkAllRead,
              child: Text(
                strings.choose('Citeste tot', 'Read all'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _NotificationsScreenState._text,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unreadCount == 0
                        ? strings.choose('Esti la zi', 'You are up to date')
                        : strings.choose(
                            '$unreadCount notificari noi',
                            '$unreadCount new notifications',
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.choose(
                      'Activitatea importanta din cont apare aici.',
                      'Important account activity appears here.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
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

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.showUnreadOnly,
    required this.onChanged,
  });

  final bool showUnreadOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _NotificationsScreenState._surface,
        border: Border.all(color: _NotificationsScreenState._border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _FilterButton(
                label: strings.choose('Toate', 'All'),
                selected: !showUnreadOnly,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _FilterButton(
                label: strings.choose('Necitite', 'Unread'),
                selected: showUnreadOnly,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _NotificationsScreenState._text : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : _NotificationsScreenState._muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _NotificationsScreenState._surface,
          border: Border.all(
            color: item.isRead
                ? _NotificationsScreenState._border
                : item.color.withValues(alpha: 0.36),
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.choose(item.titleRo, item.titleEn),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _NotificationsScreenState._text,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.choose(item.bodyRo, item.bodyEn),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _NotificationsScreenState._muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.choose(item.timeRo, item.timeEn),
                      style: TextStyle(
                        color: item.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _NotificationsScreenState._surface,
        border: Border.all(color: _NotificationsScreenState._border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: _NotificationsScreenState._success,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _NotificationsScreenState._text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.titleRo,
    required this.titleEn,
    required this.bodyRo,
    required this.bodyEn,
    required this.timeRo,
    required this.timeEn,
    this.isRead = false,
  });

  final String id;
  final IconData icon;
  final Color color;
  final String titleRo;
  final String titleEn;
  final String bodyRo;
  final String bodyEn;
  final String timeRo;
  final String timeEn;
  final bool isRead;

  _NotificationItem copyWith({bool? isRead}) {
    return _NotificationItem(
      id: id,
      icon: icon,
      color: color,
      titleRo: titleRo,
      titleEn: titleEn,
      bodyRo: bodyRo,
      bodyEn: bodyEn,
      timeRo: timeRo,
      timeEn: timeEn,
      isRead: isRead ?? this.isRead,
    );
  }
}
