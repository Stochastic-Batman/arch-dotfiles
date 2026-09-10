#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/home/lado/.opam/opam-init/init.sh' && . '/home/lado/.opam/opam-init/init.sh' > /dev/null 2> /dev/null || true
# END opam configuration
eval $(opam env)


open_spiel_copy() {
    echo "This should be run from open_spiel/open_spiel/games/"

    local src_dir_name="$1"
    local dest_dir_name="$2"

    src_dir_name="${src_dir_name%/}"
    dest_dir_name="${dest_dir_name%/}"
    
    if [[ -z "$src_dir_name" || -z "$dest_dir_name" ]]; then
        echo "Error: Missing arguments. Usage: open_spiel_copy <src_dir_name> <dest_dir_name>"
        return 1
    fi
    
    local src_base="${src_dir_name##*/}"
    local src_h="${src_dir_name}/${src_dir_name##*/}.h"
    local src_cc="${src_dir_name}/${src_dir_name##*/}.cc"
    local src_test="${src_dir_name}/${src_dir_name##*/}_test.cc"
    
    local dest_base="${dest_dir_name##*/}"
    local dest_h="${dest_dir_name}/${dest_base}.h"
    local dest_cc="${dest_dir_name}/${dest_base}.cc"
    local dest_test="${dest_dir_name}/${dest_base}_test.cc"
    
    cp "$src_h" "$dest_h" && echo "Copied '$src_h' → '$dest_h'"
    cp "$src_cc" "$dest_cc" && echo "Copied '$src_cc' → '$dest_cc'"
    cp "$src_test" "$dest_test" && echo "Copied '$src_test' → '$dest_test'"

    local src_upper dest_upper src_pascal dest_pascal

    src_upper="$(echo "$src_base" | tr '[:lower:]' '[:upper:]')"
    dest_upper="$(echo "$dest_base" | tr '[:lower:]' '[:upper:]')"

    src_pascal="$(echo "$src_base" | sed -r 's/(^|_)([a-z])/\U\2/g')"
    dest_pascal="$(echo "$dest_base" | sed -r 's/(^|_)([a-z])/\U\2/g')"

    for file in "$dest_h" "$dest_cc" "$dest_test"; do
	sed -i "s#${src_dir_name}/${src_base}\.h#${dest_dir_name}/${dest_base}\.h#g" "$file"
	sed -i "s/${src_pascal}/${dest_pascal}/g" "$file"
	sed -i "s/${src_base}/${dest_base}/g" "$file"
    done

    sed -i "s/OPEN_SPIEL_GAMES_${src_upper}_H_/OPEN_SPIEL_GAMES_${dest_upper}_H_/g" "$dest_h"

    local pyspiel_test="../python/tests/pyspiel_test.py"
    if [[ -f "$pyspiel_test" ]]; then
        awk -v new_game="$dest_base" '
        BEGIN { inserted = 0 }
        /EXPECTED_MANDATORY_GAMES = frozenset\(\[/ { in_set = 1 }
        in_set && /\]\)/ { in_set = 0 }
        in_set && !inserted && /"/ {
            match($0, /"([^"]+)"/, arr)
            if (arr[1] > new_game) {
                print "    \"" new_game "\","
                inserted = 1
            }
        }
        { print }
        ' "$pyspiel_test" > "${pyspiel_test}.tmp" && mv "${pyspiel_test}.tmp" "$pyspiel_test"
        
        echo "Added '$dest_base' to '$pyspiel_test'."
    else
        echo "Warning: Could not find '$pyspiel_test'"
    fi

    echo "Updated boilerplate references in '$dest_dir_name' files."
}


