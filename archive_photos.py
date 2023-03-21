#!/usr/bin/env python
import argparse
import datetime as dt
import functools
import json
import re
import shutil
import subprocess
from contextlib import contextmanager
from pathlib import Path

iphone_path = Path("~/Arqbox/Aart/Photos/iPhone").expanduser()
photos_path = Path("~/Arqbox/Aart/Photos").expanduser()
trash_path = Path("~/.Trash").expanduser()

esc_blue = "\x1b[38;2;100;100;255m"
esc_red = "\x1b[38;2;255;100;100m"
esc_reset = "\x1b[0m"


def blue(string):
    return f"{esc_blue}{string}{esc_reset}"


def red(string):
    return f"{esc_red}{string}{esc_reset}"


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--actually-move", action="store_true")
    args = parser.parse_args(argv)
    actually_move = args.actually_move

    with run_exiftool() as get_metadata:
        for path in media():
            process(path, get_metadata, actually_move)
    return 0


@contextmanager
def run_exiftool():
    process = subprocess.Popen(
        [
            "exiftool",
            # Keep running and replying to new args
            "-stay_open",
            "True",
            # Read args from stdin
            "-@",
            "-",
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    # Ensure it’s running
    process.poll()

    def get_metadata(path):
        process.stdin.write(
            "\n".join(
                [
                    "-j",  # JSON
                    str(path),
                    "-execute",
                    "",
                ]
            ).encode()
        )
        process.stdin.flush()
        lines = []
        while True:
            line = next(process.stdout)
            if line == b"{ready}\n":
                break
            else:
                lines.append(line)
        return json.loads(b"".join(lines))[0]

    yield get_metadata

    process.kill()


def process(path, get_metadata, actually_move):
    out = blue(path.relative_to(iphone_path)) + " "

    date_taken = get_date_taken(path, get_metadata)
    if date_taken is None:
        out += red("😓  Could not find date/time")
        print(out)
        return

    destination_path = get_date_path(date_taken) / path.name
    dest_display = blue(destination_path.relative_to(photos_path).parent)

    if destination_path.exists():
        optimize(path)
        optimize(destination_path)
        if path.read_bytes() == destination_path.read_bytes():
            out += f"🗑️ duplicate, destination exists: {destination_path} "
            if actually_move:
                path.unlink()
                print(out)
                return
        else:
            if actually_move:
                # Prefer the new version. Imports from iMazing come with edits made
                # on the phone applied, whilst old imported versions with Image
                # Capture do not.
                out += f" 🗑️ duplicate, destination exists: {destination_path} "
                shutil.move(destination_path, trash_path)
            else:
                out += red(
                    f"❗️ destination exists with different contents: {destination_path}"
                )
                print(out)
                return

    if not actually_move:
        out += f"would move to {dest_display}"
        print(out)
    else:
        out += f"=> {dest_display}"
        shutil.move(path, destination_path)

        if path.suffix.lower() in (".jpg", ".jpeg"):
            iphone_aae_path = path.with_suffix(".aae")
            if iphone_aae_path.exists():
                out += blue(" 🗑️ iPhone photo edits AAE file")
                shutil.move(iphone_aae_path, trash_path)

        if (
            path.suffix.lower() == ".heic"
            and (jpeg_dest_path := destination_path.with_suffix(".jpg")).exists()
        ):
            out += blue("🗑️ existing JPEG")
            shutil.move(jpeg_dest_path, trash_path)

        if optimize(destination_path):
            out += " ✓"
        print(out)


FILE_EXTENSIONS = {
    ".avi",
    ".gif",
    ".heic",
    ".jpeg",
    ".jpg",
    ".mov",
    ".mp4",
    ".png",
}


def media():
    paths = list(iphone_path.iterdir())
    paths.sort()  # Basically random order thanks to random filenames.
    for path in paths:
        if (
            path.suffix.lower() in FILE_EXTENSIONS
            and not path.is_symlink()
            and path.exists()
        ):
            yield path


def get_date_taken(path, get_metadata):
    metadata = get_metadata(path)

    # Exif date taken
    if path.suffix.lower() == ".mov":
        field_names = ("MediaCreateDate", "FileModifyDate")
    else:
        field_names = (
            "DateTimeOriginal",
            "CreateDate",
            "DateCreated",
        )
    values = []
    for name in field_names:
        if metadata.get(name, None) not in (None, "0000:00:00 00:00:00"):
            values.append(metadata[name])
    if values:
        return min(parse_date(v) for v in values)

    modification = parse_date(metadata["FileModifyDate"])
    if modification <= dt.date.today():
        return modification

    return None


date_taken_re = re.compile(
    r"(?P<year>\d{4}):(?P<month>\d{2}):(?P<day>\d{2})( \d{2}:\d{2}:\d{2})?"
)


def parse_date(line):
    parsed = date_taken_re.search(line)
    parsed_types = {k: int(v) for k, v in parsed.groupdict().items()}
    return dt.date(**parsed_types)


@functools.cache
def get_date_path(date):
    year_path = photos_path / str(date.year)
    year_path.mkdir(parents=True, exist_ok=True)  # new year

    # Might exist already as date_string + textual name
    date_string = date.isoformat()
    for path in year_path.iterdir():
        if path.parts[-1].startswith(date_string):
            return path

    # Does not exist, create
    path = year_path / date_string
    path.mkdir()
    return path


def optimize(path):
    if path.suffix.lower() == ".png":
        subprocess.run(["oxipng", str(path)], check=True, capture_output=True)
        return True
    elif path.suffix.lower() in (".jpg", ".jpeg"):
        subprocess.run(
            ["jpegoptim", "--preserve", "--preserve-perms", str(path)],
            check=True,
            capture_output=True,
        )
        return True
    return False


if __name__ == "__main__":
    raise SystemExit(main())
