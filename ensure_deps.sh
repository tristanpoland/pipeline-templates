#!/bin/bash

prompt_install() {
    local package=$1
    read -p "${package} is not installed. Do you want to install it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

ensure_fly() {
    if command -v fly &> /dev/null; then
        echo "fly is already installed."
        return 0
    fi

    echo "fly is not installed."
    if prompt_install "fly"; then
        echo "Attempting to install fly..."

        # Determine the operating system
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                # Debian-based
                sudo apt-get update
                sudo apt-get install -y wget
            elif command -v yum &> /dev/null; then
                # Red Hat-based
                sudo yum install -y wget
            elif command -v pacman &> /dev/null; then
                # Arch-based
                sudo pacman -Sy wget
            else
                echo "Unsupported Linux distribution. Please install fly manually."
                return 1
            fi

            # Download and install fly
            wget -O fly "https://github.com/concourse/concourse/releases/latest/download/fly-linux-amd64"
            chmod +x fly
            sudo mv fly /usr/local/bin/

        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install fly
            else
                echo "Homebrew is not installed. Please install Homebrew or fly manually."
                return 1
            fi

        else
            echo "Unsupported operating system. Please install fly manually."
            return 1
        fi

        if command -v fly &> /dev/null; then
            echo "fly has been successfully installed."
            return 0
        else
            echo "Failed to install fly. Please install it manually."
            return 1
        fi
    else
        echo "fly installation skipped."
        return 1
    fi
}

ensure_bosh() {
    if command -v bosh &> /dev/null; then
        echo "bosh CLI is already installed."
        return 0
    fi

    echo "bosh CLI is not installed."
    if prompt_install "bosh CLI"; then
        echo "Attempting to install bosh CLI..."

        # Determine the operating system
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                # Debian-based
                sudo apt-get update
                sudo apt-get install -y wget
            elif command -v yum &> /dev/null; then
                # Red Hat-based
                sudo yum install -y wget
            elif command -v pacman &> /dev/null; then
                # Arch-based
                sudo pacman -Sy wget
            else
                echo "Unsupported Linux distribution. Please install bosh CLI manually."
                return 1
            fi

            # Download and install bosh CLI
            wget -O bosh https://github.com/cloudfoundry/bosh-cli/releases/latest/download/bosh-cli-$(uname -s)-amd64
            chmod +x bosh
            sudo mv bosh /usr/local/bin/

        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install cloudfoundry/tap/bosh-cli
            else
                echo "Homebrew is not installed. Please install Homebrew or bosh CLI manually."
                return 1
            fi

        else
            echo "Unsupported operating system. Please install bosh CLI manually."
            return 1
        fi

        if command -v bosh &> /dev/null; then
            echo "bosh CLI has been successfully installed."
            return 0
        else
            echo "Failed to install bosh CLI. Please install it manually."
            return 1
        fi
    else
        echo "bosh CLI installation skipped."
        return 1
    fi
}

# Main execution
fly_installed=true
bosh_installed=true

ensure_fly
if [ $? -ne 0 ]; then
    fly_installed=false
fi

ensure_bosh
if [ $? -ne 0 ]; then
    bosh_installed=false
fi

if $fly_installed && $bosh_installed; then
    echo "All dependencies are installed successfully."
    exit 0
else
    echo "Some dependencies are missing. Please install them manually to proceed."
    exit 1
fi