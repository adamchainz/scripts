#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "rich",
#     "urllib3",
# ]
# ///
import sys

import urllib3
from rich import print as rprint


def main():
    """
    Format an incoming diff of package updates into a list of links to
    changelogs.
    """
    out = []
    fail = False

    input = sys.stdin.read()
    if "--- ./uv.lock" in input:
        # uv.lock diff
        pkg = None
        for line in input.splitlines():
            if not line.startswith(' name = "'):
                continue

            pkg = line.split('"')[1]
            link = get_changelog_link(pkg)
            if link is None:
                fail = True
                continue

            out.append(f"* [{pkg}]({link}) - ")
    else:
        # requirements.txt diff
        for line in input.splitlines():
            if not line.startswith("+") or "==" not in line:
                continue

            pkg, *_ = line.lstrip("+").split("==")

            link = get_changelog_link(pkg)
            if link is None:
                fail = True
                continue

            out.append(f"* [{pkg}]({link}) - ")

    if fail:
        raise SystemExit(1)
    else:
        print("Changelogs:")
        print("")
        for line in out:
            print(line)


def get_changelog_link(pkg: str) -> str | None:
    link = links.get(pkg.lower())
    if link is None:
        # Use urllib3 to request JSON from PyPI and find the changelog link there
        response = urllib3.request(
            "GET", "https://pypi.python.org/pypi/{pkg}/json".format(pkg=pkg)
        )
        if response.status != 200:
            print("{pkg} not found on PyPI".format(pkg=pkg), file=sys.stderr)
            return None
        data = response.json()
        project_urls = data["info"]["project_urls"]
        if "Changelog" in project_urls:
            link = project_urls["Changelog"]
        else:
            rprint(
                f"[link=https://pypi.org/project/{pkg}]{pkg}[/link] changelog link unknown",
                file=sys.stderr,
            )
            return None
    return link


links = {
    "azure-core": "https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/core/azure-core/CHANGELOG.md",
    "billiard": "https://pypi.python.org/pypi/billiard",
    "botbuilder-core": "https://github.com/microsoft/botbuilder-python/releases",
    "botbuilder-schema": "https://github.com/microsoft/botbuilder-python/releases",
    "botframework-connector": "https://github.com/microsoft/botbuilder-python/releases",
    "botframework-streaming": "https://github.com/microsoft/botbuilder-python/releases",
    "boto": "http://docs.pythonboto.org/en/latest/#release-notes",
    "boto3": "https://github.com/boto/boto3/blob/develop/CHANGELOG.rst",
    "botocore": "https://github.com/boto/botocore/blob/develop/CHANGELOG.rst",
    "celery": "http://docs.celeryproject.org/en/latest/changelog.html",
    "dj-database-url": "https://github.com/jazzband/dj-database-url/blob/master/CHANGELOG.md",
    "django-filter": "https://github.com/carltongibson/django-filter/blob/master/CHANGES.rst",
    "django-htmlmin": "https://github.com/cobrateam/django-htmlmin/commits/master",
    "django-leaflet": "https://github.com/makinacorpus/django-leaflet/blob/master/CHANGES",
    "django-modeldict-yplan": "https://pypi.python.org/pypi/django-modeldict-yplan",
    "django-perf-rec": "https://pypi.python.org/pypi/django-perf-rec",
    "django-picklefield": "https://github.com/gintas/django-picklefield#changes",
    "django-q2": "https://github.com/django-q2/django-q2/blob/master/CHANGELOG.md",
    "django-recaptcha": "https://pypi.python.org/pypi/django-recaptcha#changelog",
    "django-reversion": "https://github.com/etianen/django-reversion/blob/master/CHANGELOG.rst",
    "django-schema-viewer": "https://github.com/pikhovkin/django-schema-viewer/commits/main/",
    "djangorestframework-gis": "https://github.com/openwisp/django-rest-framework-gis/blob/master/CHANGES.rst",
    "flake8": "https://flake8.readthedocs.io/en/latest/release-notes/3.2.1.html",
    "flake8-coding": "https://github.com/tk0miya/flake8-coding/blob/master/CHANGES.rst",
    "flake8-tidy-imports": "https://pypi.python.org/pypi/flake8-tidy-imports",
    "fonttools": "https://github.com/fonttools/fonttools/blob/main/NEWS.rst",
    "jinja2": "https://jinja.palletsprojects.com/en/stable/changes/",
    "kombu": "https://kombu.readthedocs.io/en/latest/changelog.html",
    "markdown": "https://github.com/waylan/Python-Markdown/blob/master/docs/change_log.txt",
    "matplotlib": "https://matplotlib.org/stable/users/release_notes",
    "mycli": "https://github.com/dbcli/mycli/blob/master/changelog.md",
    "pillow": "https://github.com/python-pillow/Pillow/blob/master/CHANGES.rst",
    "pipdeptree": "https://github.com/naiquevin/pipdeptree/blob/master/CHANGES.md",
    "prompt-toolkit": "https://github.com/jonathanslenders/python-prompt-toolkit/blob/master/CHANGELOG",
    "pycodestyle": "https://pypi.python.org/pypi/pycodestyle",
    "pyflakes": "https://github.com/PyCQA/pyflakes/blob/master/NEWS.txt",
    "pyparsing": "https://github.com/pyparsing/pyparsing/blob/master/CHANGES",
    "pytest": "http://docs.pytest.org/en/latest/changelog.html",
    "pytest-django": "https://pytest-django.readthedocs.io/en/latest/changelog.html",
    "pytest-randomly": "https://pypi.python.org/pypi/pytest-randomly",
    "raven": "https://github.com/getsentry/raven-python/blob/master/CHANGES",
    "redis": "https://github.com/redis/redis-py/releases",
    "regex": "https://bitbucket.org/mrabarnett/mrab-regex/commits/branch/default",
    "s3transfer": "https://github.com/boto/s3transfer/blob/develop/CHANGELOG.rst",
    "schema": "https://github.com/keleshev/schema/commits/master",
    "scipy": "https://docs.scipy.org/doc/scipy/release.html",
    "sentinelhub": "https://github.com/sentinel-hub/sentinelhub-py/blob/master/CHANGELOG.MD",
    "sqlparse": "https://sqlparse.readthedocs.io/en/latest/changes/",
    "tldextract": "https://github.com/john-kurkowski/tldextract/blob/master/CHANGELOG.md",
    "twilio": "https://github.com/twilio/twilio-python/blob/main/CHANGES.md",
    "ua-parser": "https://github.com/ua-parser/uap-python/commits/master",
    "vcrpy": "https://vcrpy.readthedocs.io/en/latest/changelog.html",
    "waitress": "https://github.com/Pylons/waitress/blob/master/CHANGES.txt",
    "webob": "https://webob.readthedocs.io/en/stable/changes.html",
}


if __name__ == "__main__":
    main()
