let pkgs = import <nixpkgs> { };

    jupyterhubEnvironment = (pkgs.python3.withPackages (p: with p; [
      jupyterhub
      jupyterhub-systemdspawner
      batchspawner
    ]));

    jupyterlabEnvironment = (pkgs.python3.withPackages (p: with p; [
      jupyterhub
      jupyterlab
      batchspawner
      dask-gateway
    ]));

    jupyterlabKernels = pkgs.jupyter-kernel.create {
      definitions = (import ../common/kernels.nix { inherit pkgs; });
    };

    daskEnvironment = (pkgs.python3.withPackages (p: with p; [
      dask
      distributed
      dask-gateway
      bokeh
      numpy
      scipy
    ]));

    jupyterhubTokens = {
      daskGateway = "b1e2ad43a121fe8fb69839ba2f4c4eaa911fa3abd79a5d1595df5a11399c2e00";
    };

    baseConfig = {
      services.slurm = {
        controlMachine = "master01";
        nodeName = [ "node0[1-3] CPUs=2 RealMemory=4048 State=UNKNOWN" ];
        partitionName = [ "debug Nodes=node0[1-3] Default=YES MaxTime=INFINITE State=UP" ];
        extraConfig = ''
          AccountingStorageHost=master01
          AccountingStorageType=accounting_storage/slurmdbd
        '';
      };

      networking.firewall.enable = false;

      systemd.tmpfiles.rules = [
        "f /etc/munge/munge.key 0400 munge munge - mungeverryweakkeybuteasytointegratoinatest"
      ];
    };

    computeNode = {
      deployment.targetEnv = "libvirtd";
      deployment.libvirtd.imageDir = "/var/lib/libvirt/images";

      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        baseConfig
      ];

      environment.etc."dask/gateway.yaml".text = builtins.toJSON {
        gateway = {
          address = "http://master01:8010";
          proxy-address = "tls://master01:8010";
          auth = {
            type = "jupyterhub";
          };
        };
      };

      environment.etc."jupyterhub".text = ''
        JupyterlabEnvironment=${jupyterlabEnvironment}
        JupyterlabKernels=${jupyterlabKernels}
        DaskEnvironment=${daskEnvironment}
      '';

      services.slurm = {
        client.enable = true;
      };

      fileSystems."/home" = {
        device = "master01:/home";
        fsType = "nfs";
      };
    };

    masterNode = {
      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        (import ./dask-gateway.nix {
          inherit pkgs;
          daskgatewaySchedulerEnvironment = daskEnvironment;
          daskgatewayWorkerEnvironment = daskEnvironment;
          daskgatewayToken = jupyterhubTokens.daskGateway;
        })
        baseConfig
        (import ./jupyterhub.nix {
          inherit pkgs jupyterhubTokens jupyterhubEnvironment jupyterlabEnvironment jupyterlabKernels; })
      ];

      services.slurm = {
        server.enable = true;
        enableStools = true;
        dbdserver = {
          enable = true;
          storagePass = "password123";
        };
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        initialScript = pkgs.writeText "mysql-init.sql" ''
          CREATE USER 'slurm'@'localhost' IDENTIFIED BY 'password123';
          GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
        '';
        ensureDatabases = [ "slurm_acct_db" ];
        ensureUsers = [{
          ensurePermissions = { "slurm_acct_db.*" = "ALL PRIVILEGES"; };
          name = "slurm";
        }];
        extraOptions = ''
          # recommendations from: https://slurm.schedmd.com/accounting.html#mysql-configuration
          innodb_buffer_pool_size=1024M
          innodb_log_file_size=64M
          innodb_lock_wait_timeout=900
        '';
      };

      security.pam.services.login.setLoginUid = false;

      services.nfs.server = {
        enable = true;
        # some hardcoding assuming the network that the vms are deployed within
        exports = ''
          /home 192.168.122.1/24(rw,no_subtree_check,no_root_squash)
        '';
      };
    };
in {
  master01 = masterNode;
  node01 = computeNode;
  node02 = computeNode;
  node03 = computeNode;
}
