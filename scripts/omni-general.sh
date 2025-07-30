#!/bin/bash

# Function for error handling
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function for printing confirmation messages
print_confirmation() {
    echo "$1 completed successfully."
}

# Function for updating package manager
update_package_manager() {
    sudo apt update || handle_error "Failed to update package manager"
}

# Ensure consistent indentation
set -e

# Function to install Go latest or custom version
install_go() {
    update_package_manager
    version="$1"
    
    if [ -z "$version" ]; then
        # Default to latest stable version
        echo "Fetching latest Go version..."
        version=$(curl -s https://go.dev/VERSION?m=text 2>/dev/null | head -n1)
        if [ -z "$version" ]; then
            handle_error "Failed to fetch latest Go version"
        fi
    fi
    
    # Normalize version format (remove 'go' prefix if present)
    version_clean=${version#go}
    go_tarball="go${version_clean}.linux-amd64.tar.gz"
    url="https://dl.google.com/go/${go_tarball}"
    
    # Check if Go is already installed with the requested version
    if command -v go &> /dev/null; then
        installed_version=$(go version | awk '{print $3}')
        if [ "$installed_version" == "go${version_clean}" ]; then
            echo "Go version ${version_clean} is already installed"
            return 0
        else
            echo "Removing existing Go installation: $installed_version"
            sudo rm -rf /usr/local/go
        fi
    fi
    
    echo "Downloading Go ${version_clean}..."
    curl -LO "$url" || handle_error "Failed to download Go ${version_clean}"
    
    echo "Installing Go ${version_clean}..."
    sudo tar -C /usr/local -xzf "$go_tarball" || handle_error "Failed to extract Go ${version_clean}"
    rm -f "$go_tarball" || handle_error "Failed to remove Go tarball"
    
    # Update PATH in multiple shell profiles for compatibility
    for profile in ~/.bashrc ~/.zshrc ~/.profile; do
        if [[ -f "$profile" ]]; then
            if ! grep -q "/usr/local/go/bin" "$profile"; then
                echo "export PATH=\$PATH:/usr/local/go/bin" >> "$profile"
                echo "Updated PATH in $profile"
            fi
        fi
    done
    
    # Set GOPATH and GOROOT
    for profile in ~/.bashrc ~/.zshrc ~/.profile; do
        if [[ -f "$profile" ]]; then
            if ! grep -q "GOROOT" "$profile"; then
                echo "export GOROOT=/usr/local/go" >> "$profile"
                echo "export GOPATH=\$HOME/go" >> "$profile"
                echo "Updated Go environment variables in $profile"
            fi
        fi
    done
    
    # Create GOPATH directory
    mkdir -p "$HOME/go"/{bin,src,pkg}
    
    export PATH=$PATH:/usr/local/go/bin
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/go
    
    print_confirmation "Go ${version_clean} installation"
    
    # Verify installation
    if command -v go &> /dev/null; then
        echo "Go version: $(go version)"
        echo "GOROOT: $(go env GOROOT)"
        echo "GOPATH: $(go env GOPATH)"
    fi
}

# Function to install Docker
install_docker() {
    update_package_manager
    if ! command -v docker &> /dev/null; then
        sudo apt install -y docker.io || handle_error "Failed to install Docker"
        sudo usermod -aG docker $USER || handle_error "Failed to add user to Docker group"
        sudo chmod 666 /var/run/docker.sock || handle_error "Failed to set permissions for Docker socket"
        print_confirmation "Docker installation"
    else
        echo "Docker is already installed"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    update_package_manager
    if ! command -v "docker compose" &> /dev/null; then
        while true; do
            echo "Do you want to install Docker Compose plugin(p) / Docker compose standalone(s) or skip it? (p/s/any key)"
            read answer

            case "$answer" in
                p)
                    if ! command docker compose &> /dev/null; then
                        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
                        mkdir -p $DOCKER_CONFIG/cli-plugins
                        curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose || handle_error "Failed to download Docker Compose plugin"
                        chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose || handle_error "Failed to set execute permission for Docker Compose plugin"
                    else
                        echo "Docker Compose plugin is already installed"
                    fi
                    print_confirmation "Docker Compose plugin installation"
                    break
                    ;;
                s)
                    if ! command docker-compose &> /dev/null; then
                        sudo curl -SL https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose || handle_error "Failed to download Docker Compose standalone"
                        sudo chmod +x /usr/local/bin/docker-compose || handle_error "Failed to set execute permission for Docker Compose standalone"
                    else
                        echo "Docker Compose standalone is already installed"
                    fi
                    print_confirmation "Docker Compose standalone installation"
                    break
                    ;;
                *)
                    echo "Skipping Docker Compose installation."
                    break
                    ;;
            esac
        done
    else
        echo "Docker Compose is already installed"
    fi
}

# Function to install Minikube
install_minikube() {
    update_package_manager
    if ! command -v minikube &> /dev/null; then
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 || handle_error "Failed to download Minikube"
        sudo install minikube-linux-amd64 /usr/local/bin/minikube || handle_error "Failed to install Minikube"
        rm -rf minikube* || handle_error "Failed to clean up Minikube installation files"
        print_confirmation "Minikube installation"
    else
        echo "Minikube is already installed"
    fi
}

