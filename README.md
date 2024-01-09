# Home Lab

My personal Home Lab / Home Server powered by Nix

## Test VM

This configuration comes with a test VM that can be used to test a standalone
version of this home lab. Here's how:

You can start the VM with:

```sh
nix run .#vm
```

You can SSH into the VM with:

```sh
nix run .#ssh-vm
```

### Testing web apps

Open you system `/etc/hosts` file and add the following values:

```
# Homelab dev
127.0.0.1 home.dotboris.io
127.0.0.1 traefik.dotboris.io
127.0.0.1 feeds.dotboris.io
127.0.0.1 netdata.dotboris.io
```

From there, you'll be able to access the various web apps by pointing your
browser to `https://{host}.dotboris.io:8443`. You'll need to accept the
self-signed HTTPS certificate.

Once you're done remember to comment out the entries in your hosts file.

## Todo

This is a work in progress. This is a list of things that I want / need from
this home lab.

- [x] Network wide ad blocking. Something like pi-hole.
- [ ] Password manager. Something like bitwarden.
- [ ] Backup system. Doesn't have to be fancy. They should run automatically.
- [x] Monitoring stack.
- [ ] Cloud file storage. Something to replace Google Drive. (maybe)
- [x] Landing page that links to all the services.
- [x] RSS Feed aggregation.
