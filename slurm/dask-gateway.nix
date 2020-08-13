{ pkgs
, daskgatewayToken
, daskgatewaySchedulerEnvironment
, daskgatewayWorkerEnvironment
}:

let # for some reason all dask gateway environment variables are reset
    # by dask gateway this does not work with nix since
    # the default bin paths are nothing
    custom-dask-gateway-server = pkgs.python3Packages.dask-gateway-server.overridePythonAttrs(
      old: rec {
        postPatch = ''
          substituteInPlace dask_gateway_server/backends/jobqueue/base.py \
            --replace "env={}," ""
        '';
      });

    daskgatewayConfig = pkgs.writeText "daskgateway_config.py" ''
      c.DaskGateway.backend_class = (
         "dask_gateway_server.backends.jobqueue.slurm.SlurmBackend"
      )

      c.JobQueueClusterConfig.scheduler_cmd = "${daskgatewaySchedulerEnvironment}/bin/dask-gateway-scheduler"
      c.JobQueueClusterConfig.worker_cmd = "${daskgatewayWorkerEnvironment}/bin/dask-gateway-worker"

      c.Proxy.address = '0.0.0.0:8010'

      c.DaskGateway.authenticator_class = "dask_gateway_server.auth.JupyterHubAuthenticator"
      c.JupyterHubAuthenticator.jupyterhub_api_token = "${daskgatewayToken}"
      c.JupyterHubAuthenticator.jupyterhub_api_url = "http://localhost:8000/hub/api"
    '';

    daskgatewayEnvironment = (pkgs.python3.withPackages (p: with p; [
      custom-dask-gateway-server
      sqlalchemy
    ]));
in {
  systemd.services.daskgateway = {
    description = "Dask Gateway server";

    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Restart = "always";
      ExecStart = "${daskgatewayEnvironment}/bin/dask-gateway-server --config ${daskgatewayConfig}";
      User = "root";
      StateDirectory = "daskgateway";
      WorkingDirectory = "/var/lib/daskgateway";
      Environment = "PATH=/run/current-system/sw/bin/:$PATH";
    };
  };
}
