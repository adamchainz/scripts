#!/usr/bin/env python
import dateutil.parser
import re
import subprocess
import sys


def turn_current_photo_into_calendar_event(event_description):
    filename = subprocess.check_output("""
    osascript <<EOF
    tell application "iPhoto"
        set the_images to the selection
        set the_image to item 1 of the_images
        if the class of item 1 of the_image is album then error
        set the_path to the image path of the_image
        return the_path
    end tell
    EOF""", shell=True).strip()

    date = get_photo_date(filename)

    print subprocess.check_output(
        "lifelogger add --start '%s' '%s'" % (
            date.isoformat(), event_description),
        shell=True
    )

    subprocess.check_output("""
    osascript <<EOF
    tell application "iPhoto"
        set the_images to the selection
        set the_image to item 1 of the_images
        remove the_image
    end tell
    EOF""", shell=True).strip()


def get_photo_date(filename):
    output = subprocess.check_output(['identify', '-verbose', filename])
    line = [line for line in output.split('\n')
            if 'exif:DateTimeOriginal:' in line]
    line = line[0]
    datetime_string = re.search(r'\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}', line) \
                        .group(0)
    datetime_string = datetime_string.replace(':', '-', 2)
    return dateutil.parser.parse(datetime_string)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Need event description"
        sys.exit(1)
    turn_current_photo_into_calendar_event(sys.argv[1])
