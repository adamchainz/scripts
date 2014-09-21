#!/usr/bin/env python
# coding=utf-8
from __future__ import print_function

import functools
import json
import os
import re
import sys

import IPython


def main():
    if len(sys.argv) != 2:
        print("Usage: {} filename.ipynb".format(sys.argv[0]))
        print("Will create filename.md.")
        return 1

    filename = sys.argv[1]
    notebook = json.load(open(filename))
    out_filename = os.path.splitext(filename)[0] + '.markdown'
    out = open(out_filename, 'w')
    write = functools.partial(print, file=out)

    cells = notebook['worksheets'][0]['cells']

    for cell in cells:
        if cell['cell_type'] == 'markdown':
            # Easy
            write(''.join(cell['source']))
        elif cell['cell_type'] == 'code':
            # Can't use ``` or any shortcuts as markdown fails for some code
            write("{% highlight ipy %}")

            write("In [{}]: {}".format(
                cell['prompt_number'],
                ''.join(cell['input'])
            ))

            try:
                assert all(o['output_type'] in ('stream', 'pyout', 'pyerr')
                           for o in cell['outputs'])
            except AssertionError as e:
                print(e)
                IPython.embed()

            for output in cell['outputs']:
                if output['output_type'] == 'pyout':
                    write("Out[{}]: {}".format(
                        cell['prompt_number'],
                        ''.join(output['text'])
                    ))
                elif output['output_type'] == 'stream':
                    write(''.join(output['text']))
                elif output['output_type'] == 'pyerr':
                    write('\n'.join(strip_colors(o)
                                    for o in output['traceback']))
                else:
                    print(output)
                    IPython.embed()

            write("{% endhighlight %}")
        write("")

    print("{} created.".format(out_filename))


ansi_escape = re.compile(r'\x1b[^m]*m')


def strip_colors(string):
    return ansi_escape.sub('', string)


if __name__ == '__main__':
    main()
