# Home Lab

My personal Home Lab / Home Server powered by Nix

## Test VM

To test things out, you can install the Home Lab config into a test VM. 

### Setup

These instructions will guide you on how to create a test VM and install a test
version of the Home Lab to it.

1. Build an installer iso: `nix build -L .#installer-iso`
1. In `libvirt`, create a Linux VM. Most of the default settings should just
   work. Make sure you set the boot ISO to
   `./result/iso/nixos-installer-x86_64-linux.iso`.
1. Boot the VM. It'll eventually land on a page showing you network information
1. Install NixOS using `nixos-anywhere`: 

    ```sh
    nixos-anywhere --flake .#homelab-test root@nixos-installer.local
    ```

### Testing web apps

First, figure out the IP address of your VM:

```sh
virsh -c qemu:///system net-dhcp-leases default
```

Open you system `/etc/hosts` file and add the following values:

```
# Homelab dev
{VM IP Address} home.dotboris.io
{VM IP Address} traefik.dotboris.io
{VM IP Address} feeds.dotboris.io
{VM IP Address} netdata.dotboris.io
```

From there, you'll be able to access the various web apps by pointing your
browser to `https://{host}.dotboris.io`. You'll need to accept the self-signed
HTTPS certificate.

Once you're done remember to comment out the entries in your hosts file.

## Updates

### Local Packages

There are custom package in this repo. Some of these packages pull source from other places like GitHub. These are pinned to specific versions and hashes. Updating those packages means updating those versions and hashes. There's tooling in place to automate this:

```sh
nix run .#update-packages
```

This will update all packages in the flake with `passthru.update = true;`. If
you want to update a package, add that to the derivation.

### Flake lock

```sh
nix flake update -L
```

### Do I need to reboot?

Most of the time you don't need to reboot. Services with new versions gets rebooted automatically and other programs get the the update when they're closed and re-opened.

There are a few packages that require a reboot. They're core components of the systems that can't just be restarted. They are:

- The Linux kernel
- SystemD

You can figure out what changed through the following steps:

1. SSH into the machine
1. Run: `nix profile diff-closures --profile /nix/var/nix/profiles/system`

If the packages mentioned above have been updated, you need to reboot.

## Todo

This is a work in progress. This is a list of things that I want / need from
this home lab.

- [x] Network wide ad blocking. Something like pi-hole.
- [ ] Password manager. Something like bitwarden.
- [x] Backup system. Doesn't have to be fancy. They should run automatically.
- [x] Monitoring stack.
- [ ] Cloud file storage. Something to replace Google Drive. (maybe)
- [x] Landing page that links to all the services.
- [x] RSS Feed aggregation.
