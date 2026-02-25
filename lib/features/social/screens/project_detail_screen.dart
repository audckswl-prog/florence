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

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final Project? project;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.project,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  // Local state for the slider to provide instant feedback
  double _currentSliderValue = 0;
  bool _isDragging = false;
  
  @override
  Widget build(BuildContext context) {
    // We re-fetch projects to get the latest status
    final projectsAsync = ref.watch(myProjectsProvider);
    final membersAsync = ref.watch(projectMembersProvider(widget.projectId));
    final booksAsync = ref.watch(projectBooksProvider(widget.projectId)); // Using this if project_books is still a thing
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
        title: Text(
          widget.project?.name ?? '함께 읽기',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
        ),
      ),
      body: projectsAsync.when(
        data: (projects) {
          final project = projects.firstWhere(
            (p) => p.id == widget.projectId, 
            orElse: () => widget.project ?? Project(id: widget.projectId, name: '알 수 없음', ownerId: '', createdAt: DateTime.now())
          );
          
          return membersAsync.when(
            data: (members) {
              if (members.isEmpty) return const Center(child: Text('멤버 정보를 불러올 수 없습니다.'));
              
              ProjectMember? me;
              ProjectMember? friend;
              for (var m in members) {
                if (m.userId == myId) me = m;
                else friend = m;
              }
              
              if (me == null || friend == null) return const Center(child: Text('멤버 정보를 불러올 수 없습니다.'));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Area
                    _buildHeader(project, me, friend),
                    const SizedBox(height: 32),
                    
                    if (project.status == 'pending_books') 
                      _buildBookSelectionPhase(project, me, friend)
                    else 
                      _buildInProgressPhase(project, me, friend),
                      
                    const SizedBox(height: 32),
                    // Members Section & AI Chat
                    _buildAiChatStart(project),
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

  Widget _buildHeader(Project project, ProjectMember me, ProjectMember friend) {
    String subtitle = '준비 중';
    if (project.status == 'in_progress') {
       if (project.endDate != null) {
          final daysLeft = project.endDate!.difference(DateTime.now()).inDays;
          subtitle = daysLeft >= 0 ? 'D-$daysLeft' : '기한 초과';
       }
    } else if (project.status == 'completed') {
       subtitle = '완수 됨!';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatarPair(me, friend),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            project.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.charcoal),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: project.status == 'in_progress' ? AppColors.burgundy : AppColors.greyLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: project.status == 'in_progress' ? Colors.white : AppColors.charcoal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPair(ProjectMember me, ProjectMember friend) {
    // In a real app we'd fetch the profile_url for both. For now, we use placeholders.
    return SizedBox(
      width: 100,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.ivory,
              child: const Icon(Icons.person, color: AppColors.grey),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.greyLight,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookSelectionPhase(Project project, ProjectMember me, ProjectMember friend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '읽을 책 선택하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
        const SizedBox(height: 16),
        _buildBookSelectionCard(me, isMe: true),
        const SizedBox(height: 16),
        _buildBookSelectionCard(friend, isMe: false),
        const SizedBox(height: 24),
        const Text(
          '* 두 사람 모두 책을 선택하면 2주간의 독서 프로젝트가 자동으로 시작됩니다.',
          style: TextStyle(color: AppColors.grey, fontSize: 12),
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
        border: Border.all(color: isMe ? AppColors.burgundy.withOpacity(0.3) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // Book cover
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: hasSelected ? AppColors.burgundy.withOpacity(0.1) : AppColors.ivory,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasSelected && coverUrl != null && coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.book, color: AppColors.burgundy),
                  )
                : Icon(
                    hasSelected ? Icons.book : Icons.help_outline,
                    color: hasSelected ? AppColors.burgundy : AppColors.greyLight,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '나의 책' : '친구의 책',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                if (hasSelected && bookTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    bookTitle,
                    style: const TextStyle(color: AppColors.charcoal, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  hasSelected ? '책을 선택했습니다!' : '아직 고르지 않았어요.',
                  style: TextStyle(color: hasSelected ? AppColors.burgundy : AppColors.grey, fontSize: 12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        onBookSelected: (b) => b, // Return the book directly without opening details
      ),
    );

    if (book != null && mounted) {
      try {
        final myId = Supabase.instance.client.auth.currentUser!.id;
        final projectStarted = await ref.read(supabaseRepositoryProvider).selectProjectBook(
          projectId: projectId,
          userId: myId,
          book: book,
        );
        ref.invalidate(myProjectsProvider);
        ref.invalidate(projectMembersProvider(projectId));

        if (mounted && projectStarted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Icon(Icons.celebration, color: AppColors.burgundy, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    '프로젝트가 시작되었습니다! 🎉',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '2주 안에 완독에 도전하세요!\n서로의 진도를 확인하며 함께 읽어봐요.',
                    style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('시작하기', style: TextStyle(fontWeight: FontWeight.bold)),
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
            builder: (_) => AlertDialog(
              title: const Text('책 선택 실패'),
              content: Text('$e'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
            ),
          );
        }
      }
    }
  }

  Widget _buildInProgressPhase(Project project, ProjectMember me, ProjectMember friend) {
    if (project.status == 'completed') {
      return Column(
        children: [
          const Icon(Icons.celebration, color: AppColors.burgundy, size: 64),
          const SizedBox(height: 16),
          const Text(
            '프로젝트 성공!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.charcoal),
          ),
          const SizedBox(height: 24),
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
             child: const Text('독서 티켓 확인하기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    // Default to In Progress -> Needs integration with user_books to get exact pages
    // For this mockup, we'll assume we fetch the user's book progress.
    // Actually, we must use a FutureBuilder or Provider to get the specific user_books row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '독서 진도',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
        ),
        const SizedBox(height: 16),
        _buildProgressCard(me, isMe: true),
        const SizedBox(height: 16),
        _buildProgressCard(friend, isMe: false),
      ],
    );
  }

  Widget _buildProgressCard(ProjectMember member, {required bool isMe}) {
    // Fetch the user's book status for this specific ISBN
    if (member.selectedIsbn == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(supabaseRepositoryProvider).getUserBooks(member.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final userBooks = snapshot.data!;
        final userBook = userBooks.firstWhere(
           (ub) => ub['isbn'] == member.selectedIsbn,
           orElse: () => {'read_pages': 0, 'total_pages': 300}, // Fallback
        );

        final int read = userBook['read_pages'] ?? 0;
        final int total = userBook['total_pages'] ?? 300;
        final double percent = total > 0 ? read / total : 0.0;
        
        if (isMe && !_isDragging) {
           _currentSliderValue = read.toDouble();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMe ? '나의 진도' : '친구의 진도',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                  Text(
                    '${isMe ? _currentSliderValue.toInt() : read} / $total p',
                    style: const TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold),
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
                        await ref.read(supabaseRepositoryProvider).syncProjectReadingProgress(
                           projectId: member.projectId,
                           userId: member.userId,
                           isbn: member.selectedIsbn!,
                           readPages: val.toInt(),
                           totalPages: total,
                        );
                        ref.invalidate(myProjectsProvider);
                        // Show motivational snackbar based on progress
                        if (mounted) {
                           if (val >= total) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('축하합니다! 완독하셨네요!')));
                           } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('진도가 저장되었습니다. 화이팅!')));
                           }
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
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
      },
    );
  }

  Widget _buildAiChatStart(Project project) {
    if (project.status == 'pending_books') return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.burgundy, // Softer AI UI
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.ivory, size: 24),
              const SizedBox(width: 12),
              Text(
                'AI 도슨트와 대화하기',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '책을 읽다가 생긴 궁금증, 혹은 발제문이 필요하다면 언제든 AI 도슨트에게 물어보세요.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {
                context.push('/home/social/detail/${project.id}/ai-chat', extra: project);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('대화 시작', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
