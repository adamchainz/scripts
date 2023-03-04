#!/usr/bin/env python
import argparse
import datetime as dt
import functools
import re
import shutil
import subprocess
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

    for path in media():
        process(path, actually_move)
    return 0


def process(path, actually_move):
    out = blue(path.relative_to(iphone_path)) + " "

    date_taken = get_date_taken(path)
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


def get_date_taken(path):
    output = subprocess.run(
        ["exiftool", str(path)], capture_output=True, text=True, check=True
    ).stdout

    values = {}
    for line in output.split("\n"):
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip()

    # Exif date taken
    if path.suffix.lower() == ".mov":
        exif_field_names = ("Media Create Date", "File Modification Date/Time")
    else:
        exif_field_names = ("Date/Time Original", "Create Date", "Date Created")
    exif_values = []
    for field in exif_field_names:
        if values.get(field, None) not in (None, "0000:00:00 00:00:00"):
            exif_values.append(values[field])
    if exif_values:
        return min(parse_date(v) for v in exif_values)

    modification = parse_date(values["File Modification Date/Time"])
    if modification < dt.date.today():
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
            ["jpegoptim", str(path)],
            check=True,
            capture_output=True,
        )
        return True
    return False


if __name__ == "__main__":
    raise SystemExit(main())
