{ config, pkgs, ... }:
let
  cursor = {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
  };
  dpi = 100;
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
    hostName = "nixos";
    useDHCP = false;
    interfaces.wlp63s0.useDHCP = true;
    networkmanager.enable = true;
    # nameservers = [ "8.8.8.8" "8.8.4.4"];
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
        tapping = false;
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
    };

    redshift = {
      enable = true;
      package = pkgs.redshift-wlr;
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
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji
      source-code-pro
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
  hardware.pulseaudio.enable = true;

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

  security.pam.services.lightdm.enableGnomeKeyring = true;


  # System packages
  environment.systemPackages = with pkgs; [
    gnome3.adwaita-icon-theme
    acpi brightnessctl

    polkit_gnome

    man-pages

    ntfs3g jmtpfs

    networkmanagerapplet inetutils
    unzip
    calc
    wget git youtube-dl
    perl532Packages.FileMimeInfo
    zsh fish direnv nix-direnv exa bat
    gettext
    nano emacs
    firefox qutebrowser tor-browser-bundle-bin thunderbird
    alacritty
    mu offlineimap
    zathura

    pass

    pavucontrol
    arandr

    dunst libnotify

    htop

    gnome2.pango

    scrot feh viewnior imagemagick

    hunspell hunspellDicts.de_DE hunspellDicts.en_GB-large

    # Python
    (python3.withPackages (pythonPackages: with pythonPackages; [
      requests
      python-language-server
      rope
      pyflakes
      pycodestyle
      pydocstyle
      yapf
    ]))
    python27

    # C/C++
    # gcc clang clang-tools cmake ninja gnumake
    cmake-language-server
    cmake-format

    # Web dev
    hugo
    nodejs
    nodePackages.npm
    nodePackages.prettier
    nodePackages.typescript
    nodePackages.typescript-language-server

    mpg123 mpg321 vlc cmus spotify playerctl

    exiftool xdg-user-dirs

    nextcloud-client
    skype signal-desktop

    texlive.combined.scheme-full

    gimp inkscape

    vanilla-dmz flashfocus
  ];

  # Don't edit.
  system.stateVersion = "20.09";

}
