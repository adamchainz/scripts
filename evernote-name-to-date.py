#!/usr/bin/env python
# -*- coding:utf-8 -*-
from __future__ import (absolute_import, division, print_function,
                        unicode_literals)

import re
import sys
import datetime as dt


date_re = re.compile(
    r'\b(?P<year>\d\d\d\d)-(?P<month>\d\d)-(?P<day>\d\d)\b',
)


def main():
    stdin = sys.stdin.read()
    match = date_re.search(stdin)
    if not match:
        print('No date found', file=sys.stderr)
    else:
        when = dt.date(
            year=int(match.group('year')),
            month=int(match.group('month')),
            day=int(match.group('day')),
        )
        print(when.strftime(r'%d %B %Y'))


if __name__ == '__main__':
    main()
