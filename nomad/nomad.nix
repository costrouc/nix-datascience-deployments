{ pkgs
, isServer ? true
, isClient ? true
, masterServer
}:

let nomadConfiguration = pkgs.writeText "nomad_configuartion.json" (builtins.toJSON {
      datacenter = "dc1";
      data_dir = "/var/lib/nomad";

      server = {
        enabled = isServer;

        server_join = {
          retry_join = [ masterServer ];
        };
      };

      client = {
        enabled = isClient;

        server_join = {
          retry_join = [ masterServer ];
        };
      };
    });
in {
  systemd.services.nomad = {
    description = "Nomad";

    after = [ "network-online.target" ];
    wantedBy = [ "network-online.target" ];

    serviceConfig = {
      ExecReload = "${pkgs.utillinux.bin}/bin/kill -HUP $MAINPID";
      ExecStart = "${pkgs.nomad}/bin/nomad agent -config ${nomadConfiguration}";
      KillMode = "process";
      KillSignal = "SIGINT";
      LimitNOFILE = "infinity";
      LimitNPROC = "infinity";
      Restart = "on-failure";
      RestartSec = 2;
      StartLimitBurst = 3;
      StartLimitIntervalSec = 10;
      TasksMax = "infinity";
      StateDirectory = "nomad";
      Environment = "PATH=/run/current-system/sw/bin/:$PATH";
    };
  };
}
