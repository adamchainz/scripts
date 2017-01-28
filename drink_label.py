#!/usr/bin/env python3
"""
Emulate the output of 'brew info' for labelling drinks
"""
from termcolor import cprint


def main():
    cprint('$ brew info cider')
    cprint('cider: 1.0.0 (bottled)')
    cprint('A fermented apple juice beverage.')
    cprint('Created by Adam & Marie 2017-01-27')

    cprint('==> ', 'blue', attrs=['bold'], end='')
    cprint('Dependencies', attrs=['bold'])
    cprint('Digestive System')
    cprint('Sense of Taste')
    cprint('Alcohol Dehydrogenase')

    cprint('==> ', 'blue', attrs=['bold'], end='')
    cprint('Installation Instructions', attrs=['bold'])
    cprint('1. Remove cap')
    cprint('2. Place at lips')
    cprint('3. Tilt back and swallow')

    cprint('==> ', 'blue', attrs=['bold'], end='')
    cprint('Caveats', attrs=['bold'])
    cprint('Should probably be drunk before 2017-02-19')


if __name__ == '__main__':
    main()
