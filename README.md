# Home Lab

My personal Home Lab / Home Server powered by Nix

## Test VM

This configuration comes with a test VM that can be used to test a standalone
version of this home lab. Here's how:

1. Start the VM

    ```sh
    nix run .#vm
    ```

1. SSH into the VM (in another terminal)

    ```sh
    nix run .#ssh-vm
    ```

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
