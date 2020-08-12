let pkgs = import <nixpkgs> { };

    baseConfig = {
      services.slurm = {
        controlMachine = "master01";
        nodeName = [ "node0[1-3] CPUs=1 State=UNKNOWN" ];
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

    jupyterhubEnvironment = (pkgs.python37.withPackages (p: with p; [
      jupyterhub
      jupyterhub-systemdspawner
      batchspawner
    ]));

    jupyterlabEnvironment = (pkgs.python37.withPackages (p: with p; [
      jupyterhub
      jupyterlab
      batchspawner
    ]));

    jupyterlabKernels = pkgs.jupyter-kernel.create {
      definitions = (import ../common/kernels.nix { inherit pkgs; });
    };

    computeNode = {
      deployment.targetEnv = "libvirtd";
      deployment.libvirtd.imageDir = "/var/lib/libvirt/images";

      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        baseConfig
      ];

      environment.etc."jupyterhub".text = ''
        JupyterlabEnvironment=${jupyterlabEnvironment}
        JupyterlabKernels=${jupyterlabKernels}
      '';

      services.slurm = {
        client.enable = true;
      };
    };

    masterNode = {
      imports = [
        ../common/libvirt-deployment.nix
        ../common/users.nix
        baseConfig
        (import ./jupyterhub.nix {
          inherit pkgs jupyterhubEnvironment jupyterlabEnvironment jupyterlabKernels; })
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
    };
in {
  master01 = masterNode;
  node01 = computeNode;
  node02 = computeNode;
  node03 = computeNode;
}
