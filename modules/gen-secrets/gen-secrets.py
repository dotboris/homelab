import json
import os
from pathlib import Path
import secrets
import string


def main():
    spec = json.loads(os.environ["GEN_SECRETS_SPEC"])
    size = spec["size"]
    assert isinstance(size, int)
    mode = int(spec["mode"], 8)
    typ = spec["type"]
    path = Path(spec["path"])
    name = spec["name"]

    if path.exists():
        print(f"Secret {name} already exists")
        return

    print(f"Generating {name} secret")

    secret: bytes = b""
    if typ == "password":
        alphabet = string.ascii_letters + string.digits + string.punctuation
        secret = bytes(
            "".join(secrets.choice(alphabet) for _ in range(size)),
            encoding="utf-8",
        )
    else:
        raise ValueError(f"Unsupported secret type {typ}")

    path.touch(mode)
    _ = path.write_bytes(secret)
    print(f"Wrote secret to {path}")


if __name__ == "__main__":
    main()
