{...}: {
  flake.hosts.homelab.module = {...}: {
    disko.devices = {
      disk = {
        intel-ssd-0 = {
          device = "/dev/disk/by-id/ata-INTEL_SSDSC2CT240A3_CVMP2380003N240DGN";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              MBR = {
                type = "EF02"; # for grub MBR
                size = "1M";
                priority = 1; # Needs to be first partition
              };
              boot = {
                size = "5G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              primary = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "main";
                };
              };
            };
          };
        };
      };
      lvm_vg = {
        main = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
