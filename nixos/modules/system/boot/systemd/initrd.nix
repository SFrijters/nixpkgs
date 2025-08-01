{
  lib,
  options,
  config,
  utils,
  pkgs,
  ...
}:

with lib;

let
  inherit (utils) systemdUtils escapeSystemdPath;
  inherit (systemdUtils.unitOptions) unitOption;
  inherit (systemdUtils.lib)
    generateUnits
    pathToUnit
    serviceToUnit
    sliceToUnit
    socketToUnit
    targetToUnit
    timerToUnit
    mountToUnit
    automountToUnit
    attrsToSection
    ;

  cfg = config.boot.initrd.systemd;

  upstreamUnits = [
    "basic.target"
    "ctrl-alt-del.target"
    "debug-shell.service"
    "emergency.service"
    "emergency.target"
    "final.target"
    "halt.target"
    "initrd-cleanup.service"
    "initrd-fs.target"
    "initrd-parse-etc.service"
    "initrd-root-device.target"
    "initrd-root-fs.target"
    "initrd-switch-root.service"
    "initrd-switch-root.target"
    "initrd.target"
    "kexec.target"
    "kmod-static-nodes.service"
    "local-fs-pre.target"
    "local-fs.target"
    "modprobe@.service"
    "multi-user.target"
    "paths.target"
    "poweroff.target"
    "reboot.target"
    "rescue.service"
    "rescue.target"
    "rpcbind.target"
    "shutdown.target"
    "sigpwr.target"
    "slices.target"
    "sockets.target"
    "swap.target"
    "sysinit.target"
    "sys-kernel-config.mount"
    "syslog.socket"
    "systemd-ask-password-console.path"
    "systemd-ask-password-console.service"
    "systemd-fsck@.service"
    "systemd-halt.service"
    "systemd-hibernate-resume.service"
    "systemd-journald-audit.socket"
    "systemd-journald-dev-log.socket"
    "systemd-journald.service"
    "systemd-journald.socket"
    "systemd-kexec.service"
    "systemd-modules-load.service"
    "systemd-poweroff.service"
    "systemd-reboot.service"
    "systemd-sysctl.service"
    "timers.target"
    "umount.target"
    "systemd-bsod.service"
  ]
  ++ cfg.additionalUpstreamUnits;

  upstreamWants = [
    "sysinit.target.wants"
  ];

  enabledUpstreamUnits = filter (n: !elem n cfg.suppressedUnits) upstreamUnits;
  enabledUnits = filterAttrs (n: v: !elem n cfg.suppressedUnits) cfg.units;
  jobScripts = concatLists (
    mapAttrsToList (_: unit: unit.jobScripts or [ ]) (filterAttrs (_: v: v.enable) cfg.services)
  );

  stage1Units = generateUnits {
    type = "initrd";
    units = enabledUnits;
    upstreamUnits = enabledUpstreamUnits;
    inherit upstreamWants;
    inherit (cfg) packages package;
  };

  kernel-name = config.boot.kernelPackages.kernel.name or "kernel";

  initrdBinEnv = pkgs.buildEnv {
    name = "initrd-bin-env";
    paths = map getBin cfg.initrdBin;
    pathsToLink = [
      "/bin"
      "/sbin"
    ];

    # Make sure sbin and bin have the same contents, and add extraBin
    postBuild = ''
      find $out/bin -maxdepth 1 -type l -print0 | xargs --null cp --no-dereference --no-clobber -t $out/sbin/
      find $out/sbin -maxdepth 1 -type l -print0 | xargs --null cp --no-dereference --no-clobber -t $out/bin/
      ${concatStringsSep "\n" (
        mapAttrsToList (n: v: ''
          ln -sf '${v}' $out/bin/'${n}'
          ln -sf '${v}' $out/sbin/'${n}'
        '') cfg.extraBin
      )}
    '';
  };

  initialRamdisk = pkgs.makeInitrdNG {
    name = "initrd-${kernel-name}";
    inherit (config.boot.initrd) compressor compressorArgs prepend;

    contents = lib.filter (
      { source, enable, ... }: (!lib.elem source cfg.suppressedStorePaths) && enable
    ) cfg.storePaths;
  };

