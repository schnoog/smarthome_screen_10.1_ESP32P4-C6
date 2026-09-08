#!/usr/bin/bash

BP=$(dirname $(realpath $0))"/"

ORG="$BP""big.yaml"
SDL="$BP""sdl.yaml"

cd "$BP"

which esphome || source ../venv/bin/activate


cp "$ORG" "$SDL"

comment_yaml_block() {
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


sed -i 's|esphome-modular-lvgl-buttons/hardware/crowpanel-adv-10.1inch-esp32p4-hmi.yaml|esphome-modular-lvgl-buttons/hardware/SDL-lvgl.yaml|g' "$SDL"
sed -i 's|esphome-modular-lvgl-buttons/common/sensors_base.yaml|esphome-modular-lvgl-buttons/common/sensors_base_sdl.yaml|g' "$SDL"
sed -i 's|captive_portal:||g' "$SDL"
sed -i 's|wifi:|#wifi:|g' "$SDL"
sed -i 's|ota_screen:|#ota_screen:|g' "$SDL"
sed -i 's|hardware_uart:|#hardware_uart:|g' "$SDL"
sed -i 's|loading_screen:|#loading_screen:|g' "$SDL"
sed -i 's|- script.execute: update_loading_page|#- script.execute: update_loading_page|g' "$SDL"
#sed -i 's|x|y|g' "$SDL"
#sed -i 's|x|y|g' "$SDL"
#sed -i 's|x|y|g' "$SDL"


SH="  screen_height: '600'"
SW="  screen_width: '1024'"

sed -i "21i\\$SH" "$SDL"
sed -i "21i\\$SW" "$SDL"

#sed -i 's|x|y|g' "$SDL"

comment_yaml_block "$SDL" "media_source"
comment_yaml_block "$SDL" "media_player"


esphome run sdl.yaml



