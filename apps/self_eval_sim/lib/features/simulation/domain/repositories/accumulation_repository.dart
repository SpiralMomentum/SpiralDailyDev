import 'package:utils/utils.dart';

import '../entities/accumulation.dart';

/// 누적 기록 저장소. 기기 안에만 저장한다.
abstract interface class AccumulationRepository {
  Future<Result<AccumulationState>> load();
  Future<Result<void>> save(AccumulationState state);
  Future<Result<void>> clear();
}
