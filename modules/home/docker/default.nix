{ pkgs, username, ... }:
let
  colimaCpu = "6";
  colimaMemory = "12";
  colimaDisk = "100";
  colimaStart = pkgs.writeShellScript "colima-autostart" ''
    export PATH=${pkgs.colima}/bin:/usr/bin:/bin:/usr/sbin:/sbin
    colima start --cpu ${colimaCpu} --memory ${colimaMemory} --disk ${colimaDisk} || true
  '';
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      colima
      docker-client
      docker-compose
    ];

    launchd.agents.colima = {
      enable = true;
      config = {
        ProgramArguments = [ "${colimaStart}" ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/tmp/colima.autostart.out.log";
        StandardErrorPath = "/tmp/colima.autostart.err.log";
      };
    };

    programs.zsh.shellAliases = {
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";
      dlog = "docker logs -f";
      colima-up = "colima start --cpu ${colimaCpu} --memory ${colimaMemory} --disk ${colimaDisk}";
    };
  };
}
