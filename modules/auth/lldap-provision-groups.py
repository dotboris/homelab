import json
import logging
import os
import sys

import requests


logging.basicConfig(level=logging.INFO)


def main():
    groups = set(json.loads(os.environ["GROUPS"]))
    base_url = os.environ["BASE_URL"]
    username = os.environ["USERNAME"]
    password_file = os.environ["PASSWORD_FILE"]
    with open(password_file) as fh:
        password = fh.readline().strip()

    res = requests.post(
        f"{base_url}/auth/simple/login",
        json={
            "username": username,
            "password": password,
        },
    )
    res.raise_for_status()
    token: str = res.json()["token"]
    assert isinstance(token, str)

    res = requests.post(
        f"{base_url}/api/graphql",
        headers={"Authorization": f"Bearer {token}"},
        json={"query": "{ groups { displayName } }"},
    )
    res.raise_for_status()
    existing_groups = {g["displayName"] for g in res.json()["data"]["groups"]}
    todo = groups - existing_groups
    logging.info(f"found: {existing_groups}")
    logging.info(f"want: {groups}")
    logging.info(f"will create: {todo}")

    for group in todo:
        res = requests.post(
            f"{base_url}/api/graphql",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "query": """
                    mutation ($group: String!) {
                        createGroup(name: $group) { id }
                    }
                """,
                "variables": {"group": group},
            },
        )
        res.raise_for_status()
        logging.info(f"created {group}!")


if __name__ == "__main__":
    try:
        main()
    except requests.HTTPError as error:
        text = "(no response body)"
        if error.response is not None:
            text = error.response.text
        logging.exception(text)
        sys.exit(1)
