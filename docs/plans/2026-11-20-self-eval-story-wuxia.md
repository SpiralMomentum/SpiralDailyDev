# 무협 이야기형 누적 시행 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 무협 채널을 "인물을 만나며 관계와 판단이 이어지는 이야기"로 바꾼다. 같은 인물은 나를 기억하고, 인물마다 다른 성격 이론으로 나를 판단하며, 만남이 쌓이면 인물이 열리고 사건이 일어난다.

**Architecture:** 기존 `simulation` 기능 안에 이야기 영역(`domain/story/`, `data/story/`)을 더한다. 규칙은 전부 순수 함수(정책)이고, 상태는 저장된 만남 기록에서 파생한다. 화면은 지금의 문항 화면과 미연시 결과 화면을 그대로 쓰고, `AttemptBloc` 이 "흐름(AttemptFlow)" 인터페이스를 통해 기존 채널 흐름과 이야기 흐름을 같은 방식으로 돌린다.

**Tech Stack:** Flutter 3.41.2, Dart 3.11, flutter_bloc, get_it, equatable, mocktail, flutter_gemma (Gemma 4 E2B, 온디바이스)

**Spec:** `doc/self-eval-sim-story-design.md` (반드시 함께 읽는다). 이론 근거: `doc/self-eval-sim-research/personality_theories_A.md`, `personality_theories_B.md`. 문체 규칙: `doc/self-eval-sim-implementation-decisions.md` 2.6절.

**Working Directory:** `/Users/gyubinhwang/AndroidStudioProjects/spiral_dev/.worktrees/self-eval-sim/apps/self_eval_sim/`

**Test / Analyze:** `flutter test`, `flutter analyze` (작업 디렉터리에서). 각 Task 끝에 둘 다 통과(분석 0건)해야 한다.

## Global Constraints

- 한국어만 운영한다 (`SupportedLanguages.codes == ['ko']`). 이야기 문장은 `ko` 하나만 쓴다.
- 이모지 금지. 코드 주석과 문서는 한국어.
- 함수형: 정책은 `abstract final class` 의 static 순수 함수, 엔티티는 불변 `Equatable`, 부수효과는 유스케이스와 Data 계층에만.
- 레이어 규칙: `/Users/gyubinhwang/AndroidStudioProjects/spiral_dev/doc/Coding/Architecture/*.md`, `View/bloc_guideline.md`. Domain 은 Flutter/IO 를 import 하지 않는다. 실패는 `utils` 패키지의 `Result`/`Failure`.
- 테스트 대체 구현은 mocktail 또는 손으로 쓴 fake (build_runner 금지).
- 화면에 이론 이름, 이론 코드(예: INTJ, `E+`), 관계 종류, 친밀도를 절대 표시하지 않는다.
- 주인공 호칭은 성별 없이 '너'. 성별 전제 표현(그녀, 소저, 소협, 형님, 누이, 오라버니)은 이야기 금지 표현에 넣는다.
- 질문과 선택지는 미리 쓴 조각으로 만든다. 모델은 결과 대사만 만든다.
- 커밋과 푸시는 사용자가 요청할 때만 한다. 계획의 "체크포인트" 단계는 테스트/분석 통과 확인이며 커밋하지 않는다. `doc/` 는 gitignore 대상이라 커밋 시 `git add -f`.
- 수치 기본값 (시뮬레이션으로 조정, 상수 한 곳에 둠): 소문 가중치 `0.5`, 판단 전환 문턱 `2.0`, 같은 상황 틀 간격 `2` 만남, 한 만남 질문 수 `4`, 관계 종류 `friend, lover, enemy, rival` 균등 무작위.

## Review Focus

1. 기존 무협 시행 기록이 있는 사용자가 이야기를 처음 열 때: 이야기는 빈 상태(첫 만남 = 객잔 주인)로 시작하고, 기존 기록은 발현 재료로 남아야 한다. -> Task 7 테스트 `기존 무협 시행 기록은 이야기 기록에 섞이지 않는다`.
2. 한 인물이 쓸 수 있는 (틀, 변주) 조합을 다 쓴 뒤에도 만남이 계속될 때: 질문 4개가 나와야 하고, 같은 조합은 가장 오래전 것부터 연결 문장과 함께 재사용한다. 오류나 빈 문항이 되면 안 된다. -> Task 5 테스트 `조합을 다 쓰면 가장 오래된 조합을 연결 문장과 함께 다시 쓴다`.
3. 결과 생성 중 앱 종료: 만남 기록은 생성 전에 저장되어야 한다 (지금 시행과 같은 원칙). -> Task 7 테스트 `판단과 만남 기록은 대사 생성 전에 저장된다`.
4. 설정의 기록 전체 삭제: 이야기 기록도 지워져야 한다. -> Task 6 테스트 `기록 전체 삭제는 이야기 기록도 지운다`.
5. 이야기 저장 파일이 깨졌을 때: 앱이 멈추지 않고 화면에 오류 문구가 나와야 한다 (`ParsingFailure`). -> Task 6 테스트 `깨진 이야기 파일은 ParsingFailure`.

---

## 파일 구조

| 파일 | 책임 |
| --- | --- |
| `lib/features/simulation/domain/policies/accumulation_step.dart` (신규) | 시행 하나를 누적 상태에 더하고 발현을 굴리는 순수 함수 (PlanAttemptUseCase 에서 추출) |
| `lib/features/simulation/domain/story/story_world.dart` | 세계 정의 엔티티: 인물, 이론, 상황 틀, 변주, 사건, 안면 관계 |
| `lib/features/simulation/domain/story/story_record.dart` | 저장 엔티티: 만남 기록, 답, 관계 enum |
| `lib/features/simulation/domain/story/story_ledger.dart` | 만남 기록에서 파생한 상태 (인물별 만남, 관계, 쓴 조합, 판단, 세계 상태) |
| `lib/features/simulation/domain/story/story_judge.dart` | 가중 투표, 극 별칭, 이력 현상, 확신/의외 판정 |
| `lib/features/simulation/domain/story/story_director.dart` | 해금, 사건, 오늘 만날 인물 고르기 |
| `lib/features/simulation/domain/story/frame_picker.dart` | 상황 틀과 변주 고르기, 반복 규칙 |
| `lib/features/simulation/domain/story/story_text.dart` | 이야기 문장 키 규칙 (TextBook 위의 확장) |
| `lib/features/simulation/domain/story/story_composer.dart` | 질문 문장, 도입 문장, 결과 장면, 모델 요청 조립 |
| `lib/features/simulation/domain/story/story_repository.dart` | 이야기 기록 저장소 인터페이스 |
| `lib/features/simulation/domain/story/story_use_cases.dart` | 만남 시작, 계획(판단+저장), 결과 생성 |
| `lib/features/simulation/data/story/story_world_mapper.dart` | `world.json` -> StoryWorld |
| `lib/features/simulation/data/story/story_record_mapper.dart` | 만남 기록 <-> JSON |
| `lib/features/simulation/data/story/story_repository_impl.dart` | 파일 저장 (`story_wuxia.json`) |
| `lib/features/simulation/presentation/flow/attempt_flow.dart` | 흐름 인터페이스와 화면용 문항 모델, 채널 흐름 구현 |
| `lib/features/simulation/presentation/flow/story_flow.dart` | 이야기 흐름 구현 |
| `assets/story/wuxia/world.json` | 세계 구조 (태그, 해금, 사건) |
| `assets/story/wuxia/ko.json` | 이야기 문장 (키는 `story.wuxia.*`, `theory.*`) |
| `integration_test/story_report_test.dart` | 실기 이야기 시뮬레이션 리포트 |

