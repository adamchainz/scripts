#!/usr/bin/env python
import subprocess
from pathlib import Path

TRASH = Path("~/.Trash").expanduser()


def main():
    directory = Path(".")
    for file in directory.iterdir():
        if not file.is_file():
            continue

        if file.suffix.lower() not in (".jpeg", ".jpg"):
            continue

        # Delete blurless copy of image from iPhone portrait mode
        if file.name.startswith("IMG_") and not file.name.startswith("IMG_E"):
            e_version = directory / file.name.replace("IMG_", "IMG_E", 1)
            if e_version.exists():
                print(f"Removing {file.name} in favour of {e_version.name}")
                file.rename(TRASH / file.name)

        # Delete movies from iPhone live mode
        if file.name.endswith(".JPG"):
            movie_version = directory / (file.name[: -len(".JPG")] + ".MOV")
            if movie_version.exists() and is_one_second_movie(movie_version):
                print(f"Removing {movie_version.name}")
                movie_version.rename(TRASH / movie_version.name)


def is_one_second_movie(file):
    result = subprocess.run(["ffmpeg", "-i", str(file)], capture_output=True)
    return any(
        line.strip().startswith("Duration: 00:00:01.")
        for line in result.stderr.decode().splitlines()
    )


if __name__ == "__main__":
    raise SystemExit(main())
