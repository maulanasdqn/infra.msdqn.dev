{ config, pkgs, ... }:
let
  backupScript = pkgs.writeShellScriptBin "rkm-backup" ''
    set -euo pipefail

    BACKUP_DIR="/var/lib/backup"
    DATE=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_FILE="rkm-backup-$DATE.sql.gz"

    mkdir -p "$BACKUP_DIR"

    # Dump PostgreSQL database
    ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump rkm | ${pkgs.gzip}/bin/gzip > "$BACKUP_DIR/$BACKUP_FILE"

    # Upload to Google Drive
    ${pkgs.rclone}/bin/rclone --config /run/secrets/rclone_config copy "$BACKUP_DIR/$BACKUP_FILE" gdrive:rkm-backups/

    # Keep only last 7 local backups
    ls -t "$BACKUP_DIR"/rkm-backup-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm

    # Keep only last 30 backups on Google Drive
    ${pkgs.rclone}/bin/rclone --config /run/secrets/rclone_config delete gdrive:rkm-backups/ --min-age 30d

    echo "Backup completed: $BACKUP_FILE"
  '';
in
{
  environment.systemPackages = [ pkgs.rclone backupScript ];

  systemd.services.rkm-backup = {
    description = "RKM Database Backup to Google Drive";
    after = [ "postgresql.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${backupScript}/bin/rkm-backup";
      PrivateTmp = true;
    };
  };

  systemd.timers.rkm-backup = {
    description = "Daily RKM Database Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/backup 0700 root root -"
  ];

  sops.secrets."rclone_config" = {
    mode = "0400";
    owner = "root";
  };
}