---

### Task 1: 누적 단계 추출

PlanAttemptUseCase 의 "시행 기록 추가 + 발현 판정 + 게이지 갱신"을 순수 함수로 뺀다. 이야기 계획도 같은 게이지와 발현을 쓰기 위해서다. 동작은 바뀌지 않는다.

**Files:**
- Create: `lib/features/simulation/domain/policies/accumulation_step.dart`
- Modify: `lib/features/simulation/domain/usecases/plan_attempt_use_case.dart`
- Test: `test/features/simulation/domain/accumulation_step_test.dart`

**Interfaces:**
- Produces:
  - `typedef AccumulationAdvance = ({AccumulationState next, ManifestationRecord? manifestation});`
  - `AccumulationStep.advance(AccumulationState state, AttemptRecord attempt, {required List<Theory> theories, required Random random}) -> AccumulationAdvance`
    - `state.attempts` 에 `attempt` 추가, 게이지 굴림(`ManifestationGauge.roll`), 재료 선택(`MaterialSelector.select`), 발현 형태 무작위, 발현 이론은 `TheoryPicker.pick(theories, random, avoid: attempt.theoryId)`. 난수 소비 순서는 지금 `_manifest` 와 같게 유지한다 (기존 시뮬레이션 재현성).

- [ ] **Step 1: 테스트 작성** `accumulation_step_test.dart`
  - `게이지 1000 이고 과거 기록이 있으면 발현이 생기고 게이지가 초기화된다`: `advance(...).manifestation != null`, `next.gaugePermille` 가 `ManifestationGauge.next(1000, manifested: true, ...)` 결과와 같음.
  - `게이지 0 이면 발현 없음, 시행은 추가된다`: `next.attempts.last == attempt`, `manifestation == null`.
  - `같은 시드면 PlanAttemptUseCase 와 같은 결과`: 기존 `use_cases_test.dart` 의 발현 케이스와 같은 입력/시드로 같은 `ManifestationRecord`.
- [ ] **Step 2: 실패 확인** `flutter test test/features/simulation/domain/accumulation_step_test.dart` -> 컴파일 실패.
- [ ] **Step 3: 구현** `accumulation_step.dart` 에 `AccumulationStep.advance`. `PlanAttemptUseCase.call` 은 이 함수를 쓰도록 바꾸고 `_manifest` 를 지운다.
- [ ] **Step 4: 통과 확인** `flutter test` 전체 통과 (기존 141개 포함), `flutter analyze` 0건.

---

### Task 2: 이야기 세계 엔티티와 로더

**Files:**
- Create: `lib/features/simulation/domain/story/story_world.dart`
- Create: `lib/features/simulation/domain/story/story_record.dart`
- Create: `lib/features/simulation/data/story/story_world_mapper.dart`
- Modify: `lib/features/simulation/domain/entities/catalog.dart` (Theory 확장)
- Modify: `lib/features/simulation/data/mappers/catalog_mapper.dart` (Theory 파싱 공유)
- Test: `test/features/simulation/data/story_world_mapper_test.dart`, `test/support/story_fixtures.dart`

**Interfaces:**
- Produces (Theory 확장, 기존 생성자 호출은 그대로 컴파일되어야 함):
  - `Theory({required String id, required TheoryMode mode, required List<List<String>> axes, String? measures, Map<String, String> poleAlias = const {}, Map<String, String> outcomeAlias = const {}})`
    - `measures`: 태그를 읽어 올 이론 id (없으면 자기 id). 예: 관상가의 `type16` 은 `measures: 'bigfive'`.
    - `poleAlias`: 읽어 온 극을 이 이론의 극으로 바꾼다. 예: `{'E+':'E','E-':'I','O+':'N','O-':'S','A+':'F','A-':'T','C+':'J','C-':'P'}`.
    - `outcomeAlias`: 계산된 유형을 이름 키로 바꾼다. 예: 의원 `temperament` 는 axes `[['E+','E-'],['N+','N-']]`, code 모드, `{'E+N-':'sanguine','E+N+':'choleric','E-N+':'melancholic','E-N-':'phlegmatic'}`.
    - `String get tagSource => measures ?? id;`
  - `story_world.dart`:
    - `enum Relationship { friend, lover, enemy, rival }`
    - `StoryCharacter({required String id, required String theoryId, required int unlockAt, Map<String, int> requires = const {}})` — `unlockAt`: 전체 만남 수 하한, `requires`: 인물 id -> 최소 만남 수.
    - `FrameChoice({required String id, required Map<String, List<String>> traits})` — 키는 이론 id(태그 원천).
    - `StoryFrame({required String id, required List<FrameChoice> choices, required List<String> axes, Set<String> requiresStatus = const {}, Set<String> forbidsStatus = const {}})` — `axes`: 이 틀이 쓰는 변주 축 이름(예: `['who','where']`).
    - `StoryEvent({required String id, required String characterId, int minMeetings = 0, Map<String, int> met = const {}, Set<String> requiresStatus = const {}, String? grantsStatus, List<(String, String)> reveals = const []})` — 그 인물이 등장하는 만남에서, 조건을 채웠고 아직 안 일어났으면 일어난다. `reveals`: 새로 생기는 안면 관계.
    - `StoryWorld({required String id, required List<StoryCharacter> characters, required List<Theory> theories, required List<StoryFrame> frames, required Map<String, List<String>> variants, required List<StoryEvent> events, required List<(String, String)> links})` — `variants`: 축 이름 -> 변주 id 목록. 조회 함수 `characterById`, `theoryById`, `frameById`.
  - `story_record.dart`:
    - `StoryAnswer({required String frameId, required Map<String, String> variant, required String choiceId})` — `String get comboKey` = 틀 id + 축 이름순 변주 id 를 `|` 로 이은 것.
    - `StoryMeeting({required int number, required String characterId, required Relationship relationship, required List<StoryAnswer> answers, required String outcome, required DateTime at, String? eventId})` — `number` 는 1부터.
  - `StoryWorldMapper.fromJson(Map<String, dynamic>) -> StoryWorld`. 이론 파싱은 `CatalogMapper` 의 이론 파싱 함수를 공개(`CatalogMapper.theory(Map)`)해 공유한다.
  - `test/support/story_fixtures.dart`: 작은 세계 `miniWorld` (인물 3: `innkeeper`(bigfive, unlockAt 0), `smith`(holland, unlockAt 2), `hermit`(values, unlockAt 4, requires {innkeeper: 3}); 틀 6개; 변주 축 `who`(3), `where`(3); 사건 1: `old_friends` (hermit, met {innkeeper:3}, reveals [(innkeeper, hermit)]); links [(innkeeper, smith)]) 와 그 JSON. 이후 Task 들의 테스트가 쓴다.

