{
  config,
  options,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.virtualisation.oci-containers;
  proxy_env = config.networking.proxy.envVars;

  defaultBackend = options.virtualisation.oci-containers.backend.default;

  containerOptions =
    { name, ... }:
    {

      config = {
        podman = mkIf (cfg.backend == "podman") { };
      };

      options = {

        image = mkOption {
          type = with types; str;
          description = "OCI image to run.";
          example = "library/hello-world";
        };

        imageFile = mkOption {
          type = with types; nullOr package;
          default = null;
          description = ''
            Path to an image file to load before running the image. This can
            be used to bypass pulling the image from the registry.

            The `image` attribute must match the name and
            tag of the image contained in this file, as they will be used to
            run the container with that image. If they do not match, the
            image will be pulled from the registry as usual.
          '';
          example = literalExpression "pkgs.dockerTools.buildImage {...};";
        };

        imageStream = mkOption {
          type = with types; nullOr package;
          default = null;
          description = ''
            Path to a script that streams the desired image on standard output.

            This option is mainly intended for use with
            `pkgs.dockerTools.streamLayeredImage` so that the intermediate
            image archive does not need to be stored in the Nix store.  For
            larger images this optimization can significantly reduce Nix store
            churn compared to using the `imageFile` option, because you don't
            have to store a new copy of the image archive in the Nix store
            every time you change the image.  Instead, if you stream the image
            then you only need to build and store the layers that differ from
            the previous image.
          '';
          example = literalExpression "pkgs.dockerTools.streamLayeredImage {...};";
        };

        serviceName = mkOption {
          type = types.str;
          default = "${cfg.backend}-${name}";
          defaultText = "<backend>-<name>";
          description = "Systemd service name that manages the container";
        };

        login = {

          username = mkOption {
            type = with types; nullOr str;
            default = null;
            description = "Username for login.";
          };

          passwordFile = mkOption {
            type = with types; nullOr str;
            default = null;
            description = "Path to file containing password.";
            example = "/etc/nixos/dockerhub-password.txt";
          };

          registry = mkOption {
            type = with types; nullOr str;
            default = null;
            description = "Registry where to login to.";
            example = "https://docker.pkg.github.com";
          };

        };

        cmd = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = "Commandline arguments to pass to the image's entrypoint.";
          example = literalExpression ''
            ["--port=9000"]
          '';
        };

        labels = mkOption {
          type = with types; attrsOf str;
          default = { };
          description = "Labels to attach to the container at runtime.";
          example = literalExpression ''
            {
              "traefik.https.routers.example.rule" = "Host(`example.container`)";
            }
          '';
        };

        entrypoint = mkOption {
          type = with types; nullOr str;
          description = "Override the default entrypoint of the image.";
          default = null;
          example = "/bin/my-app";
        };

        environment = mkOption {
          type = with types; attrsOf str;
          default = { };
          description = "Environment variables to set for this container.";
          example = literalExpression ''
            {
              DATABASE_HOST = "db.example.com";
              DATABASE_PORT = "3306";
            }
          '';
        };

        environmentFiles = mkOption {
          type = with types; listOf path;
          default = [ ];
          description = "Environment files for this container.";
          example = literalExpression ''
            [
              /path/to/.env
              /path/to/.env.secret
            ]
          '';
        };

        log-driver = mkOption {
          type = types.str;
          default = "journald";
          description = ''
            Logging driver for the container.  The default of
            `"journald"` means that the container's logs will be
            handled as part of the systemd unit.

            For more details and a full list of logging drivers, refer to respective backends documentation.

            For Docker:
            [Docker engine documentation](https://docs.docker.com/engine/logging/configure/)

            For Podman:
            Refer to the {manpage}`docker-run(1)` man page.
          '';
        };

        ports = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            Network ports to publish from the container to the outer host.

            Valid formats:
            - `<ip>:<hostPort>:<containerPort>`
            - `<ip>::<containerPort>`
            - `<hostPort>:<containerPort>`
            - `<containerPort>`

            Both `hostPort` and `containerPort` can be specified as a range of
            ports.  When specifying ranges for both, the number of container
            ports in the range must match the number of host ports in the
            range.  Example: `1234-1236:1234-1236/tcp`

            When specifying a range for `hostPort` only, the `containerPort`
            must *not* be a range.  In this case, the container port is published
            somewhere within the specified `hostPort` range.
            Example: `1234-1236:1234/tcp`

            Publishing a port bypasses the NixOS firewall. If the port is not
            supposed to be shared on the network, make sure to publish the
            port to localhost.
            Example: `127.0.0.1:1234:1234`

            Refer to the
            [Docker engine documentation](https://docs.docker.com/engine/network/#published-ports) for full details.
          '';
          example = literalExpression ''
            [
              "127.0.0.1:8080:9000"
            ]
          '';
        };

        user = mkOption {
          type = with types; nullOr str;
          default = null;
          description = ''
            Override the username or UID (and optionally groupname or GID) used
            in the container.
          '';
          example = "nobody:nogroup";
        };

        volumes = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            List of volumes to attach to this container.

            Note that this is a list of `"src:dst"` strings to
            allow for `src` to refer to `/nix/store` paths, which
            would be difficult with an attribute set.  There are
            also a variety of mount options available as a third
            field; please refer to the
            [docker engine documentation](https://docs.docker.com/engine/storage/volumes/) for details.
          '';
          example = literalExpression ''
            [
              "volume_name:/path/inside/container"
              "/path/on/host:/path/inside/container"
            ]
          '';
        };

        workdir = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "Override the default working directory for the container.";
          example = "/var/lib/hello_world";
        };

        dependsOn = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            Define which other containers this one depends on. They will be added to both After and Requires for the unit.

            Use the same name as the attribute under `virtualisation.oci-containers.containers`.
          '';
          example = literalExpression ''
            virtualisation.oci-containers.containers = {
              node1 = {};
              node2 = {
                dependsOn = [ "node1" ];
              }
            }
          '';
        };

        hostname = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "The hostname of the container.";
          example = "hello-world";
        };

        preRunExtraOptions = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = "Extra options for {command}`${defaultBackend}` that go before the `run` argument.";
          example = [
            "--runtime"
            "runsc"
          ];
        };

        extraOptions = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = "Extra options for {command}`${defaultBackend} run`.";
          example = literalExpression ''
            ["--network=host"]
          '';
        };

        autoStart = mkOption {
          type = with types; bool;
          default = true;
          description = ''
            When enabled, the container is automatically started on boot.
            If this option is set to false, the container has to be started on-demand via its service.
          '';
        };

        podman = mkOption {
          type = types.nullOr (
            types.submodule {
              options = {
                sdnotify = mkOption {
                  default = "conmon";
                  type = types.enum [
                    "conmon"
                    "healthy"
                    "container"
                  ];
                  description = ''
                    Determines how `podman` should notify systemd that the unit is ready. There are
                    [three options](https://docs.podman.io/en/latest/markdown/podman-run.1.html#sdnotify-container-conmon-healthy-ignore):

                    * `conmon`: marks the unit as ready when the container has started.
                    * `healthy`: marks the unit as ready when the [container's healthcheck](https://docs.podman.io/en/stable/markdown/podman-healthcheck-run.1.html) passes.
                    * `container`: `NOTIFY_SOCKET` is passed into the container and the process inside the container needs to indicate on its own that it's ready.
                  '';
                };
                user = mkOption {
                  default = "root";
                  type = types.str;
                  description = ''
                    The user under which the container should run.
                  '';
                };
              };
            }
          );
          default = null;
          description = ''
            Podman-specific settings in OCI containers. These must be null when using
            the `docker` backend.
          '';
        };

        pull = mkOption {
          type =
            with types;
            enum [
              "always"
              "missing"
              "never"
              "newer"
            ];
          default = "missing";
          description = ''
            Image pull policy for the container. Must be one of: always, missing, never, newer
          '';
        };

        capabilities = mkOption {
          type = with types; lazyAttrsOf (nullOr bool);
          default = { };
          description = ''
            Capabilities to configure for the container.
            When set to true, capability is added to the container.
            When set to false, capability is dropped from the container.
            When null, default runtime settings apply.
          '';
          example = literalExpression ''
            {
              SYS_ADMIN = true;
              SYS_WRITE = false;
            {
          '';
        };

        devices = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            List of devices to attach to this container.
          '';
          example = literalExpression ''
            [
              "/dev/dri:/dev/dri"
            ]
          '';
        };

        privileged = mkOption {
          type = with types; bool;
          default = false;
          description = ''
            Give extended privileges to the container
          '';
        };

        autoRemoveOnStop = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Automatically remove the container when it is stopped or killed
          '';
        };

        networks = mkOption {
          type = with types; listOf str;
          default = [ ];
          description = ''
            Networks to attach the container to
          '';
        };
      };
    };

  isValidLogin =
    login: login.username != null && login.passwordFile != null && login.registry != null;

  mkService =
    name: container:
    let
      dependsOn = map (x: "${cfg.backend}-${x}.service") container.dependsOn;
      escapedName = escapeShellArg name;
      preStartScript = pkgs.writeShellApplication {
        name = "pre-start";
        runtimeInputs = [ ];
        text = ''
          ${cfg.backend} rm -f ${name} || true
          ${optionalString (isValidLogin container.login) ''
            # try logging in, if it fails, check if image exists locally
            ${cfg.backend} login \
            ${container.login.registry} \
            --username ${escapeShellArg container.login.username} \
            --password-stdin < ${container.login.passwordFile} \
            || ${cfg.backend} image inspect ${container.image} >/dev/null \
            || { echo "image doesn't exist locally and login failed" >&2 ; exit 1; }
          ''}
          ${optionalString (container.imageFile != null) ''
            ${cfg.backend} load -i ${container.imageFile}
          ''}
          ${optionalString (container.imageStream != null) ''
            ${container.imageStream} | ${cfg.backend} load
          ''}
          ${optionalString (cfg.backend == "podman") ''
            rm -f /run/${escapedName}/ctr-id
          ''}
        '';
      };

      effectiveUser = container.podman.user or "root";
      inherit (config.users.users.${effectiveUser}) uid;
      dependOnLingerService =
        cfg.backend == "podman" && effectiveUser != "root" && config.users.users.${effectiveUser}.linger;
    in
    {
      wantedBy = [ ] ++ optional (container.autoStart) "multi-user.target";
      wants =
        lib.optional (container.imageFile == null && container.imageStream == null) "network-online.target"
        ++ lib.optionals dependOnLingerService [ "linger-users.service" ];
      after =
        lib.optionals (cfg.backend == "docker") [
          "docker.service"
          "docker.socket"
        ]
        # if imageFile or imageStream is not set, the service needs the network to download the image from the registry
        ++ lib.optionals (container.imageFile == null && container.imageStream == null) [
          "network-online.target"
        ]
        ++ dependsOn
        ++ lib.optionals dependOnLingerService [ "linger-users.service" ]
        ++ lib.optionals (effectiveUser != "root" && container.podman.sdnotify == "healthy") [
          "user@${toString uid}.service"
        ];
      requires =
        dependsOn
        ++ lib.optionals (effectiveUser != "root" && container.podman.sdnotify == "healthy") [
          "user@${toString uid}.service"
        ];
      environment = lib.mkMerge [
        proxy_env
        (mkIf (cfg.backend == "podman" && container.podman.user != "root") {
          HOME = config.users.users.${container.podman.user}.home;
        })
      ];

      path =
        if cfg.backend == "docker" then
          [ config.virtualisation.docker.package ]
        else if cfg.backend == "podman" then
          [ config.virtualisation.podman.package ]
        else
          throw "Unhandled backend: ${cfg.backend}";

      script = concatStringsSep " \\\n  " (
        [
          "exec ${cfg.backend} "
        ]
        ++ map escapeShellArg container.preRunExtraOptions
        ++ [
          "run"
          "--name=${escapedName}"
          "--log-driver=${container.log-driver}"
        ]
        ++ optional (container.entrypoint != null) "--entrypoint=${escapeShellArg container.entrypoint}"
        ++ optional (container.hostname != null) "--hostname=${escapeShellArg container.hostname}"
        ++ lib.optionals (cfg.backend == "podman") [
          "--cidfile=/run/${escapedName}/ctr-id"
          "--cgroups=enabled"
          "--sdnotify=${container.podman.sdnotify}"
          "-d"
          "--replace"
        ]
        ++ (mapAttrsToList (k: v: "-e ${escapeShellArg k}=${escapeShellArg v}") container.environment)
        ++ map (f: "--env-file ${escapeShellArg f}") container.environmentFiles
        ++ map (p: "-p ${escapeShellArg p}") container.ports
        ++ optional (container.user != null) "-u ${escapeShellArg container.user}"
        ++ map (v: "-v ${escapeShellArg v}") container.volumes
        ++ (mapAttrsToList (k: v: "-l ${escapeShellArg k}=${escapeShellArg v}") container.labels)
        ++ optional (container.workdir != null) "-w ${escapeShellArg container.workdir}"
        ++ optional (container.privileged) "--privileged"
        ++ optional (container.autoRemoveOnStop) "--rm"
        ++ mapAttrsToList (k: _: "--cap-add=${escapeShellArg k}") (
          filterAttrs (_: v: v == true) container.capabilities
        )
        ++ mapAttrsToList (k: _: "--cap-drop=${escapeShellArg k}") (
          filterAttrs (_: v: v == false) container.capabilities
        )
        ++ map (d: "--device=${escapeShellArg d}") container.devices
        ++ map (n: "--network=${escapeShellArg n}") container.networks
        ++ [ "--pull ${escapeShellArg container.pull}" ]
        ++ map escapeShellArg container.extraOptions
        ++ [ container.image ]
        ++ map escapeShellArg container.cmd
      );

      preStop =
        if cfg.backend == "podman" then
          "podman stop --ignore --cidfile=/run/${escapedName}/ctr-id"
        else
          "${cfg.backend} stop ${name} || true";

      postStop =
        if cfg.backend == "podman" then
          "podman rm -f --ignore --cidfile=/run/${escapedName}/ctr-id"
        else
          "${cfg.backend} rm -f ${name} || true";

      unitConfig = mkIf (effectiveUser != "root") {
        RequiresMountsFor = "/run/user/${toString uid}/containers";
      };

      serviceConfig = {
        ### There is no generalized way of supporting `reload` for docker
        ### containers. Some containers may respond well to SIGHUP sent to their
        ### init process, but it is not guaranteed; some apps have other reload
        ### mechanisms, some don't have a reload signal at all, and some docker
        ### images just have broken signal handling.  The best compromise in this
        ### case is probably to leave ExecReload undefined, so `systemctl reload`
        ### will at least result in an error instead of potentially undefined
        ### behaviour.
        ###
        ### Advanced users can still override this part of the unit to implement
        ### a custom reload handler, since the result of all this is a normal
        ### systemd service from the perspective of the NixOS module system.
        ###
        # ExecReload = ...;
        ###
        ExecStartPre = [ "${preStartScript}/bin/pre-start" ];
        TimeoutStartSec = 0;
        TimeoutStopSec = 120;
        Restart = "always";
      }
      // optionalAttrs (cfg.backend == "podman") {
        Environment = "PODMAN_SYSTEMD_UNIT=podman-${name}.service";
        Type = "notify";
        NotifyAccess = "all";
        Delegate = mkIf (container.podman.sdnotify == "healthy") true;
        User = effectiveUser;
        RuntimeDirectory = escapedName;
      };
    };

