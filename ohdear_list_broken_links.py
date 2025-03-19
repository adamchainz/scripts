#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "httpx",
#     "rich",
# ]
# ///
import os
from typing import Any
import httpx
from rich.console import Console
from rich.table import Table


def call_ohdear_api(endpoint: str) -> list[dict[str, Any]]:
    base_url = "https://ohdear.app/api"
    headers = {
        "Authorization": f"Bearer {os.environ['OHDEAR_API_TOKEN']}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }
    response = httpx.get(f"{base_url}/{endpoint}", headers=headers)
    response.raise_for_status()
    return response.json()["data"]


def fetch_sites() -> list[dict[str, Any]]:
    return call_ohdear_api("sites")


def fetch_broken_links(site_id: int) -> list[dict[str, Any]]:
    return call_ohdear_api(f"broken-links/{site_id}")


def main() -> int:
    console = Console()
    sites = fetch_sites()
    for site in sites:
        site_name = site["url"]
        site_id = site["id"]
        broken_links = fetch_broken_links(site_id)

        table = Table(title=site_name)
        table.add_column("Found On", style="cyan")
        table.add_column("Broken Link", style="magenta")
        table.add_column("Status Code", style="red")

        for link in broken_links:
            table.add_row(
                link["relative_found_on_url"],
                link["crawled_url"],
                str(link["status_code"]),
            )

        console.print(table)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
