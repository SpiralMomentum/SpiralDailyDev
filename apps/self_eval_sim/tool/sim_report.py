"""시뮬레이션 결과(report.json)를 Markdown 리포트로 바꾼다.

사용: python3 tool/sim_report.py build/simulation/report.json > out.md
이야기 리포트(integration_test/story_report_test.dart, "kind": "story")는 이야기 지표로 집계한다.
순수 함수로 표/문단을 만들고, 파일 입출력은 main 에서만 한다.
"""
import json
import os
import re
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


# ---- 이야기 리포트 (kind == "story") ----

# 화면에 나오면 안 되는 이론 이름/유형 코드/관계 이름 (자동 추정).
LEAK = re.compile(
    r"빅파이브|에니어그램|MBTI|홀랜드|슈워츠|HEXACO|감각\s?추구|조절\s?초점|통제\s?소재|도덕\s?기반|"
    r"[EI][SN][TF][JP]|\b[OCEANH][+-]|TAS[+-]|DIS[+-]|\b(friend|lover|enemy|rival)\b|연인|악연|라이벌"
)

# 인물별 기대 종결 (말끝 문장부호/따옴표를 뗀 뒤 검사). 정파 장문인만 하게체, 나머지는 반말 해라체.
HAERA = re.compile(r"(다|지|냐|군|구나|라|거든|구먼|렷다|단다|니라|로다|느냐|거라|마라|어|야|게|걸|네)$")
HAGE = re.compile(r"(네|세|게|가|는가|일세|구먼|군|지)$")
POLITE = re.compile(r"(요|니다|니까|시오|하오|이오|소)$")

TONE_WORDS = {
    "confirmed": re.compile(r"역시|여전|그대로|변함|이번에도|또다시|과연|다르지 않"),
    "surprised": re.compile(r"의외|뜻밖|달라|다르|놀랍|놀랐|웬일|몰랐|새롭"),
}

STOP = {"그냥", "바로", "먼저", "모두", "다시", "조금", "한다", "하고", "한번", "없이", "자리", "말한다"}


def strip_end(line):
    return re.sub(r"[\s.!?…~,'\"」』)]+$", "", line)


def ending_ok(character, line):
    end = strip_end(line)
    if POLITE.search(end):
        return False
    return bool((HAGE if character == "sectleader" else HAERA).search(end))


def base_scene(r):
    return next(s for s in r["scenes"] if s["kind"] == "base")


def _story_text():
    path = os.path.join(os.path.dirname(__file__), "..", "assets", "story", "wuxia", "ko.json")
    return json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {}


STORY_TEXT = _story_text()


def evidence_pattern(character):
    """인물 근거 문장 템플릿들({act})을 하나의 정규식으로. 없으면 None."""
    prefix = f"story.wuxia.char.{character}.evidence"
    ts = [v for k, v in STORY_TEXT.items() if k == prefix or k.startswith(prefix + ".")]
    if not ts:
        return None
    alts = []
    for t in ts:
        head, _, tail = t.partition("{act}")
        alts.append(re.escape(head) + ".+" + re.escape(tail))
    return re.compile("^(?:" + "|".join(alts) + ")$")


def evidence_line(r):
    """칭호 다음 줄이 코드가 만든 근거 문장이면 그 줄, 아니면 None."""
    lines = base_scene(r)["lines"]
    pat = evidence_pattern(r["character"])
    return lines[1] if pat and len(lines) > 1 and pat.match(lines[1]) else None


def model_lines(r):
    """칭호 첫 줄(과 코드 근거 줄)과 맺음 문장 사이의 모델 대사 줄. 템플릿 대체면 빈 목록.
    섞임 발현은 같은 장면 맺음 문장 뒤에 발현 줄이 붙으므로 맺음 문장 위치로 자른다."""
    if r["baseSource"] != "model":
        return []
    lines = base_scene(r)["lines"]
    saying = STORY_TEXT.get(f"story.wuxia.char.{r['character']}.saying.{r['outcome']}")
    end = lines.index(saying, 1) if saying in lines[1:] else len(lines) - 1
    start = 2 if evidence_line(r) else 1
    return lines[start:end]


def stems(choice):
    return {w[:2] for w in re.findall(r"[가-힣]+", choice) if len(w) >= 2 and w not in STOP}


def evidence_lines(r):
    ss = set().union(*(stems(a["c"]) for a in r["answers"]))
    return sum(1 for line in model_lines(r) if any(s in line for s in ss))


def banned_patterns(report):
    """세계 금지 표현 + prompts.json 의 ko 금지 패턴."""
    pats = list(report.get("avoid", []))
    path = os.path.join(os.path.dirname(__file__), "..", "assets", "narration", "prompts.json")
    if os.path.exists(path):
        pats += json.load(open(path, encoding="utf-8"))["languages"]["ko"]["banned"]
    return [re.compile(p[4:], re.I) if p.startswith("(?i)") else re.compile(p) for p in pats]


def visible_texts(r):
    return [*r["intro"], *(a["q"] for a in r["answers"]), *(a["c"] for a in r["answers"]),
            r["title"], *(line for s in r["scenes"] for line in s["lines"])]


