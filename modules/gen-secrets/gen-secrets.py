from dataclasses import dataclass
import grp
import json
import os
from pathlib import Path
import pwd
import secrets
import string
from typing import Any


@dataclass()
class Spec:
    name: str
    typ: str
    size: int
    path: Path
    mode: int
    owner: str
    group: str

    @classmethod
    def parse(cls, raw: dict[str, Any]):
        return cls(
            name=raw["name"],
            typ=raw["type"],
            size=raw["size"],
            path=Path(raw["path"]),
            mode=int(raw["mode"], 8),
            owner=raw["owner"],
            group=raw["group"],
        )

    def uid(self):
        return pwd.getpwnam(self.owner).pw_uid

    def gid(self):
        return grp.getgrnam(self.group).gr_gid


def create_secret(spec: Spec):
    if spec.path.exists():
        print(f"Secret {spec.name} already exists")
        return

    print(f"Generating {spec.name} secret")

    secret: bytes = b""
    if spec.typ == "password":
        alphabet = string.ascii_letters + string.digits + string.punctuation
        secret = bytes(
            "".join(secrets.choice(alphabet) for _ in range(spec.size)),
            encoding="utf-8",
        )
    else:
        raise ValueError(f"Unsupported secret type {spec.typ}")

    _ = spec.path.write_bytes(secret)
    print(f"Created secret {spec.path}")


def main():
    spec = Spec.parse(json.loads(os.environ["GEN_SECRETS_SPEC"]))

    create_secret(spec)

    os.chmod(spec.path, spec.mode)
    os.chown(spec.path, spec.uid(), spec.gid())


if __name__ == "__main__":
    main()
