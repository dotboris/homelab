# Bootstrap a new Host

Bootstrapping a new host is a bit of a chicken and egg dance. This is because of
the secrets. They need to be encrypted for the given host but the host doesn't
exist yet.

## Boot the installer ISO

First, you need to build the installer ISO and boot it on the machine in
question. You can build the ISO like so:

```sh
nix build -L .#installer-iso
```

This will put the installer ISO in `./result/iso/...`. If you're dealing with a
VM, you can set that as the ISO for the virtual CD drive. If it's a real
machine, you can throw it on a USB drive. Something like Ventoy makes this easy.

Once the host boots into the installer ISO, you'll see a screen with network
information and the root password.

Make sure it's connected to the network, you can `Ctrl + C` access the shell and
connect to the network. Once you're done, hit `Ctrl + D` and you'll be back to
the previous screen.

To make sure that everything works, try connecting to the host using SSH.

```sh
ssh root@nixos-installer echo hello world
```

## Generate the base configuration

Create a `hosts/{your-host}` directory and add the following files:

```nix
# hosts/{your-host}/configuration.nix
{config, ...}: {
  flake.hosts.{your-host} = {
    # TODO: replace this with the hostname when DNS is working correctly
    hostname = "{your host's ip address}";
    system = "x86_64-linux";
    module = {...}: {
      imports = [config.flake.modules.nixos.default];

      # the rest of your config will go here
    };
  };
}

# hosts/{your-host}/hardware-configuration.nix
{...}: {
  flake.hosts.{your-host}.module = {...}: {
    # the generated hardware config will go here
  };
}

# hosts/{your-host}/disk-config.nix
{...}: {
  flake.hosts.{your-host}.module = {...}: {
    # your disko config will go here
  };
}
```

We can generate the config from the running installer:

```sh
ssh root@nixos-installer nixos-generate-config --root --no-filesystems --dir .
```

These will be in the home directory of the installer. Copy-paste the content of
`configuration.nix` and `hardware-configuration.nix` into the files you just
created. Remember to keep the `flake.hosts.{...}` structure.

## Configure disk formatting

The disk setup is based on [disko](https://github.com/nix-community/disko). It
lets use define the disks, partitions & formatting declaratively.

Open `hosts/{your-host}/disk-config.nix` and define how you want the disks to be
formatted. This will depend on the system and what you need. See the [disko
examples](https://github.com/nix-community/disko/tree/master/example). Remember
to keep the `flake.hosts.{your-host}` structure.

Since every disk setup is different, you may need to do some trial and error.
The installer has disko pre-installed. You'll be able to test things out by
running your disko config in the installer through SSH and checking the results.
For this to work, you'll need to strip out the `flake.hosts.{your-host}`
structure.

## Setup Secrets

First, you'll need to generate an encryption key for the host. You can generate
the key with:

```sh
ssh-keyscan nixos-installer | ssh-to-age
```

Copy that key and add it to `.sops.yaml` under the `keys: ...` array. Be sure to add an alias for it. It should look something like this:

```yml
keys:
  # ...
  - &host-{your-host} {your key}
```

Add an entry in `.sops.yaml` for a new secrets file:

```yml
creation_rules:
  # ...
  - path_regex: '^hosts/{your-host}/secrets.sops.yaml$'
    key_groups:
      - age:
          - *admin-dotboris
          - *host-{your-host}
```

You can then create your secrets file with:

```sh
sops hosts/{your-host}/secrets.sops.yaml
```

Finally, add the following to your `configuration.nix`:

```nix
sops = {
  defaultSopsFile = ./secrets.sops.yaml;

  # Generate an age key based on our SSH host key.
  age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  gnupg.sshKeyPaths = []; # Turn off GPG key gen
};
```

## Perform the Install

The actual installation process is handled by
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere).

```sh
git add --intent-to-add . # make sure nix knows about your new files
nixos-anywhere --copy-host-keys --flake .#{your-host} root@nixos-installer
```

The `--copy-host-keys` flag is very important here. It takes the SSH host keys
from the running installer ISO and copies them over to the newly installed NixOS
system. This ensures that the secrets we previously encrypted can still be read
when the system is fully installed.

## Wrapping up

Once DNS works and you can reach your host through its hostname, open
`hosts/{your-host}/configuration.nix` and update
`flake.hosts.{your-host}.hostname` to use your hosts's DNS name.

With that, you should be able to run a few final tests:

- `nix flake check -L`
- `nix run .#deploy-{your-host}`

