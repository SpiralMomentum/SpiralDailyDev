import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info_list.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo/memo_repository.dart';

class MemoUsecase {
  late final MemoRepository _memoRepository;

  MemoUsecase({required MemoRepository memoRepository}) {
    _memoRepository = memoRepository;
  }

  Future<MemoInfoList> get getAllMemoInfo => _memoRepository.getAllMemoInfo;

  Future<MemoInfo?> getMemoById(int memoId) =>
      _memoRepository.getMemoInfoById(memoId);

  Future<bool> addMemo({
    required String title,
    required String content,
  }) =>
      _memoRepository.addMemo(title: title, content: content);

  Future<MemoInfo?> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  }) =>
      _memoRepository.modifyMemo(
        memoId: memoId,
        title: title,
        content: content,
        madeDateTime: madeDateTime,
      );

  Future<bool> deleteMemo(int memoId) => _memoRepository.deleteMemo(memoId);
}
