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
      "nvidia-settings"
      "nvidia-x11"
      "optifine"
      "steam"
      "steam-original"
      "steam-run"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "vscode-with-extensions"
      "wpsoffice"
    ];
    overlays = [
      (self: super: {
        gnome = super.gnome.overrideScope (selfg: superg: {
          gnome-shell = superg.gnome-shell.overrideAttrs (old: {
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
        });
      })
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot = {
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
    # Enable udev rules for Ledger support
    ledger.enable = true;
    opengl.enable = true;
    nvidia = {
      modesetting.enable = true;
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
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
    vim.defaultEditor = true;
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
    gnome.gnome-tweaks
    gnome.pomodoro
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
    nvidia-offload
    nodejs-slim
    nodePackages.npm
    nodePackages.create-react-app
    openssl
    openvpn
    optifine
    pavucontrol
    pre-commit
    prismlauncher
    python3
    ripgrep
    rofi
    rxvt_unicode
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

    # openvpn.servers.mandco = {
    #   config = ''
    #     client
    #     nobind
    #     dev tun
    #     remote openvpn.mcointernal.net 443 tcp
    #     providers legacy default
    #     data-ciphers AES-256-CBC:BF-CBC
    #     route 34.247.35.19 255.255.255.255 10.240.0.9
    #     route 172.0.0.0 255.0.0.0 10.240.0.9
    #     <key>
    #     -----BEGIN PRIVATE KEY-----
    #     MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDE9R2TLaucDnuW
    #     JjZODXs2GdTdnsgNBYJSXNlOo/8dEyK219drSl0cHTMoDJFtMXAR067DUjza4G8F
    #     cAtVxxhRsE6gpeF38JnzytjoOcSTj+6PHO8QVL5U1tyQjBExLexmzdlAZAmy1KJY
    #     WUyjL6Rp98uesoVlEmr0DxqvGPWoVuxvdVk3uQJqZsRFggmxnMJkoUda2VbwJn9W
    #     rAefGgXKAeRTyEBkFoI4VoYR6FEVof96ASBt/nRkavfuo1lU8fimAcv1YnGJ6a5x
    #     XSsiVgzPPN4U2UuWjymqc9ldm5Uba5EBQAtLHjEDww09I37stuC5CVGtKhMN5UFw
    #     AJijMKSvAgMBAAECggEAV4Jq8g48LdnXemafAT4HLQn8JL3cN8DnXu3nFYRTINl0
    #     NpYfHgoL5aZpqNUwtjndh+YsQ5dh94P5gAqA1stfmEgEH2ekjpRl6saJamDkYQX1
    #     4jtiUri8Wlie5lB9gQLdAu5aJTxtfLnyKdv/a5AK9pRFMc0y7K3qvGaLnhmyaGjy
    #     1KpyTonH+L/udoflelUNFUKbckMmE5sX/f23V5EB8Q6Ldb4rzpEt9PnZ/7IQqGFW
    #     VPpp8HEQTe3gqeqCcrDDPtGldGahbiIyySdBcywN3tWqbw01cC6DWCRC1ByAKBEK
    #     CGVHWyvHUJhdITJXCIR+jjQ6mkxohjVNiFKScHaiuQKBgQDsgpyu0X4LC/vGgWF5
    #     /NfSg1tb+bmkfFjKvsyrRsCmh3US6z3k9Jww6lYUVoPfNA/JMdvC+OBwWNcU53dX
    #     YZYNu5QgO33goQ6+iJoG3uzrKOEdkqtqJSnCo2DlPqRsdL8XfQ64UQXDs4jqpfGR
    #     QV7XkyQzddcX/mY6fiCEyE0NtwKBgQDVMBrB1onkse9nrxppWJoFcpR9HHJpEy1i
    #     XTVTug+bCK3X/sROlZgboVbutZ69P4X1gIiUZvnQYG7mRQGsLWrWcHHurtqp6kdB
    #     aeOyPrGj6re4HW4PUr1xId2ehsZGWUUtGY5Ncoo9VYFB968MnyHMoP5Lbm9AeVzN
    #     sCJ96tYgyQKBgQDn28OuvkFKoxzYpc3hwTXzckMGD/MmhaCmYhZTcrE6kGD9gxDS
    #     e9sDOTfaCFaPYoJ3QyGmKkYc3Xs9Sw175HcuT04Pq0LkDABgWZpmUfUBNLo8O6VA
    #     Ed62qWQ8WQToLiuH41mi6As2p7L6FmSTefp4bA95Q3TyWLvva+aFRbgEUQKBgF4Z
    #     CIZsapr+CvzJ5i9/gyRKac47Qyir5UlYeNRG+OJmV01ST1WcY/I2KYfdtH41zqwJ
    #     Gr/eH//gwLJ03QMhXNnf8fn3Rd7f4Km30l/3mjMOxB7JJq4uyB1qZEa3mEau2oDI
    #     me4HU4s09YOnjqVUi/elS/kBequLpfHH/8FyaSc5AoGBAMX5Ts/ryec/tzGpEB0J
    #     dejXfxtrQUjKoCxRit/8SOZ6OBgMQ+BIxCo3vHPjND31kgLjD6oaw/OBvcOYyJMW
    #     HdIunxooxPBbTYX4AP6iOGqLfTZ/DE5TBpcEwvt7g3GNPn0rBcZGDZce0GxQh1q7
    #     1tVIGB8PsBdB1jOO1DcNPuix
    #     -----END PRIVATE KEY-----
    #     </key>
    #     <cert>
    #     Certificate:
    #         Data:
    #             Version: 3 (0x2)
    #             Serial Number:
    #                 5e:cb:53:72:11:94:7d:73:b3:8d:97:91:90:af:bc:2c
    #             Signature Algorithm: sha256WithRSAEncryption
    #             Issuer: CN=Easy-RSA CA
    #             Validity
    #                 Not Before: Oct 11 12:07:58 2022 GMT
    #                 Not After : Jan 13 12:07:58 2025 GMT
    #             Subject: CN=adam
    #             Subject Public Key Info:
    #                 Public Key Algorithm: rsaEncryption
    #                     Public-Key: (2048 bit)
    #                     Modulus:
    #                         00:c4:f5:1d:93:2d:ab:9c:0e:7b:96:26:36:4e:0d:
    #                         7b:36:19:d4:dd:9e:c8:0d:05:82:52:5c:d9:4e:a3:
    #                         ff:1d:13:22:b6:d7:d7:6b:4a:5d:1c:1d:33:28:0c:
    #                         91:6d:31:70:11:d3:ae:c3:52:3c:da:e0:6f:05:70:
    #                         0b:55:c7:18:51:b0:4e:a0:a5:e1:77:f0:99:f3:ca:
    #                         d8:e8:39:c4:93:8f:ee:8f:1c:ef:10:54:be:54:d6:
    #                         dc:90:8c:11:31:2d:ec:66:cd:d9:40:64:09:b2:d4:
    #                         a2:58:59:4c:a3:2f:a4:69:f7:cb:9e:b2:85:65:12:
    #                         6a:f4:0f:1a:af:18:f5:a8:56:ec:6f:75:59:37:b9:
    #                         02:6a:66:c4:45:82:09:b1:9c:c2:64:a1:47:5a:d9:
    #                         56:f0:26:7f:56:ac:07:9f:1a:05:ca:01:e4:53:c8:
    #                         40:64:16:82:38:56:86:11:e8:51:15:a1:ff:7a:01:
    #                         20:6d:fe:74:64:6a:f7:ee:a3:59:54:f1:f8:a6:01:
    #                         cb:f5:62:71:89:e9:ae:71:5d:2b:22:56:0c:cf:3c:
    #                         de:14:d9:4b:96:8f:29:aa:73:d9:5d:9b:95:1b:6b:
    #                         91:01:40:0b:4b:1e:31:03:c3:0d:3d:23:7e:ec:b6:
    #                         e0:b9:09:51:ad:2a:13:0d:e5:41:70:00:98:a3:30:
    #                         a4:af
    #                     Exponent: 65537 (0x10001)
    #             X509v3 extensions:
    #                 X509v3 Basic Constraints:
    #                     CA:FALSE
    #                 X509v3 Subject Key Identifier:
    #                     B1:39:53:F6:38:4C:0B:77:2F:FB:50:D2:3F:44:3F:8F:C8:5F:6D:E2
    #                 X509v3 Authority Key Identifier:
    #                     keyid:CE:B0:B7:14:68:F8:AD:42:EE:3F:71:2E:67:9F:9F:0D:91:8B:8A:97
    #                     DirName:/CN=Easy-RSA CA
    #                     serial:55:19:1D:C8:ED:1B:74:39:80:BC:A9:F0:28:B5:D9:B2:A7:B5:1C:39
    #                 X509v3 Extended Key Usage:
    #                     TLS Web Client Authentication
    #                 X509v3 Key Usage:
    #                     Digital Signature
    #         Signature Algorithm: sha256WithRSAEncryption
    #         Signature Value:
    #             14:3f:59:cf:4a:f1:ab:49:2e:15:7c:46:26:0a:80:85:96:df:
    #             fd:7d:72:08:e4:42:70:5e:50:48:18:d7:f1:54:39:b7:05:00:
    #             16:64:c3:62:42:59:32:45:16:8d:44:d7:9c:e7:08:fe:77:2d:
    #             7c:f9:e5:cb:1d:f8:aa:ce:bf:0e:1c:b5:c5:1e:09:ad:d5:0b:
    #             89:07:01:52:13:71:5a:ae:bd:fe:7c:fb:53:98:72:ad:d1:62:
    #             30:1c:53:86:36:85:f4:3c:71:e5:8c:c5:aa:fa:19:1c:bc:78:
    #             d7:5d:f4:c1:13:c8:18:3c:b7:aa:10:9e:de:63:3f:6b:37:65:
    #             10:a5:2e:bb:2c:6e:4a:40:08:21:98:1d:d5:32:40:94:ce:76:
    #             c6:04:87:a6:d7:5c:4c:7a:94:4e:98:1a:ad:04:48:8e:47:ba:
    #             9a:de:0f:86:91:3a:18:5a:09:93:c5:7d:a0:b2:db:b7:06:f6:
    #             41:07:78:88:fb:79:74:58:5c:5b:38:82:7b:f3:74:98:a1:12:
    #             cf:72:c5:3e:12:74:76:ed:6b:78:19:b1:1f:fb:95:cb:62:76:
    #             0f:15:a4:80:b0:d6:09:e9:6d:6d:14:17:b1:76:58:e3:8c:9e:
    #             d2:fd:47:cd:20:fb:de:e3:5d:25:21:42:8d:69:86:34:1b:c8:
    #             4d:95:a3:89
    #     -----BEGIN CERTIFICATE-----
    #     MIIDUjCCAjqgAwIBAgIQXstTchGUfXOzjZeRkK+8LDANBgkqhkiG9w0BAQsFADAW
    #     MRQwEgYDVQQDDAtFYXN5LVJTQSBDQTAeFw0yMjEwMTExMjA3NThaFw0yNTAxMTMx
    #     MjA3NThaMA8xDTALBgNVBAMMBGFkYW0wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
    #     ggEKAoIBAQDE9R2TLaucDnuWJjZODXs2GdTdnsgNBYJSXNlOo/8dEyK219drSl0c
    #     HTMoDJFtMXAR067DUjza4G8FcAtVxxhRsE6gpeF38JnzytjoOcSTj+6PHO8QVL5U
    #     1tyQjBExLexmzdlAZAmy1KJYWUyjL6Rp98uesoVlEmr0DxqvGPWoVuxvdVk3uQJq
    #     ZsRFggmxnMJkoUda2VbwJn9WrAefGgXKAeRTyEBkFoI4VoYR6FEVof96ASBt/nRk
    #     avfuo1lU8fimAcv1YnGJ6a5xXSsiVgzPPN4U2UuWjymqc9ldm5Uba5EBQAtLHjED
    #     ww09I37stuC5CVGtKhMN5UFwAJijMKSvAgMBAAGjgaIwgZ8wCQYDVR0TBAIwADAd
    #     BgNVHQ4EFgQUsTlT9jhMC3cv+1DSP0Q/j8hfbeIwUQYDVR0jBEowSIAUzrC3FGj4
    #     rULuP3EuZ5+fDZGLipehGqQYMBYxFDASBgNVBAMMC0Vhc3ktUlNBIENBghRVGR3I
    #     7Rt0OYC8qfAotdmyp7UcOTATBgNVHSUEDDAKBggrBgEFBQcDAjALBgNVHQ8EBAMC
    #     B4AwDQYJKoZIhvcNAQELBQADggEBABQ/Wc9K8atJLhV8RiYKgIWW3/19cgjkQnBe
    #     UEgY1/FUObcFABZkw2JCWTJFFo1E15znCP53LXz55csd+KrOvw4ctcUeCa3VC4kH
    #     AVITcVquvf58+1OYcq3RYjAcU4Y2hfQ8ceWMxar6GRy8eNdd9METyBg8t6oQnt5j
    #     P2s3ZRClLrssbkpACCGYHdUyQJTOdsYEh6bXXEx6lE6YGq0ESI5HupreD4aROhha
    #     CZPFfaCy27cG9kEHeIj7eXRYXFs4gnvzdJihEs9yxT4SdHbta3gZsR/7lctidg8V
    #     pICw1gnpbW0UF7F2WOOMntL9R80g+97jXSUhQo1phjQbyE2Vo4k=
    #     -----END CERTIFICATE-----
    #     </cert>
    #     <ca>
    #     -----BEGIN CERTIFICATE-----
    #     MIIDSzCCAjOgAwIBAgIUVRkdyO0bdDmAvKnwKLXZsqe1HDkwDQYJKoZIhvcNAQEL
    #     BQAwFjEUMBIGA1UEAwwLRWFzeS1SU0EgQ0EwHhcNMjIxMDExMTIwNzI1WhcNMzIx
    #     MDA4MTIwNzI1WjAWMRQwEgYDVQQDDAtFYXN5LVJTQSBDQTCCASIwDQYJKoZIhvcN
    #     AQEBBQADggEPADCCAQoCggEBANV5K+pTV+XfCjT7laSc+3jkOFJgPMAojaMlRWog
    #     DBSHb6O9/mr2KG4qR8nlKZoYhVMUGtT9DPsetjBZzDEjGcvLHWazgtwAgPV1atcj
    #     XY4XT5LvknIY+u0JguLyy7hVD6b9rTkjUXMpwQa/kiH4+vP9O60aOVV9CrHnA3IF
    #     NXTJd5ULiadRcHt9h4/RJbJm1/aFaUzkap217wedOQrFj/3WvtfyATjcCUIkcXrz
    #     DZLImV2hJPVPv+CZCArzLBIVQnE/R9nWuGoqZSDIRzOr+fTb7mu98jgjxCjxToxY
    #     UfUdOXXzYukEjjQkyQck2BjG8J7h+rXyrmgBFDQA+qUEEKcCAwEAAaOBkDCBjTAM
    #     BgNVHRMEBTADAQH/MB0GA1UdDgQWBBTOsLcUaPitQu4/cS5nn58NkYuKlzBRBgNV
    #     HSMESjBIgBTOsLcUaPitQu4/cS5nn58NkYuKl6EapBgwFjEUMBIGA1UEAwwLRWFz
    #     eS1SU0EgQ0GCFFUZHcjtG3Q5gLyp8Ci12bKntRw5MAsGA1UdDwQEAwIBBjANBgkq
    #     hkiG9w0BAQsFAAOCAQEAZc7D8Azr53hG4Dt1xdsgV2D6CrLV05u+5TyjUOxJL8BW
    #     eS8z1KVTVDTuuGNDHOEsHELjamsR8SroCTVTBBwxQQThaPNukxeiEU2ziHCxFqjK
    #     Mjsnnx4mdaz0o+PLn8SrW/rqrbDBXMa0a+02nSIjsRolceD7CChzw+5+T3GUHMBU
    #     bHqSgaCBFYzbLBAsGc8aIee/Ey9kzOa0udsZnZt4t2xBSNDlr5vLtWGXAud5NlUD
    #     edu/41KqB9OykFgpszZw9t0R05pSON/JANsr12B/nmN2Qa/slu7xp/O2qowvdD6n
    #     bo6E2iLKE7p2cfX/KfxP8p4KdDRzr/9BCDYKa/26YQ==
    #     -----END CERTIFICATE-----
    #     </ca>
    #   '';
    #   updateResolvConf = true;
    # };

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
      gnome-photos
      gnome-tour
    ]) ++ (with pkgs.gnome; [
      cheese
      gnome-music
      epiphany
      geary
      gnome-characters
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
