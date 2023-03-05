#!/usr/bin/env python
import argparse
import shutil
import subprocess
from pathlib import Path


photos_path = Path("~/Arqbox/Aart/Photos").expanduser()
trash_path = Path("~/.Trash/remove-duplicate-photos").expanduser()


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--actually-remove", action="store_true")
    args = parser.parse_args(argv)
    actually_remove = args.actually_remove

    trash_path.mkdir(exist_ok=True)

    for year_path in sorted(photos_path.iterdir()):
        if not (
            year_path.is_dir()
            and year_path.parts[-1].isdigit()
            and int(year_path.parts[-1]) >= 2018
        ):
            continue

        for day_path in sorted(year_path.iterdir()):
            if not day_path.is_dir():
                continue

            result = subprocess.run(
                ["fdupes", str(day_path)], capture_output=True, text=True
            )
            lines = result.stdout.rstrip("\n").splitlines()
            if not lines:
                continue

            groups = []
            group = set()
            for line in lines:
                if line == "" and group:
                    groups.append(group)
                    group = set()
                else:
                    group.add(Path(line).relative_to(day_path))
            if group:
                groups.append(group)

            if not groups:
                continue

            print(day_path)

            for group in groups:
                keep = max(group, key=lambda p: len(str(p)))

                for suffix in (" 1", " copy"):
                    if keep.stem.endswith(suffix) and (
                        (better := Path(keep.stem.removesuffix(suffix) + keep.suffix))
                        in group
                    ):
                        keep = better

                for path in group:
                    if path != keep:
                        full_path = day_path / path

                        print(f"    🗑️ {path}")
                        if actually_remove:
                            shutil.move(full_path, trash_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
