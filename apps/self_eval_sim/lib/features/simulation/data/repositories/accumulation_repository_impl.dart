import 'package:utils/utils.dart';

import '../../domain/entities/accumulation.dart';
import '../../domain/repositories/accumulation_repository.dart';
import '../datasources/accumulation_file_data_source.dart';
import '../mappers/accumulation_mapper.dart';

class AccumulationRepositoryImpl implements AccumulationRepository {
  const AccumulationRepositoryImpl(this._source);

  final AccumulationFileDataSource _source;

  static Failure _storage(Object e, StackTrace st) =>
      LocalStorageFailure(message: 'accumulation', cause: e, stackTrace: st);

  @override
  Future<Result<AccumulationState>> load() => guardAsync(
        action: () async => AccumulationMapper.fromJson(await _source.read()),
        onError: (e, st) => e is FormatException || e is TypeError
            ? ParsingFailure(message: 'accumulation', cause: e, stackTrace: st)
            : _storage(e, st),
      );

  @override
  Future<Result<void>> save(AccumulationState state) => guardAsync(
        action: () => _source.write(AccumulationMapper.toJson(state)),
        onError: _storage,
      );

  @override
  Future<Result<void>> clear() => guardAsync(action: _source.delete, onError: _storage);
}
