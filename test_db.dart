import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://ilqfaamrcfihcbfgdttr.supabase.co';
  final supabaseKey = 'sb_publishable_kfBPax6qukxYwTLOB5B53Q_rz_ubM4t';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  print('Testing profiles(*) query...');
  try {
    final response = await client
        .from('project_members')
        .select('*, profiles(*)')
        .limit(1);
    print('SUCCESS profiles(*): $response');
  } catch (e) {
    print('ERROR profiles(*): $e');
  }
  
  print('\nTesting just books(*) query...');
  try {
    final response2 = await client
        .from('project_members')
        .select('*, books(*)')
        .limit(1);
    print('SUCCESS books(*): $response2');
  } catch (e) {
    print('ERROR books(*): $e');
  }
}
