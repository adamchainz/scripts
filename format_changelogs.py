#!/usr/bin/env python
import sys


def main():
    out = []
    fail = False

    for line in sys.stdin.readlines():
        pkg, *_ = line.split(" ")

        if pkg not in links:
            print("{pkg} link unknown".format(pkg=pkg), file=sys.stderr)
            fail = True
        else:
            out.append("* [[ {link} | {pkg} ]] - ".format(link=links[pkg], pkg=pkg))

    if fail:
        raise SystemExit(1)
    else:
        print("Changelogs:")
        print("")
        for line in out:
            print(line)


links = {
    "billiard": "https://pypi.python.org/pypi/billiard",
    "boto": "http://docs.pythonboto.org/en/latest/#release-notes",
    "boto3": "https://github.com/boto/boto3/blob/develop/CHANGELOG.rst",
    "botocore": "https://github.com/boto/botocore/blob/develop/CHANGELOG.rst",
    "celery": "http://docs.celeryproject.org/en/latest/changelog.html",
    "django-filter": "https://github.com/carltongibson/django-filter/blob/master/CHANGES.rst",
    "django-htmlmin": "https://github.com/cobrateam/django-htmlmin/commits/master",
    "django-modeldict-yplan": "https://pypi.python.org/pypi/django-modeldict-yplan",
    "django-perf-rec": "https://pypi.python.org/pypi/django-perf-rec",
    "django-recaptcha": "https://pypi.python.org/pypi/django-recaptcha#changelog",
    "django-reversion": "https://github.com/etianen/django-reversion/blob/master/CHANGELOG.rst",
    "flake8": "https://flake8.readthedocs.io/en/latest/release-notes/3.2.1.html",
    "flake8-coding": "https://github.com/tk0miya/flake8-coding/blob/master/CHANGES.rst",
    "flake8-tidy-imports": "https://pypi.python.org/pypi/flake8-tidy-imports",
    "kombu": "https://kombu.readthedocs.io/en/latest/changelog.html",
    "Markdown": "https://github.com/waylan/Python-Markdown/blob/master/docs/change_log.txt",
    "mycli": "https://github.com/dbcli/mycli/blob/master/changelog.md",
    "Pillow": "https://github.com/python-pillow/Pillow/blob/master/CHANGES.rst",
    "pipdeptree": "https://github.com/naiquevin/pipdeptree/blob/master/CHANGES.md",
    "prompt-toolkit": "https://github.com/jonathanslenders/python-prompt-toolkit/blob/master/CHANGELOG",
    "pycodestyle": "https://pypi.python.org/pypi/pycodestyle",
    "pyflakes": "https://github.com/PyCQA/pyflakes/blob/master/NEWS.txt",
    "pytest": "http://docs.pytest.org/en/latest/changelog.html",
    "pytest-django": "https://pytest-django.readthedocs.io/en/latest/changelog.html",
    "pytest-randomly": "https://pypi.python.org/pypi/pytest-randomly",
    "raven": "https://github.com/getsentry/raven-python/blob/master/CHANGES",
    "regex": "https://bitbucket.org/mrabarnett/mrab-regex/commits/branch/default",
    "s3transfer": "https://github.com/boto/s3transfer/blob/develop/CHANGELOG.rst",
    "schema": "https://github.com/keleshev/schema/commits/master",
    "sqlparse": "https://sqlparse.readthedocs.io/en/latest/changes/",
    "tldextract": "https://github.com/john-kurkowski/tldextract/blob/master/CHANGELOG.md",
    "ua-parser": "https://github.com/ua-parser/uap-python/commits/master",
    "vcrpy": "https://vcrpy.readthedocs.io/en/latest/changelog.html",
    "waitress": "https://github.com/Pylons/waitress/blob/master/CHANGES.txt",
    "WebOb": "https://webob.readthedocs.io/en/stable/changes.html",
}


if __name__ == "__main__":
    main()
