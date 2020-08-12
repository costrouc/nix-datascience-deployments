{ pkgs, jupyterhubEnvironment, jupyterlabEnvironment, jupyterlabKernels }:

let jupyterhubConfig = pkgs.writeText "jupyterhub_config.py" ''
      c.JupyterHub.hub_ip = "0.0.0.0"
      c.JupyterHub.authentication_class = "jupyterhub.auth.PAMAuthenticator"

      import batchspawner
      c.JupyterHub.spawner_class = 'batchspawner.SlurmSpawner'
      c.SlurmSpawner.default_url = '/lab'
      c.SlurmSpawner.environment = {
        'JUPYTER_PATH': '${jupyterlabKernels}'
      }
      c.SlurmSpawner.batchspawner_singleuser_cmd = '${jupyterlabEnvironment}/bin/batchspawner-singleuser'
      c.SlurmSpawner.cmd = "${jupyterlabEnvironment}/bin/.jupyterhub-singleuser-wrapped"

      c.SlurmSpawner.batch_script = """#!/usr/bin/env bash
      #SBATCH --output={{homedir}}/.jupyterhub_slurmspawner_%j.log
      #SBATCH --job-name=spawner-jupyterhub
      #SBATCH --chdir={{homedir}}
      #SBATCH --export={{keepvars}}
      #SBATCH --get-user-env=L
      {% if partition  %}#SBATCH --partition={{partition}}
      {% endif %}{% if runtime    %}#SBATCH --time={{runtime}}
      {% endif %}{% if memory     %}#SBATCH --mem={{memory}}
      {% endif %}{% if gres       %}#SBATCH --gres={{gres}}
      {% endif %}{% if nprocs     %}#SBATCH --cpus-per-task={{nprocs}}
      {% endif %}{% if reservation%}#SBATCH --reservation={{reservation}}
      {% endif %}{% if options    %}#SBATCH {{options}}{% endif %}
      set -euo pipefail
      trap 'echo SIGTERM received' TERM
      {{prologue}}
      {% if srun %}{{srun}} {% endif %}{{cmd}} --debug
      echo "jupyterhub-singleuser ended gracefully"
      {{epilogue}}
      """
    '';
in {
  systemd.services.jupyterhub = {
    description = "Jupyterhub development server";

    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      ExecStart = "${jupyterhubEnvironment}/bin/jupyterhub --config ${jupyterhubConfig}";
      User = "root";
      StateDirectory = "jupyterhub";
      WorkingDirectory = "/var/lib/jupyterhub";
      Environment = "PATH=/run/current-system/sw/bin/:$PATH";
    };
  };
}
