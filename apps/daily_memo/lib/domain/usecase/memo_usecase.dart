import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/domain/model/memo/modify_memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';

class MemoUsecase {
  final MemoRepository memoRepository;

  MemoUsecase(this.memoRepository);

  Future<List<MemoListItem>> get getMemoList => memoRepository.getMemoList;
  Future<MemoListItem> getMemoById(int memoId) => memoRepository.getMemoById(memoId);
  Future<AddMemoModel> addMemo(AddMemoModel memoModel) => memoRepository.addMemo(memoModel);
  Future<ModifyMemoModel> modifyMemo(ModifyMemoModel memoModel) => memoRepository.modifyMemo(memoModel);
  Future<bool> deleteMemo(int memoId) => memoRepository.deleteMemo(memoId);
}