#!/usr/bin/env python
from __future__ import print_function
import subprocess
import sys


def main():
    if len(sys.argv) != 2:
        print("1 arg - operation to apply to files selected in Finder")
        return 1

    operation = sys.argv[1].lower()
    command = commands[operation]

    for filename in finder_filenames():
        runnable = command.format(filename=filename.strip())
        print(subprocess.check_output(runnable, shell=True))

    return 0


def make_command(args):
   return "/usr/local/bin/convert '{filename}' " + args + " '{filename}'"

commands = {
    "normalize": make_command('-normalize'),
    "rotate_clockwise": make_command('-rotate 90'),
}


finder_selection = """
    osascript <<EOF
        set output to ""
        tell application "Finder" to set the_selection to selection
        set item_count to count the_selection
        repeat with item_index from 1 to count the_selection
          if item_index is less than item_count then set the_delimiter to "\\n"
          if item_index is item_count then set the_delimiter to ""
          set output to output & ((item item_index of the_selection as alias)'s POSIX path) & the_delimiter
        end repeat
EOF"""


def finder_filenames():
    return subprocess.check_output(finder_selection, shell=True) \
                     .strip() \
                     .split('\n')

if __name__ == '__main__':
    exit(main())
