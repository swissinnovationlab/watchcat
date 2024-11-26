#!/bin/bash

SYSTEMD_DIR="$HOME/.config/systemd/user"
INSTALLER_FILE_PATH=$(realpath "$0")
INSTALLER_PATH=$(dirname "$INSTALLER_FILE_PATH")
DRYRUN=""
INSTALL=false

usage() {
    echo "Usage: $0 [-i|--install] [--dryrun] [-d|--delete] [-h|--help]"
    echo ""
    echo "Options:"
    echo "  -i, --install      Install the application."
    echo "      --dryrun       Add dry-run mode to watchcat.service during installation."
    echo "  -d, --delete       Delete the application."
    echo "  -h, --help         Display this help message."
    exit 1
}

install_app() {
    echo "Installing Watchcat services..."

    if [[ ! -d "$SYSTEMD_DIR" ]]; then
        echo "Creating systemd user directory at $SYSTEMD_DIR..."
        mkdir -p "$SYSTEMD_DIR"
    fi

    echo "Copying service and timer files to $SYSTEMD_DIR..."
    cp "$INSTALLER_PATH"/services/*.service "$SYSTEMD_DIR/"
    cp "$INSTALLER_PATH"/services/*.timer "$SYSTEMD_DIR/"

    echo "Injecting installer path into systemd service files..."
    sed -i "s|Environment=PATH=<PATH>|Environment=PATH=$INSTALLER_PATH|" "$SYSTEMD_DIR"/watchcat.service
    sed -i "s|Environment=PATH=<PATH>|Environment=PATH=$INSTALLER_PATH|" "$SYSTEMD_DIR"/watchcat_devconn_connector.service
    sed -i "s|Environment=PATH=<PATH>|Environment=PATH=$INSTALLER_PATH|" "$SYSTEMD_DIR"/watchcat_openvpn_dmp.service

    echo "Inject dryrun mode for watchcat.service..."
    sed -i "s|Environment=DRYRUN=<DRYRUN>|Environment=DRYRUN=$DRYRUN|" "$SYSTEMD_DIR"/watchcat.service

    echo "Reloading systemd daemon..."
    systemctl --user daemon-reload

    echo "Enabling services..."
    systemctl --user enable watchcat.service
    systemctl --user enable watchcat_devconn_connector.service
    systemctl --user enable watchcat_openvpn_dmp.service
    systemctl --user enable watchcat.timer

    echo "Installation completed successfully."
}

delete_app() {
    echo "Deleting Watchcat services..."

    echo "Disabling services..."
    systemctl --user disable watchcat.service
    systemctl --user disable watchcat_devconn_connector.service
    systemctl --user disable watchcat_openvpn_dmp.service
    systemctl --user disable watchcat.timer

    echo "Removing service files from $SYSTEMD_DIR..."
    rm -f "$SYSTEMD_DIR"/watchcat.service
    rm -f "$SYSTEMD_DIR"/watchcat_devconn_connector.service
    rm -f "$SYSTEMD_DIR"/watchcat_openvpn_dmp.service
    rm -f "$SYSTEMD_DIR"/watchcat.timer

    echo "Application deleted successfully."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install)
            INSTALL=true
            shift
            ;;
        --dryrun)
            DRYRUN="--dryrun"
            shift
            ;;
        -d|--delete)
            delete_app
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if $INSTALL; then
    install_app
fi
