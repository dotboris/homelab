{pkgs, ...}:
pkgs.writeShellScript "ssh-vm"
''
  ${pkgs.openssh}/bin/ssh \
    -o "UserKnownHostsFile=/dev/null" \
    -o "StrictHostKeyChecking=no" \
    -p 2022 \
    dotboris@localhost
''
