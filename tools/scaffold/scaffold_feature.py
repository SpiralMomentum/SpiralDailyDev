#!/usr/bin/env python3
"""Clean Architecture feature 디렉토리 스캐폴딩 도구.

지정한 앱에 Clean Architecture 구조를 따르는 feature 디렉토리와 stub 파일을 생성한다.
모노레포의 기존 패턴(daily_memo, adage_spark 등)과 동일한 구조를 보장한다.

사용법:
    # 기본 feature 생성 (entity + repository + usecase + datasource + bloc + view)
    python tools/scaffold/scaffold_feature.py --app daily_memo --feature bookmark

    # 엔티티명 직접 지정
    python tools/scaffold/scaffold_feature.py --app daily_memo --feature bookmark --entity Bookmark

    # dry-run (생성될 파일 목록만 출력)
    python tools/scaffold/scaffold_feature.py --app daily_memo --feature bookmark --dry-run
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import List

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def to_pascal_case(snake: str) -> str:
    """snake_case를 PascalCase로 변환한다."""
    return "".join(word.capitalize() for word in snake.split("_"))


def to_camel_case(snake: str) -> str:
    """snake_case를 camelCase로 변환한다."""
    parts = snake.split("_")
    return parts[0] + "".join(word.capitalize() for word in parts[1:])


def generate_entity(feature: str, entity: str) -> str:
    """Domain entity stub."""
    return f"""class {entity} {{
  const {entity}({{
    required this.id,
  }});

  final String id;
}}
"""


def generate_repository_interface(feature: str, entity: str) -> str:
    """Domain repository interface stub."""
    repo_name = f"{entity}Repository"
    entity_file = f"{feature}_entity.dart"
    return f"""import 'package:utils/utils.dart';

import '../entities/{entity_file}';

abstract class {repo_name} {{
  Future<Result<List<{entity}>>> fetchAll();
  Future<Result<{entity}>> fetchById(String id);
}}
"""


def generate_usecase(feature: str, entity: str, action: str, action_pascal: str) -> str:
    """Domain use case stub."""
    repo_name = f"{entity}Repository"
    usecase_name = f"{action_pascal}{entity}UseCase"
    repo_file = f"{feature}_repository.dart"
    entity_file = f"{feature}_entity.dart"
    return f"""import 'package:utils/utils.dart';

import '../entities/{entity_file}';
import '../repositories/{repo_file}';

class {usecase_name} {{
  const {usecase_name}(this._repository);

  final {repo_name} _repository;

  Future<Result<List<{entity}>>> call() => _repository.fetchAll();
}}
"""


def generate_datasource_interface(feature: str, entity: str) -> str:
    """Data datasource interface stub."""
    ds_name = f"{entity}LocalDataSource"
    model_name = f"{entity}Model"
    model_file = f"{feature}_model.dart"
    return f"""import '../models/{model_file}';

abstract class {ds_name} {{
  Future<List<{model_name}>> loadAll();
  Future<{model_name}?> loadById(String id);
}}
"""


def generate_model(feature: str, entity: str) -> str:
    """Data model stub."""
    model_name = f"{entity}Model"
    return f"""class {model_name} {{
  const {model_name}({{
    required this.id,
  }});

  final String id;

  factory {model_name}.fromJson(Map<String, dynamic> json) {{
    return {model_name}(
      id: json['id'] as String,
    );
  }}

  Map<String, dynamic> toJson() => {{
        'id': id,
      }};
}}
"""


def generate_mapper(feature: str, entity: str) -> str:
    """Data mapper stub."""
    model_name = f"{entity}Model"
    model_file = f"{feature}_model.dart"
    entity_file = f"{feature}_entity.dart"
    return f"""import '../../domain/entities/{entity_file}';
import '../models/{model_file}';

