# Threads 게시 파이프라인

Threads API(graph.threads.net)로 텍스트, 이미지, 영상, 캐러셀을 게시한다.
2026-11-12 `spiral_momentum` 계정에 실제 게시로 검증함:
- 텍스트 https://www.threads.com/@spiral_momentum/post/DfoVNfhj_gi
- 이미지 https://www.threads.com/@spiral_momentum/post/DfoVPeHD-im
- 캐러셀 3장 https://www.threads.com/@spiral_momentum/post/DfoVnldj14C
- 영상 20초 https://www.threads.com/@spiral_momentum/post/DfoVpZYBVok (처리 대기 10초 x3회)

## 구성

| 파일 | 역할 |
|---|---|
| `__main__.py` | CLI. 결과는 stdout JSON 한 줄, 로그는 stderr |
| `config.py` | 설정 (`common/envfile.py`로 로드) |
| `publisher.py` | API 단계 함수, job 검증, 토큰 갱신, 파이프라인 |
| `jobs/` | 게시 job 정의(YAML). 소재는 `instagram/jobs/assets` 공유 |
| `state/published.jsonl` | 게시/삭제 원장 (gitignore) |
| `../common/` | HTTP 호출·재시도(`http_api.py`), 공개 URL 호스팅(`hosting.py`), 원장(`ledger.py`), .env 로드(`envfile.py`). Instagram과 공유 |

## 온보딩 (2026-11-12 화면 기준)

1. Meta 앱(기존 Instagram용 앱 그대로) > 이용 사례 > "이용 사례 추가" > **Threads API 액세스** 선택, 저장. 별도 앱 불필요. Threads 앱 ID가 따로 생긴다.
2. 이용 사례 > Threads API 액세스 > 권한 및 기능: `threads_basic`(기본), `threads_content_publish`, `threads_delete` "추가".
3. 앱 역할 > 역할 > 사람 추가 > **Threads 테스터** > Threads 아이디.
4. **threads.com(웹)** > 설정 > 설정 더 보기 > 웹사이트 권한 > **초대** 탭에서 수락. 모바일 앱에서는 찾기 어렵다.
5. 이용 사례 > Threads API 액세스 > **설정** 탭 > 사용자 토큰 생성기 > "액세스 토큰 생성하기". 공개 계정만 가능. `THAA`로 시작하는 60일 장기 토큰.
6. `.env`에 `MKT_THREADS_TOKEN` 저장. `MKT_THREADS_USER_ID`는 `GET /me`로 조회.

## 설정

| 키 | 필수 | 설명 |
|---|---|---|
| `MKT_THREADS_USER_ID` | O | Threads 사용자 ID (Instagram ID와 다름) |
| `MKT_THREADS_TOKEN` | O | 60일 장기 토큰. `refresh-token`으로 연장 |
| `MKT_THREADS_MEDIA_HOST` | - | `uguu`(기본, 임시) 또는 `none` |
| `MKT_THREADS_API_HOST` / `_VERSION` | - | 기본 `https://graph.threads.net` / `v1.0` |

## 사용법

```bash
python tools/marketing/threads check
python tools/marketing/threads validate tools/marketing/threads/jobs/daily_memo_carousel.yaml
python tools/marketing/threads post tools/marketing/threads/jobs/daily_memo_carousel.yaml --dry-run
python tools/marketing/threads post tools/marketing/threads/jobs/daily_memo_carousel.yaml
python tools/marketing/threads list --limit 5
python tools/marketing/threads delete <media_id>      # 원장에 삭제 기록 -> 같은 job 재게시 가능
python tools/marketing/threads refresh-token          # 50일 주기 정도로 실행 권장 (60일 만료)
```

단계별 수동: `create-text "본문"` 또는 `upload a.jpg` -> `create-image <url> --text ..` -> `wait <id>` -> `publish <id>` -> `info <media_id>`

종료 코드: `0` 성공 또는 건너뜀, `1` API/네트워크 오류, `2` 입력 검증 실패, `3` 24시간 한도 초과

## job 형식

```yaml
name: daily_memo_text
type: text            # text | image | video | carousel
text: |-              # 또는 text_file: 경로. 500자 이하
  ...
media: []             # image/video 1개, carousel 2~20개
link: https://...     # text 타입 전용 링크 미리보기 (선택)
topic: 메모앱          # 주제 태그 1개 (선택)
```

## 검증 규칙

| 항목 | 기준 |
|---|---|
| 본문 | 500자 이하, 본문 링크 5개 이하, text 타입은 본문 필수 |
| 이미지 | JPEG/PNG, 8MB 이하, 폭 320~1440px, 비율 최대 10:1 |
| 캐러셀 | 2~20개 |
| 24시간 한도 | 게시 250, 답글 1,000 (`threads_publishing_limit`, 게시 직전 조회) |

## 2026-11-12 실측 사항

- 토큰은 `THAA` 형식, 207자. `graph.threads.net/v1.0` 사용.
- 텍스트 컨테이너는 첫 조회에서 `IN_PROGRESS`, 3초 후 `FINISHED`. 이미지 컨테이너는 첫 조회에서 `FINISHED`.
- 게시 후 `media_type`은 텍스트가 `TEXT_POST`, 이미지는 `IMAGE`로 조회된다. `topic_tag` 반영 확인.
- `refresh-token`은 문서상 발급 24시간 후부터지만, 발급 직후 호출해도 성공(만료 60.0일)했고 새 토큰으로 조회 정상.
- 게시 직후 `quota_usage`는 0으로 조회됨(Instagram과 같은 집계 지연).

## 삭제 (현재 미사용)

- 콘솔 "사용자 토큰 생성기" 토큰에는 `threads_delete`가 없다 (`token-scopes`로 확인). `delete`는 code 10(403).
- 필요해지면: 설정 탭 "리디렉션 콜백 URL" 등록 -> `.env`에 `MKT_THREADS_APP_SECRET`, `MKT_THREADS_REDIRECT_URI` -> `auth-url`로 받은 URL에서 허용 -> `exchange-code "<리디렉션된 URL>"`.
- 2026-11-12 결정: 삭제 기능은 범위에서 제외. 테스트 게시물은 앱에서 직접 삭제.

## 미검증

- OAuth(`auth-url`, `exchange-code`) 실제 교환
- 게시 후 수정: Threads API에 수정 엔드포인트가 없는 것으로 알려져 있으나 이 저장소에서 확인하지 않음
