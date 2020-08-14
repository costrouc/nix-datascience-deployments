{ pkgs }:

let nomadConfiguration = pkgs.writeText "nomad.hcl" ''
      datacenter = "nomad"
      data_dir = "/var/lib/nomad"

      server {
        enabled = true
      }

      client {
        enabled = true
      }
    '';
in {
  systemd.services.nomad = {
    description = "Jupyterhub development server";

    after = [ "network-online.target" ];
    wantedBy = [ "network-online.target" ];

    serviceConfig = {
      ExecReload = "/run/current-system/sw/bin/kill -HUP $MAINPID";
      ExecStart = "${pkgs.nomad}/bin/nomad agent -config /etc/nomad.d
      Restart = "always";
      ExecStart = "${jupyterhubEnvironment}/bin/jupyterhub --config ${jupyterhubConfig}";
      StateDirectory = "jupyterhub";
      WorkingDirectory = "/var/lib/jupyterhub";
      Environment = "PATH=/run/current-system/sw/bin/:$PATH";
    };
  };
}