- [ ] **Step 1: 테스트 작성** `story_world_mapper_test.dart`
  - `world.json 형식을 읽는다`: `miniWorldJson` -> `miniWorld` 와 같음 (Equatable).
  - `measures/poleAlias/outcomeAlias 를 읽고 tagSource 는 measures`: type16 이론 `tagSource == 'bigfive'`.
  - `기존 structure.json 이론은 그대로 읽힌다`: 실제 `assets/content/structure.json` 의 이론 4개 `measures == null`.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현** 엔티티와 매퍼. JSON 키는 매퍼 테스트의 `miniWorldJson` 이 정의한다 (짧은 영문 키, 예: `chars`, `theories`, `frames`, `variants`, `events`, `links`).
- [ ] **Step 4: 통과 확인** 전체 테스트, 분석.

---

### Task 3: 판단 (StoryJudge)

**Files:**
- Create: `lib/features/simulation/domain/story/story_judge.dart`
- Test: `test/features/simulation/domain/story/story_judge_test.dart`

**Interfaces:**
- Consumes: `Theory` (Task 2), `TheoryMode`.
- Produces:
  - `enum JudgmentTone { first, confirmed, surprised }`
  - `typedef WeightedVote = ({List<String> poles, double weight});`
  - `Judgment({required String outcome, required JudgmentTone tone, required Map<String, double> tally})`
  - `StoryJudge.poles(Theory theory, FrameChoice choice) -> List<String>`: `choice.traits[theory.tagSource]` 를 `poleAlias` 로 바꾼 것 (별칭 없는 극은 그대로).
  - `StoryJudge.score(Theory theory, List<WeightedVote> votes) -> ({String outcome, Map<String, double> tally})`: 지금 `PersonalityScorer.score` 와 같은 규칙(dominant: 순점수 최대, 동률은 먼저 드러난 극 / code: 축마다 큰 쪽, 동률은 나중 극, 미등장 축은 첫 극)을 가중치(double)로. 결과에 `outcomeAlias` 적용.
  - `StoryJudge.judge(Theory theory, {required List<WeightedVote> history, required List<WeightedVote> current, String? previous, double switchMargin = StoryRules.switchMargin}) -> Judgment`
    - 누적 = history + current 로 계산한 후보 유형.
    - `previous == null` -> 후보, tone first.
    - 이력 현상: dominant 는 (후보의 순점수 - previous 의 순점수) >= switchMargin 일 때만 후보로 바꾸고 아니면 previous 유지. code 는 축마다 (이긴 극 - 진 극) >= switchMargin 일 때만 previous 의 그 축 글자를 바꾼다. outcomeAlias 가 있으면 별칭 전 코드로 비교한다 (previous 를 역별칭).
    - tone: current 만으로 계산한 유형이 최종 유형과 같으면 confirmed, 다르면 surprised.
  - `StoryRules` 상수: `rumorWeight = 0.5`, `switchMargin = 2.0`, `frameGap = 2`, `questionsPerMeeting = 4`.

- [ ] **Step 1: 테스트 작성** `story_judge_test.dart` (이론은 테스트 안에서 직접 생성)
  - `첫 판단은 first 이고 누적 최다 극`: bigfive, current = [C+ x3, E+ x1] -> outcome `C+`, tone first.
  - `같은 쪽 답이면 confirmed`: previous `C+`, history [C+ x3], current [C+ x2, O+ x2] -> `C+`, confirmed.
  - `근거가 문턱만큼 쌓이지 않으면 판단을 유지하고 surprised`: previous `C+`, history [C+ x4], current [C- x4] -> 순점수 C+ 0, C- 0, 차이 0 < 2 -> `C+`, tone surprised.
  - `근거가 문턱 이상 쌓이면 판단이 바뀐다`: previous `C+`, history [C+ x1], current [C- x4] -> C- 순점수 3, C+ 순점수 -3, 차이 6 >= 2 -> `C-`, tone confirmed.
  - `소문 가중치 0.5 가 반영된다`: history 에 weight 0.5 표 [O+ x3] (=1.5), current [E+ x1] -> 첫 판단 `O+`.
  - `16상은 빅파이브 태그를 별칭으로 읽어 네 글자 유형`: theory `type16`(measures bigfive, poleAlias 위 예시, code, axes [[E,I],[S,N],[T,F],[J,P]]) 와 choice traits `{'bigfive': ['E+','O+']}` -> `poles == ['E','N']`; votes [E,N,F,J] -> `ENFJ`.
  - `4체질은 E x N 코드를 기질 이름으로`: votes [E+, N-] -> `sanguine`; previous `sanguine`, current [E-, N+] (history 없음, margin 2) -> 축마다 차이 0 -> `sanguine` 유지, surprised.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인**

---

### Task 4: 파생 상태와 진행 (StoryLedger, StoryDirector)

**Files:**
- Create: `lib/features/simulation/domain/story/story_ledger.dart`
- Create: `lib/features/simulation/domain/story/story_director.dart`
- Test: `test/features/simulation/domain/story/story_director_test.dart`

