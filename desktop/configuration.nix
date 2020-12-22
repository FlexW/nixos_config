{ config, pkgs, ... }:
let
  cursor = {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
  };
  dpi = 100;

  # Enable properitary nvidia drivers when NVIDIA environment variable
  # is set
  nvidiaDriver = builtins.getEnv "NVIDIA" != "";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;

  # links /libexec from derivations to /run/current-system/sw
  environment.pathsToLink = [ "/libexec" "/share/nix-direnv" ];

  # nix options for derivations to persist garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # Use the systemd-boot EFI boot loader.
  boot = {

    kernelParams = [ "quiet" ];

    consoleLogLevel = 0;

    plymouth = {
      enable = true;
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  location = {
    latitude= 48.78232;
    longitude= 9.17702;
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure networking.
  networking = {
    hostName = "desktop";
    useDHCP = false;
    interfaces.enp3s0.useDHCP = true;
    networkmanager.enable = true;
  };


  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };
  console = {
    useXkbConfig = true;
    font = "Lat2-Terminus16";
  };

  services = {

    gnome3 = {
      gnome-keyring.enable = true;
    };

    locate = {
      enable = true;
      localuser = null;
      locate = pkgs.mlocate;
      interval = "hourly";
    };

    # Configure x server.
    xserver = {
      enable = true;

      # Configure keymap.
      layout = "de";
      xkbOptions = "eurosign:e, ctrl:nocaps";
      desktopManager = {
        xterm.enable = false;
      };

      libinput = {
        enable = true;
      };

      displayManager = {
        defaultSession = "sway";

        # HighDPI and cursor
        sessionCommands = ''
          ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
          Xft.dpi: ${toString dpi}
          Xcursor.theme: ${cursor.name}
          # Xcursor.size: ${toString cursor.size}
          EOF
          ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cursor.package}/share/icons/${cursor.name}/cursors/left_ptr ${toString cursor.size}

        '';
      };
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          rofi
          i3lock-fancy-rapid
          yad
          i3blocks
          flashfocus
          picom
        ];
      };

      videoDrivers = if nvidiaDriver then [ "nvidia" ] else [];
    };

    redshift = {
      enable = true;
    };

    # Enable OpenSSH
    openssh.enable = true;

    emacs = {
      # Start emacs on startup.
      enable = true;
      defaultEditor = true;
    };
  };

  # Add fonts
  fonts = {
    enableDefaultFonts = true;

    fonts = with pkgs; [
      dejavu_fonts
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji
      source-code-pro
      inconsolata
      ubuntu_font_family
      font-awesome
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Ubuntu" ];
        sansSerif = [ "Ubuntu" ];
        monospace = [ "Ubuntu Mono" ];
      };
    };
  };

  programs = {

    # Let Gtk apps save data.
    dconf.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    seahorse.enable = true;
    nm-applet.enable = true;

        sway = {
      enable = true;
      wrapperFeatures.gtk = true; # so that gtk works properly
      extraPackages = with pkgs; [
        swaylock-effects # Screen locker
        swayidle
        wl-clipboard # Clipboard support
        mako # Notifications
        wofi # Program starter
        xwayland # Legacy X support
        waybar # Statusbar
        wf-recorder # Screenrecorder
        brightnessctl # Brightness
        sway-contrib.grimshot # Screenshot
        grim # Screenshot
        slurp # Select area for screenshot
        jq # Parse swaymsg
        wdisplays # Configure screens
        kanshi # Configure screens automatic
        # wshowkeys # Screencast keys
        waypipe # Screen forwarding
        wev # Key events
        wayvnc # VNC
        gammastep # Redshift
        libappindicator-gtk3 # Tray icons
      ];
      extraSessionCommands = ''
        export QT_QPA_PLATFORM=xcb
        # Fix for some Java AWT applications (e.g. Android Studio),
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware = {
    pulseaudio.enable = true;

    nvidia = {
      modesetting.enable = true;
    };
  };

  systemd.user = {
    services = {

      "dunst" = {
        enable = true;
        description = "Desktop notifications";
        wantedBy = [ "default.target" ];
        serviceConfig.Restart = "always";
        serviceConfig.RestartSec = 2;
        serviceConfig.ExecStart = "${pkgs.dunst}/bin/dunst";
      };

      "flashfocus" = {
        enable = true;
        description = "Flashfocus";
        wantedBy = [ "default.target" ];
        serviceConfig.Restart = "always";
        serviceConfig.RestartSec = 2;
        serviceConfig.ExecStart = "${pkgs.flashfocus}/bin/flashfocus";
      };

      "nextcloud" = {
        enable = true;
        description = "Nextcloud client";
        wantedBy = [ "default.target" ];
        serviceConfig.Restart = "always";
        serviceConfig.RestartSec = 2;
        serviceConfig.ExecStart = "${pkgs.nextcloud-client}/bin/nextcloud";
      };

    };
  };

  # Define my user account.
  users = {
    mutableUsers = true;

    users.felix = {
      isNormalUser = true;
      extraGroups = [ "wheel" "mlocate" "networkmanager" "video" "adbusers" ];
    };
  };

  programs.adb.enable = true;

  nixpkgs.config = {
    android_sdk.accept_license = true;

    zathura.useMupdf = true;
  };


  # System packages
  environment.systemPackages = with pkgs; [
    man-pages
    busybox

    ntfs3g jmtpfs

    unzip
    calc
    wget git youtube-dl
    perl532Packages.FileMimeInfo
    zsh fish direnv nix-direnv exa bat
    gettext
    nano emacs
    firefox qutebrowser tor-browser-bundle-bin
    alacritty
    mu offlineimap
    zathura mupdf

    pass

    pavucontrol
    arandr

    dunst libnotify

    htop

    scrot feh viewnior imagemagick fbida

    hunspell hunspellDicts.de_DE hunspellDicts.en_GB-large

    # Python
    python3 python27

    # C/C++
    gcc clang clang-tools cmake ninja gnumake ccls

    # Web dev
    hugo
    nodejs
    nodePackages.npm
    nodePackages.prettier
    nodePackages.typescript
    nodePackages.typescript-language-server

    mpg123 mpg321 vlc cmus spotify playerctl mplayer

    exiftool

    (nextcloud-client.overrideAttrs(old: rec {
      version = "3.1.0";
      src = fetchFromGitHub {
        owner = "nextcloud";
        repo = "desktop";
        rev = "v${version}";
        sha256 = "0z373dws7f77gxdi0r5s8jy9jg6qyz7vmd6sw38sfl3j67pchwn2";
      };
      buildInputs = old.buildInputs ++ [libsecret];
    }))
    skype signal-desktop

    texlive.combined.scheme-full

    gimp inkscape

    vanilla-dmz
  ];

  security.pam.services.lightdm.enableGnomeKeyring = true;

  # Don't edit.
  system.stateVersion = "20.09";

}
