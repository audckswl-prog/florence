import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/ai_ticket_repository.dart';

final aiTicketRepositoryProvider = Provider((ref) {
  return AITicketRepository(Supabase.instance.client);
});