**Interfaces:**
- Consumes: Task 2 엔티티, Task 3 `StoryJudge`, `StoryRules`.
- Produces:
  - `StoryLedger.of(StoryWorld world, List<StoryMeeting> meetings)` (불변 값 객체, 생성 시 한 번 계산):
    - `int get total` (만남 수), `int metCount(String characterId)`, `Relationship? relationship(String characterId)` (첫 만남의 관계), `String? lastOutcome(String characterId)`, `int? lastMetAt(String characterId)` (마지막 만남 번호).
    - `Set<String> get status` (일어난 사건의 grantsStatus), `Set<String> get firedEvents`, `Set<(String, String)> get links` (기본 + 공개된 것, 순서 무관 비교).
    - `bool acquainted(String a, String b)`, `List<String> acquaintancesOf(String characterId)` (만난 적 있는 아는 인물만).
    - `List<StoryAnswer> answersTo(String characterId)` (시간 순), `List<StoryAnswer> rumorsAbout(String characterId)` (아는 인물에게 한 답, 시간 순).
    - `List<String> recentFrames(int gap)` (최근 gap 만남에 나온 틀 id).
  - `StoryDirector.unlocked(StoryWorld, StoryLedger) -> List<StoryCharacter>`: `ledger.total >= unlockAt` 이고 `requires` 충족. 세계 정의 순서 유지.
  - `StoryDirector.pendingEvent(StoryWorld, StoryLedger, String characterId) -> StoryEvent?`: 그 인물의 사건 중 조건(`minMeetings <= total`, `met`, `requiresStatus`) 충족하고 아직 안 일어난 첫 사건.
  - `StoryDirector.nextCharacter(StoryWorld, StoryLedger, Random) -> StoryCharacter`, 우선순위:
    1. 사건이 걸린(pendingEvent != null) 열린 인물 중 세계 순서 첫 인물.
    2. 열렸지만 아직 못 만난 인물 중 세계 순서 첫 인물.
    3. 열린 인물 중 직전 만남 인물을 뺀 후보(후보가 하나뿐이면 포함)에서, 가중치 = (total - lastMetAt) 로 무작위.
  - `StoryDirector.relationshipFor(StoryLedger, String characterId, Random) -> Relationship`: 만난 적 있으면 기록된 관계, 없으면 `Relationship.values` 균등 무작위.

- [ ] **Step 1: 테스트 작성** `story_director_test.dart` (`miniWorld` 사용, 만남 기록은 헬퍼로 생성)
  - `첫 만남은 객잔 주인`: 빈 기록 -> innkeeper.
  - `만남 2번 뒤 대장장이가 열리고 아직 못 만났으니 먼저 나온다`.
  - `은거기인은 만남 4번이어도 객잔 주인 3번 전에는 안 열린다`.
  - `사건 조건을 채운 인물이 먼저 나오고, 사건은 한 번만 일어난다`: innkeeper 3회 + 총 4회 -> hermit, pendingEvent `old_friends`; 그 만남에 eventId 를 기록한 ledger 에서는 pendingEvent null, links 에 (innkeeper, hermit) 포함.
  - `직전 인물은 연달아 나오지 않는다 (후보가 둘 이상일 때)`: 같은 시드 100회 반복에서 직전 인물 재등장 0.
  - `관계는 첫 만남에 정하고 유지한다`: 기록된 관계가 있으면 Random 과 무관하게 같은 값.
  - `rumorsAbout 은 아는 사이 인물에게 한 답만`: smith 의 rumors 는 innkeeper 에게 한 답, hermit 의 rumors 는 사건 전엔 빈 목록.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인**

---

### Task 5: 질문 고르기 (FramePicker)

**Files:**
- Create: `lib/features/simulation/domain/story/frame_picker.dart`
- Test: `test/features/simulation/domain/story/frame_picker_test.dart`

**Interfaces:**
- Consumes: Task 2, Task 4 `StoryLedger`.
- Produces:
  - `PickedFrame({required StoryFrame frame, required Map<String, String> variant, String? recallChoiceId})` — `recallChoiceId`: 이 인물이 이 틀에서 지난번 고른 선택지 (재등장일 때만).
  - `FramePicker.pick(StoryWorld world, StoryLedger ledger, StoryCharacter character, Random random, {int count = StoryRules.questionsPerMeeting, int gap = StoryRules.frameGap}) -> List<PickedFrame>`
    규칙 (순서대로 적용, 결과는 서로 다른 틀 `count` 개):
    1. 후보 틀: 이 인물 이론의 `tagSource` 태그가 선택지 중 하나 이상에 있고, `requiresStatus ⊆ ledger.status`, `forbidsStatus ∩ status = ∅`.
    2. 이 인물에게 아직 안 쓴 틀을 먼저, 그다음 쓴 틀. 각 묶음 안에서 `recentFrames(gap)` 에 든 틀은 뒤로 미룬다. 같은 순위 안에서는 무작위.
    3. 변주: 틀의 축마다 `world.variants[축]` 에서, 이 인물에게 쓴 적 없는 조합이 되도록 무작위로 고른다. 그런 조합이 없으면 이 인물에게 가장 오래전에 쓴 조합을 쓴다.
    4. 이 인물이 이 틀을 쓴 적이 있으면 `recallChoiceId` = 가장 최근 그 틀에서 고른 선택지.
    5. 후보 틀이 `count` 보다 적으면 있는 만큼만 돌려준다 (콘텐츠 검사 테스트가 이 상황을 막는다).

- [ ] **Step 1: 테스트 작성** `frame_picker_test.dart`
  - `인물 이론 태그가 있는 틀만, 서로 다른 4개`.
  - `안 쓴 틀이 남아 있으면 쓴 틀은 나오지 않는다`.
  - `같은 인물에게 같은 (틀, 변주) 조합은 다시 나오지 않는다`: 같은 인물 30회 연속 만남 시뮬레이션(답은 첫 선택지)에서 comboKey 중복 0 (조합 수가 충분한 픽스처).
  - `다시 나온 틀에는 지난 선택지가 recallChoiceId 로 붙는다`.
  - `최근 2만남에 다른 인물이 쓴 틀은 뒤로 밀린다`.
  - `조합을 다 쓰면 가장 오래된 조합을 연결 문장과 함께 다시 쓴다` (Review Focus 2): 틀 4개 x 변주 1개 픽스처로 2번째 만남 -> 4개 모두 반환, 모두 recallChoiceId 있음.
  - `상태 조건: martial 이 없으면 requiresStatus martial 틀은 제외`.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인**

---

### Task 6: 이야기 저장소와 기록 삭제

**Files:**
- Create: `lib/features/simulation/domain/story/story_repository.dart`
- Create: `lib/features/simulation/data/story/story_record_mapper.dart`
- Create: `lib/features/simulation/data/story/story_repository_impl.dart`
- Modify: `lib/features/simulation/domain/usecases/history_use_cases.dart` (ClearHistoryUseCase 가 이야기 기록도 지움, GetHistorySummary 의 시행 수에 이야기 만남 포함 여부는 아래 참조)
- Modify: `lib/app/di/service_locator.dart`
- Test: `test/features/simulation/data/story_repository_test.dart`, `test/features/simulation/domain/use_cases_test.dart` (삭제 케이스 추가)

**Interfaces:**
- Produces:
  - `abstract interface class StoryRepository { Future<Result<List<StoryMeeting>>> load(String worldId); Future<Result<void>> append(String worldId, StoryMeeting meeting); Future<Result<void>> clear(); }`
  - `StoryRecordMapper.toJson(List<StoryMeeting>) / fromJson(Map<String, dynamic>?)` — `schema: 1`, 시각 UTC ISO8601. 없는 파일 = 빈 목록.
  - `StoryRepositoryImpl(Future<Directory> Function() documentsDirectory)` — 파일 `story_<worldId>.json`. 실패 의미화는 `AccumulationRepositoryImpl` 과 같다 (`FormatException`/`TypeError` -> `ParsingFailure`, 그 외 `LocalStorageFailure`). 쓰기는 임시 파일에 쓴 뒤 rename (기존 data source 와 같은 방식이면 그대로 따름).
  - `ClearHistoryUseCase(AccumulationRepository, StoryRepository)`: 둘 다 지우고, 하나라도 실패하면 실패.
  - 시행 수 표시: 이야기 만남도 `AccumulationState.attempts` 에 기록되므로(Task 7) 요약 수는 바꾸지 않는다.

