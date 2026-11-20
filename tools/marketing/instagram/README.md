# Instagram 게시 파이프라인

Instagram Graph API(Unified login, 비즈니스 포트폴리오 방식)로 이미지, 캐러셀, 릴스를 게시한다.
2026-11-12 `spiral_momentum` 계정에 실제 게시로 검증함: 이미지 https://www.instagram.com/p/Dfm1s4dj29c/ , 캐러셀 https://www.instagram.com/p/Dfm25WQj4t0/

## 구성

| 파일 | 역할 |
|---|---|
| `__main__.py` | CLI. 결과는 stdout JSON 한 줄, 로그는 stderr |
| `config.py` | 설정 (`common/envfile.py`: 환경변수 > `tools/marketing/.env`) |
| `graph_api.py` | Graph API get/post/delete. HTTP·재시도(지수 백오프 3회)는 `common/http_api.py`, 토큰 로그 출력 안 함 |
| `publisher.py` | 단계별 API 함수, job 검증, 오케스트레이션 (함수형: 순수 함수와 부수효과 분리) |
| `../common/` | 공개 URL 호스팅(`hosting.py`), 원장(`ledger.py`) 등 Threads와 공유하는 모듈 |
| `jobs/` | 게시 job 정의(YAML)와 샘플 소재 |
| `state/published.jsonl` | 게시 원장 (gitignore). 같은 key는 다시 게시하지 않음 (삭제 기록이 있으면 재게시 가능) |

## 설정

`tools/marketing/.env` (gitignore됨) 또는 CI secrets:

| 키 | 필수 | 설명 |
|---|---|---|
| `MKT_IG_USER_ID` | O | Instagram 사용자 ID (앱 대시보드 > 2. 액세스 토큰 생성 표에 표시) |
| `MKT_IG_TOKEN` | O | 같은 표의 "토큰 생성"으로 발급. `EAA`로 시작 |
| `MKT_IG_MEDIA_HOST` | - | `uguu`(기본, 임시 호스팅) 또는 `none`(job에 https URL 직접 지정) |
| `MKT_IG_GRAPH_HOST` | - | 기본 `https://graph.facebook.com` |
| `MKT_IG_GRAPH_VERSION` | - | 기본 `v24.0` |

## 사용법

저장소 루트에서 실행한다. 의존성은 `tools/marketing/requirements.txt` 패키지(PyYAML, Pillow)를 쓴다.

```bash
# 파이프라인: job 하나 게시 (검증 -> 업로드 -> 컨테이너 -> 대기 -> 게시 -> 원장 기록)
python tools/marketing/instagram validate tools/marketing/instagram/jobs/daily_memo_carousel.yaml
python tools/marketing/instagram post tools/marketing/instagram/jobs/daily_memo_carousel.yaml --dry-run
python tools/marketing/instagram post tools/marketing/instagram/jobs/daily_memo_carousel.yaml

# 상태 점검
python tools/marketing/instagram check          # 계정 + 24시간 게시 한도
python tools/marketing/instagram list --limit 5

# API 단계별 수동 실행
python tools/marketing/instagram upload a.jpg                     # -> {"url": ...}
python tools/marketing/instagram create-image <url> --caption "..." # -> {"id": 컨테이너}
python tools/marketing/instagram wait <container_id>
python tools/marketing/instagram publish <container_id>           # -> {"media_id": ...}
python tools/marketing/instagram info <media_id>
```

캐러셀 수동: `create-image <url> --carousel-item`을 장마다 실행 -> `create-carousel id1,id2,... --caption ".."` -> `wait` -> `publish`
릴스 수동: `create-video <url> --reel --caption ".."` -> `wait --timeout 600` -> `publish`

종료 코드: `0` 성공 또는 중복으로 건너뜀, `1` API/네트워크 오류, `2` 입력 검증 실패, `3` 24시간 한도 초과

## job 형식

```yaml
name: daily_memo_carousel        # 원장 기록용 이름
type: carousel                   # image | carousel | reel
media:                           # job 파일 기준 상대 경로 또는 https URL
  - assets/daily_memo_feed_4x5_0.jpg
  - assets/daily_memo_feed_4x5_1.jpg
caption: |-                      # 또는 caption_file: caption.txt
  ...
share_to_feed: true              # reel 전용
cover: cover.jpg                 # reel 전용, 선택
idempotency_key: launch-2026-11  # 선택. 없으면 type + 미디어 바이트 + 캡션의 SHA-256 앞 24자
```

## 검증 규칙 (게시 전 로컬에서 차단)

| 항목 | 기준 |
|---|---|
| 이미지 포맷 | JPEG만 (PNG는 거부) |
| 이미지 비율 | 가로/세로 0.8(4:5) ~ 1.91 |
| 이미지 용량 | 8MB 이하 |
| 캐러셀 장수 | 2~10 |
| 캡션 | 2,200자 이하, 해시태그 30개 이하, 멘션 20개 이하 |
| 24시간 게시 | `content_publishing_limit` 100건 (게시 직전 조회) |

## 2026-11-12 실측 사항

- Unified login 토큰은 `EAA`(Facebook) 형식이라 `graph.facebook.com`에서만 동작. `graph.instagram.com`은 `code 190 Cannot parse access token`.
- 게시 후 수정: 캡션 변경 `POST /{media_id} caption=` 은 `code 3 Unknown method`로 불가. `comment_enabled`만 변경 가능(`comments` 명령). 캡션을 고치려면 인스타 앱에서 직접 수정하거나 삭제 후 재게시해야 하므로, 게시 전 승인 단계가 필요하다.
- 이미지 컨테이너는 생성 직후 첫 조회에서 `FINISHED`.
- 캐러셀 3장 게시 성공 (2026-11-12, https://www.instagram.com/p/Dfm25WQj4t0/): 업로드 3 -> 자식 컨테이너 3(1개만 IN_PROGRESS 1회, 5초 대기) -> CAROUSEL 컨테이너 -> 게시. 재실행 시 `skipped`.
- 이미 게시된 컨테이너에 `publish`를 다시 호출하면 새 게시물이 생기지 않고 같은 `media_id`를 돌려줌 (상태 `PUBLISHED`).
- `content_publishing_limit.quota_usage`는 게시 직후 0, 수 분 뒤 1로 반영 (집계 지연).
- 임시 호스팅: `uguu.se` 성공. `catbox.moe`는 파일 도메인 DNS 실패 + Meta `code 1`, `tmpfiles.org`는 HTML로 리다이렉트되어 사용 불가.

## 남은 작업

- 운영용 공개 스토리지(S3/R2/GCS) 제공자를 `hosting.py`에 추가 (`MKT_STORAGE_*`). 임시 호스팅은 테스트 전용.
- 토큰 만료 모니터링: `debug_token`에 앱 토큰(앱 ID|시크릿) 필요. 시스템 사용자 토큰(SUAT, 만료 없음)으로 전환하면 불필요.
- 릴스 20초 게시 성공 (2026-11-12, https://www.instagram.com/reel/DfoVvdTmetf/): 처리 대기 10초 x3회.
