import 'package:utils/utils.dart';

import 'story_record.dart';

/// 이야기 만남 기록 저장소. 기기 안에만 저장한다.
abstract interface class StoryRepository {
  /// 세계의 만남 기록을 읽는다. 기록이 없으면 빈 목록.
  Future<Result<List<StoryMeeting>>> load(String worldId);

  /// 만남 하나를 기록 끝에 덧붙인다.
  Future<Result<void>> append(String worldId, StoryMeeting meeting);

  /// 모든 세계의 이야기 기록을 지운다.
  Future<Result<void>> clear();
}