- [ ] **Step 1: 테스트 작성**
  - `만남을 덧붙이고 다시 읽는다` (임시 디렉터리).
  - `파일이 없으면 빈 목록`.
  - `깨진 이야기 파일은 ParsingFailure` (Review Focus 5).
  - `기록 전체 삭제는 이야기 기록도 지운다` (Review Focus 4): fake 두 저장소, clear 호출 확인.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**, DI 등록 (`StoryRepository` lazy singleton, `ClearHistoryUseCase(sl(), sl())`).
- [ ] **Step 4: 통과 확인**

---

### Task 7: 만남 유스케이스와 결과 조립

**Files:**
- Create: `lib/features/simulation/domain/story/story_text.dart`
- Create: `lib/features/simulation/domain/story/story_composer.dart`
- Create: `lib/features/simulation/domain/story/story_use_cases.dart`
- Modify: `lib/features/simulation/domain/entities/evaluation.dart` (BaseNarrationRequest 에 `context`)
- Modify: `lib/features/simulation/data/engine/prompt_builder.dart`, `assets/narration/prompts.json` (`{context}` 자리)
- Modify: `lib/features/simulation/data/repositories/content_repository_impl.dart`, `data/datasources/content_asset_data_source.dart` (이야기 세계와 문장 로드)
- Test: `test/features/simulation/domain/story/story_use_cases_test.dart`, `test/features/simulation/domain/story/story_composer_test.dart`, `test/features/simulation/data/llm_engine_test.dart` (context 케이스)

**Interfaces:**
- Consumes: Task 1~6.
- Produces:
  - 문장 키 (`StoryText`, `TextBook` 확장 메서드, 없는 키는 키 그대로 - 기존 규칙):
    - 세계: `story.<w>.name`, `story.<w>.style` (공통 말투 규칙), `story.<w>.avoid` (정규식, 성별 표현 포함)
    - 인물 `story.<w>.char.<id>.`: `name`, `place`, `art`(배경 키, 없으면 채널 art), `style`, `reveal`(`{title}`), `intro.first`, `intro.again.<relationship>`, `intro.rumor`(`{source}` = 소문 준 인물 이름), `title.<outcome>`, `saying.<outcome>`
    - 관계 말투: `story.<w>.rel.<relationship>.style`
    - 틀 (틀 id 는 `f_` 로 시작해 다른 키와 겹치지 않게 함): `story.<w>.<frameId>` (질문, `{who}` `{where}` 등 축 자리표시자), `story.<w>.<frameId>.<choiceId>` (선택지, 자리표시자 없음), `story.<w>.<frameId>.recall.<choiceId>` (재등장 연결 문장). 이 형식이면 기존 `TextBook.question/choice('story.<w>', frameId, ...)` 와 발현 재료 풀이(`ResultComposer.resolve`)가 그대로 동작한다.
    - 변주: `story.<w>.var.<axis>.<variantId>`
    - 사건: `story.<w>.event.<id>.intro`
    - 이론 프로필: 기존과 같은 `theory.<id>.<outcome>.label/desc/strength/weakness`, `theory.<id>.<pole>.label`
  - `MeetingSetup({required StoryCharacter character, required Relationship relationship, required List<PickedFrame> frames, required List<String> intro, StoryEvent? event, required int number})`
  - `QuizQuestion({required String id, required String text, required List<QuizChoice> choices})`, `QuizChoice({required String id, required String text})` — 새 파일 `lib/features/simulation/domain/entities/quiz_question.dart` (Equatable). 화면이 키 없이 그대로 그리는 풀린 문항.
  - `StoryComposer.questions(StoryWorld, TextBook, MeetingSetup) -> List<QuizQuestion>`. 질문 문장 = 재등장이면 `recall.<지난선택>` + 공백 + 변주를 채운 질문, 아니면 채운 질문. 질문 id = `comboKey`.
  - `StoryComposer.intro(StoryWorld, TextBook, StoryLedger, StoryCharacter, Relationship, StoryEvent?) -> List<String>`: 사건이 있으면 사건 도입, 그다음 첫 만남이면 (소문 준 인물이 있으면 `intro.rumor` 아니면 `intro.first`), 다시 만나면 `intro.again.<관계>`.
  - `StoryComposer.baseRequest(...) -> BaseNarrationRequest`: speaker/place 는 인물, title 은 인물 칭호, answers 는 (채운 질문, 선택지, 이 인물 이론의 성향 이름), profile 은 `typeProfile(theoryId, outcome)`, style = 세계 style + 인물 style + 관계 style, avoid = 세계 avoid, examples = 빈 목록, fallbackLines = 프로필 3줄, `context` = 아래 3~4줄:
    - 관계 한 줄 (`rel` 말투 규칙에서 첫 줄이 아니라, 고정 문장 `story.<w>.ctx.rel.<relationship>`)
    - 판단 흐름 한 줄 (`story.<w>.ctx.tone.<first|confirmed|surprised>`)
    - 지난번 근거 한 줄 (다시 만난 경우: 지난 만남 답 하나의 선택지 문장을 `story.<w>.ctx.past` 의 `{choice}` 에)
    - 소문 한 줄 (소문 근거가 있을 때: `story.<w>.ctx.rumor` 의 `{source}`)
  - `BaseNarrationRequest` 에 `final List<String> context` (기본 빈 목록, props 포함). `PromptBuilder.base` 는 `'context': r.context.join('\n')` 을 채우고, `prompts.json` ko `base` 에 `{context}` 를 "네가 이 사람에 대해 아는 것:" 아래에 둔다 (빈 값이면 그 줄만 비고 다른 동작 없음).
  - `StoryComposer.result({required StoryWorld world, required TextBook text, required MeetingPlan plan, Narration? base, ManifestationText? manifest}) -> EvaluationResult`: 장면 하나 (kind base, art, place, speaker = 인물 name), 줄 = [reveal(칭호), ...대사(모델 또는 프로필 3줄), saying.<outcome>]. 발현은 `ResultComposer.withManifestation` 재사용. `channelId = 'story.<w>'`, `archetype = 0`, `title` = 칭호.
  - 유스케이스 (`story_use_cases.dart`):
    - `StartMeetingUseCase(StoryRepository, Random).call(StoryWorld world, TextBook text) -> Future<Result<MeetingSetup>>`: 기록 로드 -> ledger -> nextCharacter -> relationshipFor -> pendingEvent -> FramePicker.pick -> intro.
    - `MeetingPlan({required MeetingSetup setup, required StoryMeeting meeting, required Judgment judgment, required AttemptPlan attemptPlan})`
    - `PlanMeetingUseCase(StoryRepository, AccumulationRepository, Random, DateTime Function() clock).call({required StoryWorld world, required MeetingSetup setup, required List<String> choiceIds}) -> Future<Result<MeetingPlan>>`:
      1. 판단: theory = 인물 이론, history = 이 인물에게 한 지난 답(가중치 1) + 아는 인물에게 한 답(가중치 `rumorWeight`), current = 이번 답, previous = `ledger.lastOutcome`.
      2. `StoryMeeting` 생성 (number = total+1, eventId = setup.event?.id).
      3. 누적: `AttemptRecord(index: state.nextAttemptIndex, channelId: 'story.<w>', answers: [Answer(questionId: frameId, choiceId) ...], archetype: 0, at, theoryId: 인물 이론 id)` 를 `AccumulationStep.advance(state, attempt, theories: catalog.theories, random)` 로 더한다. 발현 재료로 쓰일 때 선택지 문장은 `text.choice('story.<w>', frameId, choiceId)`, 세계 이름은 `text.channelName('story.<w>') == story.<w>.name` 으로 풀린다.
      4. 저장 순서: 이야기 기록 append -> 누적 save. 둘 다 대사 생성 전에 끝난다.
      5. `attemptPlan` 은 `AttemptPlan(channelId, attempt, manifestation, reading: null, deepReading: null)`.
    - `StoryComposer.manifestationRequest(StoryWorld, TextBook, MeetingPlan) -> ManifestationRequest`: speaker = 인물 이름, title = 칭호, materials = `ResultComposer.resolve` 재사용, profile/tally 없음(deepReading 이 null), style = 섞인 형태일 때 세계+인물 style, avoid = 세계 avoid.
    - `ComposeMeetingUseCase(NarrationEngine, Random).call({required StoryWorld world, required TextBook text, required MeetingPlan plan}) -> Future<EvaluationResult>`: baseRequest -> 엔진, 발현이면 manifestationRequest -> 엔진, -> `StoryComposer.result`.
  - 콘텐츠 로드: `ContentAssetDataSource.storyWorld(String worldId)` (`assets/story/<w>/world.json`), `storyStrings(String worldId, String lang)` (`assets/story/<w>/<lang>.json`). `ContentRepositoryImpl.loadText` 는 기본 문장에 이야기 문장을 합친다 (이야기 파일이 없으면 기본 문장만). `ContentRepository.loadStoryWorld(String worldId) -> Future<Result<StoryWorld>>` 추가 (캐시). `LocalizedContent` 에 `Map<String, StoryWorld> stories` 추가 (`LoadContentUseCase` 가 `'wuxia'` 를 함께 로드, 실패하면 빈 맵 - 무협은 기존 채널 흐름으로 동작).
  - 이 Task 의 테스트용 이야기 문장은 `test/support/story_fixtures.dart` 에 `miniStoryText` 로 둔다 (실제 콘텐츠는 Task 9~10).

