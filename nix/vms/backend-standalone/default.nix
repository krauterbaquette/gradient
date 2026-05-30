{
  name = "development-backend-standalone";
  testScript = "start_all()";

  interactive = {
    sshBackdoor.enable = true;
    nodes.server.virtualisation.graphics = false;
  };

  nodes.server =
    {
      pkgs,
      lib,
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
          host.port = 3000;
          guest.port = 80;
        }
      ];
      virtualisation.writableStore = true;
      virtualisation.memorySize = 8048;

      security.pam.services.sshd.allowNullPassword = true;
      services = {
        gradient =
          let
            workerId = "70fccc5a-541d-4136-bc79-c01b55a0160e";
            workerToken = "zXluobred+d5qQRrwSuATx3+CWGwfNLHxkBCB6j4yPR2LQw5c/02jjWNsDQp91QL";
          in
          {
            enable = true;
            domain = "localhost";
            reverseProxy.nginx.enable = true;
            frontend.enable = false;
            useTls = false;
            jwtSecretFile = toString (
              pkgs.writeText "jwtSecret" "b68a8eaa8ebcff23ebaba1bd74ecb8a2eb7ba959570ff8842f148207524c7b8d731d7a1998584105e951599221f9dcd20e41223be17275ca70ab6f7e6ecafa8d4f8905623866edb2b344bd15de52ccece395b3546e2f00644eb2679cf7bdaa156fd75cc5f47c34448cba19d903e68015b1ad3c8e9d04862de0a2c525b6676779012919fa9551c4746f9323ab207aedae86c28ada67c901cae821eef97b69ca4ebe1260de31add34d8265f17d9c547e3bbabe284d9cadcc22063ee625b104592403368090642a41967f8ada5791cb09703d0762a3175d0fe06ec37822e9e41d0a623a6349901749673735fdb94f2c268ac08a24216efb058feced6e785f34185a"
            );
            cryptSecretFile = toString (pkgs.writeText "cryptSecret" "aW52YWxpZC1pbnZhbGlkLWludmFsaWQK");
            state = {
              users.admin = {
                email = "admin@example.com";
                email_verified = true;
                name = "Admin";
                # password
                password_file = toString (
                  pkgs.writeText "password" "$argon2id$v=19$m=32768,t=2,p=1$MzFjOGE4NWVhYTgwZTExMTk2ZTU4MWUwMTMyMWM1NDE$P6keQxfn+XuQ2mZxLrbhSA7lWbtc0VU51ZD3VTsW/E8"
                );
                superuser = true;
              };
              organizations.org = {
                created_by = "admin";
                display_name = "Org";
                private_key_file = toString ../../../dev/gradient_org_org_private_key;
              };
              projects.bun2nix = {
                organization = "org";
                created_by = "admin";
                wildcard = "packages.x86_64-linux.docs";
                repository = "https://github.com/nix-community/bun2nix.git";
              };
              caches.cache = {
                created_by = "admin";
                display_name = "Cache";
                organizations = [ "org" ];
                signing_key_file = toString ../../../dev/gradient_cache_cache_signing_key;
              };
              workers.local = {
                created_by = "admin";
                display_name = "local";
                organizations = [ "org" ];
                token_file = (pkgs.writeText "tokenf-file" workerToken);
                worker_id = workerId;
              };
            };

            worker = {
              enable = true;
              serverUrl = "ws://127.0.0.1:3000/proto";
              inherit workerId;
              peersFile = toString (pkgs.writeText "peerFile" "*:${workerToken}");
              settings.maxConcurrentBuilds = 2;
              capabilities = {
                fetch = true;
                eval = true;
                build = true;
              };
            };

          };
        postgresql = {
          enable = true;
          ensureDatabases = [ "gradient" ];
          ensureUsers = [
            {
              name = "gradient";
              ensureDBOwnership = true;
            }
          ];
          package = pkgs.postgresql_18;
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
