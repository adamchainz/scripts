#!/usr/bin/env python
import argparse
import datetime as dt
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

    # Keep recent photos in the iPhone directory
    recent_cutoff = dt.date.today() - dt.timedelta(days=30)

    for path in media():
        print(blue(path.relative_to(iphone_path)), end=" ")

        if path.suffix.lower() == ".png":
            subprocess.run(
                ["oxipng", str(path)], check=True, capture_output=True
            )
            print("✔", end=" ")
        elif path.suffix.lower() in (".jpg", ".jpeg"):
            subprocess.run(
                ["jpegoptim", str(path)], check=True, capture_output=True
            )
            print("✔", end=" ")

        date_taken = get_date_taken(path)
        if date_taken is None:
            print(red("😓  Could not find date/time"))
            continue
        print("@", date_taken, end=" ")

        if date_taken >= recent_cutoff:
            print(blue("recent, leaving in place."))
            continue

        destination_path = get_date_path(date_taken) / path.name
        dest_display = blue(destination_path.relative_to(photos_path).parent)
        if not actually_move:
            print("would move to", dest_display)

        if actually_move:
            print("->", dest_display)
            shutil.move(path, destination_path)
            if path.suffix.lower() in (".jpg", ".jpeg"):
                iphone_aae_path = path.with_suffix(".aae")
                if iphone_aae_path.exists():
                    print(blue("\t🗑️ iPhone photo edits AAE file"))
                    shutil.move(iphone_aae_path, trash_path)


FILE_EXTENSIONS = {".avi", ".jpg", ".jpeg", ".mov", ".mp4", ".png"}


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
    lines = output.split("\n")

    exif_date_taken = get_exif_date_taken(path, lines)
    if exif_date_taken:
        return exif_date_taken

    file_date_taken = get_file_date_taken(lines)
    if file_date_taken:
        return file_date_taken

    return None


def get_exif_date_taken(path, lines):
    if path.suffix.lower() == ".mov":
        exif_field_names = ("Media Create Date", "File Modification Date/Time")
    else:
        exif_field_names = ("Date/Time Original",)

    lines = [line for line in lines if line.startswith(exif_field_names)]
    if not lines:
        return None
    return min(extract_datetime(line) for line in lines)


def get_file_date_taken(lines):
    lines = [line for line in lines if "File Modification Date/Time" in line]
    if not lines:
        return None
    return extract_datetime(lines[0])


def extract_datetime(line):
    parsed = date_taken_re.search(line)
    parsed_types = {k: int(v) for k, v in parsed.groupdict().items()}
    return dt.date(**parsed_types)


date_taken_re = re.compile(
    r"(?P<year>\d{4}):(?P<month>\d{2}):(?P<day>\d{2}) \d{2}:\d{2}:\d{2}"
)


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


if __name__ == "__main__":
    raise SystemExit(main())