- [ ] **Step 1: 테스트 작성**
  - `story_composer_test.dart`:
    - `질문 문장은 변주를 채우고, 재등장이면 연결 문장을 앞에 붙인다`.
    - `첫 만남에 소문 준 인물이 있으면 rumor 도입, 없으면 first, 다시 만나면 관계별 again`.
    - `사건 도입이 맨 앞에 온다`.
    - `결과 장면: 칭호를 밝히는 첫 줄, 모델 대사, 맺음 문장. 이론 이름과 유형 코드는 어느 줄에도 없다`: 줄 전체에 `theory.<id>.name` 값, outcome 문자열(`C+`, `ENFJ` 등), 관계 이름(`friend` 등과 한국어 `story.<w>.rel` 라벨) 미포함.
    - `모델 요청에 관계/판단 흐름/지난 근거/소문 context 가 실리고 style 은 세계+인물+관계 순`.
  - `story_use_cases_test.dart` (fake 저장소, fake 엔진):
    - `첫 만남: 객잔 주인, 질문 4개, 관계 정해짐`.
    - `판단과 만남 기록은 대사 생성 전에 저장된다` (Review Focus 3): PlanMeeting 후 두 저장소에 기록 존재, Compose 호출 전.
    - `같은 인물을 다시 만나면 이전 판단에서 이어진다`: 첫 만남 C+ 쪽 답 4개, 둘째 만남 C- 쪽 답 1개 + 중립 3개 -> outcome 유지, tone surprised.
    - `기존 무협 시행 기록은 이야기 기록에 섞이지 않는다` (Review Focus 1): 누적에 `channelId: 'wuxia'` 시행 5개가 있어도 첫 만남은 innkeeper, 판단 history 비어 있음; 발현 재료 후보에는 그 시행들이 남음 (`MaterialSelector.attemptPool(state.attempts)` 에 포함).
    - `모델이 실패하면 프로필 3줄로 결과를 만든다`.
  - `llm_engine_test.dart`: `context 줄이 프롬프트에 들어간다`.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인**

---

### Task 8: 화면 흐름 (AttemptFlow) 과 무협 연결

문항 화면이 TextBook 키 대신 "풀린 문장"을 받게 하고, AttemptBloc 이 흐름 인터페이스로 채널/이야기를 같은 방식으로 처리하게 한다.

**Files:**
- Create: `lib/features/simulation/presentation/flow/attempt_flow.dart`
- Create: `lib/features/simulation/presentation/flow/story_flow.dart`
- Modify: `lib/features/simulation/presentation/bloc/attempt_bloc.dart`, `attempt_state.dart`, `attempt_event.dart`
- Modify: `lib/features/simulation/presentation/widgets/quiz_view.dart`, `lib/features/simulation/presentation/attempt_page.dart`
- Modify: `lib/app/self_eval_app.dart`, `lib/app/di/service_locator.dart`
- Test: `test/features/simulation/presentation/attempt_bloc_test.dart`, `views_widget_test.dart`, `pages_widget_test.dart`, `integration_test/app_flow_test.dart`

