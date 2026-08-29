#!/usr/bin/env sh
set -eu

UPS_NAME="${1:-eaton@localhost}"
LAST_ONBATT_FILE="/var/lib/ups/last-onbatt-epoch"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/plasma-ups-monitor"
LOCAL_LAST_ONBATT_FILE="${STATE_DIR}/last-onbatt-epoch"
LOCAL_PREV_ONBATT_FILE="${STATE_DIR}/previous-onbatt"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_number_or_null() {
    case "${1-}" in
        "")
            printf 'null'
            ;;
        *)
            printf '%s' "$1"
            ;;
    esac
}

read_first_existing_timestamp() {
    for candidate in "$LOCAL_LAST_ONBATT_FILE" "$LAST_ONBATT_FILE"; do
        if [ -r "$candidate" ]; then
            timestamp="$(tr -cd '0-9' < "$candidate" | head -c 16)"
            if [ -n "$timestamp" ]; then
                printf '%s' "$timestamp"
                return 0
            fi
        fi
    done
    return 1
}

if ! output="$(upsc "$UPS_NAME" 2>&1)"; then
    err="$(json_escape "$output")"
    printf '{'
    printf '"ok":false,'
    printf '"upsName":"%s",' "$(json_escape "$UPS_NAME")"
    printf '"error":"%s"' "$err"
    printf '}\n'
    exit 0
fi

get_value() {
    printf '%s\n' "$output" | sed -n "s/^$1: //p" | head -n 1
}

status="$(get_value 'ups.status')"
model="$(get_value 'ups.model')"
firmware="$(get_value 'ups.firmware.aux')"
charge="$(get_value 'battery.charge')"
watts="$(get_value 'ups.realpower')"
voltage="$(get_value 'output.voltage')"
input_voltage="$(get_value 'input.voltage')"
battery_voltage="$(get_value 'battery.voltage')"
frequency="$(get_value 'output.frequency')"
runtime="$(get_value 'battery.runtime')"
load="$(get_value 'ups.load')"
alarm="$(get_value 'ups.alarm')"
nominal_current="$(get_value 'output.current.nominal')"
nominal_voltage="$(get_value 'output.voltage.nominal')"

if [ -z "$model" ]; then
    if [ -n "$firmware" ]; then
        model="UPS ($firmware)"
    else
        model="UPS"
    fi
fi

if [ -z "$voltage" ]; then
    voltage="$nominal_voltage"
fi

# Calculate estimated watts if not reported
if [ -z "$watts" ] && [ -n "$load" ]; then
    nom_v="${nominal_voltage:-230}"
    nom_i="${nominal_current:-6}"
    # Max real power ~ (nom_v * nom_i * 0.6)
    max_watts=$(( $(printf '%.0f' "$nom_v") * $(printf '%.0f' "$nom_i") * 6 / 10 ))
    watts=$(( max_watts * $(printf '%.0f' "$load") / 100 ))
fi

# Calculate estimated runtime if not reported (based on 2x7Ah 24V batteries ~ 168Wh)
if [ -z "$runtime" ] && [ -n "$charge" ]; then
    cur_watts="${watts:-50}"
    if [ "$cur_watts" -le 0 ]; then
        cur_watts=30
    fi
    # Total usable energy ~ 140Wh * (charge/100), runtime in seconds
    runtime=$(( 140 * 3600 * $(printf '%.0f' "$charge") / 100 / (cur_watts + 15) ))
fi

last_onbatt=""
last_onbatt_epoch=""
previous_onbatt=false

on_battery=false
case "$status" in
    *OB*)
        on_battery=true
        ;;
esac

mkdir -p "$STATE_DIR"

if [ -r "$LOCAL_PREV_ONBATT_FILE" ] && [ "$(cat "$LOCAL_PREV_ONBATT_FILE" 2>/dev/null)" = "true" ]; then
    previous_onbatt=true
fi

if [ "$on_battery" = true ] && [ "$previous_onbatt" != true ]; then
    date +%s > "$LOCAL_LAST_ONBATT_FILE"
fi

if [ "$on_battery" = true ]; then
    printf 'true' > "$LOCAL_PREV_ONBATT_FILE"
else
    printf 'false' > "$LOCAL_PREV_ONBATT_FILE"
fi

powersave_active=false
if [ -r /sys/devices/system/cpu/cpufreq/boost ]; then
    if [ "$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)" = "0" ]; then
        powersave_active=true
    fi
elif command -v powerprofilesctl >/dev/null 2>&1; then
    if [ "$(powerprofilesctl get 2>/dev/null)" = "power-saver" ]; then
        powersave_active=true
    fi
fi

printf '{'
printf '"ok":true,'
printf '"upsName":"%s",' "$(json_escape "$UPS_NAME")"
printf '"model":"%s",' "$(json_escape "$model")"
printf '"status":"%s",' "$(json_escape "$status")"
printf '"onBattery":%s,' "$on_battery"
printf '"powerSaveActive":%s,' "$powersave_active"
printf '"batteryPercent":'
json_number_or_null "$charge"
printf ','
printf '"batteryVoltage":'
json_number_or_null "$battery_voltage"
printf ','
printf '"inputVoltage":'
json_number_or_null "$input_voltage"
printf ','
printf '"outputVoltage":'
json_number_or_null "$voltage"
printf ','
printf '"frequency":'
json_number_or_null "$frequency"
printf ','
printf '"powerWatts":'
json_number_or_null "$watts"
printf ','
printf '"runtimeSeconds":'
json_number_or_null "$runtime"
printf ','
printf '"loadPercent":'
json_number_or_null "$load"
printf ','
printf '"alarm":"%s",' "$(json_escape "$alarm")"
printf '"lastPowerLoss":"%s",' "$(json_escape "$last_onbatt")"
printf '"error":""'
printf '}\n'
