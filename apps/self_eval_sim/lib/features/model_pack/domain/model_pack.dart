import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

/// 모델 단독 용량 상한 초과 (명세: 상한을 따로 둠, 수치는 미정).
class ModelTooLargeFailure extends BusinessRuleFailure {
  const ModelTooLargeFailure({required this.bytes, required this.limit})
      : super(message: 'model pack $bytes bytes exceeds $limit');

  final int bytes;
  final int limit;
}

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();
}

final class DownloadProgress extends DownloadEvent {
  const DownloadProgress({required this.received, required this.total});

  final int received;

  /// 서버가 크기를 알려주지 않으면 null.
  final int? total;

  int? get percent =>
      total == null || total == 0 ? null : (received * 100 ~/ total!).clamp(0, 100);

  @override
  List<Object?> get props => [received, total];
}

final class DownloadCompleted extends DownloadEvent {
  const DownloadCompleted();

  @override
  List<Object?> get props => [];
}

final class DownloadFailed extends DownloadEvent {
  const DownloadFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// 용량 상한 정책. 크기를 미리 알 수 있으면 받기 전에, 받는 중에는 누적 바이트로 검사한다.
abstract final class ModelPackPolicy {
  static bool exceeds(int bytes, int limit) => bytes > limit;
}

/// 온디바이스 모델 파일 설치 저장소.
abstract interface class ModelPackRepository {
  Future<bool> isInstalled();

  /// 모델을 내려받아 설치한다. 진행 이벤트를 흘리고 완료/실패 이벤트로 끝난다.
  Stream<DownloadEvent> download({required int maxBytes});
}

class CheckModelPackUseCase {
  const CheckModelPackUseCase(this._repository);

  final ModelPackRepository _repository;

  Future<bool> call() => _repository.isInstalled();
}

class DownloadModelPackUseCase {
  const DownloadModelPackUseCase(this._repository, {required this.maxBytes});

  final ModelPackRepository _repository;
  final int maxBytes;

  Stream<DownloadEvent> call() => _repository.download(maxBytes: maxBytes);
}
