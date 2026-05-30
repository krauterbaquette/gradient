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
      ...
    }:
    {
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