in
{
  imports = [
    (lib.mkRemovedOptionModule [ "boot" "initrd" "systemd" "strip" ] ''
      The option to strip ELF files in initrd has been removed.
      It only saved ~1MiB of initramfs size, but caused a few issues
      like unloadable kernel modules.
    '')
    (lib.mkRemovedOptionModule [
      "boot"
      "initrd"
      "systemd"
      "extraConfig"
    ] "Use boot.initrd.systemd.settings.Manager instead.")
  ];

  options.boot.initrd.systemd = {
    enable = mkEnableOption "systemd in initrd" // {
      description = ''
        Whether to enable systemd in initrd. The unit options such as
        {option}`boot.initrd.systemd.services` are the same as their
        stage 2 counterparts such as {option}`systemd.services`,
        except that `restartTriggers` and `reloadTriggers` are not
        supported.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = config.systemd.package;
      defaultText = lib.literalExpression "config.systemd.package";
      description = ''
        The systemd package to use.
      '';
    };

    settings.Manager = mkOption {
      default = { };
      defaultText = lib.literalExpression ''
        {
          DefaultEnvironment = "PATH=/bin:/sbin";
        }
      '';
      type = lib.types.submodule {
        freeformType = types.attrsOf unitOption;
      };
      example = {
        WatchdogDevice = "/dev/watchdog";
        RuntimeWatchdogSec = "30s";
        RebootWatchdogSec = "10min";
        KExecWatchdogSec = "5min";
      };
      description = ''
        Options for the global systemd service manager used in initrd. See {manpage}`systemd-system.conf(5)` man page
        for available options.
      '';
    };

    managerEnvironment = mkOption {
      type =
        with types;
        attrsOf (
          nullOr (oneOf [
            str
            path
            package
          ])
        );
      default = { };
      defaultText = ''
        {
          PATH = "/bin:/sbin";
        }
      '';
      example = {
        SYSTEMD_LOG_LEVEL = "debug";
      };
      description = ''
        Environment variables of PID 1. These variables are
        *not* passed to started units.
      '';
    };

    contents = mkOption {
      description = "Set of files that have to be linked into the initrd";
      example = literalExpression ''
        {
          "/etc/machine-id".source = /etc/machine-id;
        }
      '';
      default = { };
      type = utils.systemdUtils.types.initrdContents;
    };

    storePaths = mkOption {
      description = ''
        Store paths to copy into the initrd as well.
      '';
      type = utils.systemdUtils.types.initrdStorePath;
      default = [ ];
    };

    extraBin = mkOption {
      description = ''
        Tools to add to /bin
      '';
      example = literalExpression ''
        {
          umount = ''${pkgs.util-linux}/bin/umount;
        }
      '';
      type = types.attrsOf types.path;
      default = { };
    };

    suppressedStorePaths = mkOption {
      description = ''
        Store paths specified in the storePaths option that
        should not be copied.
      '';
      type = types.listOf types.singleLineStr;
      default = [ ];
    };

    root = lib.mkOption {
      type = lib.types.enum [
        "fstab"
        "gpt-auto"
      ];
      default = "fstab";
      example = "gpt-auto";
      description = ''
        Controls how systemd will interpret the root FS in initrd. See
        {manpage}`kernel-command-line(7)`. NixOS currently does not
        allow specifying the root file system itself this
        way. Instead, the `fstab` value is used in order to interpret
        the root file system specified with the `fileSystems` option.
      '';
    };

    emergencyAccess = mkOption {
      type =
        with types;
        oneOf [
          bool
          (nullOr (passwdEntry str))
        ];
      description = ''
        Set to true for unauthenticated emergency access, and false or
        null for no emergency access.

        Can also be set to a hashed super user password to allow
        authenticated access to the emergency mode.

        For emergency access after initrd, use `${options.systemd.enableEmergencyMode}` instead.
      '';
      default = false;
    };

    initrdBin = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Packages to include in /bin for the stage 1 emergency shell.
      '';
    };

    additionalUpstreamUnits = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [
        "debug-shell.service"
        "systemd-quotacheck.service"
      ];
      description = ''
        Additional units shipped with systemd that shall be enabled.
      '';
    };

    suppressedUnits = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [ "systemd-backlight@.service" ];
      description = ''
        A list of units to skip when generating system systemd configuration directory. This has
        priority over upstream units, {option}`boot.initrd.systemd.units`, and
        {option}`boot.initrd.systemd.additionalUpstreamUnits`. The main purpose of this is to
        prevent a upstream systemd unit from being added to the initrd with any modifications made to it
        by other NixOS modules.
      '';
    };

    units = mkOption {
      description = "Definition of systemd units.";
      default = { };
      visible = "shallow";
      type = systemdUtils.types.units;
    };

    packages = mkOption {
      default = [ ];
      type = types.listOf types.package;
      example = literalExpression "[ pkgs.systemd-cryptsetup-generator ]";
      description = "Packages providing systemd units and hooks.";
    };

    targets = mkOption {
      default = { };
      visible = "shallow";
      type = systemdUtils.types.initrdTargets;
      description = "Definition of systemd target units.";
    };

    services = mkOption {
      default = { };
      type = systemdUtils.types.initrdServices;
      visible = "shallow";
      description = "Definition of systemd service units.";
    };

    sockets = mkOption {
      default = { };
      type = systemdUtils.types.initrdSockets;
      visible = "shallow";
      description = "Definition of systemd socket units.";
    };

    timers = mkOption {
      default = { };
      type = systemdUtils.types.initrdTimers;
      visible = "shallow";
      description = "Definition of systemd timer units.";
    };

    paths = mkOption {
      default = { };
      type = systemdUtils.types.initrdPaths;
      visible = "shallow";
      description = "Definition of systemd path units.";
    };

    mounts = mkOption {
      default = [ ];
      type = systemdUtils.types.initrdMounts;
      visible = "shallow";
      description = ''
        Definition of systemd mount units.
        This is a list instead of an attrSet, because systemd mandates the names to be derived from
        the 'where' attribute.
      '';
    };

    automounts = mkOption {
      default = [ ];
      type = systemdUtils.types.automounts;
      visible = "shallow";
      description = ''
        Definition of systemd automount units.
        This is a list instead of an attrSet, because systemd mandates the names to be derived from
        the 'where' attribute.
      '';
    };

    slices = mkOption {
      default = { };
      type = systemdUtils.types.slices;
      visible = "shallow";
      description = "Definition of slice configurations.";
    };
  };

  config = mkIf (config.boot.initrd.enable && cfg.enable) {
    assertions = [
      {
        assertion =
          cfg.root == "fstab" -> any (fs: fs.mountPoint == "/") (builtins.attrValues config.fileSystems);
        message = "The ‘fileSystems’ option does not specify your root file system.";
      }
    ]
    ++
      map
        (name: {
          assertion = lib.attrByPath name (throw "impossible") config.boot.initrd == "";
          message = ''
            systemd stage 1 does not support 'boot.initrd.${lib.concatStringsSep "." name}'. Please
              convert it to analogous systemd units in 'boot.initrd.systemd'.

                Definitions:
            ${lib.concatMapStringsSep "\n" ({ file, ... }: "    - ${file}")
              (lib.attrByPath name (throw "impossible") options.boot.initrd).definitionsWithLocations
            }
          '';
        })
        [
          [ "preFailCommands" ]
          [ "preDeviceCommands" ]
          [ "preLVMCommands" ]
          [ "postDeviceCommands" ]
          [ "postResumeCommands" ]
          [ "postMountCommands" ]
          [ "extraUdevRulesCommands" ]
          [ "extraUtilsCommands" ]
          [ "extraUtilsCommandsTest" ]
          [
            "network"
            "postCommands"
          ]
        ];

    system.build = { inherit initialRamdisk; };

    boot.initrd.availableKernelModules = [
      # systemd needs this for some features
      "autofs"
      # systemd-cryptenroll
    ]
    ++ lib.optional cfg.package.withEfi "efivarfs";

    boot.kernelParams = [
      "root=${config.boot.initrd.systemd.root}"
    ]
    ++ lib.optional (config.boot.resumeDevice != "") "resume=${config.boot.resumeDevice}"
    # `systemd` mounts root in initrd as read-only unless "rw" is on the kernel command line.
    # For NixOS activation to succeed, we need to have root writable in initrd.
    ++ lib.optional (config.boot.initrd.systemd.root == "gpt-auto") "rw";

    boot.initrd.systemd = {
      # bashInteractive is easier to use and also required by debug-shell.service
      initrdBin = [
        pkgs.bashInteractive
        pkgs.coreutils
        cfg.package.kmod
        cfg.package
      ];
      extraBin = {
        less = "${pkgs.less}/bin/less";
        mount = "${cfg.package.util-linux}/bin/mount";
        umount = "${cfg.package.util-linux}/bin/umount";
        fsck = "${cfg.package.util-linux}/bin/fsck";
      };

      managerEnvironment.PATH = "/bin:/sbin";
      settings.Manager.ManagerEnvironment = lib.concatStringsSep " " (
        lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v}") cfg.managerEnvironment
      );
      settings.Manager.DefaultEnvironment = "PATH=/bin:/sbin";

      contents = {
        "/tmp/.keep".text = "systemd requires the /tmp mount point in the initrd cpio archive";
        "/init".source = "${cfg.package}/lib/systemd/systemd";
        "/etc/systemd/system".source = stage1Units;

        "/etc/systemd/system.conf".text = ''
          [Manager]
          ${attrsToSection cfg.settings.Manager}
        '';

        "/lib".source = "${config.system.build.modulesClosure}/lib";

        "/etc/modules-load.d/nixos.conf".text = concatStringsSep "\n" config.boot.initrd.kernelModules;

        # We can use either ! or * to lock the root account in the
        # console, but some software like OpenSSH won't even allow you
        # to log in with an SSH key if you use ! so we use * instead
        "/etc/shadow".text =
          let
            ea = cfg.emergencyAccess;
            access = ea != null && !(isBool ea && !ea);
            passwd = if isString ea then ea else "";
          in
          "root:${if access then passwd else "*"}:::::::";

        "/bin".source = "${initrdBinEnv}/bin";
        "/sbin".source = "${initrdBinEnv}/sbin";

        "/etc/sysctl.d/nixos.conf".text = "kernel.modprobe = /sbin/modprobe";
        "/etc/modprobe.d/systemd.conf".source = "${cfg.package}/lib/modprobe.d/systemd.conf";
        "/etc/modprobe.d/ubuntu.conf".source = "${pkgs.kmod-blacklist-ubuntu}/modprobe.conf";
        "/etc/modprobe.d/debian.conf".source = pkgs.kmod-debian-aliases;

        "/etc/os-release".source = config.boot.initrd.osRelease;
        "/etc/initrd-release".source = config.boot.initrd.osRelease;

        # For systemd-journald's _HOSTNAME field; needs to be set early, cannot be backfilled.
        "/etc/hostname".text = config.networking.hostName;

      }
      // optionalAttrs (config.environment.etc ? "modprobe.d/nixos.conf") {
        "/etc/modprobe.d/nixos.conf".source = config.environment.etc."modprobe.d/nixos.conf".source;
      };

      storePaths = [
        # systemd tooling
        "${cfg.package}/lib/systemd/systemd-executor"
        "${cfg.package}/lib/systemd/systemd-fsck"
        "${cfg.package}/lib/systemd/systemd-hibernate-resume"
        "${cfg.package}/lib/systemd/systemd-journald"
        "${cfg.package}/lib/systemd/systemd-makefs"
        "${cfg.package}/lib/systemd/systemd-modules-load"
        "${cfg.package}/lib/systemd/systemd-remount-fs"
        "${cfg.package}/lib/systemd/systemd-shutdown"
        "${cfg.package}/lib/systemd/systemd-sulogin-shell"
        "${cfg.package}/lib/systemd/systemd-sysctl"
        "${cfg.package}/lib/systemd/systemd-bsod"
        "${cfg.package}/lib/systemd/systemd-sysroot-fstab-check"

        # generators
        "${cfg.package}/lib/systemd/system-generators/systemd-debug-generator"
        "${cfg.package}/lib/systemd/system-generators/systemd-fstab-generator"
        "${cfg.package}/lib/systemd/system-generators/systemd-gpt-auto-generator"
        "${cfg.package}/lib/systemd/system-generators/systemd-hibernate-resume-generator"
        "${cfg.package}/lib/systemd/system-generators/systemd-run-generator"

        # utilities needed by systemd
        "${cfg.package.util-linux}/bin/mount"
        "${cfg.package.util-linux}/bin/umount"
        "${cfg.package.util-linux}/bin/sulogin"

        # required for services generated with writeShellScript and friends
        pkgs.runtimeShell
        # some tools like xfs still want the sh symlink
        "${pkgs.bashNonInteractive}/bin"

        # so NSS can look up usernames
        "${pkgs.glibc}/lib/libnss_files.so.2"

        # Resolving sysroot symlinks without code exec
        "${pkgs.chroot-realpath}/bin/chroot-realpath"
      ]
      ++ jobScripts
      ++ map (c: builtins.removeAttrs c [ "text" ]) (builtins.attrValues cfg.contents);

      targets.initrd.aliases = [ "default.target" ];
      units =
        mapAttrs' (n: v: nameValuePair "${n}.path" (pathToUnit v)) cfg.paths
        // mapAttrs' (n: v: nameValuePair "${n}.service" (serviceToUnit v)) cfg.services
        // mapAttrs' (n: v: nameValuePair "${n}.slice" (sliceToUnit v)) cfg.slices
        // mapAttrs' (n: v: nameValuePair "${n}.socket" (socketToUnit v)) cfg.sockets
        // mapAttrs' (n: v: nameValuePair "${n}.target" (targetToUnit v)) cfg.targets
        // mapAttrs' (n: v: nameValuePair "${n}.timer" (timerToUnit v)) cfg.timers
        // listToAttrs (
          map (
            v:
            let
              n = escapeSystemdPath v.where;
            in
            nameValuePair "${n}.mount" (mountToUnit v)
          ) cfg.mounts
        )
        // listToAttrs (
          map (
            v:
            let
              n = escapeSystemdPath v.where;
            in
            nameValuePair "${n}.automount" (automountToUnit v)
          ) cfg.automounts
        );

      services.initrd-find-nixos-closure = {
        description = "Find NixOS closure";

        unitConfig = {
          RequiresMountsFor = "/sysroot/nix/store";
          DefaultDependencies = false;
        };
        before = [
          "initrd.target"
          "shutdown.target"
        ];
        conflicts = [ "shutdown.target" ];
        requiredBy = [ "initrd.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = # bash
          ''
            set -uo pipefail
            export PATH="/bin:${cfg.package.util-linux}/bin:${pkgs.chroot-realpath}/bin"

            # Figure out what closure to boot
            closure=
            for o in $(< /proc/cmdline); do
                case $o in
                    init=*)
                        IFS="=" read -r -a initParam <<< "$o"
                        closure="''${initParam[1]}"
                        ;;
                esac
            done

            # Sanity check
            if [ -z "''${closure:-}" ]; then
              echo 'No init= parameter on the kernel command line' >&2
              exit 1
            fi

            # Resolve symlinks in the init parameter. We need this for some boot loaders
            # (e.g. boot.loader.generationsDir).
            closure="$(chroot-realpath /sysroot "$closure")"

            # Assume the directory containing the init script is the closure.
            closure="$(dirname "$closure")"

            ln --symbolic "$closure" /nixos-closure

            # If we are not booting a NixOS closure (e.g. init=/bin/sh),
            # we don't know what root to prepare so we don't do anything
            if ! [ -x "/sysroot$(readlink "/sysroot$closure/prepare-root" || echo "$closure/prepare-root")" ]; then
              echo "NEW_INIT=''${initParam[1]}" > /etc/switch-root.conf
              echo "$closure does not look like a NixOS installation - not activating"
              exit 0
            fi
            echo 'NEW_INIT=' > /etc/switch-root.conf
          '';
      };

      # We need to propagate /run for things like /run/booted-system
      # and /run/current-system.
      mounts = [
        {
          where = "/sysroot/run";
          what = "/run";
          options = "rbind";
          unitConfig = {
            # See the comment on the mount unit for /run/etc-metadata
            DefaultDependencies = false;
          };
          requiredBy = [ "initrd-fs.target" ];
          before = [ "initrd-fs.target" ];
        }
      ];

      services.initrd-nixos-activation = {
        after = [ "initrd-switch-root.target" ];
        requiredBy = [ "initrd-switch-root.service" ];
        before = [ "initrd-switch-root.service" ];
        unitConfig.DefaultDependencies = false;
        unitConfig = {
          AssertPathExists = "/etc/initrd-release";
          RequiresMountsFor = [
            "/sysroot/run"
          ];
        };
        serviceConfig.Type = "oneshot";
        description = "NixOS Activation";

        script = # bash
          ''
            set -uo pipefail
            export PATH="/bin:${cfg.package.util-linux}/bin"

            closure="$(realpath /nixos-closure)"

            # Initialize the system
            export IN_NIXOS_SYSTEMD_STAGE1=true
            exec chroot /sysroot "$closure/prepare-root"
          '';
      };

      # This will either call systemctl with the new init as the last parameter (which
      # is the case when not booting a NixOS system) or with an empty string, causing
      # systemd to bypass its verification code that checks whether the next file is a systemd
      # and using its compiled-in value
      services.initrd-switch-root.serviceConfig = {
        EnvironmentFile = "-/etc/switch-root.conf";
        ExecStart = [
          ""
          ''systemctl --no-block switch-root /sysroot "''${NEW_INIT}"''
        ];
      };

      services.panic-on-fail = {
        wantedBy = [ "emergency.target" ];
        unitConfig = {
          DefaultDependencies = false;
          ConditionKernelCommandLine = [
            "|boot.panic_on_fail"
            "|stage1panic"
          ];
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/echo c";
          StandardOutput = "file:/proc/sysrq-trigger";
        };
      };
    };
  };
}
