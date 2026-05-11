# Project Context

이 문서는 AI 코딩 도구가 이 저장소를 다룰 때 참조하는 프로젝트 컨텍스트이다.

## Language & Output Style

한국어로 대화합니다.

- 이모지를 사용하지 않는다
- 주장이나 판단에는 객관적인 수치 근거를 제시한다
- 무의미하거나 과대한 추론을 하지 않는다

## Build & Development Commands

```bash
# Monorepo bootstrap (install all dependencies)
melos bootstrap

# Run tests for a single app
flutter test                              # from an app directory
cd apps/daily_memo && flutter test        # specific app

# Run tests/analysis across all packages
melos run test:all
melos run analyze:all

# Code generation (freezed, json_serializable, retrofit)
dart run build_runner build --delete-conflicting-outputs   # from app directory

# Release pipeline (dry-run by default)
python tools/release/publisher.py --app daily_memo
python tools/release/publisher.py --app daily_memo --platform android --track internal
python tools/release/publisher.py --execute   # actually runs commands

# Fastlane (from repo root)
bundle exec fastlane android deploy_internal app:daily_memo
bundle exec fastlane ios deploy_testflight app:daily_memo
```

### Docs 

상세 가이드는 `doc/` 디렉토리의 개별 문서를 참조한다. 코드 작성/리뷰 시 해당 레이어의 문서를 읽고 규칙을 따른다.
