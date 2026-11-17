import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lets the user pick an audio file and keeps a copy in the app folder,
/// because the picker's temporary file can be deleted by the system.
class SoundFileStore {
  /// Returns the stored file path, or null if the user cancelled.
  Future<String?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final source = result?.files.single.path;
    if (source == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final target = p.join(dir.path, 'alarm_${p.basename(source)}');
    await File(source).copy(target);
    return target;
  }

  String displayName(String path) => p.basename(path).replaceFirst('alarm_', '');
}
