"""시뮬레이션 결과(report.json)를 Markdown 리포트로 바꾼다.

사용: python3 tool/sim_report.py build/simulation/report.json > out.md
순수 함수로 표/문단을 만들고, 파일 입출력은 main 에서만 한다.
"""
import json
import statistics
import sys


def percentile(values, p):
    ordered = sorted(values)
    if not ordered:
        return 0
    k = min(len(ordered) - 1, max(0, round(p / 100 * (len(ordered) - 1))))
    return ordered[k]


def manifestation_intervals(records):
    indexes = [r["index"] for r in records if r["manifested"]]
    return [b - a for a, b in zip([0] + indexes, indexes)]


def summary(report):
    rs = report["records"]
    man = [r for r in rs if r["manifested"]]
    base_ms = [r["composeMs"] for r in rs if not r["manifested"]]
    man_ms = [r["composeMs"] for r in man]
    count = lambda pred: sum(1 for r in rs if pred(r))
    rows = [
        ("모델", report["model"]),
        ("기기", report["device"]),
        ("시행 수", str(len(rs))),
        ("언어", ", ".join(report["langs"])),
        ("모델 로드 시간", f'{report["loadMs"] / 1000:.1f}초'),
        ("누적 발현 횟수", f"{len(man)}회 (시행 순번 {', '.join(str(r['index']) for r in man)})"),
        ("발현 간격", ", ".join(map(str, manifestation_intervals(rs))) or "-"),
        ("발현 형태", f"섞임 {count(lambda r: r['form'] == 'mixed')} / 별도 {count(lambda r: r['form'] == 'separate')}"),
        ("기본 대사 모델 생성 비율", f"{count(lambda r: r['baseSource'] == 'model')}/{len(rs)}"),
        ("발현 대사 모델 생성 비율", f"{sum(1 for r in man if r['manifestationSource'] == 'model')}/{len(man)}"),
        ("이론별 시행 수", theory_counts(rs, "reading")),
        ("발현 이론 (누적 유형)", theory_counts(man, "deepReading")),
        ("결과 생성 시간 (발현 없음)", fmt_ms(base_ms)),
        ("결과 생성 시간 (발현 있음)", fmt_ms(man_ms)),
    ]
    return table(["항목", "값"], rows)


def theory_counts(records, key):
    counts = {}
    for r in records:
        if r.get(key):
            name = r[key].get("id") or r[key]["theory"]
            counts[name] = counts.get(name, 0) + 1
    return ", ".join(f"{k} {v}" for k, v in sorted(counts.items(), key=lambda kv: -kv[1])) or "-"


def reading_line(reading, prefix):
    if not reading:
        return None
    tally = ", ".join(f"{k} {v}" for k, v in sorted(reading["tally"].items(), key=lambda kv: -kv[1])[:6])
    return (f"- {prefix}: **{reading['theory']} · {reading['label']}** - {reading['desc']} "
            f"(답 {reading['answers']}개, 성향 {tally})")


def fmt_ms(values):
    if not values:
        return "-"
    return (f"중앙값 {statistics.median(values) / 1000:.1f}초, "
            f"90% {percentile(values, 90) / 1000:.1f}초, 최대 {max(values) / 1000:.1f}초 (n={len(values)})")


def table(headers, rows):
    head = "| " + " | ".join(headers) + " |\n| " + " | ".join("---" for _ in headers) + " |\n"
    return head + "\n".join("| " + " | ".join(c.replace("|", "\\|") for c in row) + " |" for row in rows)


def source_label(source):
    return {"model": "모델", "template": "템플릿 대체", None: "-"}[source]


def scene_block(scene):
    badges = "".join(f" [{b}]" for b in scene.get("badges", []))
    head = f"*{scene['kind']}* · {scene['place'] or '-'} · **{scene['speaker']}**{badges}"
    return head + "\n" + "\n".join(f"> {line}" for line in scene["lines"])


def record_block(r):
    answers = " / ".join(a["c"] + (f" ({a['t']})" if a.get("t") else "") for a in r["answers"])
    tag = f" · 누적 발현({'섞임' if r['form'] == 'mixed' else '별도'})" if r["manifested"] else ""
    lines = [
        f"### {r['index']}. {r['channel']} · {r['title']}{tag}",
        f"- 언어 {r['lang']}, 발현 확률 {r['gaugeBeforePermille'] / 10:.1f}%, 생성 {r['composeMs'] / 1000:.1f}초, "
        f"기본 대사 {source_label(r['baseSource'])}, 발현 대사 {source_label(r['manifestationSource'])}",
        f"- 고른 답: {answers}",
        *filter(None, [reading_line(r.get("reading"), "이번 유형"), reading_line(r.get("deepReading"), "누적 유형")]),
    ]
    if r["materials"]:
        lines.append("- 재료: " + " / ".join(
            f"{m['ago']}번 전 {'(발현)' if m['kind'] == 'manifestation' else ''}{m['channel']} '{m['choice']}'"
            + (f" ({m['trait']})" if m.get("trait") else "")
            for m in r["materials"]))
    return "\n".join(lines) + "\n\n" + "\n\n".join(scene_block(s) for s in r["scenes"])


def render(report):
    rs = report["records"]
    single = [r for r in rs if not r["manifested"]]
    accumulated = [r for r in rs if r["manifested"]]
    return "\n\n".join([
        "## 요약", summary(report),
        "## 누적 발현 결과", *(record_block(r) for r in accumulated),
        "## 개별 시행 결과", *(record_block(r) for r in single),
    ]) + "\n"


def main(path):
    sys.stdout.write(render(json.load(open(path, encoding="utf-8"))))


if __name__ == "__main__":
    main(sys.argv[1])
