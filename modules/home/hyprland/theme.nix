{
  pkgs,
  username,
  ...
}:
let
  # rose-pine-gtk-theme was dropped from nixpkgs along with gtk-engine-murrine
  # (GTK2). adw-gtk3 is the maintained stand-in; rose-pine still themes the
  # icons, Kvantum/Qt, and the editors.
  gtkTheme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
in
{
  home-manager.users.${username} = {
    gtk = {
      enable = true;

      theme = gtkTheme;

      iconTheme = {
        name = "rose-pine";
        package = pkgs.rose-pine-icon-theme;
      };

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 32;
      };

      font = {
        name = "Quicksand";
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };

      gtk4.theme = gtkTheme;

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        name = "kvantum";
      };
    };

    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
      rose-pine-kvantum
      adw-gtk3
    ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=rose-pine-iris
    '';

    home.pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_SIZE = "32";
      XCURSOR_THEME = "Bibata-Modern-Classic";
      GTK_THEME = "adw-gtk3-dark";
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "rose-pine";
        cursor-theme = "Bibata-Modern-Classic";
        font-name = "Quicksand 11";
        document-font-name = "Quicksand 11";
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };
    };

    # TODO: Add wallpaper.jpg to repo root to enable this
    # home.file.".config/hypr/wallpaper.jpg".source = ../../../wallpaper.jpg;
  };
}
