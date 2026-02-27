{
  pkgs,
  lib,
  ...
}:
let
  zjiang-cups-driver = pkgs.stdenv.mkDerivation {
    pname = "zjiang-cups-driver";
    version = "1.0";

    src = ../../packages/zjiang-cups-driver;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.cups
      pkgs.glibc
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/lib/cups/filter
      mkdir -p $out/share/cups/model/zjiang

      # Install filter binaries
      cp bin/rastertozj $out/lib/cups/filter/
      cp bin/rastertozj58 $out/lib/cups/filter/
      chmod 755 $out/lib/cups/filter/rastertozj
      chmod 755 $out/lib/cups/filter/rastertozj58

      # Install PPD files
      cp ppd/POS80.ppd $out/share/cups/model/zjiang/
      cp ppd/POS58.ppd $out/share/cups/model/zjiang/
    '';

    meta = with lib; {
      description = "Zjiang POS thermal receipt printer CUPS driver (58mm/80mm)";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  services.printing.drivers = [ zjiang-cups-driver ];
}
