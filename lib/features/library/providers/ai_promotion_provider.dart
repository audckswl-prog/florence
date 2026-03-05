import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/ai_promotion_model.dart';
import '../../../../data/repositories/ai_promotion_repository.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../data/models/book_model.dart'; // 추가

final aiPromotionRepositoryProvider = Provider<AIPromotionRepository>((ref) {
  return AIPromotionRepository(SupabaseService().client);
});

// Record 대신 Book 객체 원본을 받아 내부 캐싱 무결성을 유지합니다.
final aiPromotionFutureProvider =
    FutureProvider.family<AIPromotionModel?, Book>((ref, book) async {
  final repository = ref.read(aiPromotionRepositoryProvider);
  return repository.getPromotion(
    book.isbn,
    book.title,
    book.author,
    book.description,
  );
});
