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

## Updating Packages

1. Do the update: `nix run .#update-packages`
1. Check the differences: `git diff`
1. Test the changes: `nix flake check -L`
1. Test with the VM
1. Ship to prod

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
