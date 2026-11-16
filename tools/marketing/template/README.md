# 템플릿 렌더러

`doc/00_마케팅/01_소재_디자인_리서치/07_템플릿_스펙.md`의 YAML 스키마를 읽어 스토어 스크린샷·소셜 이미지를 만든다.
프리셋 한 개 = 채널 한 개의 장 세트이며, 값은 전부 리서치 카탈로그의 관측값·공식 규정을 그대로 옮긴 것이다.

## 구성

| 파일 | 역할 |
|---|---|
| `__main__.py` | CLI. `render <preset.yaml>` 결과를 stdout JSON 한 줄로, 장별 PASS/FAIL 은 stderr |
| `render.py` | 프리셋 로드 -> 장별 렌더(레이어 reduce) -> 저장(JPEG 용량 상한 맞춤) -> 규격 검증 |
| `layers.py` | 레이어 유형별 렌더러 디스패치 테이블 (`background`, `caption`, `device_frame`, `ui_popout`, `brand`, `screen`, `decoration`) |
| `layout.py` | 캡션/화면 영역 분할과 화면 맞춤(contain, crop_top) 순수 함수. 렌더와 검증이 공유 |
| `fonts.py` | 폰트 로딩(굵기 -> ttc face index), 단어 단위 줄바꿈, `[[강조]]` 마크업 파싱 |
| `../templates/*.yaml` | 프리셋. 머리말 주석에 근거(스펙 절·raw 출처)와 출처 없는 값을 적어 둔다 |
| `../assets/` | 로고 등 에셋 (폰트를 추가하면 `fonts.FONT_FILES`에 등록) |

## 사용법

```bash
# 스크린샷은 앱 프로필의 shots_dir (daily_memo: assets/shots/daily_memo/ko/*.png) -> tools/marketing/out/template/
python3 tools/marketing/template render tools/marketing/templates/ig_carousel.yaml --app tools/marketing/apps/daily_memo.yaml --copy tools/marketing/copy/daily_memo.yaml --voice legacy_ig_carousel
python3 tools/marketing/template render tools/marketing/templates/store_pastel.yaml --app tools/marketing/apps/daily_memo.yaml --copy tools/marketing/copy/daily_memo.yaml --voice legacy_store_pastel --out /tmp/store
python3 tools/marketing/template render ... --shots <dir> --glob '*.png'
```

의존성은 Pillow, PyYAML (`tools/marketing/requirements.txt`). 시스템 python3 3.9로 확인함.

## 프리셋 작성 규칙

