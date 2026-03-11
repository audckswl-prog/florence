import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://ilqfaamrcfihcbfgdttr.supabase.co';
  final supabaseKey = 'sb_publishable_kfBPax6qukxYwTLOB5B53Q_rz_ubM4t';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  final projectId = '271cab55-4997-4296-b713-f3169fb27517';
  
  print('Testing project_members for project $projectId');
  try {
    final response = await client
        .from('project_members')
        .select()
        .eq('project_id', projectId);
    
    for (var row in response) {
      print('User ID: ${row['user_id']}');
      print('Selected ISBN: ${row['selected_isbn']}');
      print('Role: ${row['role']}');
      print('---');
    }
  } catch (e) {
    print('ERROR project_members: $e');
  }
}
