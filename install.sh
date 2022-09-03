#!/usr/bin/env bash
# Based on https://bun.sh/install

if [[ ${OS:-} = Windows_NT ]]; then
    echo 'Please install Rustbase using Windows Subsystem for Linux'
    exit 1
fi

# if [ "$EUID" -ne 0 ]
#     then echo "You can run as a root to better experience"
#     echo "Waiting for 10 seconds..."
#     sleep 10
#     exit
# fi

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

echo "Installing Rustbase..."

case $(uname -ms) in
'Linux x86_64')
    target=linux-x64
    ;;

*)
    error 'Unsupported platform'
    ;;
esac

rustbase_repo=https://github.com/rustbase/rustbase
rustbase_cli_repo=https://github.com/rustbase/rustbase-cli

rustbase_download=$rustbase_repo/releases/latest/download/rustbase-$target.zip
rustbase_cli_download=$rustbase_cli_repo/releases/latest/download/rustbase-cli-$target.zip

rustbase_bin=$HOME/rustbase/bin

rustbase_cli_exe=$rustbase_bin/rustbase
rustbase_server_exe=$rustbase_bin/rustbase_server


if [[ ! -d $rustbase_bin ]]; then
    mkdir -p "$rustbase_bin" ||
        error "Failed to create install directory \"$rustbase_bin\""
fi

# Rustbase Server

curl --fail --location -s --output "rustbase-server.zip" "$rustbase_download" ||
    echo "Failed to download Rustbase from \"$rustbase_download\""

unzip -oqjd "$rustbase_bin" "rustbase-server.zip" ||
    echo 'Failed to extract Rustbase'

mv "$rustbase_bin/rustbase" "$rustbase_server_exe" ||
    echo 'Failed to move extracted Rustbase to destination'

chmod +x "$rustbase_server_exe" ||
    echo 'Failed to set permissions on Rustbase executable'

rm -r "rustbase-server.zip" ||
    echo 'Failed to remove downloaded Rustbase archive'

# Rustbase CLI

curl --fail --location -s --output "rustbase-cli.zip" "$rustbase_cli_download" ||
    echo "Failed to download Rustbase from \"$rustbase_cli_download\""

unzip -oqjd "$rustbase_bin" "rustbase-cli.zip" ||
    echo 'Failed to extract Rustbase'

mv "$rustbase_bin/rustbase-cli" "$rustbase_cli_exe" ||
    echo 'Failed to move extracted Rustbase to destination'

chmod +x "$rustbase_cli_exe" ||
    echo 'Failed to set permissions on Rustbase executable'

rm -r "rustbase-cli.zip" ||
    echo 'Failed to remove downloaded Rustbase archive'

success "Rustbase installed!"

info "Adding Rustbase to PATH..."

case $(basename "$SHELL") in
'fish')

    commands=(
        "set --export PATH $rustbase_bin\$PATH"
    )

    fish_config=$HOME/.config/fish/config.fish
    {
        echo -e '\n# rustbase'

        for command in "${commands[@]}"; do
            echo "$command"
        done
    } >>"$fish_config"

    info "Rustbase added to PATH!"
    ;;

'zsh')
    zsh_config=$HOME/.zshrc
    {
        echo -e '\n# rustbase'
        echo "export PATH=\"$rustbase_bin:\$PATH\""
    } >>"$zsh_config"
    info "Rustbase added to PATH!"
    ;;

*)
    echo 'Manually add the directory to ~/.bashrc (or similar):'
    echo "export PATH=\"$rustbase_bin:\$PATH\""
    ;;
esac

{

echo "
[Unit]
Description=Rustbase Database Server
After=network.target

[Service]
Type=simple
ExecStart=$rustbase_server_exe

[Install]
WantedBy=multi-user.target" > "/lib/systemd/system/rustbase.service"
} > /dev/null 2>&1


sudo systemctl enable rustbase.service && systemctl start rustbase.service

success "Run 'rustbase' to get started"