- `template.spec_ref`에 근거가 되는 스펙 절을 적는다.
- `layers`는 순서대로 합성된다 (배경 -> 캡션 -> 기기 -> 팝아웃 -> 브랜드).
- 장별 값은 `slides[i].layers.<type>`로 덮어쓴다. `headline`, `body`, `screenshot`(인덱스 또는 경로)은 장 콘텐츠.
- `per_slide_color: true` + `palette_per_slide`로 장마다 배경색을 바꾼다 (Goodnotes·Todoist·Notion 관측).
- `[[단어]]`는 `emphasis_color`로 그린다. 단어 안(`[[저장]]하면`)에서도 쓸 수 있다.
- `ui_popout.crop`은 스크린샷 비율 `[x0, y0, x1, y1]`. `x_pct`/`y_pct`로 카드가 캔버스 밖으로 나가게 둘 수 있다 (overflow_canvas 관측).
- `device_frame`은 generic 단색 베젤이다. Apple Design Resources 베젤은 Apple 플랫폼 UI 목업 전용 라이선스라 쓰지 않는다 (raw/05 #2).

## 현재 한계

- 폰트: 시스템 Apple SD Gothic Neo. 배포용은 OFL 폰트(Pretendard 등)를 `assets/fonts/`에 넣고 `families`를 바꾼다.
- `decoration`(일러스트·스티커·마스코트)은 라이선스 확인된 에셋이 없어 `kind: none`만 지원.
- 스크린샷은 `apps/daily_memo/integration_test/screenshots_test.dart`가 인메모리 더미 메모 6건을 심고 찍는다 (0 목록, 1 추가 입력 중, 2 수정, 3 달력; iPhone Xs Max 시뮬레이터 1242x2688).
  실행: `cd apps/daily_memo && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshots_test.dart -d <udid>`.
  상태 표시줄은 포함되지 않는다(Flutter 뷰만 캡처). 달력 장은 앱의 firstDay 계산 때문에 최신 메모일 이전 날짜 표시가 비활성이라 프리셋에서 쓰지 않는다.
- 영상(Reels·앱 미리보기)은 미구현. 기존 `render_and_validate.py`의 ffmpeg 경로를 쓴다.

## 카피 변형 (variations.py)

카피는 `tools/marketing/copy/<앱 id>.yaml`에만 있다. 말투(voices)별 슬라이드 4장의 `headline`, `body`, `screen`(스크린샷 번호, 크롭 이름)을 적는다.
스타일(배경, 정렬, 카드 모양)은 `variations.py`의 `STYLES`.

```bash
python3 tools/marketing/variations.py --app daily_memo                                   # COMBOS 전체
python3 tools/marketing/variations.py --app daily_memo --voice maker --style cover_3d   # 한 조합만
python3 tools/marketing/variations.py --app daily_memo --copy copy/other.yaml            # 다른 카피 파일
```

한계: 글이 길면 줄바꿈은 되지만 글자 크기는 줄지 않는다. 넘침 경고도 아직 없다.

## 화면 배치 모델 (`screen` 레이어)

`ui_popout`/`device_frame`은 폭과 위치(y_pct)를 따로 받아 화면 노출량이 우연히 정해진다. 앱 화면이 메시지의 증거일 때는 `layout` + `screens` + `screen` 레이어를 쓴다.
스키마는 `07_템플릿_스펙.md` 4.7. 렌더 결과 행의 `metrics`/`warnings`로 노출 높이, 글자 배율, 캡션 넘침을 확인한다.

```bash
python3 -m unittest discover -s tools/marketing/tests -t tools/marketing   # layout 순수 함수 테스트
```

주의: 1:1 캔버스에 세로 화면 전체(`contain`)를 넣으면 배율이 0.25~0.4라 앱 글자가 읽히지 않는다(기본 하한 0.5 미만 경고). 읽히는 노출은 `crop_top`과 키 큰 크롭을 쓴다.

### 구도 변주 (겹침, 기울기, 가장자리 걸침)

`screen` 레이어에서 `arrange: stack`(겹쳐 쌓기), `tilts`(카드별 기울기), `shift_x_pct`(옆으로 밀어 걸침)를 쓴다. 장별로 다르게 하려면 `slides[i].layers.screen`에 같은 키를 적는다.
옆으로 밀어 가로 노출이 92% 미만이면 `warnings`에 나온다.

3D 원근은 `poses: [{yaw, pitch, roll}]`로 준다(`perspective.py`). 카드 한 장을 평면으로 보고 원근 투영하는 방식이라 두께나 조명은 없다. 관찰상 표지 장에만 강하게 쓰는 구도가 많아(raw/10) 변형 스타일은 표지만 3D, 나머지는 평면으로 뒀다. yaw/pitch 40도, roll 20도 상한 경고는 우리 설정값이다.

## 영상 (MP4)

`python3 video.py --app daily_memo --voice maker --style cover_3d` -> `out/video/video_<앱>_<voice>_<style>.mp4` (1080x1920, 30fps, H.264).
이미지와 같은 카피·스타일을 쓰고, 장마다 캡션(0~0.5초 등장) -> 화면(0.25~0.9초 아래에서 올라옴) -> 정지(천천히 위로 흐름) -> 0.25초 퇴장을 합성한다.
시간값은 `template/video.py` 의 `Motion` (우리 설정, 관측 근거 없음). 인코더는 imageio-ffmpeg 가 제공하는 ffmpeg 를 쓴다.

## 앱 독립 구조 (템플릿 / 앱 프로필 / 카피)

| 층 | 위치 | 들어 있는 것 |
|---|---|---|
| 템플릿 | `templates/*.yaml`, `variations.py` 의 STYLES | 레이아웃, 크기, 배경 팔레트. 앱 값과 문구는 `{{...}}` 자리표시자 |
| 앱 프로필 | `apps/<id>.yaml` (양식 `apps/_template.yaml`) | 이름, 브랜드 색, 로고, 글꼴, 스크린샷 폴더, 화면 레지스트리 |
| 카피 | `copy/<id>.yaml` 의 `voices.<이름>` | 장별 headline, body, 쓸 화면 이름 |

자리표시자: `{{headline}}` `{{body?}}` (카피, `?` 는 선택), `{{app.brand.primary}}` `{{app.font}}` 같은 `{{app.경로}}` (앱 프로필).
합성 순서는 앱 값 -> 카피(화면 이름에서 shot/crop/screens 파생) -> 앱 값이며, 장 수가 다르거나 채우지 못한 자리표시자가 남으면 오류다.
새 앱 추가: `apps/_template.yaml` 을 복사해 값을 채우고, 스크린샷과 `copy/<id>.yaml` 을 만든 뒤
`python3 variations.py --app <id>` 또는 `python3 video.py --app <id> --voice <이름> --style <스타일>`.

## 감사와 자동 규칙

`python3 audit.py` : 모든 앱 프로필 x 카피 조합 x 1:1·9:16 을 렌더 없이 측정해 경고 종류별 건수를 낸다 (개선 전후 비교 기준).
렌더러 자동 규칙(대비, 크롭 연장, 앱 배경색 띠 걷기, 초점 맞추기, 반복 확대)과 루프 기록은
`tools/marketing/docs/템플릿_운영_규칙.md` 4.1절·10절 (원본은 gitignore 된 doc/ 아래 08 문서).
