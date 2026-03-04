import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/book_model.dart';
import '../../library/providers/book_providers.dart';
import '../../library/screens/book_search_delegate.dart';
import '../../../data/repositories/supabase_repository.dart';
import '../providers/social_providers.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Book? _selectedBook;
  bool _isLoading = false;

  DateTime? _selectedTargetDate;

  Future<void> _selectBook() async {
    await showSearch(
      context: context,
      delegate: BookSearchDelegate(
        ref,
        onBookSelected: (book) {
          setState(() {
            _selectedBook = book;
          });
        },
      ),
    );
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.burgundy,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모임 이름을 입력해주세요.')));
      return;
    }

    if (_selectedBook == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('함께 읽을 책을 선택해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final projectName = _nameController.text.trim();

      // Note: In the new 1:1 flow, projects are created via friend profile directly.
      // This screen is technically deprecated but kept compilable for reference.
      await ref
          .read(supabaseRepositoryProvider)
          .createProject(
            name: projectName,
            ownerId: userId,
            friendIds: [userId], // Mocked for compile success
          );

      // Refresh project list
      ref.invalidate(myProjectsProvider);

      if (mounted) {
        context.pop(); // Close create screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('새로운 독서 모임이 생성되었습니다!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('생성 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          '새 모임 만들기',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '모임 이름',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            NeumorphicContainer(
              depth: -2.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 12,
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '예: 새벽 5시 기상 독서',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.greyLight),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '모임 소개 & 목표',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            NeumorphicContainer(
              depth: -2.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 12,
              child: TextField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      '어떤 책을 읽을지, 언제까지 완독할지\n멤버들에게 목표를 공유해주세요.\n\n예: 이번 달은 <데미안>을 읽고 토론합니다.',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.greyLight),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '함께 읽을 책',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            NeumorphicContainer(
              depth: -2.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 12,
              child: GestureDetector(
                onTap: _selectBook,
                child: Row(
                  children: [
                    Icon(
                      _selectedBook != null ? Icons.book : Icons.search,
                      color: _selectedBook != null
                          ? AppColors.burgundy
                          : AppColors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedBook?.title ?? '책을 검색해서 선택해주세요',
                        style: TextStyle(
                          color: _selectedBook != null
                              ? AppColors.black
                              : AppColors.greyLight,
                          fontWeight: _selectedBook != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '목표 완독일 (선택)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            NeumorphicContainer(
              depth: -2.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 12,
              child: GestureDetector(
                onTap: _selectTargetDate,
                child: Row(
                  children: [
                    Icon(
                      _selectedTargetDate != null
                          ? Icons.calendar_today
                          : Icons.calendar_month_outlined,
                      color: _selectedTargetDate != null
                          ? AppColors.burgundy
                          : AppColors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTargetDate != null
                            ? '${_selectedTargetDate!.year}년 ${_selectedTargetDate!.month}월 ${_selectedTargetDate!.day}일'
                            : '언제까지 다 읽을까요?',
                        style: TextStyle(
                          color: _selectedTargetDate != null
                              ? AppColors.black
                              : AppColors.greyLight,
                          fontWeight: _selectedTargetDate != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            _isLoading
                ? const Center(child: FlorenceLoader())
                : NeumorphicButton(
                    onPressed: _createProject,
                    color: AppColors.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: 12,
                    child: const Text(
                      '모임 시작하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
