import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/user_book_model.dart';
import '../../library/providers/book_providers.dart';
import '../../library/providers/library_providers.dart';
import '../../library/screens/reading_ticket_screen.dart';
import '../../memo/providers/memo_providers.dart';
import '../providers/social_providers.dart';

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
  Book? _book;
  bool _isLoadingBook = false;
  
  late final Alignment _bgAlignment;
  late final Color _bgTint;

  static const _tints = [
    Color(0xFFE57373), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFF64B5F6),
    Color(0xFFFFB74D), Color(0xFFF06292), Color(0xFF81C784), Color(0xFF90A4AE),
    Color(0xFFFF8A65), Color(0xFFA1887F),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _bgAlignment = Alignment((rng.nextDouble() * 1.4) - 0.7, (rng.nextDouble() * 1.4) - 0.7);
    _bgTint = _tints[rng.nextInt(_tints.length)];
    _loadBook();
  }

  Future<void> _loadBook() async {
    if (widget.project.isbn != null) {
      setState(() => _isLoadingBook = true);
      try {
        final book = await ref.read(bookRepositoryProvider).getBookDetail(widget.project.isbn!);
        if (mounted) {
          setState(() {
            _book = book;
            _isLoadingBook = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingBook = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBook || _book == null) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(child: FlorenceLoader()),
      );
    }

    final memosAsync = widget.project.ownerId.isNotEmpty
        ? ref.watch(memosForUserProvider((userId: widget.project.ownerId, isbn: _book!.isbn)))
        : const AsyncValue<List<dynamic>>.data([]);
    
    final aiDataAsync = ref.watch(aiTicketFutureProvider(_book!));
    final readCountThisYear = ref.watch(readBooksThisYearProvider).value ?? 1;

    String memoQuote = '';
    memosAsync.whenData((memos) {
      if (memos.isNotEmpty) {
        memoQuote = memos.first.content;
      }
    });

    final dummyUserBook = UserBook(
      id: widget.project.id,
      userId: widget.project.ownerId,
      isbn: _book!.isbn,
      status: 'read',
      book: _book!,
    );

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

          Align(
            alignment: Alignment.center,
            child: SizedBox.expand(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Hero(
                      tag: 'shared_ticket_${_book!.isbn}',
                      child: aiDataAsync.when(
                        data: (aiData) => ReadingTicketWidget(
                          userBook: dummyUserBook,
                          quote: memoQuote,
                          readCountThisYear: readCountThisYear,
                          nationalityCode: aiData.nationalityCode,
                          nationalityName: aiData.nationalityName,
                          publicationYear: aiData.publicationYear != '연도 미상'
                              ? aiData.publicationYear
                              : _book!.publicationYear,
                        ),
                        loading: () => ReadingTicketWidget(
                          userBook: dummyUserBook,
                          quote: memoQuote,
                          readCountThisYear: readCountThisYear,
                          nationalityCode: 'UN',
                          nationalityName: '분석 중',
                          publicationYear: _book!.publicationYear,
                        ),
                        error: (e, st) => ReadingTicketWidget(
                          userBook: dummyUserBook,
                          quote: memoQuote,
                          readCountThisYear: readCountThisYear,
                          nationalityCode: 'UN',
                          nationalityName: '알 수 없음',
                          publicationYear: _book!.publicationYear,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이미지로 저장되었습니다 (준비중)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ivory,
                foregroundColor: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 12,
              ),
              icon: const Icon(Icons.download, color: AppColors.burgundy),
              label: const Text(
                '이미지로 저장',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
