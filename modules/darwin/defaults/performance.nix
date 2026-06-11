{ lib, enableAggressiveTweaks ? false, ... }:
{
  # Whole-machine performance daemons (disable Spotlight/Time Machine on ALL volumes,
  # kernel/network sysctl, pmset, weekly storage cleanup). Single-owner machines only.
  launchd.daemons = lib.mkIf enableAggressiveTweaks {
    disable-tm-local = {
      serviceConfig = {
        Label = "com.local.disable-tm-local";
        ProgramArguments = [
          "/usr/bin/tmutil"
          "disablelocal"
        ];
        RunAtLoad = true;
      };
    };

    disable-spotlight-indexing = {
      serviceConfig = {
        Label = "com.local.disable-spotlight";
        ProgramArguments = [
          "/usr/bin/mdutil"
          "-a"
          "-i"
          "off"
        ];
        RunAtLoad = true;
      };
    };

    # Weekly storage cleanup — runs every Sunday at 03:00
    storage-cleanup = {
      serviceConfig = {
        Label = "com.local.storage-cleanup";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # Chrome code_sign_clone (biggest offender, accumulates ~1-2GB/day)
            find /private/var/folders -type d -name 'com.google.Chrome.code_sign_clone' -exec rm -rf {} + 2>/dev/null

            # uv Python package cache
            rm -rf /Users/ms/.cache/uv

            # Nix garbage collection
            /run/current-system/sw/bin/nix-collect-garbage -d

            # Homebrew cache
            /opt/homebrew/bin/brew cleanup --prune=all 2>/dev/null

            # Xcode DerivedData
            rm -rf /Users/ms/Library/Developer/Xcode/DerivedData

            # Unused simulator runtimes and devices
            /usr/bin/xcrun simctl delete unavailable 2>/dev/null

            # App caches older than 7 days
            find /Users/ms/Library/Caches -mindepth 2 -maxdepth 2 -atime +7 -exec rm -rf {} + 2>/dev/null

            # Nix cache
            rm -rf /Users/ms/.cache/nix

            # Claude Code vm_bundles (recreated on demand)
            rm -rf "/Users/ms/Library/Application Support/Claude/vm_bundles"

            # Docker prune inside Colima (unused images, volumes, build cache)
            /opt/homebrew/bin/colima ssh -- docker system prune -af --volumes 2>/dev/null

            # Stale git worktrees in Development projects
            find /Users/ms/Development -maxdepth 3 -name ".git" -type d | while read g; do
              git -C "$(dirname $g)" worktree prune 2>/dev/null
            done

            # Gradle caches
            rm -rf /Users/ms/.gradle/caches /Users/ms/.gradle/wrapper/dists

            echo "Storage cleanup done: $(date)" >> /var/log/storage-cleanup.log
          ''
        ];
        StartCalendarInterval = [
          {
            Weekday = 1;
            Hour = 3;
            Minute = 0;
          }
        ];
        StandardOutPath = "/var/log/storage-cleanup.log";
        StandardErrorPath = "/var/log/storage-cleanup.log";
      };
    };

    # Max performance pmset — battery drain acceptable
    pmset-performance = {
      serviceConfig = {
        Label = "com.local.pmset-performance";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # Disable hibernation (no RAM dump to disk — faster sleep/wake)
            /usr/bin/pmset -a hibernatemode 0
            /usr/bin/pmset -a standby 0
            /usr/bin/pmset -a autopoweroff 0

            # AC: sleep 30min, no throttle, no power saving
            /usr/bin/pmset -c sleep 30 displaysleep 10 disksleep 10 \
              powernap 0 lowpowermode 0 womp 0 tcpkeepalive 0

            # Battery: same performance profile, don't reduce CPU speed
            /usr/bin/pmset -b sleep 10 displaysleep 5 disksleep 5 \
              powernap 0 lowpowermode 0 lessbright 0
          ''
        ];
        RunAtLoad = true;
      };
    };

    # Kernel performance tuning via sysctl
    sysctl-performance = {
      serviceConfig = {
        Label = "com.local.sysctl-performance";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # File descriptor limits — prevents "too many open files" under heavy dev load
            /usr/sbin/sysctl -w kern.maxfiles=524288
            /usr/sbin/sysctl -w kern.maxfilesperproc=524288

            # Network: disable TCP delayed ACK for lower latency
            /usr/sbin/sysctl -w net.inet.tcp.delayed_ack=0

            # Network: larger TCP buffers for faster throughput
            /usr/sbin/sysctl -w net.inet.tcp.sendspace=1048576
            /usr/sbin/sysctl -w net.inet.tcp.recvspace=1048576

            # Network: faster connection reuse
            /usr/sbin/sysctl -w net.inet.tcp.msl=1000
          ''
        ];
        RunAtLoad = true;
      };
    };
  };
}
