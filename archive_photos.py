#!/usr/bin/env python3
import datetime as dt
import os
import re
import shutil
import subprocess
import sys

from termcolor import colored

iphone_dir = os.path.expanduser('~/Arqbox/Aart/Photos/iPhone')
photo_dir = os.path.expanduser('~/Arqbox/Aart/Photos')
trash = os.path.expanduser('~/.Trash')

blue = lambda x: colored(x, 'blue')
red = lambda x: colored(x, 'red')


def main():
    thirty_days_ago = dt.date.today() - dt.timedelta(days=30)
    for filename in old_photos():
        print(filename)
        date_taken = get_date_taken(filename)
        if date_taken is None:
            print(red('\t😓  No DateTimeOriginal'))
            continue

        if date_taken > thirty_days_ago:
            print(blue('\tWas taken < 30 days ago, leaving'))
            continue

        destination_dir = get_date_dir(date_taken)
        print(blue('\tMoving to {}'.format(destination_dir)))

        destination_filename = os.path.join(destination_dir, os.path.basename(filename))
        os.rename(filename, destination_filename)


def old_photos():
    for filename in os.listdir(iphone_dir):
        if filename.lower().endswith(('.jpg', '.jpeg', '.mov')) and not os.path.islink(filename):
            yield os.path.join(iphone_dir, filename)


def get_date_taken(filename):
    output = subprocess.check_output(
        ['exiftool', filename],
        universal_newlines=True,
    )
    if filename.lower().endswith('.mov'):
        exif_field_name = 'Media Create Date'
    else:
        exif_field_name = 'Date/Time Original'
    lines = [line for line in output.split('\n') if exif_field_name in line]
    if not lines:
        return None
    parsed = date_taken_re.search(lines[0])
    parsed_types = {k: int(v) for k, v in parsed.groupdict().items()}
    return dt.date(**parsed_types)


date_taken_re = re.compile(r'(?P<year>\d{4}):(?P<month>\d{2}):(?P<day>\d{2}) \d{2}:\d{2}:\d{2}')


def get_date_dir(date):
    year_folder = os.path.join(photo_dir, str(date.year))
    os.makedirs(year_folder, exist_ok=True)  # Just in case it's a new year

    # Might exist already as date_string + textual name
    date_string = date.isoformat()
    for name in os.listdir(year_folder):
        if name.startswith(date_string):
            return os.path.join(year_folder, name)

    # Does not exist, create
    basic_path = os.path.join(year_folder, date_string)
    os.makedirs(basic_path, exist_ok=True)
    return basic_path


if __name__ == '__main__':
    main()
