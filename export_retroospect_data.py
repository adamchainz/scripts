#!/usr/bin/env python3
import argparse
import csv
import json
import sys

import requests

parser = argparse.ArgumentParser(description='Export Retroospect data to csv on stdout.')
parser.add_argument('email_address', type=str, help='Login email address')
parser.add_argument('password', type=str, help='Login password')


def main():
    args = parser.parse_args()
    session = log_in(args.email_address, args.password)
    responses = fetch_responses(session)
    write_csv_out(responses)


def log_in(email_address, password):
    session = requests.Session()
    auth_resp = session.post(
        'https://api.retroospect.com/auth/email',
        headers={'content-type': 'application/json'},
        data=json.dumps({
            'email': email_address,
            'password': password,
        }),
    )
    token = auth_resp.json()['session']['token']
    session.headers.update({'authorization': token})
    return session


def fetch_responses(session):
    resp = session.get('https://api.retroospect.com/responses')
    responses = resp.json()['responses']
    responses.sort(key=lambda r: r['week'])
    return responses


def write_csv_out(responses):
    rows = [['week', 'submitted', 'enjoyment', 'stress', 'productivity', 'learning', 'team']]

    for response in responses:
        rows.append([
            response['week'],
            response['submitted'],
            response['values']['enjoyment'],
            response['values']['stress'],
            response['values']['productivity'],
            response['values']['learning'],
            response['values']['team'],
        ])

    writer = csv.writer(sys.stdout)
    writer.writerows(rows)


if __name__ == '__main__':
    main()
