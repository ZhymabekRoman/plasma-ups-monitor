#!/usr/bin/env bash
# Apply or revert UPS-mode power tweaks.
# Usage: power-tweaks.sh on|off|status   (needs root for on/off)

BOOST=/sys/devices/system/cpu/cpufreq/boost
ASPM=/sys/module/pcie_aspm/parameters/policy
AUDIO_PS=/sys/module/snd_hda_intel/parameters/power_save
AUDIO_PSC=/sys/module/snd_hda_intel/parameters/power_save_controller
LOW_FREQ_KHZ=${LOW_FREQ_KHZ:-1200000} # 1.2 GHz cap for low power / UPS mode

aspm_write() {  # aspm_write <policy>
  if grep -q 'pcie_aspm=off' /proc/cmdline; then
    echo "pcie aspm: locked off by kernel cmdline (pcie_aspm=off), skipped"
    return 1
  fi
  if [[ -f "$ASPM" ]]; then
    echo "$1" > "$ASPM" && echo "pcie aspm: $1"
  fi
}

case "$1" in
  on)   # low-power mode (UPS)
    [[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

    # 1. CPU Boost
    [[ -f "$BOOST" ]] && echo 0 > "$BOOST" && echo "cpu boost: off"

    # 2. PCIe ASPM
    aspm_write powersave

    # 3. System Power Profile & Governor
    if command -v powerprofilesctl &>/dev/null; then
      powerprofilesctl set power-saver 2>/dev/null && echo "profile: power-saver"
    fi
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      [[ -f "$gov" ]] && echo powersave > "$gov" 2>/dev/null
    done

    # 4. AMD P-State Energy-Performance Preference (EPP)
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      [[ -f "$epp" ]] && echo power > "$epp" 2>/dev/null
    done
    echo "cpu epp: power"

    # 5. CPU Max Frequency Clamping
    for max_f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      [[ -f "$max_f" ]] && echo "$LOW_FREQ_KHZ" > "$max_f" 2>/dev/null
    done
    echo "cpu max freq: ${LOW_FREQ_KHZ} kHz"

    # 6. SATA Link Power Management (ALPM)
    for alpm in /sys/class/scsi_host/host*/link_power_management_policy; do
      [[ -f "$alpm" ]] && echo min_power > "$alpm" 2>/dev/null
    done
    echo "sata alpm: min_power"

    # 7. Audio Codec Power Saving
    [[ -f "$AUDIO_PS" ]] && echo 1 > "$AUDIO_PS"
    [[ -f "$AUDIO_PSC" ]] && echo Y > "$AUDIO_PSC"
    echo "audio power save: on"

    # 8. AMD GPU Power Profile
    for gpu_dpm in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
      [[ -f "$gpu_dpm" ]] && echo low > "$gpu_dpm" 2>/dev/null
    done
    echo "gpu dpm: low"

    exit 0 ;;

  off)  # back to defaults
    [[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

    # 1. CPU Boost
    [[ -f "$BOOST" ]] && echo 1 > "$BOOST" && echo "cpu boost: on"

    # 2. PCIe ASPM
    aspm_write default

    # 3. System Power Profile
    if command -v powerprofilesctl &>/dev/null; then
      powerprofilesctl set balanced 2>/dev/null && echo "profile: balanced"
    fi

    # 4. AMD P-State Energy-Performance Preference (EPP)
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      [[ -f "$epp" ]] && echo balance_performance > "$epp" 2>/dev/null
    done
    echo "cpu epp: balance_performance"

    # 5. Restore CPU Max Frequency
    for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*; do
      if [[ -f "$cpu_dir/cpufreq/cpuinfo_max_freq" && -f "$cpu_dir/cpufreq/scaling_max_freq" ]]; then
        cat "$cpu_dir/cpufreq/cpuinfo_max_freq" > "$cpu_dir/cpufreq/scaling_max_freq" 2>/dev/null
      fi
    done
    echo "cpu max freq: restored (hardware max)"

    # 6. SATA Link Power Management (ALPM)
    for alpm in /sys/class/scsi_host/host*/link_power_management_policy; do
      [[ -f "$alpm" ]] && echo med_power_with_dipm > "$alpm" 2>/dev/null
    done
    echo "sata alpm: med_power_with_dipm"

    # 7. Audio Codec Power Saving
    [[ -f "$AUDIO_PS" ]] && echo 0 > "$AUDIO_PS"
    [[ -f "$AUDIO_PSC" ]] && echo N > "$AUDIO_PSC"
    echo "audio power save: off"

    # 8. AMD GPU Power Profile
    for gpu_dpm in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
      [[ -f "$gpu_dpm" ]] && echo auto > "$gpu_dpm" 2>/dev/null
    done
    echo "gpu dpm: auto"

    exit 0 ;;

  status)
    echo "cpu boost:        $(cat "$BOOST" 2>/dev/null) (1=on, 0=off)"
    echo "governor:         $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
    echo "cpu epp:          $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"
    echo "cpu max freq:     $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null) kHz"
    echo -n "pcie aspm:        "
    cat "$ASPM" 2>/dev/null | grep -o '\[[a-z]*\]' | tr -d '[]' || echo "n/a"
    echo "sata alpm:        $(cat /sys/class/scsi_host/host0/link_power_management_policy 2>/dev/null)"
    echo "audio power save: $(cat "$AUDIO_PS" 2>/dev/null) (1=on, 0=off)"
    echo "gpu dpm:          $(cat /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null)"
    echo "profile:          $(powerprofilesctl get 2>/dev/null)"
    ;;
  *)
    echo "usage: $0 on|off|status"
    exit 2
    ;;
esac
