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