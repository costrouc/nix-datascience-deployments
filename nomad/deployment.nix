let pkgs = import <nixpkgs> { };
    serverMachine = {
      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        (import ./nomad.nix { inherit pkgs; masterServer = "nomad01"; })
      ];

      networking.firewall.enable = false;
    };

    clientMachine = {
      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        (import ./nomad.nix { inherit pkgs; masterServer = "nomad01"; isServer = false; })
      ];

      networking.firewall.enable = false;
    };
in {
  nomad01 = serverMachine;
  nomad02 = serverMachine;
  nomad03 = serverMachine;
  nomad04 = clientMachine;
  nomad05 = clientMachine;
  nomad06 = clientMachine;
}
