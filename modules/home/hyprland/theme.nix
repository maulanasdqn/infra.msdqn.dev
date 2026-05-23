{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    gtk = {
      enable = true;

      theme = {
        name = "rose-pine";
        package = pkgs.rose-pine-gtk-theme;
      };

      iconTheme = {
        name = "rose-pine";
        package = pkgs.rose-pine-icon-theme;
      };

      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      font = {
        name = "Quicksand";
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "appmenu:none";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style = {
        name = "kvantum";
      };
    };

    home.packages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
      rose-pine-kvantum
    ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=rose-pine-iris
    '';

    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Classic";
      GTK_THEME = "rose-pine";
    };

    # TODO: Add wallpaper.jpg to repo root to enable this
    # home.file.".config/hypr/wallpaper.jpg".source = ../../../wallpaper.jpg;
  };
}
