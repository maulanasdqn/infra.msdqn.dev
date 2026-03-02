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
        name = "Catppuccin-Latte-Standard-Pink-Light";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          variant = "latte";
        };
      };

      iconTheme = {
        name = "Papirus-Light";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "latte";
          accent = "pink";
        };
      };

      cursorTheme = {
        name = "catppuccin-mocha-pink-cursors";
        package = pkgs.catppuccin-cursors.mochaPink;
        size = 24;
      };

      font = {
        name = "Quicksand";
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = false;
        gtk-decoration-layout = "appmenu:none";
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = false;
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
      catppuccin-kvantum
    ];

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=catppuccin-latte-pink
    '';

    home.pointerCursor = {
      name = "catppuccin-mocha-pink-cursors";
      package = pkgs.catppuccin-cursors.mochaPink;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "catppuccin-mocha-pink-cursors";
      GTK_THEME = "Catppuccin-Latte-Standard-Pink-Light";
    };

    # TODO: Add wallpaper.jpg to repo root to enable this
    # home.file.".config/hypr/wallpaper.jpg".source = ../../../wallpaper.jpg;
  };
}