extension {model_name}Mapper on {model_name} {{
  {entity} toEntity() {{
    return {entity}(
      id: id,
    );
  }}
}}
"""


def generate_repository_impl(feature: str, entity: str) -> str:
    """Data repository implementation stub."""
    repo_name = f"{entity}Repository"
    repo_impl_name = f"{entity}RepositoryImpl"
    ds_name = f"{entity}LocalDataSource"
    model_file = f"{feature}_model.dart"
    entity_file = f"{feature}_entity.dart"
    repo_file = f"{feature}_repository.dart"
    ds_file = f"{feature}_local_data_source.dart"
    mapper_file = f"model_to_entity_mapper.dart"
    return f"""import 'package:utils/utils.dart';

import '../../domain/entities/{entity_file}';
import '../../domain/repositories/{repo_file}';
import '../datasources/{ds_file}';
import '../mappers/{mapper_file}';

class {repo_impl_name} implements {repo_name} {{
  const {repo_impl_name}(this._dataSource);

  final {ds_name} _dataSource;

  @override
  Future<Result<List<{entity}>>> fetchAll() => guardAsync(
        action: () async {{
          final models = await _dataSource.loadAll();
          return models.map((m) => m.toEntity()).toList();
        }},
        onError: (e, s) => LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: s,
        ),
      );

  @override
  Future<Result<{entity}>> fetchById(String id) => guardAsync(
        action: () async {{
          final model = await _dataSource.loadById(id);
          if (model == null) {{
            throw Exception('{entity} not found: $id');
          }}
          return model.toEntity();
        }},
        onError: (e, s) => LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: s,
        ),
      );
}}
"""


def generate_exception(feature: str) -> str:
    """Data exception stub."""
    return """class ExternalException implements Exception {
  const ExternalException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ExternalException: $message';
}
"""


def generate_bloc(feature: str, entity: str) -> str:
    """Presentation BLoC stub."""
    bloc_name = f"{entity}Bloc"
    event_name = f"{entity}Event"
    state_name = f"{entity}State"
    event_file = f"{feature}_event.dart"
    state_file = f"{feature}_state.dart"
    return f"""import 'package:flutter_bloc/flutter_bloc.dart';

import '{event_file}';
import '{state_file}';

class {bloc_name} extends Bloc<{event_name}, {state_name}> {{
  {bloc_name}() : super(const {state_name}()) {{
    on<Load{entity}s>(_onLoad);
  }}

  Future<void> _onLoad(
    Load{entity}s event,
    Emitter<{state_name}> emit,
  ) async {{
    // TODO: implement
  }}
}}
"""


def generate_event(feature: str, entity: str) -> str:
    """Presentation event stub."""
    event_name = f"{entity}Event"
    return f"""sealed class {event_name} {{
  const {event_name}();
}}

class Load{entity}s extends {event_name} {{
  const Load{entity}s();
}}
"""


def generate_state(feature: str, entity: str) -> str:
    """Presentation state stub."""
    state_name = f"{entity}State"
    return f"""class {state_name} {{
  const {state_name}({{
    this.isLoading = false,
    this.items = const [],
    this.error,
  }});

  final bool isLoading;
  final List<dynamic> items;
  final String? error;
}}
"""


def generate_view(feature: str, entity: str) -> str:
    """Presentation view stub."""
    view_name = f"{entity}Page"
    return f"""import 'package:flutter/material.dart';