open_spiel_CMakeLists_update() {
    echo "This should be run from open_spiel/open_spiel/games/"

    local new_game="$1"
    new_game="${new_game%/}"
    new_game="${new_game##*/}"

    if [[ -z "$new_game" ]]; then
        echo "Error: Missing argument. Usage: open_spiel_CMakeLists_update <new_game>"
        return 1
    fi

    python3 - "$new_game" << 'EOF'
import sys

new_game = sys.argv[1]
filepath = "CMakeLists.txt"

with open(filepath, "r") as f:
    lines = f.readlines()

in_game_sources = False
insert_idx_sources = -1
target_entry = f"{new_game}/{new_game}.cc"

for idx, line in enumerate(lines):
    if "set(GAME_SOURCES" in line:
        in_game_sources = True
        continue
    if in_game_sources:
        if line.strip() == ")":
            insert_idx_sources = idx
            break
        stripped = line.strip()
        if stripped and stripped > target_entry:
            insert_idx_sources = idx
            break

sources_to_insert = [
    f"  {new_game}/{new_game}.cc\n",
    f"  {new_game}/{new_game}.h\n"
]

if insert_idx_sources != -1:
    lines = lines[:insert_idx_sources] + sources_to_insert + lines[insert_idx_sources:]

target_test = f"{new_game}_test"
insert_idx_tests = -1

for idx in range(len(lines)):
    if lines[idx].startswith("add_executable(") and "_test " in lines[idx]:
        test_name = lines[idx].split("add_executable(")[1].split("_test")[0] + "_test"
        if test_name > target_test:
            insert_idx_tests = idx
            break

test_block_to_insert = [
    f"add_executable({new_game}_test {new_game}/{new_game}_test.cc ${{OPEN_SPIEL_OBJECTS}}\n",
    f"               $<TARGET_OBJECTS:tests>)\n",
    f"add_test({new_game}_test {new_game}_test)\n",
    "\n"
]

if insert_idx_tests != -1:
    lines = lines[:insert_idx_tests] + test_block_to_insert + lines[insert_idx_tests:]

with open(filepath, "w") as f:
    f.writelines(lines)

print(f"Updated '{filepath}' with entries for '{new_game}'")
EOF
}

# --- GTU MICM VPN ---
micm() {
    sudo swanctl --load-all --noprompt > /dev/null
    if sudo swanctl --initiate --child fortigate-child; then
        vip=$(ip -4 -o addr show scope global | awk '$4 ~ /^172\.16\.0\./ {sub(/\/.*/,"",$4); print $4; exit}')
        ssh -b "${vip}" besom@10.60.100.100
        sudo swanctl --terminate --ike fortigate
    else
        echo "VPN connection failed"
    fi
}

micm_logs() {
    vip=$(ip -4 -o addr show scope global | awk '$4 ~ /^172\.16\.0\./ {sub(/\/.*/,"",$4); print $4; exit}')
    rsync -avz --progress -e "ssh -b ${vip}" besom@10.60.100.100:'~/EngageNet/logs/*.log' ~/Downloads/
}

# Created by `pipx` on 2026-07-30 17:03:10
export PATH="$PATH:/home/lado/.local/bin"

# --- Bluetooth Functions ---
bt_radio_on() {
    sudo rfkill unblock bluetooth
    sudo systemctl start bluetooth
    sleep 1
}

bt_radio_off() {
    echo "Turning Bluetooth radio OFF (disconnects everything)..."
    sudo systemctl stop bluetooth
    sudo rfkill block bluetooth
}

# Full reset - use when a device refuses to connect
bt_reset() {
    echo "Resetting Bluetooth..."
    sudo systemctl stop bluetooth 2>/dev/null
    sudo rfkill block bluetooth
    sleep 1
    bt_radio_on
}

# --- Devices ---
EARBUDS_MAC="3C:B0:ED:AF:08:B2"
CONTROLLER_MAC="A0:FA:9C:D3:8F:4B"
GF_EARBUDS_MAC="C4:A9:B8:DE:6A:4B"
SPEAKER_SINK="alsa_output.pci-0000_04_00.6.HiFi__Speaker__sink"

# Mute laptop speaker while ANY earbuds are connected; unmute when none are.
# Deliberately ignores the controller.
_speaker_auto() {
    if bluetoothctl devices Connected | grep -qE "$EARBUDS_MAC|$GF_EARBUDS_MAC"; then
        pactl set-sink-mute "$SPEAKER_SINK" 1
        echo "Earbuds connected -> laptop speaker muted."
    else
        pactl set-sink-mute "$SPEAKER_SINK" 0
        echo "No earbuds -> laptop speaker unmuted."
    fi
}

_bt_connect() {
    local mac="$1" name="$2"
    if bluetoothctl devices Connected | grep -q "$mac"; then
        echo "$name already connected."
        return 0
    fi
    echo "Connecting to $name..."
    bluetoothctl connect "$mac" > /dev/null 2>&1
    sleep 2
    bluetoothctl devices Connected | grep -q "$mac" \
        && echo "$name connected." \
        || echo "$name FAILED - try again or run bt_reset."
}

