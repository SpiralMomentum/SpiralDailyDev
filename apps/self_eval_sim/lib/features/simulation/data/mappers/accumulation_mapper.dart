import '../../domain/entities/accumulation.dart';

/// 누적 기록 <-> 저장 JSON. 저장 형식은 선택 원본 로그다 (명세 1절).
abstract final class AccumulationMapper {
  static const schemaVersion = 1;

  static Map<String, dynamic> toJson(AccumulationState s) => {
        'schema': schemaVersion,
        'gauge': s.gaugePermille,
        'attempts': [for (final a in s.attempts) _attemptToJson(a)],
        'manifestations': [for (final m in s.manifestations) _manifestToJson(m)],
      };

  static AccumulationState fromJson(Map<String, dynamic>? json) {
    if (json == null) return AccumulationState.empty;
    return AccumulationState(
      gaugePermille: json['gauge'] as int,
      attempts: [
        for (final a in json['attempts'] as List) _attemptFromJson(a as Map<String, dynamic>),
      ],
      manifestations: [
        for (final m in json['manifestations'] as List)
          _manifestFromJson(m as Map<String, dynamic>),
      ],
    );
  }

  static Map<String, dynamic> _attemptToJson(AttemptRecord a) => {
        'i': a.index,
        'ch': a.channelId,
        'at': a.at.toUtc().toIso8601String(),
        'ar': a.archetype,
        'ans': [
          for (final x in a.answers) {'q': x.questionId, 'c': x.choiceId},
        ],
      };

  static AttemptRecord _attemptFromJson(Map<String, dynamic> j) => AttemptRecord(
        index: j['i'] as int,
        channelId: j['ch'] as String,
        at: DateTime.parse(j['at'] as String),
        archetype: j['ar'] as int,
        answers: [
          for (final x in j['ans'] as List)
            Answer(
              questionId: (x as Map<String, dynamic>)['q'] as String,
              choiceId: x['c'] as String,
            ),
        ],
      );

  static Map<String, dynamic> _manifestToJson(ManifestationRecord m) => {
        'i': m.attemptIndex,
        'form': m.form.name,
        'mat': [
          for (final r in m.materials)
            {
              'k': r.kind.name,
              's': r.sourceIndex,
              'ch': r.channelId,
              'q': r.questionId,
              'c': r.choiceId,
            },
        ],
      };

  static ManifestationRecord _manifestFromJson(Map<String, dynamic> j) =>
      ManifestationRecord(
        attemptIndex: j['i'] as int,
        form: ManifestationForm.values.byName(j['form'] as String),
        materials: [
          for (final r in j['mat'] as List)
            MaterialRef(
              kind: MaterialKind.values.byName((r as Map<String, dynamic>)['k'] as String),
              sourceIndex: r['s'] as int,
              channelId: r['ch'] as String,
              questionId: r['q'] as String,
              choiceId: r['c'] as String,
            ),
        ],
      );
}
