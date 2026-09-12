#!/usr/bin/bash

BP=$(dirname $(realpath $0))"/"

DP=$(dirname $BP)"/debug_mlb/"

echo "$BP"
echo "$DP"


ORG="$BP""big.yaml"
SDL="$DP""sdl.yaml"

cd "$DP"

which esphome || source ../venv/bin/activate


cp "$ORG" "$SDL"

comment_yaml_block_old() {
    local file="$1"
    local key="$2"

    awk -v key="$key" '
    BEGIN {
        in_block=0
    }

    # Gesuchten Block finden
    $0 ~ "^" key ":" {
        in_block=1
        print "#" $0
        next
    }

    # Sobald eine neue YAML-Struktur auf gleicher Ebene beginnt,
    # ist der Block beendet
    in_block && $0 ~ "^[^[:space:]#][^:]*:" {
        in_block=0
    }

    # Zeilen des Blocks auskommentieren
    in_block {
        print "#" $0
        next
    }

    # Rest unverändert
    {
        print
    }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

 
comment_yaml_block() {
    local file="$1"
    local block="$2"
 
    if [[ -z "$file" || -z "$block" ]]; then
        echo "Nutzung: comment_yaml_block <datei> <block-schluessel>" >&2
        return 1
    fi
    if [[ ! -f "$file" ]]; then
        echo "Datei nicht gefunden: $file" >&2
        return 1
    fi
 
    local tmp
    tmp="$(mktemp)"
 
    awk -v block="$block" '
        function lead_len(s,    l) {
            match(s, /^[ \t]*/)
            return RLENGTH
        }
        function trimmed(s,    t) {
            t = s
            sub(/^[ \t]*/, "", t)
            return t
        }
        BEGIN { in_block = 0; block_indent = -1 }
        {
            line = $0
            if (!in_block) {
                stripped = trimmed(line)
                if (index(stripped, block) == 1) {
                    in_block = 1
                    block_indent = lead_len(line)
                    print "#" line
                    next
                }
                print line
                next
            } else {
                if (line ~ /^[ \t]*$/) {
                    # Leerzeile innerhalb des Blocks
                    print line
                    next
                }
                if (line ~ /^[ \t]*#/) {
                    # Bereits vorhandene Kommentarzeile: darf den Block
                    # nicht beenden, egal welche Einrueckung sie hat.
                    print "#" line
                    next
                }
                cur_indent = lead_len(line)
                if (cur_indent > block_indent) {
                    print "#" line
                    next
                } else {
                    in_block = 0
                    print line
                    next
                }
            }
        }
    ' "$file" > "$tmp" && mv "$tmp" "$file"
}



sed -i 's|esphome-modular-lvgl-buttons/hardware/crowpanel-adv-10.1inch-esp32p4-hmi.yaml|esphome-modular-lvgl-buttons/hardware/SDL-lvgl.yaml|g' "$SDL"
sed -i 's|esphome-modular-lvgl-buttons/common/sensors_base.yaml|esphome-modular-lvgl-buttons/common/sensors_base_sdl.yaml|g' "$SDL"
sed -i 's|captive_portal:||g' "$SDL"
sed -i 's|wifi:|#wifi:|g' "$SDL"
sed -i 's|ota_screen:|#ota_screen:|g' "$SDL"
sed -i 's|hardware_uart:|#hardware_uart:|g' "$SDL"
sed -i 's|loading_screen:|#loading_screen:|g' "$SDL"
sed -i 's|- script.execute: update_loading_page|#- script.execute: update_loading_page|g' "$SDL"
sed -i 's|draft/camera_remote.yaml|esphome-modular-lvgl-buttons/ui/page/page_button.yaml|g' "$SDL"
#sed -i 's|x|y|g' "$SDL"
#sed -i 's|x|y|g' "$SDL"


SH="  screen_height: '600'"
SW="  screen_width: '1024'"

sed -i "21i\\$SH" "$SDL"
sed -i "21i\\$SW" "$SDL"

#sed -i 's|x|y|g' "$SDL"

comment_yaml_block "$SDL" "media_source"
comment_yaml_block "$SDL" "media_player"
comment_yaml_block "$SDL" "mqtt"
comment_yaml_block "$SDL" "sip_client"
comment_yaml_block "$SDL" "external_components"
comment_yaml_block "$SDL" "rtttl"


esphome run sdl.yaml



