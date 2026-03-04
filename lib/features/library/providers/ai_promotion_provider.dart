import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/ai_promotion_model.dart';
import '../../../../data/repositories/ai_promotion_repository.dart';
import '../../../../data/services/supabase_service.dart';

final aiPromotionRepositoryProvider = Provider<AIPromotionRepository>((ref) {
  return AIPromotionRepository(SupabaseService().client);
});

typedef PromotionParams = ({
  String isbn,
  String title,
  String author,
  String description,
});

final aiPromotionFutureProvider =
    FutureProvider.family<AIPromotionModel?, PromotionParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(aiPromotionRepositoryProvider);
      return repository.getPromotion(
        params.isbn,
        params.title,
        params.author,
        params.description,
      );
    });