**Interfaces:**
- Consumes: Task 7 유스케이스, `QuizQuestion`/`QuizChoice`.
- Produces:
  - `abstract interface class AttemptFlow { String get art; Future<Result<({List<String> intro, List<QuizQuestion> questions})>> start(); Future<Result<bool>> plan(List<String> choiceIds); Future<EvaluationResult> compose(); EvaluationResult extend(EvaluationResult result); }` — `plan` 은 발현 여부를 돌려준다 (광고 제안 판단용). 흐름 객체는 한 시행 동안의 상태(질문, 계획)를 들고 있는 단발성 객체다.
  - `ChannelFlow(Channel, LocalizedContent, StartAttemptUseCase, PlanAttemptUseCase, ComposeResultUseCase, ExtendResultUseCase)`: 지금 AttemptBloc 의 동작을 옮긴 것. 질문 문장은 `text.question/choice` 로 푼다. intro 는 빈 목록.
  - `StoryFlow(StoryWorld, LocalizedContent, StartMeetingUseCase, PlanMeetingUseCase, ComposeMeetingUseCase)`: extend 는 결과를 그대로 돌려준다 (이야기 확장 장면은 이번 범위 밖: 광고 보상 시 확장 장면 없음 - 문서에 기록).
  - `AttemptBloc({required AttemptFlow Function() createFlow, required AdOfferDecider decideAdOffer, required RewardedAdShower showRewardedAd})`. 상태 `AttemptState.questions` 는 `List<QuizQuestion>`, `intro: List<String>`, `answers: List<String>` (선택지 id).
  - `QuizView({required String art, required QuizQuestion question, required List<String> intro, required int current, required int total, required ValueChanged<String> onChoice})`: 첫 질문(`current == 1`)일 때만 질문 위에 intro 줄을 보여 준다 (`Key('quiz_intro')`). 질문 text 는 `question.text`, 선택지는 `choices[i].text`, 키는 기존 `question_text`, `choice_$i` 유지.
  - 앱 연결: `_openChannel` 은 `content.stories[channel.id]` 가 있으면 `StoryFlow`, 없으면 `ChannelFlow`. 홈 화면의 채널 카드는 그대로 (무협 카드가 이야기로 들어감).

- [ ] **Step 1: 테스트 수정/작성**
  - `attempt_bloc_test.dart`: 기존 시나리오를 fake `AttemptFlow` 로 옮김 (질문 -> 생성 -> 광고 제안/거절/보상 -> 결과, 중복 탭 무시, 계획 실패 시 failure). 추가: `start 의 intro 가 상태에 실린다`.
  - `views_widget_test.dart`: `첫 질문에는 도입 문장이 보이고 둘째 질문부터는 안 보인다`.
  - `pages_widget_test.dart`: `이야기가 있는 채널은 이야기 흐름으로 들어간다` (fake 흐름 팩토리로 확인).
  - `app_flow_test.dart` (통합): 무협 카드 -> 도입 문장 보임 -> 4문항 -> 결과 화면. 기존 다른 채널 흐름 테스트는 그대로 통과.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**, DI 에 `StartMeetingUseCase`, `PlanMeetingUseCase`, `ComposeMeetingUseCase` 등록.
- [ ] **Step 4: 통과 확인** `flutter test`, `flutter analyze`, 에뮬레이터에서 `flutter test integration_test/app_flow_test.dart -d emulator-5554`.

---

### Task 9: 무협 세계 콘텐츠 1 - 인물, 이론, 결과 문장

설계 문서 4절 표 그대로 인물 11명과 이론을 넣는다. 문체는 구현 결정 문서 2.6절 규칙과 무협 조사 문서(`doc/self-eval-sim-research/style_wuxia.md`)를 따르되, 2인칭은 '너'이고 인물마다 종결 어미가 다를 수 있다.

**Files:**
- Create: `assets/story/wuxia/world.json` (인물, 이론, 사건, 안면 관계, 빈 frames/variants 는 Task 10 이 채움)
- Create: `assets/story/wuxia/ko.json`
- Modify: `pubspec.yaml` (assets 에 `assets/story/wuxia/`)
- Test: `test/features/simulation/data/story_content_test.dart`

**Interfaces / 고정 값:**
- 인물 id, 이론, unlockAt, requires (설계 4절 순서, 해금 간격은 [판단] 초기값):

| id | 이름(ko) | theoryId | unlockAt | requires |
| --- | --- | --- | --- | --- |
| innkeeper | 객잔 주인 | bigfive | 0 | |
| smith | 대장장이 | holland | 2 | |
| escort | 표국 표두 | conflict | 4 | |
| physiognomist | 관상가 | type16 (measures bigfive) | 6 | |
| physician | 약방 의원 | temperament (measures bigfive, E x N) | 8 | |
| ronin | 떠돌이 낭인 | sensation | 10 | |
| strategist | 군사 | regfocus | 13 | |
| diviner | 점술가 | locus | 16 | |
| hermit | 은거기인 | values | 20 | innkeeper: 3 |
| sectleader | 정파 장문인 | honesty | 24 | hermit: 2 |
| demonlord | 천마 | moral | 30 | hermit: 3, sectleader: 1 |

- 이론 (story 세계 전용 목록, id 는 위 표):
  - `bigfive`: 기존과 같음 (dominant, 5축).
  - `holland`: dominant, axes `[['R'],['I'],['A'],['S'],['E'],['C']]`.
  - `conflict`: dominant, axes `[['compete'],['collaborate'],['compromise'],['avoid'],['accommodate']]`.
  - `type16`: code, axes `[['E','I'],['S','N'],['T','F'],['J','P']]`, measures `bigfive`, poleAlias `{E+:E,E-:I,O+:N,O-:S,A+:F,A-:T,C+:J,C-:P}`. 프로필 문장은 기존 `theory.type16.*` 를 그대로 쓴다.
  - `temperament`: code, axes `[['E+','E-'],['N+','N-']]`, measures `bigfive`, outcomeAlias 4개 (Task 3 예시). 프로필은 기존 `theory.temperament.*`.
  - `sensation`: code, axes `[['TAS+','TAS-'],['DIS+','DIS-']]` (모험 추구, 탈억제), outcome 4개.
  - `regfocus`: dominant, axes `[['promotion','prevention']]`.
  - `locus`: dominant, axes `[['internal','external']]`.
  - `values`: dominant, axes 10개 단극 `[['SD'],['ST'],['HE'],['AC'],['PO'],['SE'],['CO'],['TR'],['BE'],['UN']]`.
  - `honesty`: dominant, axes `[['H+','H-']]`.
  - `moral`: dominant, axes `[['care'],['fairness'],['loyalty'],['authority'],['sanctity']]`.
- 사건 5개 (id, 인물, 조건, 효과):
  - `old_friends`: hermit, met {innkeeper: 3}, reveals (innkeeper, hermit).
  - `martial_start`: hermit, met {hermit: 2}, grantsStatus `martial`.
  - `escort_job`: escort, minMeetings 0, grantsStatus `escort`.
  - `sect_gate`: sectleader, requiresStatus {martial}.
  - `demon_shadow`: demonlord, reveals (demonlord, hermit).
