import 'package:flutter/foundation.dart';

class WaterSync {
  static final ValueNotifier<int> notifier = ValueNotifier(0);

  static void notify() {
    notifier.value++;
  }
}