def story_metrics(report):
    rs = report["records"]
    model = [r for r in rs if r["baseSource"] == "model"]
    lines = [(r, line) for r in model for line in model_lines(r)]
    banned = banned_patterns(report)
    leaks = [(r["index"], t) for r in rs for t in visible_texts(r) if LEAK.search(t)]
    bad = [(r["index"], line) for r in rs for s in r["scenes"] for line in s["lines"]
           if any(b.search(line) for b in banned)]
    ending = [ending_ok(r["character"], line) for r, line in lines]
    tones = {}
    for r in model:
        if r["tone"] in TONE_WORDS and model_lines(r):
            hit = bool(TONE_WORDS[r["tone"]].search(model_lines(r)[0]))
            k, n = tones.get(r["tone"], (0, 0))
            tones[r["tone"]] = (k + hit, n + 1)
    plain = [r["composeMs"] for r in rs if not r["manifested"]]
    recalls = [a for r in rs for a in r["answers"] if a.get("recall")]
    evid = [evidence_line(r) for r in rs]
    report_tone = re.compile(r"보여 ?(준|주|줘)|드러(낸|내)|^이는 |타입|스타일")
    return {
        "records": len(rs),
        "model": len(model),
        "fourLines": sum(1 for r in model if len(model_lines(r)) == 4),
        "leaks": leaks,
        "bannedLines": bad,
        "endingOk": (sum(ending), len(ending)),
        "evidence2": (sum(1 for r in model if evidence_lines(r) >= 2), len(model)),
        "codeEvidence": (sum(1 for e, r in zip(evid, rs)
                             if e and any(s in e for a in r["answers"] for s in stems(a["c"]))), len(rs)),
        "reportTone": [(r["index"], line) for r, line in lines if report_tone.search(line)],
        "modelLineCount": count_by([{"n": len(model_lines(r))} for r in model], "n"),
        "tones": tones,
        "recallQuestions": (sum(1 for a in recalls if a["q"].startswith(a["recall"])), len(recalls)),
        "plainMs": plain,
        "allMs": [r["composeMs"] for r in rs],
        "manifested": sum(1 for r in rs if r["manifested"]),
        "characters": count_by(rs, "character"),
        "toneCounts": count_by(rs, "tone"),
    }


def count_by(rs, key):
    out = {}
    for r in rs:
        out[r[key]] = out.get(r[key], 0) + 1
    return out


def ratio(pair):
    k, n = pair
    return f"{k}/{n} ({k / n:.0%})" if n else "-"


def story_summary(report):
    m = story_metrics(report)
    rows = [
        ("모델", report["model"]),
        ("기기", report["device"]),
        ("사용자", report["user"]),
        ("만남 수", str(m["records"])),
        ("모델 로드 시간", f'{report["loadMs"] / 1000:.1f}초'),
        ("기본 대사 모델 생성", f'{m["model"]}/{m["records"]}'),
        ("결과 4줄 성립 (모델 대사 4줄)", f'{m["fourLines"]}/{m["model"]}'),
        ("이론/코드/관계 노출 (도입, 질문, 선택지, 결과)", f'{len(m["leaks"])}건'),
        ("금지 표현 줄", f'{len(m["bannedLines"])}줄'),
        ("종결 일치 (인물 말투, 모델 대사 줄)", ratio(m["endingOk"])),
        ("답 근거 2줄 이상 (선택지 어간 일치, 자동 추정)", ratio(m["evidence2"])),
        ("코드 근거 줄이 고른 답을 짚음", ratio(m["codeEvidence"])),
        ("모델 대사 줄 수 분포", ", ".join(f"{k}줄 {v}" for k, v in sorted(m["modelLineCount"].items()))),
        ("보고서 말투/외래어 줄 (모델 대사)", f'{len(m["reportTone"])}줄'),
        *[(f"첫 대사 tone 반영 ({t})", ratio(m["tones"][t])) for t in sorted(m["tones"])],
        ("tone 분포", ", ".join(f"{k} {v}" for k, v in sorted(m["toneCounts"].items()))),
        ("재등장 틀 질문의 연결 문장", ratio(m["recallQuestions"])),
        ("누적 발현", f'{m["manifested"]}회'),
        ("인물별 만남", ", ".join(f"{k} {v}" for k, v in m["characters"].items())),
        ("결과 생성 시간 (발현 없음)", fmt_ms(m["plainMs"])),
        ("결과 생성 시간 (전체)", fmt_ms(m["allMs"])),
    ]
    detail = []
    if m["leaks"]:
        detail.append("노출 의심: " + "; ".join(f"#{i} {t}" for i, t in m["leaks"]))
    if m["bannedLines"]:
        detail.append("금지 표현 줄: " + "; ".join(f"#{i} {t}" for i, t in m["bannedLines"]))
    return table(["항목", "값"], rows) + ("\n\n" + "\n\n".join(detail) if detail else "")


def story_block(r):
    head = (f"### {r['index']}. {r['speaker']} · {r['title']}"
            + (f" · 사건 {r['event']}" if r.get("event") else ""))
    meta = (f"- 관계 {r['relationship']}, 판단 {r['outcome']} ({r['tone']}), 생성 {r['composeMs'] / 1000:.1f}초, "
            f"기본 대사 {source_label(r['baseSource'])}"
            + (f", 누적 발현({r['form']}) {source_label(r['manifestationSource'])}" if r["manifested"] else ""))
    intro = "\n".join(f"> {line}" for line in r["intro"])
    qs = "\n".join(f"{j + 1}. {a['q']} → **{a['c']}**" + (f" ({a['t']})" if a.get("t") else "")
                   for j, a in enumerate(r["answers"]))
    ctx = "- 모델 맥락: " + " / ".join(r["context"])
    return "\n".join([head, meta, ctx, "", intro, "", qs, ""]) + "\n" + "\n\n".join(
        scene_block(s) for s in r["scenes"])


def render_story(report):
    return "\n\n".join(["## 요약", story_summary(report), "## 만남별 결과",
                        *(story_block(r) for r in report["records"])]) + "\n"


def main(path):
    report = json.load(open(path, encoding="utf-8"))
    sys.stdout.write(render_story(report) if report.get("kind") == "story" else render(report))


if __name__ == "__main__":
    main(sys.argv[1])