in
{
  imports = [
    (lib.mkChangedOptionModule [ "docker-containers" ] [ "virtualisation" "oci-containers" ] (oldcfg: {
      backend = "docker";
      containers = lib.mapAttrs (
        n: v:
        builtins.removeAttrs (
          v
          // {
            extraOptions = v.extraDockerOptions or [ ];
          }
        ) [ "extraDockerOptions" ]
      ) oldcfg.docker-containers;
    }))
  ];

  options.virtualisation.oci-containers = {

    backend = mkOption {
      type = types.enum [
        "podman"
        "docker"
      ];
      default = if versionAtLeast config.system.stateVersion "22.05" then "podman" else "docker";
      description = "The underlying Docker implementation to use.";
    };

    containers = mkOption {
      default = { };
      type = types.attrsOf (types.submodule containerOptions);
      description = "OCI (Docker) containers to run as systemd services.";
    };

  };

  config = lib.mkIf (cfg.containers != { }) (
    lib.mkMerge [
      {
        systemd.services = mapAttrs' (n: v: nameValuePair v.serviceName (mkService n v)) cfg.containers;

        assertions =
          let
            toAssertions =
              name:
              {
                imageFile,
                imageStream,
                podman,
                ...
              }:
              [
                {
                  assertion = imageFile == null || imageStream == null;

                  message = "virtualisation.oci-containers.containers.${name}: You can only define one of imageFile and imageStream";
                }
                {
                  assertion = cfg.backend == "docker" -> podman == null;
                  message = "virtualisation.oci-containers.containers.${name}: Cannot set `podman` option if backend is `docker`.";
                }
                {
                  assertion =
                    cfg.backend == "podman" && podman.sdnotify == "healthy" && podman.user != "root"
                    -> config.users.users.${podman.user}.uid != null;
                  message = ''
                    Rootless container ${name} (with podman and sdnotify=healthy)
                    requires that its running user ${podman.user} has a statically specified uid.
                  '';
                }
              ];
          in
          concatMap (name: toAssertions name cfg.containers.${name}) (lib.attrNames cfg.containers);

        warnings = mkIf (cfg.backend == "podman") (
          lib.foldlAttrs (
            warnings: name:
            { podman, ... }:
            let
              inherit (config.users.users.${podman.user}) linger;
            in
            warnings
            ++ lib.optional (podman.user != "root" && linger && podman.sdnotify == "conmon") ''
              Podman container ${name} is configured as rootless (user ${podman.user})
              with `--sdnotify=conmon`, but lingering for this user is turned on.
            ''
            ++ lib.optional (podman.user != "root" && !linger && podman.sdnotify == "healthy") ''
              Podman container ${name} is configured as rootless (user ${podman.user})
              with `--sdnotify=healthy`, but lingering for this user is turned off.
            ''
          ) [ ] cfg.containers
        );
      }
      (lib.mkIf (cfg.backend == "podman") {
        virtualisation.podman.enable = true;
      })
      (lib.mkIf (cfg.backend == "docker") {
        virtualisation.docker.enable = true;
      })
    ]
  );
}
