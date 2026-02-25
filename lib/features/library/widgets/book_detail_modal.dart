import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/user_book_model.dart';
import '../providers/book_providers.dart';
import '../providers/library_providers.dart'; // For refreshing userBooks
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/florence_toast.dart';
import 'ai_promotion_card.dart';

class BookDetailModal extends ConsumerStatefulWidget {
  final Book book;
  final UserBook? userBook;

  const BookDetailModal({
    super.key,
    required this.book,
    this.userBook,
  });

  @override
  ConsumerState<BookDetailModal> createState() => _BookDetailModalState();
}

class _BookDetailModalState extends ConsumerState<BookDetailModal> {
  bool _isLoading = false;

  Future<void> _saveOrUpdateBook(String status) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.userBook != null) {
        // Update existing book
        await ref.read(supabaseRepositoryProvider).updateUserBookStatus(
              userId,
              widget.book.isbn,
              status,
            );
        if (mounted) {
          FlorenceToast.show(context, '도서 상태가 수정되었습니다.');
        }
      } else {
        // Add new book
        // If pageCount is 0, try to fetch detailed info first
        Book bookToAdd = widget.book;
        if (bookToAdd.pageCount == 0) {
          try {
             final detailedBook = await ref.read(bookRepositoryProvider).getBookDetail(bookToAdd.isbn);
             if (detailedBook != null) {
               bookToAdd = detailedBook;
             }
          } catch (e) {
            // Ignore error and use original book data if fetch fails
            debugPrint('Failed to fetch detailed book info: $e');
          }
        }

        await ref.read(supabaseRepositoryProvider).addUserBook(
              userId: userId,
              book: bookToAdd,
              status: status,
            );
        if (mounted) {
          FlorenceToast.show(context, '서재에 추가되었습니다.');
        }
      }

      // Refresh library list
      ref.invalidate(userBooksProvider);

      if (status == 'read' && mounted) {
        final mockUserBook = widget.userBook ?? UserBook(
            id: 'temp',
            userId: userId,
            isbn: widget.book.isbn,
            status: 'read',
            book: widget.book,
            readCount: 1, // default
        );
        
        // Pop the modal FIRST before showing the dialog, passing a flag so the parent can show the dialog
        // Or better yet, just show the dialog here, and THEN pop the modal but wait for the dialog to finish.
        // Actually, if we pop the modal first, this widget is unmounted. 
        // Let's pop the modal first, then the parent screen (e.g. ReadingListScreen or Home) could handle it.
        // BUT wait, this is a bottom sheet/modal. If we push a new screen over it, then pop the modal underneath, it might pop the new screen!
        // We should pop the BookDetailModal FIRST to get back to the main screen context, then show the dialog.
        
        Navigator.of(context).pop({'action': 'read_completed', 'book': mockUserBook});
        return; // Exit early so we don't pop again below
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        FlorenceToast.show(context, '작업 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBook() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || widget.userBook == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 책을 서재에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(supabaseRepositoryProvider).deleteUserBook(
            userId,
            widget.book.isbn,
          );

      ref.invalidate(userBooksProvider);

      if (mounted) {
        Navigator.pop(context, true);
        FlorenceToast.show(context, '삭제되었습니다.');
      }
    } catch (e) {
      if (mounted) {
        FlorenceToast.show(context, '삭제 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.userBook?.status;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Book Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicContainer(
                depth: 2.0,
                borderRadius: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.book.coverUrl,
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.author,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.book.publisher,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                    if (widget.book.pageCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.book.pageCount}쪽',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.burgundy,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AIPromotionCard(book: widget.book),
          const SizedBox(height: 32),
          // Action Buttons
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                _buildActionButton(
                  context,
                  label: '읽고 있는 책',
                  icon: Icons.auto_stories,
                  color: currentStatus == 'reading'
                      ? AppColors.burgundy
                      : AppColors.ivory,
                  textColor: currentStatus == 'reading'
                      ? Colors.white
                      : AppColors.burgundy,
                  onTap: () => _saveOrUpdateBook('reading'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '다 읽은 책',
                        icon: Icons.check_circle_outline,
                        color: currentStatus == 'read'
                            ? AppColors.burgundy
                            : AppColors.ivory,
                        textColor: currentStatus == 'read'
                            ? Colors.white
                            : AppColors.burgundy,
                        onTap: () => _saveOrUpdateBook('read'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: '읽고 싶은 책',
                        icon: Icons.bookmark_border,
                        color: currentStatus == 'wish'
                            ? AppColors.burgundy
                            : AppColors.ivory,
                        textColor: currentStatus == 'wish'
                            ? Colors.white
                            : AppColors.burgundy,
                        onTap: () => _saveOrUpdateBook('wish'),
                      ),
                    ),
                  ],
                ),
                if (widget.userBook != null) ...[
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _deleteBook,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    label: const Text('서재에서 삭제하기',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: 12,
        color: color,
        depth: 3.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