# Function to install kubectl
install_kubectl() {
    update_package_manager
    if ! command -v kubectl &> /dev/null; then
        sudo snap install kubectl --classic || handle_error "Failed to install kubectl"
        print_confirmation "kubectl installation"
    else
        echo "kubectl is already installed"
    fi
}

# Function to install net-tools
install_net_tools() {
    update_package_manager
    if ! command -v ifconfig &> /dev/null; then
        sudo apt install -y net-tools || handle_error "Failed to install net-tools"
        print_confirmation "net-tools installation"
    else
        echo "net-tools is already installed"
    fi
}

# Function to install programming languages and tools
install_programming_languages() {
    update_package_manager
    sudo apt install -y golang clang llvm gcc-multilib libbpf-dev || handle_error "Failed to install programming languages and tools"
    print_confirmation "Programming languages and tools installation"
}

# Function to install required tools
install_required_tools() {
    update_package_manager
    sudo apt install -y make || handle_error "Failed to install make"
    sudo snap install cmake --classic || handle_error "Failed to install cmake"
    print_confirmation "make installation"
}

# Function to install bpftool
install_bpftool() {
    update_package_manager
    kernel_version=$(uname -r)
    sudo apt install -y linux-tools-$kernel_version || {
        echo "Warning: Failed to install bpftool for kernel version $kernel_version"
        return
    }
    print_confirmation "bpftool installation for kernel version $kernel_version"
}

# Function to install Zsh
install_zsh() {
    update_package_manager
    while true; do
        echo "Do you want to continue zsh installation? (y/n)"
        read answer

        case "$answer" in
            y)
                sudo apt install -y zsh
                sudo apt install -y curl wget git
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

                echo "Installing Zsh"
                echo '' > ~/.zshrc
                echo "ZSH_THEME=\"avit\"" >> ~/.zshrc
                echo "DEFAULT_USER=$USER" >> ~/.zshrc
                echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> ~/.zshrc

                sudo apt install command-not-found -y

                cd ~/.oh-my-zsh/plugins/
                
                echo "Which plugin(s) do you want to install? (syntax-highlighting(s)/both(b))"
                read plugin_answer

                case "$plugin_answer" in
                    s)
                        echo "Installing zsh-syntax-highlighting"
                        sudo apt install command-not-found -y
                        [ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ] && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
                        ;;
                    
                    b)
                        echo "Installing zsh-autosuggestions and zsh-syntax-highlighting"
                        sudo apt install command-not-found -y
                        [ ! -d ~/.oh-my-zsh/plugins/zsh-autosuggestions ] && sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
                        [ ! -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting ] && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
                        ;;
                    *)
                        echo "Invalid choice. Please enter 's' or 'b'."
                        continue
                        ;;
                esac

                echo "source ~/.oh-my-zsh/oh-my-zsh.sh" >> ~/.zshrc
                source ~/.zshrc
                cd
                break
                ;;
            n)
                echo "Aborted"
                break
                ;;
            *)
                echo "Please enter 'y' or 'n'."
                ;;
        esac
    done
}

# Function to display help message
display_help() {
    echo "Usage: $0 [-a] [-d] [-c] [-k] [-p] [-n] [-b] [-z] [-g [version]] [-h]"
    echo "Options:"
    echo "  -a              Install all tools (Docker, Docker Compose, Minikube, kubectl, net-tools, programming languages, required tools, bpftool, Zsh, Go)"
    echo "  -d              Install Docker"
    echo "  -c              Install Docker Compose"
    echo "  -k              Install Minikube"
    echo "  -p              Install kubectl"
    echo "  -n              Install net-tools"
    echo "  -b              Install bpftool"
    echo "  -z              Install Zsh"
    echo "  -g [version]    Install Go (latest version if no version specified, or custom version like '1.21.5')"
    echo "  -h              Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -g           # Install latest Go version"
    echo "  $0 -g 1.21.5    # Install Go version 1.21.5"
    echo "  $0 -a           # Install all tools including latest Go"
    echo "  $0 -d -g 1.20.1 # Install Docker and Go version 1.20.1"
}

# Process flags with OPTARG support for -g flag
while getopts ":adckpnbzg:h" opt; do
    case ${opt} in
        a)  install_docker
            install_docker_compose
            install_minikube
            install_kubectl
            install_net_tools
            install_programming_languages
            install_required_tools
            install_bpftool
            install_zsh
            install_go
            ;;
        d)  install_docker ;;
        c)  install_docker_compose ;;
        k)  install_minikube ;;
        p)  install_kubectl ;;
        n)  install_net_tools ;;
        b)  install_bpftool ;;
        z)  install_zsh ;;
        g)  install_go "$OPTARG" ;;
        h)  display_help ;;
        \?) echo "Invalid option: -$OPTARG. Use -h for help." >&2
            exit 1 ;;
    esac
done

trap 'handle_error "An error occurred"' ERR

# Display help message if no flags are provided
if [[ $# -eq 0 ]]; then
    display_help
fi

echo "All installations completed successfully."
