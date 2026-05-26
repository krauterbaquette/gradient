{
  name = "development-postgres-worker";

  testScript = "start_all()";

  interactive = {
    sshBackdoor.enable = true;
    nodes.server.virtualisation.graphics = false;
  };

  nodes.server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ ../../modules/gradient.nix ];
      networking.firewall.enable = false;
      documentation.enable = false;

      virtualisation.forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
        {
          from = "host";
          host.port = config.services.postgresql.settings.port;
          guest.port = config.services.postgresql.settings.port;
        }
      ];

      security.pam.services.sshd.allowNullPassword = true;
      services = {
        postgresql = {
          enable = true;
          ensureDatabases = [ "gradient" ];
          ensureUsers = [
            {
              name = "gradient";
              ensureDBOwnership = true;
            }
          ];
          enableTCPIP = true;
          authentication = ''
            #...
            #type database DBuser origin-address auth-method
            # ipv4
            host  all      all     0.0.0.0/0      trust
            # ipv6
            host all       all     ::0/0        trust
          '';

          settings = {
            log_connections = true;
            logging_collector = true;
            log_disconnections = true;
            log_destination = lib.mkForce "syslog";
          };
        };

        gradient.worker = {
          enable = true;
          serverUrl = "ws://127.0.0.1:3030/proto";
          workerId = builtins.readFile ../../../dev/worker.id;
          peersFile = pkgs.writeTextFile {
            name = "peers-file";
            # see dev/gradient_worker_<id>_token
            text = ''
              *:q2KcAAEPOWyZHAHntvxfw7pnsIncZ68Gx9kDOhT8GyyPVmDp2X+zmbCQIyr9NHRc
            '';
          };
          capabilities = {
            fetch = true;
            eval = true;
            build = true;
          };
        };

        openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "yes";
            PermitEmptyPasswords = "yes";
          };
        };
      };

    };

}
