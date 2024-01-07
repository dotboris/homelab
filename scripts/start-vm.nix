{
  inputs,
  pkgs,
  system,
  ...
}: let
  runVm = inputs.self.packages.${system}.run-vm;
in
  pkgs.writeShellScript "start-vm" ''
    set -x
    rm ./homelab-test-efi-vars.fd
    rm ./homelab-test.qcow2
    exec ${runVm}/bin/run-homelab-test-vm
  ''
