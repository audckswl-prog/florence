import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/book_model.dart';
import '../../library/providers/book_providers.dart';
import '../../memo/providers/memo_providers.dart';
import '../providers/social_providers.dart';
import '../widgets/receipt_widget.dart';
// import '../../../core/widgets/neumorphic_button.dart';
import 'dart:math';

class ProjectReceiptScreen extends ConsumerStatefulWidget {
  final Project project;
  final double completionRate;

  const ProjectReceiptScreen({
    super.key,
    required this.project,
    this.completionRate = 1.0,
  });

  @override
  ConsumerState<ProjectReceiptScreen> createState() => _ProjectReceiptScreenState();
}

class _ProjectReceiptScreenState extends ConsumerState<ProjectReceiptScreen> {
  Book? _book;
  bool _isLoadingBook = false;

  @override
  void initState() {
    super.initState();
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
    final membersAsync = ref.watch(projectMembersProvider(widget.project.id));
    final memosAsync = widget.project.isbn != null && widget.project.ownerId.isNotEmpty
        ? ref.watch(memosForUserProvider((userId: widget.project.ownerId, isbn: widget.project.isbn!))) // Watch owner's memos
        : const AsyncValue<List<dynamic>>.data([]); 

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: membersAsync.when(
          data: (members) {
            final totalMembers = members.isEmpty ? 1 : members.length;
            final completedCount = members.where((m) => m.readingStatus == 'completed').length;
            final calculatedRate = completedCount / totalMembers;
            
            // Tier Logic: 100% (Perfect), >=50% (Good), <50% (Failed/Crumpled conceptually)
            String ratingText = 'GOOD EFFORT';
            if (calculatedRate == 1.0) {
              ratingText = 'PERFECT MASTERPIECE';
            } else if (calculatedRate < 0.5) {
              ratingText = 'NEEDS IMPROVEMENT';
            }

            return Column(
              children: [
                ReceiptWidget(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       // Header
                       const Center(
                         child: Icon(Icons.receipt_long, size: 40, color: AppColors.black),
                       ),
                       const SizedBox(height: 16),
                       const Center(
                         child: Text(
                           'FLORENCE RECEIPT',
                           style: TextStyle(
                             fontFamily: 'Courier', 
                             fontWeight: FontWeight.bold,
                             fontSize: 24,
                             letterSpacing: 2.0,
                           ),
                         ),
                       ),
                       const SizedBox(height: 8),
                       Center(
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           decoration: BoxDecoration(
                             color: AppColors.black,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             ratingText,
                             style: const TextStyle(
                               fontFamily: 'Courier', 
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                               fontSize: 14,
                             ),
                           ),
                         ),
                       ),
                   const Divider(color: AppColors.black, thickness: 2, height: 32),
                   
                   // Date & Project
                   _buildRow('DATE', DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now())),
                   _buildRow('PROJECT', widget.project.name),
                   if (_book != null) _buildRow('YEAR', _book!.publicationYear),
                   const SizedBox(height: 16),
                   
                   // Book Info
                   if (_book != null) ...[
                     const Divider(color: AppColors.greyLight, thickness: 1),
                     const SizedBox(height: 16),
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         if (_book!.coverUrl.isNotEmpty)
                           Container(
                             width: 60,
                             height: 90,
                             decoration: BoxDecoration(
                               border: Border.all(color: AppColors.black),
                               image: DecorationImage(
                                 image: NetworkImage(_book!.coverUrl),
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
                                 _book!.title,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                               ),
                               Text(
                                 _book!.author,
                                 style: const TextStyle(color: AppColors.grey, fontSize: 13),
                               ),
                               const SizedBox(height: 8),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(
                                   border: Border.all(color: AppColors.black),
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: const Text('READING COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                               ),
                             ],
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                   ],

                   // Members
                   const Divider(color: AppColors.greyLight, thickness: 1),
                   const SizedBox(height: 16),
                   const Text('MEMBERS', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   membersAsync.when(
                     data: (members) => Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: members.map((m) => Chip(
                         label: Text('Member ${m.userId.substring(0, 4)}'), // Mock name
                         backgroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(20), 
                           side: const BorderSide(color: AppColors.black)
                         ),
                       )).toList(),
                     ),
                     loading: () => const Text('Loading members...'),
                     error: (e, _) => const Text('Failed to load members'),
                   ),
                   const SizedBox(height: 16),

                   // Q&A (Memos)
                   // We display random or top 3 memos from the owner as "Insights"
                   const Divider(color: AppColors.greyLight, thickness: 1),
                   const SizedBox(height: 16),
                   const Text('PERSONAL Q&A', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   if (widget.project.isbn == null)
                     const Text('No book linked to this project.', style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic))
                   else
                      // Memos are loaded via provider. Note: This provider call might need to be adjusted if it expects a family.
                      // Using Consumer in existing widget tree or just ref.watch above.
                      // Assuming ref.watch returns AsyncValue.
                      memosAsync.when(
                        data: (memos) {
                          if (memos.isEmpty) {
                            return const Text('No memos recorded.', style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic));
                          }
                          // Take top 3
                          final topMemos = memos.take(3).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: topMemos.map((memo) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q. ${memo.content.length > 20 ? '${memo.content.substring(0, 20)}...' : memo.content}', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    memo.content,
                                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: AppColors.charcoal),
                                  ),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                        loading: () => const Center(child: FlorenceLoader()),
                        error: (e, _) => Text('Error: $e'),
                      ),

                   const SizedBox(height: 32),
                   // Footer Barcode
                   Center(
                     child: Column(
                       children: [
                         Container(
                           height: 40,
                           width: double.infinity,
                           color: Colors.black, // Placeholder for barcode
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: List.generate(20, (index) => Container(
                               width: Random().nextDouble() * 10 + 2,
                               color: Colors.white,
                             )),
                           ),
                         ),
                         const SizedBox(height: 8),
                         const Text('THANK YOU FOR READING', style: TextStyle(fontSize: 10, letterSpacing: 1.5)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
              // Action Buttons
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지로 저장되었습니다')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ivory,
                    foregroundColor: AppColors.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.download, color: AppColors.burgundy),
                  label: const Text('이미지로 저장', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: FlorenceLoader()),
        error: (e, stack) => const Center(child: Text('Error loading members for receipt.', style: TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
