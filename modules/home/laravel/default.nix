{ pkgs, username, ... }:
let
  php = pkgs.php83.buildEnv {
    extensions =
      { enabled, all }:
      enabled
      ++ (with all; [
        bcmath
        calendar
        curl
        exif
        fileinfo
        filter
        gd
        iconv
        intl
        mbstring
        mysqli
        mysqlnd
        opcache
        openssl
        pdo
        pdo_mysql
        pdo_pgsql
        pgsql
        readline
        redis
        simplexml
        sockets
        sodium
        xmlreader
        xmlwriter
        zip
        zlib
      ]);
    extraConfig = ''
      memory_limit = 512M
      upload_max_filesize = 100M
      post_max_size = 100M
      max_execution_time = 300
    '';
  };

  laravel-installer = pkgs.writeShellScriptBin "laravel" ''
    if [ "$1" = "new" ]; then
      shift
      exec ${php.packages.composer}/bin/composer create-project laravel/laravel "$@"
    else
      exec ${php.packages.composer}/bin/composer "$@"
    fi
  '';
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      php
      php.packages.composer
      laravel-installer
      mariadb.client
      postgresql
      redis
    ];

    programs.zsh.shellAliases = {
      pa = "php artisan";
      pas = "php artisan serve";
      pam = "php artisan migrate";
      pamf = "php artisan migrate:fresh";
      pamfs = "php artisan migrate:fresh --seed";
      par = "php artisan route:list";
      pac = "php artisan cache:clear";
      paoc = "php artisan optimize:clear";
      ci = "composer install";
      cu = "composer update";
      cr = "composer require";
      crd = "composer require --dev";
      cda = "composer dump-autoload";
    };
  };
}
