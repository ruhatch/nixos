# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./keys.nix
      ./networking.nix
      ./scripts.nix
      ./tiny-greeter-config.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    kernelModules = [ "coretemp" ];
    kernelParams = [ "i8042.reset" ];
    loader = {
      grub.device = "/dev/nvme0n1";
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 100;
      };
      efi.canTouchEfiVariables = true;
    };
    plymouth.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
    cpu.intel.updateMicrocode = true;
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
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
      extraGroups = [ "wheel" "input" "audio" "video" "plugdev" ];
      useDefaultShell = true;
    };
  };

  programs = {
    gnupg.agent.enable = true;
    light.enable = true; # Backlight control
    steam.enable = true;
    vim.defaultEditor = true;
    zsh.enable = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    arc-theme
    aspell
    aspellDicts.en
    at_spi2_core
    breeze-qt5
    cabal-install
    direnv
    discount # Markdown rendering
    emacs
    fasd
    feh
    firefox
    git
    git-crypt
    gnumake
    gnupg
    gxmessage
    haskellPackages.ghcid
    haskellPackages.hasktags
    haskellPackages.hlint
    haskellPackages.xmobar
    hsetroot
    htop
    keepassx2
    keychain
    minecraft
    openssl
    openvpn
    ormolu
    pavucontrol
    python3 # For floobits
    ripgrep
    rofi
    rxvt_unicode
    slock
    stack
    texlive.combined.scheme-full
    vlc
    xdotool
    xssproxy
    zathura

    # Photo handling
    gphoto2
    rapid-photo-downloader
  ];

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";

  fonts.fonts = with pkgs; [ fira-code fira-code-symbols font-awesome-ttf ];

  # List services that you want to enable:
  services = {
    logind.lidSwitch = "hibernate";
    lorri.enable = true;
    openssh.enable = true;

    # Enable picom for compositing
    picom = {
      enable = true;
      backend = "glx";
      fade = true;
      settings = {
        detect-transient = true;
        detect-client-leader = true;
        xrender-sync-fence = true;
      };
      shadow = true;
      shadowOffsets = [ (-17) (-17) ];
      wintypes = {
        dock = { shadow = false; };
        dropdown_menu = { shadow = false; };
      };
    };

    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = [ pkgs.gutenprint ];
    };

    postgresql.enable = true;

    # Enable redshift to change screen temperature
    redshift = {
      enable = true;
      brightness.night = "0.3";
      temperature.day = 5000;
    };

    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "none+xmonad";
        xserverArgs = [ "-dpi 192" ];
        lightdm = {
          enable = true;
          background = "/etc/nixos/background.jpg";
          greeters.tiny.enable = true;
          # greeters.pantheon.enable = true;
        };
      };
      windowManager.xmonad.enable = true;
      windowManager.xmonad.enableContribAndExtras = true;
      layout = "gb";
      libinput.enable = true;
      libinput.naturalScrolling = true;
      libinput.tapping = false;
    };
  };

  location.provider = "geoclue2"; # For redshift

  # Set up the environment, including themes, system packages, and variables
  environment = {
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

  systemd.user.services = {
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
  };

  # programs.oblogout = {
  #   enable = true;
  #   buttons = "cancel, logout, restart, shutdown, lock, hibernate";
  #   clogout = "xdotool key Super_L+shift+Q";
  #   clock = "slock";
  # };

  # Money&Co. TODO: Clean this up
  environment.etc.git-ssh-config = {
    text = ''
      Host github.com
      IdentityFile /etc/ssh/mandco_rsa_key
      StrictHostKeyChecking=no
    '';
    user = "nixbld1";
    group = "nixbld";
    mode = "0400";
  };

  nix.nixPath = [
    "ssh-config-file=/etc/git-ssh-config"
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Fixing network failure on resume bug
  powerManagement.resumeCommands = ''
    systemctl restart dhcpcd.service
  '';

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command ca-references flakes
    '';
    trustedUsers = [ "root" "rupert" ];
  };

  nixpkgs.config.allowUnfree = true;

}
