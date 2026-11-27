import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

import '../../balance/domain/profile.dart';
import '../domain/life_table.dart';

const _ageCount = 101;

class CountryInfo extends Equatable {
  const CountryInfo({
    required this.code,
    required this.name,
    required this.sourceName,
    required this.sourceYear,
  });

  final String code;
  final String name;
  final String sourceName;
  final int sourceYear;

  @override
  List<Object?> get props => [code, name, sourceName, sourceYear];
}

class JsonLifeTable implements LifeTable {
  JsonLifeTable._(this._male, this._female, this.countries);

  final Map<String, List<double>> _male;
  final Map<String, List<double>> _female;
  final List<CountryInfo> countries;

  @override
  List<String> get countryCodes => _male.keys.toList(growable: false);

  @override
  double remainingYears({
    required String countryCode,
    required Sex sex,
    required int age,
  }) {
    final series = (sex == Sex.male ? _male : _female)[countryCode];
    if (series == null) {
      throw ArgumentError.value(countryCode, 'countryCode', 'unknown country');
    }
    return series[age.clamp(0, _ageCount - 1)];
  }
}

Result<JsonLifeTable> parseLifeTable(String json) => guard(
  action: () => _parse(json),
  onError: (e, st) =>
      ParsingFailure(message: 'life table: $e', cause: e, stackTrace: st),
);

JsonLifeTable _parse(String json) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final countries = root['countries'] as Map<String, dynamic>;
  if (countries.isEmpty) throw const FormatException('no countries');
  final male = <String, List<double>>{};
  final female = <String, List<double>>{};
  final infos = <CountryInfo>[];
  for (final entry in countries.entries) {
    final c = entry.value as Map<String, dynamic>;
    final source = c['source'] as Map<String, dynamic>;
    male[entry.key] = _series(entry.key, 'male', c['male']);
    female[entry.key] = _series(entry.key, 'female', c['female']);
    infos.add(
      CountryInfo(
        code: entry.key,
        name: c['name'] as String,
        sourceName: source['name'] as String,
        sourceYear: source['year'] as int,
      ),
    );
  }
  return JsonLifeTable._(male, female, List.unmodifiable(infos));
}

List<double> _series(String code, String label, Object? raw) {
  final list = (raw as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList();
  if (list.length != _ageCount) {
    throw FormatException(
      '$code.$label length ${list.length}, expected $_ageCount',
    );
  }
  return List.unmodifiable(list);
}
