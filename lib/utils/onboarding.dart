import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OnboardingUtils {
  static const _flagFileName = '.onboarding_done';

  static Future<File> _flagFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_flagFileName');
  }

  static Future<bool> isDone() async {
    try {
      final f = await _flagFile();
      return f.existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDone() async {
    try {
      final f = await _flagFile();
      if (!await f.exists()) {
        await f.create(recursive: true);
      }
      await f.writeAsString('ok');
    } catch (_) {}
  }
}

