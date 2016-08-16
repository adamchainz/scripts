#!/usr/bin/env python3
import re
import sys


def main():
    code = sys.stdin.read().strip()
    code = code.replace('{', 'OrderedDict([')
    code = code.replace('}', '])')
    code = re.sub(r"('[^']+'):\s+(\d+\.\d+)(,?)", r"(\1, \2)\3", code)
    print(code)


if __name__ == '__main__':
    main()
