#!/usr/bin/env python
"""
Convert the Metrobank CSV to one ready for import into FreeAgent.
"""
import csv
import sys
from decimal import Decimal


def main():
    filename = sys.argv[1]
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

            # The number of columns varies because Metrobank doesn't escape
            # commas in the reference. This fixes it.
            (
                date,
                *reference_fragments,
                transaction_type,
                money_in,
                money_out,
                balance,
            ) = row
            reference = ",".join(reference_fragments)
            if money_in == '':
                money_in = '0'
            if money_out == '':
                money_out = '0'
            amount = str(Decimal(money_in) - Decimal(money_out))

            writer.writerow([date, amount, reference])


if __name__ == "__main__":
    main()
