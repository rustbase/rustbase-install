#!/usr/bin/env bash

if [[ ${OS:-} = Windows_NT ]]; then
    echo 'Please install Rustbase using Windows Subsystem for Linux'
    exit 1
fi

invalid_option() {
    echo "Invalid option: $1" >&2
    exit 1
}

no_path=0

while (($#)); do
    [[ $1 = -- ]] && {
        shift
        break
    }
    [[ $1 = -?* ]] || break
    case $1 in
    --no-path) no_path=1 ;;
    # -d) arg_d=1 ;;
    -*) invalid_option "$1" ;;
    esac
    shift
done

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

rustbase_bin=$HOME/rustbase/bin

rustbase_cli_repo=https://github.com/rustbase/rustbase-cli
rustbase_cli_download=$rustbase_cli_repo/releases/latest/download/rustbase-cli-$target.zip
rustbase_cli_exe=$rustbase_bin/rustbase

tmpdir=$(mktemp -d)

if [[ ! -d $rustbase_bin ]]; then
    mkdir -p "$rustbase_bin" ||
        error "Failed to create install directory \"$rustbase_bin\""
fi

if ! command -v unzip &>/dev/null; then
    echo "unzip could not be found"
    exit
fi

echo "[Rustbase CLI] Downloading $target binaries..."

curl --fail --location -s --output "$tmpdir/rustbase-cli.zip" "$rustbase_cli_download" ||
    echo "Failed to download Rustbase from \"$rustbase_cli_download\""

unzip -oqjd "$rustbase_bin" "$tmpdir/rustbase-cli.zip" ||
    echo 'Failed to extract Rustbase'

mv "$rustbase_bin/rustbase-cli" "$rustbase_cli_exe" ||
    echo 'Failed to move extracted Rustbase to destination'

chmod +x "$rustbase_cli_exe" ||
    echo 'Failed to set permissions on Rustbase executable'

rm -r "$tmpdir/rustbase-cli.zip" ||
    echo 'Failed to remove downloaded Rustbase archive'

if [[ $no_path -eq 0 ]]; then
    echo "[Rustbase CLI] Adding $rustbase_bin to PATH..."

    case $(basename "$SHELL") in
    'fish')

        commands=(
            "set --export PATH $rustbase_bin\$PATH"
        )

        fish_config=$HOME/.config/fish/config.fish
        {
            echo -e '\n# Rustbase Database Server'

            for command in "${commands[@]}"; do
                echo "$command"
            done
        } >>"$fish_config"

        echo "[Rustbase CLI] CLI added to PATH!"
        ;;

    'zsh')
        zsh_config=$HOME/.zshrc
        {
            echo -e '\n# Rustbase Database Server'
            echo "export PATH=\"$rustbase_bin:\$PATH\""
        } >>"$zsh_config"

        echo "[Rustbase CLI] CLI added to PATH!"
        ;;

    'bash')
        bash_config=$HOME/.bashrc
        {
            echo -e '\n# Rustbase Database Server'
            echo "export PATH=\"$rustbase_bin:\$PATH\""
        } >>"$bash_config"

        echo "[Rustbase CLI] CLI added to PATH!"
        ;;

    *)
        echo 'Manually add the directory to ~/.bashrc (or similar):'
        echo "export PATH=\"$rustbase_bin:\$PATH\""
        ;;
    esac
fi

echo "[Rustbase CLI] Installation complete!"
