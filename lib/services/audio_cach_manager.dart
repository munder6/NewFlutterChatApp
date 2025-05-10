import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioCacheManager {
  static final Map<String, String?> _cachedAudios = {};

  static Future<String?> getOrDownloadCachedAudio(String url) async {
    // تحقق أولاً إذا كان الملف موجوداً في الذاكرة أو في الكاش
    if (_cachedAudios.containsKey(url)) {
      return _cachedAudios[url]; // إذا كان موجودًا نعيد المسار المخزن
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = md5.convert(utf8.encode(url)).toString() + '.m4a';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        print('✅ الصوت موجود محلياً: $filePath');
        _cachedAudios[url] = filePath; // تخزين الملف في الكاش
        return filePath;
      }

      print('⬇️ تحميل الصوت لأول مرة...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ تم حفظ الصوت في: $filePath');
        _cachedAudios[url] = filePath; // تخزين المسار في الكاش بعد التحميل
        return filePath;
      } else {
        print('❌ فشل تحميل الصوت: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ أثناء تحميل الصوت: $e');
      return null;
    }
  }
}

