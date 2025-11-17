#!/usr/bin/env uv run --script
# /// script
# requires-python = ">=3.14"
# ///
"""
CLI tool to manage GitHub branch protection required status checks.

Usage:
    gh-branch-protection-checks.py remove <branch> <check-name>
"""

import argparse
import json
import subprocess
import sys


def gh_api(query, variables=None):
    cmd = [
        "gh",
        "api",
        "graphql",
        "-f",
        f"query={query}",
        "-F",
        "owner={owner}",
        "-F",
        "repo={repo}",
    ]
    if variables:
        for key, value in variables.items():
            if isinstance(value, list):
                for item in value:
                    cmd.extend(["-f", f"{key}[]={item}"])
            else:
                cmd.extend(["-f", f"{key}={value}"])

    result = subprocess.run(cmd, stdout=subprocess.PIPE, text=True)
    if result.returncode != 0:
        sys.exit(result.returncode)
    return json.loads(result.stdout)


def get_branch_rule(branch_name):
    query = """
    query ($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        branchProtectionRules(first: 10) {
          nodes {
            pattern
            id
            requiredStatusCheckContexts
          }
        }
      }
    }
    """

    response = gh_api(query)
    rules = response["data"]["repository"]["branchProtectionRules"]["nodes"]

    branch_rules = [r for r in rules if r["pattern"] == branch_name]

    if len(branch_rules) == 0:
        return None
    elif len(branch_rules) > 1:
        print(
            f"Error: Multiple branch protection rules found for '{branch_name}'",
            file=sys.stderr,
        )
        for r in branch_rules:
            print(
                f"- Rule ID: {r['id']}, Checks: {r['requiredStatusCheckContexts']}",
                file=sys.stderr,
            )
        sys.exit(1)

    return branch_rules[0]


def update_required_checks(rule_id, updated_checks):
    mutation = """
    mutation($ruleId: ID!, $checks: [String!]) {
      updateBranchProtectionRule(input: {
        branchProtectionRuleId: $ruleId
        requiredStatusCheckContexts: $checks
      }) {
        branchProtectionRule {
          pattern
          requiredStatusCheckContexts
        }
      }
    }
    """

    gh_api(mutation, {"ruleId": rule_id, "checks": updated_checks})


def remove_check(branch_name, check_name):
    rule = get_branch_rule(branch_name)

    if rule is None:
        print(f"No branch protection rule found for '{branch_name}'", file=sys.stderr)
        sys.exit(0)

    rule_id = rule["id"]
    required_checks = rule["requiredStatusCheckContexts"]

    if check_name not in required_checks:
        print(f"{check_name} not in the required status checks", file=sys.stderr)
        sys.exit(0)

    updated_checks = [check for check in required_checks if check != check_name]

    update_required_checks(rule_id, updated_checks)

    print(f"Successfully removed {check_name} from required status checks.")


def main():
    parser = argparse.ArgumentParser(
        description="Manage GitHub branch protection required status checks"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    remove_parser = subparsers.add_parser(
        "remove", help="Remove a required status check"
    )
    remove_parser.add_argument("branch", help="Branch name")
    remove_parser.add_argument("check_name", help="Name of the status check to remove")

    args = parser.parse_args()

    if args.command == "remove":
        remove_check(args.branch, args.check_name)


if __name__ == "__main__":
    main()
