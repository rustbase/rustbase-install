#!/usr/bin/env bash
# Based on https://bun.sh/install

if [[ ${OS:-} = Windows_NT ]]; then
    echo 'Please install Rustbase using Windows Subsystem for Linux'
    exit 1
fi

invalid_option() {
    echo "Invalid option: $1" >&2
    exit 1
}

no_cli=0
no_service=0

while (($#)); do
    [[ $1 = -- ]] && {
        shift
        break
    }
    [[ $1 = -?* ]] || break
    case $1 in
    --no-cli) no_cli=1 ;;
    --no-service) no_service=1 ;;
    -*) invalid_option "$1" ;;
    esac
    shift
done

# Reset
Color_Off=''

# Regular Colors
Red=''
Green=''
Dim='' # White

# Bold
Bold_White=''
Bold_Green=''

if [[ -t 1 ]]; then
    # Reset
    Color_Off='\033[0m' # Text Reset

    # Regular Colors
    Red='\033[0;31m'   # Red
    Green='\033[0;32m' # Green
    Dim='\033[0;2m'    # White

    # Bold
    Bold_Green='\033[1;32m' # Bold Green
    Bold_White='\033[1m'    # Bold White
fi

error() {
    echo -e "${Red}error${Color_Off}:" "$@" >&2
    exit 1
}

info() {
    echo -e "${Dim}$@ ${Color_Off}"
}

info_bold() {
    echo -e "${Bold_White}$@ ${Color_Off}"
}

success() {
    echo -e "${Green}$@ ${Color_Off}"
}

tmpdir=$(mktemp -d)

echo "Installing Rustbase..."

case $(uname -ms) in
'Linux x86_64')
    target=linux-x64
    ;;

'Linux i686')
    target=linux-x86
    ;;

*)
    error 'Unsupported platform'
    ;;
esac

rustbase_repo="https://github.com/rustbase/rustbase"
rustbase_download="$rustbase_repo/releases/latest/download/rustbase-$target.zip"
rustbase_bin="$HOME/rustbase/bin"
rustbase_server_exe="$rustbase_bin/rustbase_server"

if [[ ! -d $rustbase_bin ]]; then
    mkdir -p "$rustbase_bin" ||
        error "Failed to create install directory \"$rustbase_bin\""
fi

if ! command -v unzip &>/dev/null; then
    echo "unzip could not be found"
    exit
fi

curl --fail --location -sS --output "$tmpdir/rustbase-server.zip" "$rustbase_download" ||
    echo "Failed to download Rustbase from \"$rustbase_download\""

unzip -oqjd "$rustbase_bin" "$tmpdir/rustbase-server.zip" ||
    echo 'Failed to extract Rustbase'

mv "$rustbase_bin/rustbase" "$rustbase_server_exe" ||
    echo 'Failed to move extracted Rustbase to destination'

chmod +x "$rustbase_server_exe" ||
    echo 'Failed to set permissions on Rustbase executable'

rm -r "$tmpdir/rustbase-server.zip" ||
    echo 'Failed to remove downloaded Rustbase archive'

if [[ $no_cli -eq 0 ]]; then
    rustbase_cli_script="https://raw.githubusercontent.com/rustbase/rustbase-install/main/install-cli.sh"
    curl --location -sS --output "$tmpdir/install-cli.sh" "$rustbase_cli_script"
    chmod +x "$tmpdir/install-cli.sh"
    "$tmpdir/install-cli.sh"
    rm -r "$tmpdir/install-cli.sh"
fi

if [[ $no_service -eq 0 ]]; then
    if ! command -v systemctl &>/dev/null; then
        echo "systemctl could not be found"
        exit
    fi

    service_file="
[Unit]
Description=Rustbase Database Server
After=network.target

[Service]
Type=simple
ExecStart=$rustbase_server_exe

[Install]
WantedBy=multi-user.target"

    echo "$service_file" | sudo tee -a /etc/systemd/system/rustbase.service >/dev/null

    echo ""
    info "Enable Rustbase Database Server service using:"
    info_bold "sudo systemctl enable rustbase"
    echo ""
fi

rm -r "$tmpdir" || exit 1

success "Rustbase installed successfully"
