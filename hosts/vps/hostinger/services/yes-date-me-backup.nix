{ config, pkgs, ... }:
let
  backupScript = pkgs.writeShellScriptBin "yes-date-me-backup" ''
    set -euo pipefail

    BACKUP_DIR="/var/lib/backup"
    DATE=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_FILE="yes-date-me-backup-$DATE.sql.gz"

    mkdir -p "$BACKUP_DIR"

    # Dump PostgreSQL database
    ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump yes-date-me-backend | ${pkgs.gzip}/bin/gzip > "$BACKUP_DIR/$BACKUP_FILE"

    # Upload to Google Drive
    ${pkgs.rclone}/bin/rclone --config /run/secrets/rclone_config copy "$BACKUP_DIR/$BACKUP_FILE" gdrive:yes-date-me-backups/

    # Keep only last 7 local backups
    ls -t "$BACKUP_DIR"/yes-date-me-backup-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm

    # Keep only last 30 backups on Google Drive
    ${pkgs.rclone}/bin/rclone --config /run/secrets/rclone_config delete gdrive:yes-date-me-backups/ --min-age 30d

    echo "Backup completed: $BACKUP_FILE"
  '';
in
{
  environment.systemPackages = [ backupScript ];

  systemd.services.yes-date-me-backup = {
    description = "Yes Date Me Database Backup to Google Drive";
    after = [ "postgresql.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${backupScript}/bin/yes-date-me-backup";
      PrivateTmp = true;
    };
  };

  systemd.timers.yes-date-me-backup = {
    description = "Daily Yes Date Me Database Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:30:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
