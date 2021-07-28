#!/usr/bin/env python
"""
Convert the Metrobank CSV to one ready for import into FreeAgent.
"""
import argparse
import csv
import datetime as dt
import sys
from decimal import Decimal


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("filename", type=str)
    args = parser.parse_args(argv)
    filename = args.filename

    with open(filename) as fp:
        reader = csv.reader(fp)
        writer = csv.writer(sys.stdout)
        iterator = iter(reader)
        # Skip header line
        next(iterator)

        for row in iterator:
            # Skip empty rows from blank lines
            if not row:
                continue

            (
                date_raw,
                reference,
                transaction_type,
                money_in,
                money_out,
                balance,
            ) = row

            date = dt.datetime.strptime(date_raw, "%d %B %Y").strftime("%d/%m/%Y")

            if money_in == "":
                money_in = "0"
            if money_out == "":
                money_out = "0"

            amount = str(Decimal(money_in) - Decimal(money_out))

            writer.writerow([date, amount, reference])

    return 0


if __name__ == "__main__":
    exit(main())
