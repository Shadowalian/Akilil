import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/core.dart';
import '../core_data/seed_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<Map<String, dynamic>> _items;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(SeedData.notifications);
  }

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item['is_read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'session':
        return Icons.videocam_rounded;
      case 'message':
        return Icons.forum_rounded;
      case 'worksheet':
        return Icons.edit_note_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'group':
        return Icons.groups_2_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'session':
        return FriendColors.primary;
      case 'message':
        return FriendColors.wood;
      case 'worksheet':
        return FriendColors.accent;
      case 'achievement':
        return FriendColors.green;
      case 'group':
        return FriendColors.primaryDeep;
      default:
        return FriendColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _items
        : _items.where((x) {
            final t = x['type'] as String? ?? '';
            if (_filter == 'Sessions') return t == 'session';
            if (_filter == 'Messages') return t == 'message';
            if (_filter == 'Exercises') return t == 'worksheet';
            if (_filter == 'Groups') return t == 'group';
            return true;
          }).toList();

    return FriendPageScaffold(
      eyebrow: 'Activity',
      title: 'Notifications',
      subtitle: 'Session alerts, messages from Dr. Maya Lin, and worksheet updates.',
      showBack: true,
      trailing: TextButton.icon(
        onPressed: _markAllRead,
        icon: const Icon(Icons.done_all_rounded, size: 16),
        label: const Text('Mark Read'),
        style: TextButton.styleFrom(
          foregroundColor: FriendColors.primaryDeep,
          textStyle: GoogleFonts.urbanist(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Sessions', 'Messages', 'Exercises', 'Groups'].map((cat) {
                final isSel = _filter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _filter = cat);
                    },
                    selectedColor: FriendColors.primaryLight,
                    backgroundColor: FriendColors.surface,
                    labelStyle: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? FriendColors.primaryDeep : FriendColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSel ? FriendColors.primary : FriendColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          for (final item in filtered) ...[
            _NotificationTile(
              item: item,
              icon: _iconForType(item['type'] as String?),
              color: _colorForType(item['type'] as String?),
              onTap: () {
                setState(() => item['is_read'] = true);
                final route = item['route'] as String?;
                if (route != null && route.isNotEmpty) {
                  context.push(route);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? '';
    final time = item['time'] as String? ?? '';
    final isRead = item['is_read'] == true;

    return CandyCard(
      onTap: onTap,
      tint: isRead ? null : FriendColors.primary,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(FriendRadii.small),
            ),
            child: Icon(icon, color: color, size: 20),
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
                        title,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                          color: FriendColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: FriendColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    height: 1.4,
                    color: isRead ? FriendColors.textSecondary : FriendColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FriendColors.textMuted,
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
