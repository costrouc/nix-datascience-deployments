{ pkgs }:

{
  python27Kernel = (
      let env = (pkgs.python2.withPackages(p: with p; [
            ipykernel numpy scipy
          ])).override (args: { ignoreCollisions = true; });
      in {
        displayName = "Python 2.7";
        argv = ["${env.interpreter}" "-m" "ipykernel_launcher" "-f" "{connection_file}"];
        language = "python";
        logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
        logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
      });

  python37Kernel = (
    let env = pkgs.python37.withPackages(p: with p; [
          ipykernel numpy scipy
        ]);
    in {
      displayName = "Python 3.7";
      argv = ["${env.interpreter}" "-m" "ipykernel_launcher" "-f" "{connection_file}"];
      language = "python";
      logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
      logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
    });

  python38Kernel = (
    let env = pkgs.python38.withPackages(p: with p; [
          ipykernel numpy scipy numba nixpkgs
        ]);
    in {
      displayName = "Python 3.8";
      argv = ["${env.interpreter}" "-m" "ipykernel_launcher" "-f" "{connection_file}"];
      language = "python";
      logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
      logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
    });

  cKernel = (
    let env = pkgs.python3.withPackages(p: with p; [
          jupyter-c-kernel
        ]);
    in {
      displayName = "C";
      argv = ["${env.interpreter}" "-m" "jupyter_c_kernel" "-f" "{connection_file}"];
      language = "c";
      logo32 = "/";
      logo64 = "/";
    });

  rustKernel = {
    displayName = "Rust";
    argv = ["${pkgs.evcxr}/bin/evcxr_jupyter" "--control_file" "{connection_file}"];
    language = "Rust";
    logo32 = "/";
    logo64 = "/";
  };

  rKernel = (
    let env = pkgs.rWrapper.override { packages = with pkgs.rPackages; [
        IRkernel ggplot2
    ];};
    in {
       displayName = "R";
       argv = ["${env}/bin/R" "--slave" "-e" "IRkernel::main()" "--args" "{connection_file}"];
       language = "R";
       logo32 = "/";
       logo64 = "/";
    });

  ansibleKernel = (
    let env = (pkgs.python3.withPackages(p: with p; [
          ansible-kernel ansible
        ])).override (args: { ignoreCollisions = true; });
    in {
      displayName = "Ansible";
      argv = ["${env.interpreter}" "-m" "ansible_kernel" "-f" "{connection_file}"];
      language = "ansible";
      logo32 = "/";
      logo64 = "/";
    });

  bashKernel = (
    let env = pkgs.python3.withPackages(p: with p; [
          bash_kernel
        ]);
    in {
      displayName = "Bash";
      argv = ["${env.interpreter}" "-m" "bash_kernel" "-f" "{connection_file}"];
      language = "Bash";
      logo32 = "/";
      logo64 = "/";
    });

  nixKernel = (
    let env = pkgs.python3.withPackages(p: with p; [
          nix-kernel
        ]);
    in {
      displayName = "Nix";
      argv = ["${env.interpreter}" "-m" "nix-kernel" "-f" "{connection_file}"];
      language = "Nix";
      logo32 = "/";
      logo64 = "/";
    });

  rubyKernel = {
    displayName = "Ruby";
    argv = ["${pkgs.iruby}/bin/iruby" "kernel" "{connection_file}"];
    language = "ruby";
    logo32 = "/";
    logo64 = "/";
  };

  # # looks broken at the moment
  # haskellKernel = (
  #   let env = pkgs.haskellPackages.ghcWithPackages (pkgs: [pkgs.ihaskell]);
  #       ghciBin = pkgs.writeScriptBin "ghci" ''
  #         ${env}/bin/ghci "$@"
  #       '';
  #       ghcBin = pkgs.writeScriptBin "ghc" ''
  #         ${env}/bin/ghc "$@"
  #       '';
  #       ihaskellSh = pkgs.writeScriptBin "ihaskell" ''
  #         #! ${pkgs.stdenv.shell}
  #         export GHC_PACKAGE_PATH="$(echo ${env}/lib/*/package.conf.d| tr ' ' ':'):$GHC_PACKAGE_PATH"
  #         export PATH="${pkgs.stdenv.lib.makeBinPath ([ env ])}:$PATH"
  #         ${env}/bin/ihaskell -l $(${env}/bin/ghc --print-libdir) "$@"
  #       '';
  #   in {
  #     displayName = "Haskell";
  #     argv = ["${ihaskellSh}/bin/ihaskell" "kernel" "{connection_file}" "+RTS" "-M3g" "-N2" "-RTS"];
  #     language = "haskell";
  #   });
}