controller_on() {
    systemctl is-active --quiet bluetooth || bt_radio_on
    echo "Connecting to DualSense Wireless Controller..."
    bluetoothctl connect "$CONTROLLER_MAC"
}

controller_off() {
    echo "Disconnecting DualSense..."
    bluetoothctl disconnect "$CONTROLLER_MAC" > /dev/null 2>&1
    sleep 1
    if [ -z "$(bluetoothctl devices Connected)" ]; then
        echo "Nothing else connected - turning radio off."
        bt_radio_off
    else
        echo "Still connected, leaving radio on:"
        bluetoothctl devices Connected
    fi
}

ear_on() {
    systemctl is-active --quiet bluetooth || bt_radio_on
    _bt_connect "$EARBUDS_MAC" "Nothing Ear (a)"
    _speaker_auto
}

ear_off() {
    echo "Disconnecting Nothing Ear (a)..."
    bluetoothctl disconnect "$EARBUDS_MAC" > /dev/null 2>&1
    sleep 1
    _speaker_auto
    if [ -z "$(bluetoothctl devices Connected)" ]; then
        echo "Nothing else connected - turning radio off."
        bt_radio_off
    else
        echo "Still connected, leaving radio on:"
        bluetoothctl devices Connected
    fi
}

gf_ear_on() {
    systemctl is-active --quiet bluetooth || bt_radio_on
    _bt_connect "$GF_EARBUDS_MAC" "JBL Vibe Beam 2"
    _speaker_auto
}

gf_ear_off() {
    echo "Disconnecting JBL Vibe Beam 2..."
    bluetoothctl disconnect "$GF_EARBUDS_MAC" > /dev/null 2>&1
    sleep 1
    _speaker_auto
    [ -z "$(bluetoothctl devices Connected)" ] && bt_radio_off
}

ear_both_on() {
    systemctl is-active --quiet bluetooth || bt_radio_on
    _bt_connect "$EARBUDS_MAC"    "Nothing Ear (a)"
    _bt_connect "$GF_EARBUDS_MAC" "JBL Vibe Beam 2"
    pactl set-default-sink combine_all_sinks
    _speaker_auto
    bluetoothctl devices Connected
}

ear_both_off() {
    bluetoothctl disconnect "$EARBUDS_MAC"    > /dev/null 2>&1
    bluetoothctl disconnect "$GF_EARBUDS_MAC" > /dev/null 2>&1
    sleep 1
    _speaker_auto
    [ -z "$(bluetoothctl devices Connected)" ] && bt_radio_off
    echo "Both disconnected."
}

bt_status() {
    bluetoothctl devices Connected
}

audio_reset() {
    pactl set-default-sink "$SPEAKER_SINK"
    pactl set-sink-mute "$SPEAKER_SINK" 0
    echo "Default sink -> laptop speaker, unmuted."
    wpctl status | grep -A8 "Sinks:"
}


# TeX helper
tex() {
    local texfile="$1"
    if [ -z "$texfile" ]; then
        echo "Usage: tex <file.tex>"
        return 1
    fi
    local base="${texfile%.tex}"

    (
	rm -f "${base}.pdf"
	latexmk -pdf -pvc -interaction=nonstopmode -synctex=1 "$texfile" \
            > "/tmp/${base##*/}_latexmk.log" 2>&1 &
        local latexmk_pid=$!

        # wait until the pdf exists AND its size has stopped changing,
        # so we don't open a half-written file on the first compile
        local prev_size=-1
        local size=0
        while true; do
            if [ -f "${base}.pdf" ]; then
                size=$(stat -c%s "${base}.pdf" 2>/dev/null)
                if [ "$size" -gt 0 ] && [ "$size" = "$prev_size" ]; then
                    break
                fi
                prev_size=$size
            fi
            sleep 0.5
        done

        okular "${base}.pdf" > /dev/null 2>&1

        # okular closed -> stop latexmk and clean up build artifacts
        kill "$latexmk_pid" 2>/dev/null
        latexmk -c "$texfile" > /dev/null 2>&1
        rm -f "${base}.log" "${base}.aux" "${base}.out" \
              "${base}.fls" "${base}.fdb_latexmk" "${base}.synctex.gz"
    ) &
    disown

    echo "tex: compiling $texfile in background, opening Okular once the first build finishes..."
}
