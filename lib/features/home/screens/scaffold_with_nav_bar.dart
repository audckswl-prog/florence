import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/neumorphic_bottom_nav.dart';
import '../../social/providers/social_providers.dart';
import '../../../core/constants/app_colors.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtimeNotifications();
  }

  void _setupRealtimeNotifications() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    _notificationChannel = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: myId,
          ),
          callback: (payload) {
            final newNoti = payload.newRecord;
            ref.invalidate(notificationsProvider);

            if (mounted) {
              final message = newNoti['message'] ?? '새로운 알림이 도착했습니다.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.burgundy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NeumorphicBottomNav(
        navigationShell: widget.navigationShell,
      ),
    );
  }
}
