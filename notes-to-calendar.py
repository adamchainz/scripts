#!/usr/bin/env python
import codecs
import json
import re
import subprocess
import sys

import dateutil.parser
from sh import lifelogger
from lxml.html import document_fromstring


def main():
    path = sys.argv[1]

    notes = load_notes(path)

    export_weights(notes)

    export_inhalers(notes)


def load_notes(path):
    with codecs.open(path, 'r') as f:
        notedata = f.read().decode('utf-8', 'replace')

    notedata = notedata.replace('\t', ' ')

    import IPython; IPython.embed()

    notes = json.loads(notedata)

    for note in notes:
        body = note['body'].replace('<br>', '\n ')
        body = document_fromstring(body).text_content()
        body = body.strip()
        note['body'] = body

        note['when'] = dateutil.parser.parse(note['creationDate'])

    return notes


weights_re = re.compile("""
    ^
    (Chest\ press|
     Pec\ fly|
     Seated\ row|
     Pull\ down|
     Seated\ curl|
     Leg\ extension|
     Shoulder\ press|
     Leg\ Press[2]?)
    \s+
    (\d+)kg
    \s+
    (\d+)s  # time
    \s*
    $
""", re.VERBOSE | re.IGNORECASE)


def export_weights(notes):
    for note in notes:
        body = note['body']
        match = weights_re.match(body)
        if match:
            print note
            import ipdb; ipdb.set_trace()
            exercise, weight, seconds = match.groups()

            save_weights_event(exercise, weight, seconds, note['when'])
            archive_note(note['id'])


def save_weights_event(exercise, weight, seconds, when):
        event = "{} {}kg seconds={} #exercise".format(
            exercise, weight, seconds)

        print lifelogger('add', '--start', when.isoformat(), event).strip()


def export_inhalers(notes):
    event = 'Clenil Modulite 200mcg #drugs'
    for note in notes:
        if note['body'].lower() == 'cm':
            print note
            print lifelogger('add', '--start', note['when'].isoformat(), event)
            archive_note(note['id'])

def export():
    pass


def archive_note(note_id):
    subprocess.check_output("""
    osascript <<EOF
    tell application "Notes"
        set m to (every note whose id is "{}")
        move (item 1 of m) to folder "Archive"
    end tell
    EOF""".format(note_id), shell=True)


if __name__ == '__main__':
    main()
