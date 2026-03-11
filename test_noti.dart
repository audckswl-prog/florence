import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://ilqfaamrcfihcbfgdttr.supabase.co';
  final supabaseKey = 'sb_publishable_kfBPax6qukxYwTLOB5B53Q_rz_ubM4t';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  print('Testing getNotifications query...');
  try {
    final response = await client
        .from('notifications')
        .select('*, sender:profiles!sender_id(*)')
        .limit(1);
    print('SUCCESS notifications: $response');
  } catch (e) {
    print('ERROR notifications: $e');
  }
}
