import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';
import '../../library/providers/book_providers.dart';
import '../providers/social_providers.dart';
import '../widgets/shared_reading_ticket_widget.dart';

class ProjectReceiptScreen extends ConsumerStatefulWidget {
  final Project project;
  final double completionRate;

  const ProjectReceiptScreen({
    super.key,
    required this.project,
    this.completionRate = 1.0,
  });

  @override
  ConsumerState<ProjectReceiptScreen> createState() =>
      _ProjectReceiptScreenState();
}

class _ProjectReceiptScreenState extends ConsumerState<ProjectReceiptScreen> {
  late final Alignment _bgAlignment;
  late final Color _bgTint;
  Map<String, Profile> _profiles = {};
  bool _loadingProfiles = true;

  static const _tints = [
    Color(0xFFE57373), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFF64B5F6),
    Color(0xFFFFB74D), Color(0xFFF06292), Color(0xFF81C784), Color(0xFF90A4AE),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _bgAlignment = Alignment(
      (rng.nextDouble() * 1.4) - 0.7,
      (rng.nextDouble() * 1.4) - 0.7,
    );
    _bgTint = _tints[rng.nextInt(_tints.length)];
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final membersAsync = ref.read(projectMembersProvider(widget.project.id));
      final members = membersAsync.value ?? [];
      final repo = ref.read(supabaseRepositoryProvider);
      final profiles = <String, Profile>{};
      for (final m in members) {
        final profile = await repo.getProfile(m.userId);
        if (profile != null) {
          profiles[m.userId] = profile;
        }
      }
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _loadingProfiles = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      if (mounted) setState(() => _loadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(projectMembersProvider(widget.project.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background: Florence blurred image
          Image.asset(
            'assets/images/florence_bg.jpg',
            fit: BoxFit.cover,
            alignment: _bgAlignment,
            width: double.infinity,
            height: double.infinity,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
          Container(color: _bgTint.withOpacity(0.30)),

          // Center: Shared Reading Ticket
          membersAsync.when(
            data: (members) {
              if (_loadingProfiles) {
                return const Center(child: FlorenceLoader());
              }

              // Check if all members have submitted
              final allReady = members.every(
                (m) => m.quote != null && m.drawingUrl != null,
              );

              if (!allReady) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          color: AppColors.burgundy,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '아직 모든 멤버가\n작성을 완료하지 않았습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ...members.map((m) {
                          final profile = _profiles[m.userId];
                          final nickname = profile?.nickname ??
                              'Member ${m.userId.substring(0, 4)}';
                          final ready =
                              m.quote != null && m.drawingUrl != null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  ready
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: ready
                                      ? Colors.green
                                      : AppColors.greyLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nickname,
                                  style: TextStyle(
                                    color: ready
                                        ? AppColors.charcoal
                                        : AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                physics: const BouncingScrollPhysics(),
                child: SharedReadingTicketWidget(
                  project: widget.project,
                  members: members,
                  memberProfiles: _profiles,
                ),
              );
            },
            loading: () => const Center(child: FlorenceLoader()),
            error: (e, st) => Center(
              child: Text('오류 발생: $e', style: const TextStyle(color: Colors.white)),
            ),
          ),


        ],
      ),
    );
  }
}
