{ username, lib, enableAggressiveTweaks ? false, ... }:
{
  system.stateVersion = 5;
  system.primaryUser = username;

  # ── Single-owner machine tweaks (MacBook) — gated by enableAggressiveTweaks ──
  # These change firmware (NVRAM), global power management, and the HID keymap
  # (which applies to ALL users incl. the login window), so they are NOT applied on
  # the shared Mac mini where a second account (mrscrapersupport57) is in use.

  # VM compressor mode — NVRAM boot-args, firmware-level, whole machine, needs reboot.
  # vm_compressor=4 is the macOS default: memory compression PLUS swap to disk.
  # (The old value 2 kept compression but disabled swap, so vm.swapusage stayed
  # at 0KB even under heavy memory pressure.) Set explicitly so the daemon
  # overwrites any stale =2 value still in NVRAM from a prior boot.
  launchd.daemons.set-boot-args = lib.mkIf enableAggressiveTweaks {
    serviceConfig = {
      Label = "com.local.set-boot-args";
      ProgramArguments = [
        "/usr/sbin/nvram"
        "boot-args=-arm64e_preview_abi vm_compressor=4"
      ];
      RunAtLoad = true;
    };
  };

  # System power management (machine-wide).
  power.sleep = lib.mkIf enableAggressiveTweaks {
    computer = 30;
    display = 10;
    harddisk = 10;
  };

  # HID key remap — applies to every user, including the login window.
  system.keyboard = lib.mkIf enableAggressiveTweaks {
    enableKeyMapping = true;
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771113;
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771113;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };

  launchd.daemons.keyboard-remap = lib.mkIf enableAggressiveTweaks {
    serviceConfig = {
      Label = "com.local.keyboard-remap";
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771113},{"HIDKeyboardModifierMappingSrc":30064771113,"HIDKeyboardModifierMappingDst":30064771129}]}''
      ];
      RunAtLoad = true;
    };
  };
}
