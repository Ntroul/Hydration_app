import 'package:supabase_flutter/supabase_flutter.dart';

class WaterService {
  static Future<void> addWater(int amount) async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase.from('water_logs').insert({
      'user_id': user.id,
      'amount': amount,
    });
  }
}