class {view_name} extends StatelessWidget {{
  const {view_name}({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return const Scaffold(
      body: Center(
        child: Text('{entity}'),
      ),
    );
  }}
}}
"""


def build_file_list(app_name: str, feature: str, entity: str) -> List[tuple[Path, str]]:
    """생성할 파일 목록을 반환한다. (경로, 내용) 튜플 리스트."""
    base = REPO_ROOT / "apps" / app_name / "lib" / "features" / feature
    entity_pascal = entity

    files: List[tuple[Path, str]] = []

    # Domain
    files.append((
        base / "domain" / "entities" / f"{feature}_entity.dart",
        generate_entity(feature, entity_pascal),
    ))
    files.append((
        base / "domain" / "repositories" / f"{feature}_repository.dart",
        generate_repository_interface(feature, entity_pascal),
    ))
    files.append((
        base / "domain" / "usecases" / f"get_all_{feature}s_use_case.dart",
        generate_usecase(feature, entity_pascal, f"get_all_{feature}s", f"GetAll{entity_pascal}s"),
    ))

    # Data
    files.append((
        base / "data" / "datasources" / f"{feature}_local_data_source.dart",
        generate_datasource_interface(feature, entity_pascal),
    ))
    files.append((
        base / "data" / "models" / f"{feature}_model.dart",
        generate_model(feature, entity_pascal),
    ))
    files.append((
        base / "data" / "mappers" / "model_to_entity_mapper.dart",
        generate_mapper(feature, entity_pascal),
    ))
    files.append((
        base / "data" / "repositories" / f"{feature}_repository_impl.dart",
        generate_repository_impl(feature, entity_pascal),
    ))
    files.append((
        base / "data" / "exceptions" / "external_exception.dart",
        generate_exception(feature),
    ))

    # Presentation
    files.append((
        base / "presentation" / "bloc" / feature / f"{feature}_bloc.dart",
        generate_bloc(feature, entity_pascal),
    ))
    files.append((
        base / "presentation" / "bloc" / feature / f"{feature}_event.dart",
        generate_event(feature, entity_pascal),
    ))
    files.append((
        base / "presentation" / "bloc" / feature / f"{feature}_state.dart",
        generate_state(feature, entity_pascal),
    ))
    files.append((
        base / "presentation" / "views" / f"{feature}_page.dart",
        generate_view(feature, entity_pascal),
    ))

    return files


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Clean Architecture feature 스캐폴딩 도구",
    )
    parser.add_argument("--app", required=True, help="대상 앱 이름 (예: daily_memo)")
    parser.add_argument("--feature", required=True, help="feature 이름 (snake_case, 예: bookmark)")
    parser.add_argument("--entity", help="엔티티 클래스명 (PascalCase, 기본: feature명 변환)")
    parser.add_argument("--dry-run", action="store_true", help="생성될 파일 목록만 출력")
    args = parser.parse_args(argv)

    app_name = args.app
    feature = args.feature
    entity = args.entity or to_pascal_case(feature)

    # 앱 디렉토리 존재 확인
    app_dir = REPO_ROOT / "apps" / app_name
    if not app_dir.exists():
        print(f"Error: App directory not found: {app_dir}", file=sys.stderr)
        return 1

    # feature 디렉토리 중복 확인
    feature_dir = app_dir / "lib" / "features" / feature
    if feature_dir.exists():
        print(f"Error: Feature directory already exists: {feature_dir}", file=sys.stderr)
        return 1

    files = build_file_list(app_name, feature, entity)

    if args.dry_run:
        print(f"Will create {len(files)} files for feature '{feature}' in app '{app_name}':")
        print(f"Entity class: {entity}")
        print()
        for path, _ in files:
            rel = path.relative_to(REPO_ROOT)
            print(f"  {rel}")
        return 0

    created = 0
    for path, content in files:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        created += 1

    rel_feature = feature_dir.relative_to(REPO_ROOT)
    print(f"Created {created} files in {rel_feature}/")
    print()
    print("Structure:")
    for path, _ in files:
        rel = path.relative_to(feature_dir)
        print(f"  {rel}")
    print()
    print("Next steps:")
    print(f"  1. Define entity fields in domain/entities/{feature}_entity.dart")
    print(f"  2. Add use cases for your business operations")
    print(f"  3. Implement data source in external/ layer")
    print(f"  4. Wire dependencies in your DI setup")

    return 0


if __name__ == "__main__":
    sys.exit(main())
