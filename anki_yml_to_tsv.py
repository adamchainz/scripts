#!/usr/bin/env python
# -*- encoding:utf-8 -*-
"""
Converts all '.yml' files in this directory into '.tsv' files, deleting all
existing '.tsv' files first. Uses a very specific yaml format - used for
writing multiline cards for Anki easily.

Your yaml should look like this:

- "Some phrase for the front, or prompt, of the card"
- "Some answer on the back"
---
- "Another card"
- "yup."
---

Run the script, then import the TSVs using the usual anki import file function.
"""
from __future__ import unicode_literals

from pathlib import Path
import yaml


def main():
    for p in Path().glob('*.tsv'):
        p.unlink()
    for yml_path in Path().glob("*.yml"):
        convert(yml_path)


def convert(yml_path):
    print "Converting", yml_path
    text = yml_path.open('r', encoding='utf8').read()

    all_docs = [doc for doc in yaml.load_all(text)
                if isinstance(doc, list) and len(doc)]

    if not len(all_docs):
        print "\tEmpty."
        return

    print "\t", len(all_docs), "note[s]."
    tsv_path = yml_path.with_suffix('.tsv')
    with tsv_path.open('w') as tsv:
        for doc in all_docs:
            tsv.write(lineify(doc))


def lineify(doc):
    if len(doc) == 0:
        return ""

    assert len(doc) == 2, doc

    front = unicode(doc[0]).replace('\n', '<br>').strip()
    back = unicode(doc[1]).replace('\n', '<br>').strip()
    return "{}\t{}\n".format(front, back)

if __name__ == '__main__':
    main()
