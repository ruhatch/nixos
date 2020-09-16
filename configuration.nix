# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, config, pkgs, ... }:

let

  inherit (pkgs) lib stdenv fetchFromGitHub;

  # 'show-clock' shows an xclock that disappears when it loses focus
  show-clock = pkgs.writeScriptBin "show-clock" ''
    ${pkgs.xorg.xclock}/bin/xclock -digital -brief -padding 75 &

    while [ true ]
    do
      sleep 1
      window=`xdotool getwindowfocus getwindowname`
      if [ "$window" != "xclock" ]; then
        pkill -9 xclock
        exit
      fi
    done
  '';

  # 'focus' is a small script to set a focus in xmobar
  focus = pkgs.writeScriptBin "focus" ''
    xprop -root -f focus 8s -set focus "$*"
  '';

  pom = pkgs.writeScriptBin "pom" ''
    writeToTimer(){
      xprop -root -f pom-timer 8s -set pom-timer "$1"
    }

    countdown(){
      date1=$((`date +%s` + $1));
      while [ "$date1" -ge `date +%s` ]; do
        writeToTimer "$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)";
        sleep 0.1
      done
    }

    killPom(){
      if [ $(pgrep -c -f "pom ") -ge 2 ]; then
        kill -9 $(pgrep -f "pom " | head -n -2)
      fi
    }

    printUsage(){
      echo "pom [start|break|long-break|stop]"
    }

    if [ -n "$1" ]; then
      case "$1" in
        "start")
          killPom
          countdown $((25 * 60))
          writeToTimer "<action=\`pom break\` button=1>Pom finished. Start a break?</action>"
          gxmessage -geometry 600x400 -center "Pomodoro finished!"
          ;;
        "break")
          killPom
          countdown $((5 * 60))
          writeToTimer "<action=\`pom start\` button=1>Break finished. Start another pom?</action>"
          gxmessage -geometry 600x400 -center "Break finished!"
          ;;
        "long-break")
          killPom
          countdown $((20 * 60))
          writeToTimer "<action=\`pom start\` button=1>Break finished. Start another pom?</action>"
          gxmessage -geometry 600x400 -center "Break finished!"
          ;;
        "stop")
          killPom
          writeToTimer "<action=\`pom start\` button=1>Start a pomodoro</action>"
          ;;
        *) printUsage ;;
      esac
    else
      printUsage
    fi
  '';

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./keys.nix
      ./networking.nix
    ];

  # Add this from broadcom-43xx.nix module to allow flake usage
  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot.kernelModules = [ "coretemp" ];
  boot.kernelParams = [ "i8042.reset" ];
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.timeout = 0;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  hardware.cpu.intel.updateMicrocode = true;

  swapDevices = [ { label = "swap"; } ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # Set console font and key mapping
  console.font = "latarcyrheb-sun32";
  console.keyMap = "uk";

  # Set your time zone.
  time.timeZone = "Europe/London";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # shell scripts
    focus
    pom
    show-clock

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
    picom
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

    # Only needed until PR https://github.com/NixOS/nixpkgs/pull/86480
    # steam
  ];

  # Only needed until PR https://github.com/NixOS/nixpkgs/pull/86480
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Enable light for setting backlight and add video group for permissions
  programs.light.enable = true;
  users.groups.video = {};

  programs.zsh = {
    enable = true;
    # ohMyZsh = {
    #   enable = true;
    #   theme = "spaceship";
    # };
  };

  users.defaultUserShell = pkgs.zsh;

  programs.vim.defaultEditor = true;

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";

  environment.shells = [ "/run/current-system/sw/bin/zsh" ];

  fonts.fonts = with pkgs; [ fira-code fira-code-symbols font-awesome-ttf ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  hardware.bluetooth.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  services.logind.lidSwitch = "hibernate";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.gutenprint ];

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager = {
      xserverArgs = [ "-dpi 192" ];
      lightdm = {
        enable = true;
        background = "/etc/nixos/background.jpg";
        greeters.pantheon.enable = true;
      };
    };
    windowManager.xmonad.enable = true;
    windowManager.xmonad.enableContribAndExtras = true;
    layout = "gb";
    libinput.enable = true;
    libinput.naturalScrolling = true;
    libinput.tapping = false;
  };

  # Enable Redshift to change screen temperature
  services.redshift = {
    enable = true;
    brightness.night = "0.3";
  };
  location.provider = "geoclue2";

  services.lorri.enable = true;

  # Themes
  environment.extraInit = ''
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

  # QT4/5 global theme
  environment.etc."xdg/Trolltech.conf" = {
    text = ''
      [Qt]
      style=Arc-Darker
    '';
    mode = "444";
  };

  environment.etc."xdg/gtk-3.0/settings.ini" = {
    text = ''
      [Settings]
      gtk-icon-theme-name=breeze
      gtk-theme-name=Arc-Darker
    '';
    mode = "444";
  };

  environment.etc."libinput-gestures.conf" = {
    text = ''
      device DLL06E4:01 06CB:7A13 Touchpad
      gesture swipe left xdotool key Super_L+shift+Tab
      gesture swipe right xdotool key Super_L+shift+alt+Tab
    '';
    mode = "444";
  };

  environment.variables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  environment.variables.SUDO_ASKPASS = "${pkgs.x11_ssh_askpass}/libexec/ssh-askpass";

  systemd.user.services."libinput-gestures" = {
    description = "Add multitouch gestures using libinput-gestures";
    wantedBy = [ "default.target" ];
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 2;
    serviceConfig.ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
    environment = { DISPLAY = ":0"; };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rupert = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "audio" "video" "plugdev" ];
    useDefaultShell = true;
  };

  users.groups.plugdev = {};

  # programs.oblogout = {
  #   enable = true;
  #   buttons = "cancel, logout, restart, shutdown, lock, hibernate";
  #   clogout = "xdotool key Super_L+shift+Q";
  #   clock = "slock";
  # };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.09";

  system.autoUpgrade.enable = true;

  programs.gnupg.agent.enable = true;

  # Money&Co.
  services.postgresql.enable = true;

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

  nix.package = pkgs.nixUnstable;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.trustedUsers = [ "root" "rupert" ];
}
