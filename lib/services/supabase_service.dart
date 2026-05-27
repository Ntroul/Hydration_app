import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> getProfile() async {
    final user = supabase.auth.currentUser;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .single();

    return response;
  }
}