- 기본 안면 관계: (innkeeper, smith), (innkeeper, physiognomist), (physician, diviner), (escort, ronin), (strategist, sectleader).
- 문장 (ko.json): Task 7 의 키 전부. 인물마다 `intro.again.*` 4개, 결과 칭호와 맺음 문장은 그 인물 이론의 결과마다 1개 (bigfive 10, holland 6, conflict 5, type16 16, temperament 4, sensation 4, regfocus 2, locus 2, values 10, honesty 2, moral 5 = 66). 새 이론(holland, conflict, sensation, regfocus, locus, values, honesty, moral)의 `theory.<id>.<outcome>.label/desc/strength/weakness` 와 극 이름. 부정 극도 미덕으로 쓴다 (설계 7절). 근거 약한 이론의 공식 유형 이름(INTJ 등)이나 상표명은 사용자에게 보이는 문장에 넣지 않는다.
- `story.wuxia.avoid`: 기존 `wuxia.avoid` 패턴 + `그녀|소저|소협|형님|누이|오라버니|자네|그대`.

- [ ] **Step 1: 테스트 작성** `story_content_test.dart` (실제 에셋을 읽음)
  - `세계 구조: 인물 11명, 위 표의 이론/해금 값`.
  - `모든 인물의 이론이 세계 이론 목록에 있다`.
  - `인물마다 필요한 문장 키가 모두 있고 비어 있지 않다` (name, place, style, reveal, intro.first, intro.rumor, intro.again x4, 결과마다 title/saying).
  - `새 이론의 결과마다 프로필 4문장이 있다`.
  - `금지 표현 정규식이 컴파일되고, 인물 고정 문장 어디에도 금지 표현이 없다`.
  - `고정 문장에 이론 이름, 유형 코드, 관계 이름이 없다`.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 콘텐츠 작성**
- [ ] **Step 4: 통과 확인**

---

### Task 10: 무협 세계 콘텐츠 2 - 상황 틀과 변주

**Files:**
- Modify: `assets/story/wuxia/world.json` (frames, variants)
- Modify: `assets/story/wuxia/ko.json` (틀, 선택지, 연결 문장, 변주 문장)
- Test: `test/features/simulation/data/story_content_test.dart` (추가)

**고정 값:**
- 틀은 최소 40개, id 는 `f_` 로 시작. 각 틀은 선택지 3개, 선택지마다 2개 이상 이론에 태그. 태그 원천은 이론의 `tagSource` (type16/temperament 는 `bigfive` 태그로 측정됨).
- 이론별로 태그가 있는 틀 수: 최소 12개 (한 인물이 연결 문장 없이 3번 만날 수 있는 양). `martial` 이 필요한 틀은 따로 6개 이상 (무공 입문 뒤 상황).
- 변주 축: `who`, `where`, `stake` 각 5개 이상. 틀마다 축 1~3개 사용.
- 선택지 문장에는 자리표시자를 쓰지 않는다 (발현 재료 문장으로도 쓰이기 때문).
- 틀마다 선택지별 연결 문장 `recall.<choiceId>` (지난 선택을 너에게 짚는 한 문장).
- 태그 근거: 각 이론 조사 문서의 차원 정의를 따른다. 예: 감각추구 `TAS+` = 위험하지만 짜릿한 신체 활동 선택, `DIS+` = 규범을 깨는 사교적 일탈 선택.

- [ ] **Step 1: 테스트 작성**
  - `틀 40개 이상, 선택지 3개, 선택지마다 태그 2개 이상, 태그 극은 해당 이론 축에 존재`.
  - `이론(tagSource 기준)마다 태그 있는 틀 12개 이상, martial 틀 6개 이상`.
  - `질문 문장의 자리표시자는 틀의 축과 정확히 일치하고, 선택지 문장에는 자리표시자가 없다`.
  - `모든 틀/선택지/연결 문장/변주 문장 키가 있다`.
  - `이야기 금지 표현이 어떤 문장에도 없다`.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 콘텐츠 작성**
- [ ] **Step 4: 통과 확인**

---

### Task 11: 이야기 시뮬레이션과 검증 리포트

**Files:**
- Create: `test/features/simulation/domain/story/story_simulation_test.dart` (모델 없이 정책만, 실제 에셋)
- Create: `integration_test/story_report_test.dart` (실기, 모델 포함)
- Modify: `tool/sim_report.py` (이야기 리포트 지표), `doc/self-eval-sim-simulation-report.md`, `doc/self-eval-sim-implementation-decisions.md`
- 결과: `doc/self-eval-sim-simulation/report_story_v1.json`

**고정 값:**
- 가상 사용자 3명 (시드 2026): `consistent` (인물 이론 기준 같은 극을 고르는 선택을 우선), `random` (균등 무작위), `drifting` (만남 20회마다 선호 극이 바뀜).
- 만남 60회 (정책 테스트), 실기 리포트는 consistent 사용자 36회 (지금 리포트와 같은 규모).

- [ ] **Step 1: 정책 시뮬레이션 테스트 작성** `story_simulation_test.dart`
  - `60회 동안 같은 인물에게 같은 (틀, 변주) 재등장 0` (모든 사용자).
  - `같은 틀 재등장 시 연결 문장 포함 100%`.
  - `consistent 사용자의 같은 인물 판단 뒤집힘 비율 10% 이하` (만남 간 outcome 변화 / 재만남 수). 초기 목표치이며 실패하면 `switchMargin` 을 조정하고 결정 문서에 기록.
  - `60회 안에 11명 모두 열린다` (consistent 기준). 안 열리면 unlockAt 을 조정하고 기록.
  - `사건 5개가 모두 한 번씩 일어난다`.
- [ ] **Step 2: 실패 확인 후 정책/수치 조정, 통과**
- [ ] **Step 3: 실기 리포트** `integration_test/story_report_test.dart`: 지금 `simulation_report_test.dart` 와 같은 방식(모델 로드, 시드, JSON 출력)으로 consistent 사용자 36회. 레코드마다 인물, 관계, 사건, 질문 문장, 답, 판단(outcome, tone), 결과 줄, 대사 출처, 생성 시간.
  실행: `flutter test integration_test/story_report_test.dart -d emulator-5554` (모델 미러 서버가 떠 있어야 함: `python3 -I -m http.server 8765 --bind 127.0.0.1 --directory ~/.cache/self_eval_sim`).
- [ ] **Step 4: 지표 집계** `tool/sim_report.py` 에 이야기 지표: 결과 4줄 성립, 이론/코드/관계 노출 0, 금지 표현 줄 수, 종결 일치(인물 말투), 답 근거 2줄 이상, tone 별 첫 대사 반영 비율(확신/의외 표현), 생성 시간 중앙값/최대 (v12: 10.8초/17.7초 대비).
- [ ] **Step 5: 문서 갱신** 시뮬레이션 리포트에 "5회차: 무협 이야기" 절, 결정 문서에 이야기 모드 절(조정한 수치와 이유, 광고 보상 시 이야기 확장 장면 없음).
- [ ] **Step 6: 체크포인트** `flutter test`, `flutter analyze` 통과. 결과를 사용자에게 보고하고 커밋 여부를 묻는다.
