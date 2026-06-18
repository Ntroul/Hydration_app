import 'package:supabase_flutter/supabase_flutter.dart';

class WaterService {
  static Future<void> addWater(int amount, String userId) async {
    final supabase = Supabase.instance.client;

    await supabase.from('water_logs').insert({
      'user_id': userId,
      'amount': amount,
    });
  }
}