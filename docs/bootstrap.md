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

We can generate the config from the running installer:

```sh
ssh root@nixos-installer nixos-generate-config --root --no-filesystems --dir .
mkdir -p ./hosts/{your-host}
scp root@nixos-installer:hardware-configuration.nix ./hosts/{your-host}/
scp root@nixos-installer:configuration.nix ./hosts/{your-host}/
git add --intent-to-add .
```

Once this is in place, add your configuration in `flake.nix`:

```nix
nixosConfigurations = {
  # ...
  {your-host} = nixpkgs.lib.nixosSystem {
    inherit system pkgs;
    specialArgs = {inherit inputs;};
    modules = [
      self.nixosModules.default
      ./hosts/{your-host}/configuration.nix
    ];
  };
};
```

## Configure disk formatting

The disk setup is based on [disko](https://github.com/nix-community/disko). It
lets use define the disks, partitions & formatting declaratively.

Create `hosts/{your-host}/disk-config.nix` and define how you want the disks to
be formatted. This will depend on the system and what you need. See the [disko
examples](https://github.com/nix-community/disko/tree/master/example).

You can test it like so:

```sh
scp ./hosts/{your-host}/disk-config.nix root@nix-installer:
ssh root@nix-installer
# THIS WILL ERASE THE DISK! BEWARE! MAKE SURE YOU'RE ON THE RIGHT MACHINE!
disko -m disko ./disk-config.nix
```

When everything works as expected, import `./disk-config.nix` in your
`configuration.nix` file.

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

## Setup further deployments

Once the host is bootstrapped, we need to set things up so that we can deploy
changes to it.

Add the following to your `flake.nix`:

```nix
deploy.nodes = {
  {your-host} = {
    hostname = "{your-host-ip}";
    profiles.system = {
      user = "root";
      sshUser = "dotboris";
      interactiveSudo = true;
      fastConnection = true;
      path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.{your-host};
    };
  };
};
```

Once that's done, simply run:

```sh
deploy .#{your-host}
```
