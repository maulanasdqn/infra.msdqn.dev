{ username, lib, enableAggressiveTweaks ? false, ... }:
{
  system.stateVersion = 5;
  system.primaryUser = username;

  # ── Single-owner machine tweaks (MacBook) — gated by enableAggressiveTweaks ──
  # These change firmware (NVRAM), global power management, and the HID keymap
  # (which applies to ALL users incl. the login window), so they are NOT applied on
  # the shared Mac mini where a second account (mrscrapersupport57) is in use.

  # NOTE: there is intentionally no `vm_compressor` boot-arg here.
  # `vm_compressor` is an Intel-Mac kernel knob — on Apple Silicon there is no
  # `vm.compressor_mode` sysctl and the boot-arg is inert (and custom boot-args
  # don't even persist under Full Security). Memory compression + on-demand swap
  # are always on and not user-tunable. Swap reading 0KB while RAM is full is
  # normal: the kernel compresses pages in RAM and only writes disk swapfiles
  # when the compressor saturates. Nothing to configure.

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
