# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, config, pkgs, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

  i8k = pkgs.callPackage ./i8k.nix {};
  dell-bios-fan-control = pkgs.callPackage ./dell-bios-fan-control.nix {};
  dellfan = pkgs.callPackage ./dellfan.nix {};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./keys.nix
      ./networking.nix
      ./scripts.nix

      ./rofi-config.nix
      ./tiny-greeter-config.nix
    ];

  nixpkgs = {
    config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "google-chrome"
      "keymapp"
      "nvidia-settings"
      "nvidia-x11"
      "optifine"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "vscode-with-extensions"
      "wpsoffice"
      "zoom"
    ];
    overlays = [
      (self: super: {
        gnome-shell = super.gnome-shell.overrideAttrs (old: {
          patches = (old.patches or []) ++ [
            (pkgs.writeText "bg.patch" ''
              --- a/data/theme/gnome-shell-sass/widgets/_login-lock.scss
              +++ b/data/theme/gnome-shell-sass/widgets/_login-lock.scss
              @@ -15,4 +15,5 @@ $_gdm_dialog_width: 23em;
               /* Login Dialog */
               .login-dialog {
                 background-color: $_gdm_bg;
              +  background-image: url('file:///etc/nixos/background.jpg');
               }
            '')
          ];
        });
      })
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernel.sysctl = { "vm.swappiness" = 10; };
    extraModprobeConfig = ''
      options i8k force=1 ignore_dmi=1
    '';
    kernelModules = [ "coretemp" "i8k" ];
    kernelParams = [
        "quiet"
        "splash"
        "vga=current"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
    ];
    loader = {
      grub = {
        device = "/dev/nvme0n1";
        useOSProber = true;
      };
      timeout = 10;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = 100;
      };
      efi.canTouchEfiVariables = true;
    };
    plymouth.enable = true;
    initrd.verbose = false;
    consoleLogLevel = 0;
  };

  hardware = {
    bluetooth.enable = true;
    cpu.intel.updateMicrocode = true;
    graphics.enable = true;
    keyboard.zsa.enable = true;
    # Enable udev rules for Ledger support
    ledger.enable = true;
    nvidia = {
      open = false;
      modesetting.enable = true;
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  swapDevices = [ { label = "swap"; } ];

  # The NixOS release to be compatible with for stateful data such as databases.
  system = {
    autoUpgrade.enable = true;
    stateVersion = "17.09";
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # Set console font and key mapping
  console.font = "latarcyrheb-sun32";
  console.keyMap = "uk";

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;

    groups = {
      plugdev = {};
      video = {}; # Needed for light
    };

    users.rupert = {
      isNormalUser = true;
      extraGroups = [ "wheel" "input" "audio" "video" "plugdev" "docker" "adbusers" ];
      useDefaultShell = true;
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    direnv.enable = true;
    gnupg.agent.enable = true;
    light.enable = true; # Backlight control
    steam.enable = true;
    vim = {
      enable = true;
      defaultEditor = true;
    };
    zsh.enable = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    arc-theme
    aspell
    aspellDicts.en
    blueberry
    brave
    breeze-qt5
    cabal-install
    direnv
    discount # Markdown rendering
    emacs
    exercism
    fasd
    feh
    firefox
    git
    gitAndTools.gh
    git-crypt
    gnome-pomodoro
    gnome-tweaks
    gnumake
    gnupg
    gxmessage
    haskellPackages.fourmolu
    haskellPackages.ghcid
    haskellPackages.hasktags
    haskellPackages.hlint
    haskellPackages.xmobar
    hsetroot
    htop
    keychain
    keymapp
    nvidia-offload
    nodejs-slim
    nodePackages.npm
    nodePackages.create-react-app
    openssl
    optifine
    pavucontrol
    pre-commit
    prismlauncher
    python3
    ripgrep
    rofi
    rxvt-unicode-unwrapped
    slock
    stack
    texlive.combined.scheme-full
    vlc
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        haskell.haskell
        jnoortheen.nix-ide 
        justusadam.language-haskell
        kahole.magit
        mechatroner.rainbow-csv
        mkhl.direnv
        ms-python.black-formatter
	ms-python.python
        ms-python.vscode-pylance
        vscodevim.vim
      ];
    })
    wpa_supplicant_gui
    xdotool
    xssproxy
    zathura
    zoom-us

    # Photo handling
    gphoto2
    rapid-photo-downloader

    # i8kutils
    dell-bios-fan-control
    dellfan
    i8k
    tcl
    tcllib
  ];

  fonts.packages = with pkgs; [ fira-code fira-code-symbols font-awesome inter ];

  # List services that you want to enable:
  services = {
    logind.lidSwitch = "hibernate";
    lorri.enable = true;
    openssh.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    # Enable picom for compositing
    # picom = {
    #   enable = true;
    #   backend = "glx";
    #   fade = true;
    #   settings = {
    #     detect-transient = true;
    #     detect-client-leader = true;
    #     xrender-sync-fence = true;
    #   };
    #   shadow = true;
    #   shadowOffsets = [ (-17) (-17) ];
    #   wintypes = {
    #     dock = { shadow = false; };
    #     dropdown_menu = { shadow = false; };
    #   };
    # };

    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = [ pkgs.gutenprint ];
    };

    # Enable redshift to change screen temperature
    # redshift = {
    #   enable = true;
    #   brightness.night = "0.3";
    #   temperature.day = 5000;
    # };

    tailscale.enable = true;

    udev.extraRules = ''
      SUBSYSTEM=="hwmon", ATTRS{name}=="dell_smm", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/sys/subsystem/hwmon/devices/dell_smm"
    '';

    undervolt = {
      enable = true;
      coreOffset = -125;
      uncoreOffset = -125;
      analogioOffset = -125;
      gpuOffset = -100;
    };

    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      #displayManager = {
      #  defaultSession = "none+xmonad";
      #  xserverArgs = [ "-dpi 192" ];
      #  lightdm = {
      #    enable = true;
      #    background = "/etc/nixos/background.jpg";
      #    greeters.tiny.enable = true;
      #  };
      #};
      #windowManager.xmonad.enable = true;
      #windowManager.xmonad.enableContribAndExtras = true;
      #libinput.enable = true;
      #libinput.touchpad = {
      #  naturalScrolling = true;
      #  tapping = false;
      #};
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "gb";
        options = "compose:ralt";
      };
    };
  };

  # location.provider = "geoclue2"; # For redshift

  # Set up the environment, including themes, system packages, and variables
  environment = {
    gnome.excludePackages = (with pkgs; [
      cheese
      epiphany
      gnome-characters
      gnome-music
      gnome-photos
      gnome-tour
      tali
      iagno
      hitori
      atomix
      yelp
      gnome-contacts
      gnome-initial-setup
    ]);

    etc = {
      # QT4/5 global theme
      "xdg/Trolltech.conf" = {
        text = ''
          [Qt]
          style=Arc-Darker
        '';
        mode = "444";
      };
      "xdg/gtk-3.0/settings.ini" = {
        text = ''
          [Settings]
          gtk-icon-theme-name=breeze
          gtk-theme-name=Arc-Darker
        '';
        mode = "444";
      };
      "libinput-gestures.conf" = {
        text = ''
          device DLL06E4:01 06CB:7A13 Touchpad
          gesture swipe left xdotool key Super_L+shift+Tab
          gesture swipe right xdotool key Super_L+shift+alt+Tab
        '';
        mode = "444";
      };
      "stack/config.yaml" = {
        text = ''
          system-ghc: true
        '';
        mode = "444";
      };
      "i8kmon.conf" = {
        text = ''
          # External program to control the fans
          set config(i8kfan)  i8kfan

          # Report status on stdout, override with --verbose option
          set config(verbose) 0

          # Status check timeout (seconds), override with --timeout option
          set config(timeout) 2
          # Temperature display unit (C/F), override with --unit option
          set config(unit)    C
          # Temperature threshold at which the temperature is displayed in red
          set config(t_high)  85
          # Minimum expected fan speed
          set config(min_speed) 1200

          # Temperature thresholds: {fan_speeds low_ac high_ac low_batt high_batt}
          # These were tested on the I8000. If you have a different Dell laptop model
          # you should check the BIOS temperature monitoring and set the appropriate
          # thresholds here. In doubt start with low values and gradually rise them
          # until the fans are not always on when the cpu is idle.
          # set config(0)   {{0 0}  -1  70  -1  75}
          # set config(1)   {{0 1}  65  80  65  80}
          # set config(2)   {{1 1}  75  85  75  85}
          # set config(3)   {{2 2}  80 128  80 128}
          set config(0)   {{0 0}  -1  0  -1  0}
          set config(1)   {{0 1}  2  2  2 2}
          set config(2)   {{1 1}  3  3  3  3}
          set config(3)   {{1 2}  4 4 4 4}
          set config(4)   {{2 2}  5 5 5 5}

          # Speed values are set here to avoid i8kmon probe them at every time it starts.
          set status(leftspeed)   "0 1250 2500 5000"
          set status(rightspeed)  "0 1250 2500 5000"
        '';
        mode = "444";
      };
    };

    extraInit = ''
      # GTK3: add /etc/xdg/gtk-3.0 to search path for settings.ini
      # We use /etc/xdg/gtk-3.0/settings.ini to set the icon and theme name for GTK 3
      export XDG_CONFIG_DIRS="/etc/xdg:$XDG_CONFIG_DIRS"
      # GTK2 theme + icon theme
      export GTK2_RC_FILES=${pkgs.arc-theme}/share/themes/Arc-Darker/gtk-2.0/gtkrc:$GTK2_RC_FILES

      # these are the defaults, but some applications are buggy so we set them
      # here anyway
      export XDG_CONFIG_HOME=$HOME/.config
      export XDG_DATA_HOME=$HOME/.local/share
      export XDG_CACHE_HOME=$HOME/.cache
    '';

    shells = [ "/run/current-system/sw/bin/zsh" ];

    variables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      SUDO_ASKPASS = "${pkgs.x11_ssh_askpass}/libexec/ssh-askpass";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "L+ /lib64/ld-linux-x86-64.so.2 - - - - ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2"
    ];
    user.services = {
      "libinput-gestures" = {
        description = "Add multitouch gestures using libinput-gestures";
        wantedBy = [ "default.target" ];
        serviceConfig.Restart = "always";
        serviceConfig.RestartSec = 2;
        serviceConfig.ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
        environment = { DISPLAY = ":0"; };
      };
      "feh-background" = {
        description = "Set desktop background using feh";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = "${pkgs.feh}/bin/feh --no-fehbg --bg-center /etc/nixos/background.jpg";
      };
      # Needed until bug fixed by PR https://github.com/NixOS/nixpkgs/pull/275024 
      lorri.serviceConfig = {
        ProtectSystem = pkgs.lib.mkForce "full";
        ProtectHome = pkgs.lib.mkForce false;   
      };
    };
    # services = {
    #   "i8kmon" = {
    #     description = "DELL notebook fan control";
    #     requisite = [ "multi-user.target" ];
    #     after = [ "sys-subsystem-hwmon-devices-dell_smm.device" "multi-user.target" ];
    #     bindsTo = [ "sys-subsystem-hwmon-devices-dell_smm.device" ];
    #     serviceConfig = {
    #       ExecStartPre= "${dell-bios-fan-control}/bin/dell-bios-fan-control 0 ";
    #       ExecStart = "${i8k}/bin/i8kmon";
    #       ExecStopPost = "${dell-bios-fan-control}/bin/dell-bios-fan-control 1";
    #       Restart = "always";
    #       RestartSec = 5;
    #     };
    #     wantedBy = [ "sys-subsystem-hwmon-devices-dell_smm.device" ];
    #   };
    # };
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      bip = "10.200.0.1/24";
      fixed-cidr = "10.200.0.1/25";
      default-address-pools = [
        {base = "10.201.0.0/16"; size = 24;}
        {base = "10.202.0.0/16"; size = 24;}
      ];
    };
  };

  # Fixing network failure on resume bug
  powerManagement = {
    powertop.enable = true;
    resumeCommands = ''
      systemctl restart dhcpcd.service
      systemctl restart wpa_supplicant-wlp2s0.service
    '';
  };

  nix = {
    package = pkgs.nixVersions.git;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "rupert" ];
  };

}
