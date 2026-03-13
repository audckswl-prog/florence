import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/book_model.dart';
import '../providers/social_providers.dart';
import '../../library/screens/book_search_delegate.dart';
import '../../library/providers/book_providers.dart';
import '../../library/providers/library_providers.dart';
import '../../library/widgets/reading_completion_dialog.dart';
import '../../../data/models/user_book_model.dart';
import 'drawing_canvas_screen.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final Project? project;

  const ProjectDetailScreen({super.key, required this.projectId, this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  // Local state for the slider to provide instant feedback
  double _currentSliderValue = 0;
  bool _isDragging = false;

  /// 3단계 독서 티켓 플로우: 축하 → 인용구 → 그림 → 저장
  Future<void> _startTicketFlow(Project project, ProjectMember me) async {
    // ── STEP 1: 축하 알림 ──
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: AppColors.burgundy, size: 48),
              const SizedBox(height: 16),
              const Text(
                '프로젝트 완수를 축하합니다!',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.burgundy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '자동으로 내 서재에 책이 추가됩니다.\n함께한 독서는 추가로 독서티켓이 발급되니\n다음 지시를 따라 주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.charcoal,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다음으로',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    // ── STEP 2: 인용구 입력 ──
    final quote = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.format_quote, color: AppColors.burgundy, size: 36),
                const SizedBox(height: 12),
                const Text(
                  '인상깊었던, 혹은 다른 사람과\n나누고 싶은 1~2 문장을\n입력해주세요.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: '구절을 입력해주세요... (최대 40자)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterStyle: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.of(ctx).pop(controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '다음으로',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (quote == null || !mounted) return;

    // ── STEP 3: 그림 그리기 ──
    final drawingBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DrawingCanvasScreen(),
      ),
    );

    if (drawingBytes == null || !mounted) return;

    // ── SAVE: 인용구 + 그림 업로드 ──
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중...')),
      );

      final repo = ref.read(supabaseRepositoryProvider);

      final drawingUrl = await repo.uploadDrawingImage(
        me.projectId,
        me.userId,
        drawingBytes,
      );

      await repo.updateMemberTicketData(
        me.projectId,
        me.userId,
        quote: quote,
        drawingUrl: drawingUrl,
      );

      if (me.selectedIsbn != null) {
        await repo.updateUserBookStatus(
          me.userId,
          me.selectedIsbn!,
          'read',
          quote: quote,
        );
      }

      ref.invalidate(userBooksProvider);
      ref.invalidate(myProjectsProvider);
      ref.invalidate(projectMembersProvider(me.projectId));

      final allTicketReady = await repo.checkAllMembersTicketReady(me.projectId);

      if (mounted) {
        if (allTicketReady) {
          context.push(
            '/home/social/detail/${me.projectId}/receipt',
            extra: {'project': project, 'rate': 1.0},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장 완료! 다른 멤버가 아직 작성 중입니다. 모두 완료되면 독서 티켓이 발급됩니다.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in ticket flow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류: $e')),
        );
      }
    }
  }

  void _showDeleteOrLeaveDialog(Project project, ProjectMember me) {
    final isOwner = project.ownerId == me.userId;
    final title = isOwner ? '프로젝트 삭제' : '프로젝트 나가기';
    final content = isOwner
        ? '정말 이 프로젝트를 삭제하시겠습니까?\n프로젝트와 모든 참여 내역이 영구적으로 삭제됩니다.'
        : '정말 이 프로젝트에서 나가시겠습니까?';
    final actionText = isOwner ? '삭제' : '나가기';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
        content: Text(
          content,
          style: const TextStyle(height: 1.5, color: AppColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
            ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // dialog 닫기
              try {
                // 비동기 실행 전에 필요한 인스턴스를 미리 읽음
                final repo = ref.read(supabaseRepositoryProvider);
                
                if (isOwner) {
                  await repo.deleteProject(project.id);
                } else {
                  await repo.leaveProject(project.id, me.userId);
                }
                
                // 데이터베이스 작업이 끝난 후 캐시를 무효화
                ref.invalidate(myProjectsProvider);
                ref.invalidate(myProjectsWithMembersProvider);
                
                // 모든 작업이 끝나고 화면 닫기
                if (mounted) {
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We re-fetch projects to get the latest status
    final projectsAsync = ref.watch(myProjectsProvider);
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));
    final booksAsync = ref.watch(
      projectBooksProvider(widget.projectId),
    ); // Using this if project_books is still a thing
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: membersAsync.when(
          data: (members) {
            final myId = Supabase.instance.client.auth.currentUser?.id;
            final others = members.where((m) => m.userId != myId).toList();
            final titleText = others.isNotEmpty 
                ? '${others.first.nickname ?? "친구"} 님과 함께 읽기'
                : (widget.project?.name ?? '함께 읽기');
            return Text(
              titleText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
            );
          },
          loading: () => const Text(''),
          error: (_, __) => const Text('에러 발생'),
        ),
        actions: [
          membersAsync.when(
            data: (members) {
              final myId = Supabase.instance.client.auth.currentUser?.id;
              final me = members.firstWhere(
                (m) => m.userId == myId,
                orElse: () => ProjectMember(
                  id: '',
                  projectId: widget.projectId,
                  userId: myId ?? '',
                  role: 'member',
                  readingStatus: '',
                  aiQuestionCount: 0,
                  joinedAt: DateTime.now(),
                ),
              );

              // 프로젝트 정보가 로드 중이면 버튼 비활성화, 완료되면 메뉴 표시
              final project = projectsAsync.value?.firstWhere(
                (p) => p.id == widget.projectId,
                orElse: () => Project(
                  id: widget.projectId,
                  name: '',
                  ownerId: '',
                  createdAt: DateTime.now(),
                ),
              );

              if (project == null || project.id.isEmpty) {
                return const SizedBox.shrink();
              }

              final isOwner = project.ownerId == myId;

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.black),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'delete_or_leave') {
                    _showDeleteOrLeaveDialog(project, me);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete_or_leave',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isOwner ? Icons.delete_outline : Icons.exit_to_app, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          isOwner ? '프로젝트 삭제' : '프로젝트 나가기',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          final project = projects.firstWhere(
            (p) => p.id == widget.projectId,
            orElse: () =>
                widget.project ??
                Project(
                  id: widget.projectId,
                  name: '알 수 없음',
                  ownerId: '',
                  createdAt: DateTime.now(),
                ),
          );

          return membersAsync.when(
            data: (members) {
              if (members.isEmpty)
                return const Center(child: Text('멤버 정보를 불러올 수 없습니다.'));

              ProjectMember? me;
              final others = <ProjectMember>[];
              for (var m in members) {
                if (m.userId == myId) {
                  me = m;
                } else {
                  others.add(m);
                }
              }

              if (me == null)
                return const Center(child: Text('멤버 정보를 불러올 수 없습니다.'));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Area
                    _buildHeader(project, me, others),
                    const SizedBox(height: 32),

                    if (project.status == 'pending_books')
                      _buildBookSelectionPhase(project, me, others)
                    else
                      _buildInProgressPhase(project, me, others),
                  ],
                ),
              );
            },
            loading: () => const Center(child: FlorenceLoader()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: FlorenceLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(
    Project project,
    ProjectMember me,
    List<ProjectMember> others,
  ) {
    String subtitle = '준비 중';
    if (project.status == 'in_progress') {
      if (project.endDate != null) {
        final daysLeft = project.endDate!.difference(DateTime.now()).inDays;
        subtitle = daysLeft >= 0 ? 'D-$daysLeft' : '기한 초과';
      }
    } else if (project.status == 'completed') {
      subtitle = '완수 됨!';
    } else if (project.status == 'pending_books' && others.isNotEmpty) {
      final latestJoined = [me, ...others]
          .map((m) => m.joinedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final deadline = latestJoined.add(const Duration(hours: 48));
      final hoursLeft = deadline.difference(DateTime.now()).inHours;
      
      if (hoursLeft > 24) {
        subtitle = '선택 마감 D-${hoursLeft ~/ 24}';
      } else if (hoursLeft >= 0) {
        subtitle = '선택 마감 $hoursLeft시간 전';
      } else {
        subtitle = '선택 기한 초과';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatarGroup(me, others),
          const SizedBox(height: 20),
          Text(
            others.isNotEmpty 
                ? '${others.first.nickname ?? "친구"} 님과 함께 읽기'
                : project.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${others.length + 1}명 참여 중',
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (project.status == 'in_progress' || project.status == 'pending_books')
                  ? AppColors.burgundy
                  : AppColors.greyLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: (project.status == 'in_progress' || project.status == 'pending_books')
                    ? Colors.white
                    : AppColors.charcoal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarGroup(ProjectMember me, List<ProjectMember> others) {
    final allMembers = [me, ...others];
    final displayCount = allMembers.length > 5 ? 5 : allMembers.length;
    final avatarRadius = displayCount <= 3 ? 24.0 : 20.0;
    final overlap = avatarRadius * 0.8;
    final totalWidth =
        (avatarRadius * 2) * displayCount - overlap * (displayCount - 1);

    return SizedBox(
      width: totalWidth,
      height: avatarRadius * 2,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * (avatarRadius * 2 - overlap),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: index == 0
                    ? AppColors.ivory
                    : AppColors.greyLight,
                child: Icon(
                  Icons.person,
                  color: index == 0 ? AppColors.burgundy : Colors.white,
                  size: avatarRadius * 0.8,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookSelectionPhase(
    Project project,
    ProjectMember me,
    List<ProjectMember> others,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '읽을 책 선택하기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 16),
        _buildBookSelectionCard(me, isMe: true),
        ...others.map(
          (other) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildBookSelectionCard(other, isMe: false),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '* 모든 참여자가 책을 선택하면 2주간의 독서 프로젝트가 자동으로 시작됩니다.',
          style: const TextStyle(color: AppColors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBookSelectionCard(ProjectMember member, {required bool isMe}) {
    final hasSelected = member.selectedIsbn != null;
    final coverUrl = member.selectedBookCover;
    final bookTitle = member.selectedBookTitle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.burgundy.withOpacity(0.3)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          // Book cover
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: hasSelected
                  ? AppColors.burgundy.withOpacity(0.1)
                  : AppColors.ivory,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasSelected && coverUrl != null && coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.book, color: AppColors.burgundy),
                  )
                : Icon(
                    hasSelected ? Icons.book : Icons.help_outline,
                    color: hasSelected
                        ? AppColors.burgundy
                        : AppColors.greyLight,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '나의 책' : '${member.nickname ?? "친구"}의 책',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                if (hasSelected && bookTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    bookTitle,
                    style: const TextStyle(
                      color: AppColors.charcoal,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  hasSelected ? '책을 선택했습니다!' : '아직 고르지 않았어요.',
                  style: TextStyle(
                    color: hasSelected ? AppColors.burgundy : AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isMe && !hasSelected)
            ElevatedButton(
              onPressed: () => _openBookSearch(member.projectId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('선택'),
            ),
        ],
      ),
    );
  }

  void _openBookSearch(String projectId) async {
    final book = await showSearch<Book?>(
      context: context,
      delegate: BookSearchDelegate(
        ref,
        onBookSelected: (b) =>
            b, // Return the book directly without opening details
      ),
    );

    if (book != null && mounted) {
      try {
        final myId = Supabase.instance.client.auth.currentUser!.id;
        final projectStarted = await ref
            .read(supabaseRepositoryProvider)
            .selectProjectBook(projectId: projectId, userId: myId, book: book);
        ref.invalidate(myProjectsProvider);
        ref.invalidate(projectMembersProvider(projectId));

        if (mounted && projectStarted) {
          // Also refresh user books so the book appears in "읽는 중" tab
          ref.invalidate(userBooksProvider);

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Duomo icon (static, no animation)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: FlorenceDomePainter(
                        progress: 1.0,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '프로젝트가 시작되었습니다!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '2주 안에 완독에 도전하세요!\n서로의 진도를 확인하며 함께 읽어봐요.',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      // Refresh everything so the page shows in_progress state
                      ref.invalidate(myProjectsProvider);
                      ref.invalidate(projectMembersProvider(projectId));
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('책을 선택했습니다! 친구의 선택을 기다리고 있어요.')),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (errCtx) => AlertDialog(
              title: const Text('책 선택 실패'),
              content: Text('$e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(errCtx),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _editTotalPages(ProjectMember member, int currentTotal) {
    final controller = TextEditingController(text: currentTotal.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '총 페이지 수 수정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '실제 책 페이지 수 입력',
            filled: true,
            fillColor: AppColors.ivory,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTotal = int.tryParse(controller.text.trim());
              if (newTotal == null || newTotal <= 0) return;
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(supabaseRepositoryProvider)
                    .updateUserBookStatus(
                      member.userId,
                      member.selectedIsbn!,
                      'reading',
                      totalPages: newTotal,
                    );
                setState(() {}); // Rebuild to refresh
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressPhase(
    Project project,
    ProjectMember me,
    List<ProjectMember> others,
  ) {
    if (project.status == 'completed') {
      final hasMyTicketData = me.quote != null && me.drawingUrl != null;
      return Column(
        children: [
          const Icon(Icons.celebration, color: AppColors.burgundy, size: 64),
          const SizedBox(height: 16),
          const Text(
            '프로젝트 성공!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 24),
          if (!hasMyTicketData) ...[
            // 아직 인용구+그림을 제출하지 않은 경우
            ElevatedButton(
              onPressed: () => _startTicketFlow(project, me),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                '독서 티켓 만들기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            // 이미 제출한 경우
            ElevatedButton(
              onPressed: () {
                context.push(
                  '/home/social/detail/${widget.projectId}/receipt',
                  extra: {'project': project, 'rate': 1.0},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                '독서 티켓 확인하기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '독서 진도',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 16),
        _buildProgressCard(me, isMe: true),
        ...others.map(
          (other) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildProgressCard(other, isMe: false),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(ProjectMember member, {required bool isMe}) {
    if (member.selectedIsbn == null) return const SizedBox.shrink();

    final int read = member.readPages;
    int total = member.totalPages;
    if (total == 0) total = 300; // Last resort fallback

    final double percent = total > 0 ? (read / total).clamp(0.0, 1.0) : 0.0;

    if (isMe && !_isDragging) {
      _currentSliderValue = read.toDouble();
    }

    final bookTitle = member.selectedBookTitle;
    final coverUrl = member.selectedBookCover;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + page count
          Row(
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    coverUrl,
                    width: 32,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 32, height: 44),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? '나의 진도' : '${member.nickname ?? "친구"}의 진도',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (bookTitle != null)
                      Text(
                        bookTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Page count with edit button for "me"
              if (isMe)
                GestureDetector(
                  onTap: () => _editTotalPages(member, total),
                  child: Row(
                    children: [
                      Text(
                        '${_currentSliderValue.toInt()} / $total p',
                        style: const TextStyle(
                          color: AppColors.burgundy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '$read / $total p',
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMe) ...[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.burgundy,
                inactiveTrackColor: AppColors.ivory,
                thumbColor: AppColors.burgundy,
                overlayColor: AppColors.burgundy.withOpacity(0.2),
                trackHeight: 8.0,
              ),
              child: Slider(
                value: _currentSliderValue.clamp(0.0, total.toDouble()),
                max: total.toDouble(),
                divisions: total > 0 ? total : 100,
                onChangeStart: (_) => setState(() => _isDragging = true),
                onChanged: (val) {
                  setState(() {
                    _currentSliderValue = val;
                  });
                },
                onChangeEnd: (val) async {
                  setState(() => _isDragging = false);
                  try {
                    await ref
                        .read(supabaseRepositoryProvider)
                        .syncProjectReadingProgress(
                          projectId: member.projectId,
                          userId: member.userId,
                          isbn: member.selectedIsbn!,
                          readPages: val.toInt(),
                          totalPages: total,
                        );
                    ref.invalidate(myProjectsProvider);
                    ref.invalidate(
                      projectMembersProvider(member.projectId),
                    );
                    if (mounted) {
                      if (val >= total) {
                        ref.invalidate(userBooksProvider);

                        if (mounted) {
                          final repo = ref.read(supabaseRepositoryProvider);
                          ref.invalidate(myProjectsProvider);

                          final updatedMembers = await repo.getProjectMembers(member.projectId);
                          final allReadingDone = updatedMembers.every(
                            (m) => m['reading_status'] == 'completed',
                          );

                          if (!mounted) return;

                          if (!allReadingDone) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '🎉 완독을 축하합니다! 다른 멤버가 아직 읽는 중입니다. 모두 완독하면 독서 티켓을 만들 수 있어요!',
                                ),
                                duration: Duration(seconds: 4),
                              ),
                            );
                            return;
                          }

                          final currentProject = ref
                              .read(myProjectsProvider)
                              .value
                              ?.firstWhere(
                                (element) => element.id == member.projectId,
                              );
                          if (currentProject != null) {
                            await _startTicketFlow(currentProject, member);
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('진도가 저장되었습니다. 화이팅!'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
                  }
                },
              ),
            ),
          ] else ...[
            // For friend, just show a LinearProgressIndicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.ivory,
                color: AppColors.burgundy.withOpacity(0.6),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }


}
