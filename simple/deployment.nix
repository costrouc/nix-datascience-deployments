let pkgs = import <nixpkgs> { };
in {
  machine = {
    imports = [
      ../common/libvirt-deployment.nix
      ../common/users.nix
    ];

    services.jupyterhub = {
      enable = true;
      port = 80;
      kernels = import ../common/kernels.nix { inherit pkgs; };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];

    security.pam.services.login.setLoginUid = false;
  };
}
