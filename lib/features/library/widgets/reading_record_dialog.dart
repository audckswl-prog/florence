import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../data/models/user_book_model.dart';

class ReadingRecordDialog extends ConsumerStatefulWidget {
  final UserBook userBook;
  final Function(int readPages, int? totalPages, int readCount) onConfirm;

  const ReadingRecordDialog({
    super.key,
    required this.userBook,
    required this.onConfirm,
  });

  @override
  ConsumerState<ReadingRecordDialog> createState() => _ReadingRecordDialogState();
}

class _ReadingRecordDialogState extends ConsumerState<ReadingRecordDialog> {
  bool _isCompleted = true; // Default to fully read
  int _readCount = 1;
  final TextEditingController _readPagesController = TextEditingController();
  final TextEditingController _totalPagesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readCount = widget.userBook.readCount > 0 ? widget.userBook.readCount : 1;
    // Pre-fill total pages if we have it, either from user_books or book table fallback
    // The book model in Aladin doesn't guarantee page count, but we can allow manual entry.
    if (widget.userBook.totalPages != null) {
      _totalPagesController.text = widget.userBook.totalPages.toString();
    }
  }

  @override
  void dispose() {
    _readPagesController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _submit() {
    int readPages = 0;
    int? totalPages;

    if (_isCompleted) {
      // If completed, we assume they read everything. 
      // If total pages is provided, readPages == totalPages.
      if (_totalPagesController.text.isNotEmpty) {
        totalPages = int.tryParse(_totalPagesController.text);
        readPages = totalPages ?? 0;
      } else {
        readPages = 100; // Symbolic 100% if no page data exists
        totalPages = 100;
      }
    } else {
      readPages = int.tryParse(_readPagesController.text) ?? 0;
      totalPages = int.tryParse(_totalPagesController.text);
    }

    widget.onConfirm(readPages, totalPages, _readCount);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                '독서 기록 저장',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.burgundy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.userBook.book.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.charcoal,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // 1. Completion Toggle
              const Text(
                '끝까지 다 읽었나요?',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompleted = true),
                      child: NeumorphicContainer(
                        depth: _isCompleted ? -3 : 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            '네, 완독했어요',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCompleted ? AppColors.burgundy : AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompleted = false),
                      child: NeumorphicContainer(
                        depth: !_isCompleted ? -3 : 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            '아니요 (부분 독서)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isCompleted ? AppColors.burgundy : AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Page Tracking (if not completed)
              if (!_isCompleted) ...[
                const Text(
                  '어디까지 읽었나요?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicContainer(
                        depth: -2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        borderRadius: 8,
                        child: TextField(
                          controller: _readPagesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '읽은 쪽수',
                            hintStyle: TextStyle(color: AppColors.greyLight, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('/', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey, fontSize: 18)),
                    ),
                    Expanded(
                      child: NeumorphicContainer(
                        depth: -2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        borderRadius: 8,
                        child: TextField(
                          controller: _totalPagesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '전체 쪽수',
                            hintStyle: TextStyle(color: AppColors.greyLight, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '기록하신 분량에 꼭 맞는 두께로 서재에 꽂히게 됩니다.',
                  style: TextStyle(color: AppColors.grey, fontSize: 11, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              // 3. N-th Reading Stepper
              const Text(
                '몇 번째 읽는 책인가요?',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_readCount > 1) setState(() => _readCount--);
                    },
                    child: const NeumorphicContainer(
                      depth: 2,
                      padding: EdgeInsets.all(8),
                      borderRadius: 12,
                      child: Icon(Icons.remove, color: AppColors.grey, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$_readCount회독',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _readCount++);
                    },
                    child: const NeumorphicContainer(
                      depth: 2,
                      padding: EdgeInsets.all(8),
                      borderRadius: 12,
                      child: Icon(Icons.add, color: AppColors.burgundy, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Actions
              NeumorphicButton(
                onPressed: _submit,
                color: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: const Text(
                  '서재에 꽂기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('취소', style: TextStyle(color: AppColors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
