#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List

import yaml

from icon_generator import IconSpec, generate_icon

REQUIRED_METADATA_FIELDS = [
    "appName",
    "shortDescription",
    "fullDescription",
    "category",
    "contact",
    "privacyPolicyUrl",
]


def load_config(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def validate_metadata(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Metadata file not found: {path}")
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    missing = [field for field in REQUIRED_METADATA_FIELDS if field not in data]
    if missing:
        raise ValueError(f"Metadata file {path} is missing required fields: {', '.join(missing)}")
    return data


def run_command(command: Iterable[str], *, cwd: Path | None = None, dry_run: bool = True) -> None:
    printable = " ".join(shlex.quote(str(part)) for part in command)
    location = f" (cwd={cwd})" if cwd else ""
    if dry_run:
        print(f"[dry-run] {printable}{location}")
        return
    subprocess.run(list(command), cwd=cwd, check=True)


def maybe_generate_icon(app_name: str, app_config: Dict[str, Any]) -> Path | None:
    if not app_config.get("autoGenerateIcon"):
        return None
    icon_config = app_config.get("icon", {})
    output = Path(icon_config.get("output", f"artifacts/{app_name}/icon.png"))
    background = icon_config.get("backgroundColor", "#222831")
    label = icon_config.get("label", app_name[:2].upper())
    label_color = icon_config.get("labelColor", "#FFFFFF")
    font_size = int(icon_config.get("fontSize", 360))
    template = icon_config.get("template")

    spec = IconSpec(
        output=output,
        background_color=background,
        label=label,
        label_color=label_color,
        font_size=font_size,
        template=Path(template) if template else None,
    )
    generated_path = generate_icon(spec)
    print(f"Generated icon at {generated_path}")
    return generated_path


def maybe_capture_screenshots(
    app_config: Dict[str, Any],
    *,
    app_root: Path,
    dry_run: bool,
) -> Path | None:
    if not app_config.get("autoCaptureScreenshots"):
        return None

    screenshot_config = app_config.get("screenshots", {})
    output_path = Path(screenshot_config.get("outputPath", "artifacts/screenshots"))
    output_path.mkdir(parents=True, exist_ok=True)
    scenarios = screenshot_config.get("scenarios", [])
    for scenario in scenarios:
        command = scenario.get("command")
        if not command:
            print(f"Skipping screenshot scenario without command: {json.dumps(scenario)}")
            continue
        description = scenario.get("description")
        if description:
            print(f"Running screenshot scenario '{scenario.get('name', 'unnamed')}': {description}")
        run_command(command, cwd=app_root, dry_run=dry_run)
    return output_path


def trigger_builds(app_config: Dict[str, Any], *, app_root: Path, dry_run: bool) -> None:
    build_config = app_config.get("build", {})
    for platform, config in build_config.items():
        command = config.get("command")
        if not command:
            continue
        print(f"Running {platform} build for {app_root.name}")
        run_command(command, cwd=app_root, dry_run=dry_run)


def run_fastlane(
    *,
    pipeline_config: Dict[str, Any],
    app_name: str,
    app_config: Dict[str, Any],
    metadata_paths: Dict[str, Path],
    icon_path: Path | None,
    screenshot_path: Path | None,
    dry_run: bool,
) -> None:
    fastlane_bin = pipeline_config.get("fastlaneBinary", "fastlane")
    fastlane_parts = shlex.split(fastlane_bin)
    artifact_root = Path(pipeline_config.get("artifactRoot", "artifacts")) / app_name
    artifact_root.mkdir(parents=True, exist_ok=True)

    fastlane_config = app_config.get("fastlane", {})
    for platform_key, metadata_path in metadata_paths.items():
        lane_key = "androidLane" if platform_key == "android" else "iosLane"
        lane = fastlane_config.get(lane_key)
        if not lane:
            continue
        params = [
            fastlane_parts,
            [
                lane,
                f"metadata_path:{metadata_path}",
                f"artifact_path:{artifact_root}",
                f"skip_screenshots:{str(not bool(screenshot_path)).lower()}",
            ],
        ]
        if icon_path:
            params[1].append(f"icon_path:{icon_path}")
        command: List[str] = []
        for part in params:
            if isinstance(part, list):
                command.extend([str(p) for p in part])
            else:
                command.extend([str(part)])
        print(f"Triggering Fastlane lane '{lane}' for {platform_key}")
        run_command(command, cwd=Path(app_config["projectPath"]), dry_run=dry_run)


def determine_apps(config: Dict[str, Any], requested: List[str] | None) -> Dict[str, Any]:
    apps = config.get("apps", {})
    if not apps:
        raise ValueError("No apps defined in configuration")
    if not requested:
        return apps
    filtered = {}
    for name in requested:
        if name not in apps:
            raise KeyError(f"App '{name}' not found in configuration")
        filtered[name] = apps[name]
    return filtered


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Publish SpiralDailyDev apps using release.yaml configuration")
    parser.add_argument("--config", default="release.yaml", help="Path to the release configuration file")
    parser.add_argument("--app", action="append", help="Run pipeline for the specified app. Can be repeated.")
    parser.add_argument("--execute", action="store_true", help="Execute commands instead of printing dry-run output")
    parser.add_argument("--skip-build", action="store_true", help="Skip build commands")
    parser.add_argument("--skip-fastlane", action="store_true", help="Skip fastlane execution")
    parser.add_argument("--skip-assets", action="store_true", help="Skip icon generation and screenshot capture")
    args = parser.parse_args(argv)

    config_path = Path(args.config)
    config = load_config(config_path)
    pipeline_config = config.get("pipeline", {})
    apps = determine_apps(config, args.app)

    dry_run = not args.execute

    for app_name, app_config in apps.items():
        print("=" * 80)
        print(f"Processing app: {app_name}")
        project_path = Path(app_config.get("projectPath", "."))
        metadata_config = app_config.get("metadata", {})
        metadata_paths = {}
        for platform, path in metadata_config.items():
            metadata_path = Path(path).resolve()
            validate_metadata(metadata_path)
            metadata_paths[platform] = metadata_path
            print(f"Validated metadata for {platform}: {metadata_path}")

        icon_path = None
        screenshot_path = None
        if not args.skip_assets:
            icon_path = maybe_generate_icon(app_name, app_config)
            screenshot_path = maybe_capture_screenshots(
                app_config,
                app_root=project_path,
                dry_run=dry_run,
            )

        if not args.skip_build:
            trigger_builds(app_config, app_root=project_path, dry_run=dry_run)

        if not args.skip_fastlane:
            run_fastlane(
                pipeline_config=pipeline_config,
                app_name=app_name,
                app_config=app_config,
                metadata_paths=metadata_paths,
                icon_path=icon_path,
                screenshot_path=screenshot_path,
                dry_run=dry_run,
            )

    print("=" * 80)
    print("Pipeline completed")
    if dry_run:
        print("(Commands were not executed. Use --execute to run them.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
