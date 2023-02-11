import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/domain/model/memo/modify_memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo/memo_repository.dart';

class MemoUsecase {
  late final MemoRepository _memoRepository;

  MemoUsecase({required MemoRepository memoRepository}){
    _memoRepository = memoRepository;
  }

  Future<List<MemoListItem>> get getMemoList => _memoRepository.getMemoList;
  Future<MemoListItem> getMemoById(int memoId) => _memoRepository.getMemoById(memoId);
  Future<AddMemoModel> addMemo(AddMemoModel memoModel) => _memoRepository.addMemo(memoModel);
  Future<ModifyMemoModel> modifyMemo(ModifyMemoModel memoModel) => _memoRepository.modifyMemo(memoModel);
  Future<bool> deleteMemo(int memoId) => _memoRepository.deleteMemo(memoId);
}