# Secrets

This repo needs to handle secrets. These are passwords, credentials and the like that need to remain secret. The challenge is that this repository is public so keeping these secrets secret is harder said than done.

[SOPS][sops] is used to manage the secrets. They are stored in the repository in an encrypted state. There are 3 main layers that makes this all work:

- The secrets files: `hosts/*/secrets.sops.yaml`
- The SOPS configuration file: `.sops.yaml`
- The [`sops-nix`][sops-nix] module

The secrets file hold the secrets. They're written in YAML and all the values & comments are encrypted. The [SOPS][sops] configuration file, defines which keys are allowed to encrypt / decrypt those secrets. This varies per host. They normally are:

- The age key of the target host so that it can decrypt and use the secrets.
- My personal age key so that I can make changes to the secrets.
- A backup age key in case I lose my age key somehow.

The [`sops-nix`][sops-nix] module configures NixOS to allow it to decrypt the secrets and make them available to different modules, services and applications. This module uses the server's SSH key to derive the age key used to decrypt the secrets.

## Backup Key

The backup key is a separate age key stored in my backup vault. It's there to ensure that I can access the secrets in case I lose access to my primary age key. It is stored in my personal password vault.

Here's how to use the backup key:

1. Edit `~/.config/sops/age/keys.txt`
1. Add the backup key as a line to that file
1. Save the file
1. Use whatever `sops ...` commands you need
1. When you're done, remove the key from the `~/.config/sops/age/keys.txt` file.

The backup key should only be used to add a new key to the secrets. It should never become the primary key used to manipulate the secrets.

## Adding a New Key

First, you'll need to configure your key in `.sops.yaml`:

1. Under `keys:` add your public age key: `- &alias age...`
1. For each applicable creation rule, add the key to the key groups

Here's what it looks like all put together:

```yaml
keys:
  - &my-key-alias age...
  - ... # other keys

creation_rules:
  - path_regex: '^hosts/.../secrets.sops.yaml$'
    key_groups:
      - age:
          - *my-key-alias
          - ... # other keys
```

Then, you need to update they keys in the secrets files. Do this for every affected secret file.

```sh
sops updatekeys hosts/.../secrets.sops.yaml
```

Finally, deploy to the affected hosts.

[sops]: https://github.com/getsops/sops
[sops-nix]: https://github.com/Mic92/sops-nix
