import 'dart:convert';
import 'dart:io';

/// 누적 기록을 기기 안 JSON 파일 하나로 보관한다.
/// 쓰기는 임시 파일에 쓴 뒤 이름을 바꿔, 쓰는 도중 앱이 꺼져도 이전 기록이 깨지지 않게 한다.
class AccumulationFileDataSource {
  AccumulationFileDataSource(this._directory);

  static const fileName = 'accumulation.json';

  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  Future<Map<String, dynamic>?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> write(Map<String, dynamic> json) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(json), flush: true);
    await temp.rename(file.path);
  }

  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}
