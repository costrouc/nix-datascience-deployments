let pkgs = import <nixpkgs> { };
in {
  nomad01 = {
    imports = [
      ../common/libvirt-deployment.nix
      ../common/users.nix
    ];

    networking.firewall.enable = false;
  };
}
