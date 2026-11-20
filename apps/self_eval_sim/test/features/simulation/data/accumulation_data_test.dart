import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:self_eval_sim/features/simulation/data/datasources/accumulation_file_data_source.dart';
import 'package:self_eval_sim/features/simulation/data/mappers/accumulation_mapper.dart';
import 'package:self_eval_sim/features/simulation/data/repositories/accumulation_repository_impl.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:utils/utils.dart';

import '../../../support/fixtures.dart';

class _MockSource extends Mock implements AccumulationFileDataSource {}

void main() {
  final state = AccumulationState(
    attempts: [attempt(1), attempt(2, channelId: 'gem', choices: ['c3'])],
    manifestations: [
      ManifestationRecord(
        attemptIndex: 2,
        form: ManifestationForm.separate,
        materials: [ref(MaterialKind.attempt, 1, c: 'c2'), ref(MaterialKind.manifestation, 1)],
      ),
    ],
    gaugePermille: 37,
  );

  group('AccumulationMapper', () {
    test('저장 JSON 왕복 후 같은 상태', () {
      expect(AccumulationMapper.fromJson(AccumulationMapper.toJson(state)), state);
    });

    test('파일이 없으면(null) 빈 상태', () {
      expect(AccumulationMapper.fromJson(null), AccumulationState.empty);
    });

    test('저장 형식에 스키마 버전과 선택 원본이 들어간다', () {
      final json = AccumulationMapper.toJson(state);
      expect(json['schema'], 1);
      expect((json['attempts'] as List).first['ans'], [
        {'q': 'q1', 'c': 'c1'},
        {'q': 'q2', 'c': 'c2'},
      ]);
    });
  });

  group('AccumulationRepositoryImpl (DataSource mock)', () {
    late _MockSource source;
    late AccumulationRepositoryImpl repo;

    setUp(() {
      source = _MockSource();
      repo = AccumulationRepositoryImpl(source);
    });

    test('읽은 JSON 을 도메인 상태로 바꾼다', () async {
      when(() => source.read()).thenAnswer((_) async => AccumulationMapper.toJson(state));
      expect((await repo.load()).dataOrNull, state);
    });

    test('형식이 깨진 JSON 은 ParsingFailure', () async {
      when(() => source.read()).thenAnswer((_) async => {'gauge': 'x'});
      expect((await repo.load()).failureOrNull, isA<ParsingFailure>());
    });

    test('입출력 예외는 LocalStorageFailure', () async {
      when(() => source.read()).thenThrow(const FileSystemException('denied'));
      when(() => source.write(any())).thenThrow(const FileSystemException('full'));
      when(() => source.delete()).thenThrow(const FileSystemException('busy'));
      expect((await repo.load()).failureOrNull, isA<LocalStorageFailure>());
      expect((await repo.save(state)).failureOrNull, isA<LocalStorageFailure>());
      expect((await repo.clear()).failureOrNull, isA<LocalStorageFailure>());
    });
  });

  group('AccumulationFileDataSource (임시 디렉터리)', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('acc'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('쓰기, 읽기, 삭제', () async {
      final source = AccumulationFileDataSource(() async => dir);
      expect(await source.read(), isNull);
      await source.write(AccumulationMapper.toJson(state));
      expect(File('${dir.path}/accumulation.json').existsSync(), isTrue);
      expect(File('${dir.path}/accumulation.json.tmp').existsSync(), isFalse);
      expect(AccumulationMapper.fromJson(await source.read()), state);
      await source.delete();
      expect(await source.read(), isNull);
    });
  });
}
