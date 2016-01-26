#!/bin/zsh
/usr/local/bin/http get 'http://www.odeon.co.uk/showtimes/day/?date=2016-01-30&siteId=105&filmMasterId=100876&container=DAY8&type=DAY' | grep 'not been programmed' >/dev/null && echo "wait" || echo "BUY H8FUL"
