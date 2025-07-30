#!/bin/bash

# Python3 Installation Script with Optional Dependencies
# Supports Ubuntu/Debian, CentOS/RHEL, and macOS

# Function for error handling
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function for printing confirmation messages
print_confirmation() {
    echo "✓ $1 completed successfully."
}

# Function for printing info messages
print_info() {
    echo "ℹ $1"
}

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            OS="ubuntu"
            PKG_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            OS="centos"
            PKG_MANAGER="yum"
        elif command -v dnf &> /dev/null; then
            OS="fedora"
            PKG_MANAGER="dnf"
        else
            handle_error "Unsupported Linux distribution"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PKG_MANAGER="brew"
    else
        handle_error "Unsupported operating system: $OSTYPE"
    fi
    
    print_info "Detected OS: $OS with package manager: $PKG_MANAGER"
}

# Function for updating package manager
update_package_manager() {
    print_info "Updating package manager..."
    case $PKG_MANAGER in
        apt)
            sudo apt update || handle_error "Failed to update apt"
            ;;
        yum)
            sudo yum update -y || handle_error "Failed to update yum"
            ;;
        dnf)
            sudo dnf update -y || handle_error "Failed to update dnf"
            ;;
        brew)
            if ! command -v brew &> /dev/null; then
                print_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || handle_error "Failed to install Homebrew"
            fi
            brew update || handle_error "Failed to update Homebrew"
            ;;
    esac
}

# Function to install Python3
install_python3() {
    local version="$1"
    local install_method="$2"  # system, pyenv, or source
    
    print_info "Installing Python3..."
    
    case $install_method in
        "pyenv")
            install_python_with_pyenv "$version"
            ;;
        "source")
            install_python_from_source "$version"
            ;;
        *)
            install_python_system "$version"
            ;;
    esac
}

# Function to install Python via system package manager
install_python_system() {
    local version="$1"
    
    case $PKG_MANAGER in
        apt)
            # Install Python3 and essential packages
            sudo apt install -y python3 python3-pip python3-venv python3-dev python3-setuptools || handle_error "Failed to install Python3"
            
            # Install specific version if requested
            if [[ -n "$version" && "$version" != "latest" ]]; then
                sudo apt install -y "python${version}" "python${version}-venv" "python${version}-dev" 2>/dev/null || {
                    print_info "Specific version python${version} not available via apt, using default version"
                }
            fi
            ;;
        yum)
            sudo yum install -y python3 python3-pip python3-devel python3-setuptools || handle_error "Failed to install Python3"
            ;;
        dnf)
            sudo dnf install -y python3 python3-pip python3-devel python3-setuptools || handle_error "Failed to install Python3"
            ;;
        brew)
            if [[ -n "$version" && "$version" != "latest" ]]; then
                brew install "python@${version}" || handle_error "Failed to install Python ${version}"
            else
                brew install python3 || handle_error "Failed to install Python3"
            fi
            ;;
    esac
    
    print_confirmation "Python3 system installation"
}

# Function to install Python via pyenv
install_python_with_pyenv() {
    local version="$1"
    
    # Install pyenv if not present
    if ! command -v pyenv &> /dev/null; then
        print_info "Installing pyenv..."
        curl https://pyenv.run | bash || handle_error "Failed to install pyenv"
        
        # Add pyenv to PATH
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        
        # Update shell profiles
        for profile in ~/.bashrc ~/.zshrc ~/.profile; do
            if [[ -f "$profile" ]]; then
                if ! grep -q "pyenv" "$profile"; then
                    echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> "$profile"
                    echo 'eval "$(pyenv init --path)"' >> "$profile"
                    echo 'eval "$(pyenv init -)"' >> "$profile"
                fi
            fi
        done
    fi
    
    # Install build dependencies
    case $PKG_MANAGER in
        apt)
            sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
                libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
                libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl || \
                handle_error "Failed to install Python build dependencies"
            ;;
        yum|dnf)
            sudo $PKG_MANAGER groupinstall -y "Development Tools" || handle_error "Failed to install development tools"
            sudo $PKG_MANAGER install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite \
                sqlite-devel openssl-devel tk-devel libffi-devel xz-devel || \
                handle_error "Failed to install Python build dependencies"
            ;;
    esac
    
    # Install Python version
    if [[ -z "$version" || "$version" == "latest" ]]; then
        version=$(pyenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    fi
    
    print_info "Installing Python ${version} via pyenv..."
    pyenv install "$version" || handle_error "Failed to install Python ${version} via pyenv"
    pyenv global "$version" || handle_error "Failed to set Python ${version} as global"
    
    print_confirmation "Python ${version} installation via pyenv"
}

# Function to install Python from source
install_python_from_source() {
    local version="$1"
    
    if [[ -z "$version" || "$version" == "latest" ]]; then
        print_info "Fetching latest Python version..."
        version=$(curl -s https://www.python.org/ftp/python/ | grep -oE 'href="[0-9]+\.[0-9]+\.[0-9]+/"' | sed 's/href="//;s/\/"//g' | sort -V | tail -1)
    fi
    
    print_info "Installing Python ${version} from source..."
    
    # Install build dependencies
    case $PKG_MANAGER in
        apt)
            sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
                libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev || \
                handle_error "Failed to install build dependencies"
            ;;
        yum|dnf)
            sudo $PKG_MANAGER groupinstall -y "Development Tools" || handle_error "Failed to install development tools"
            sudo $PKG_MANAGER install -y zlib-devel bzip2-devel openssl-devel ncurses-devel \
                sqlite-devel readline-devel tk-devel gdbm-devel libffi-devel || \
                handle_error "Failed to install build dependencies"
            ;;
    esac
    
    # Download and compile Python
    cd /tmp
    wget "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" || handle_error "Failed to download Python ${version}"
    tar -xf "Python-${version}.tgz" || handle_error "Failed to extract Python ${version}"
    cd "Python-${version}"
    
    ./configure --enable-optimizations --with-ensurepip=install || handle_error "Failed to configure Python build"
    make -j $(nproc) || handle_error "Failed to compile Python"
    sudo make altinstall || handle_error "Failed to install Python"
    
    # Create symlinks
    sudo ln -sf "/usr/local/bin/python${version%.*}" /usr/local/bin/python3
    sudo ln -sf "/usr/local/bin/pip${version%.*}" /usr/local/bin/pip3
    
    # Cleanup
    cd /
    rm -rf "/tmp/Python-${version}" "/tmp/Python-${version}.tgz"
    
    print_confirmation "Python ${version} installation from source"
}

# Function to upgrade pip
upgrade_pip() {
    print_info "Upgrading pip..."
    
    if command -v pip3 &> /dev/null; then
        pip3 install --upgrade pip || handle_error "Failed to upgrade pip"
    elif command -v pip &> /dev/null; then
        pip install --upgrade pip || handle_error "Failed to upgrade pip"
    else
        handle_error "pip not found"
    fi
    
    print_confirmation "pip upgrade"
}

# Function to create virtual environment
setup_virtual_environment() {
    local env_name="$1"
    local env_path="$2"
    
    if [[ -z "$env_name" ]]; then
        env_name="python-env"
    fi
    
    if [[ -z "$env_path" ]]; then
        env_path="$HOME/python-environments"
    fi
    
    print_info "Setting up virtual environment: $env_name"
    
    mkdir -p "$env_path"
    
    if command -v python3 &> /dev/null; then
        python3 -m venv "$env_path/$env_name" || handle_error "Failed to create virtual environment"
    else
        handle_error "Python3 not found"
    fi
    
    # Create activation script
    cat > "$env_path/activate-$env_name.sh" << EOF
#!/bin/bash
source "$env_path/$env_name/bin/activate"
echo "Activated Python virtual environment: $env_name"
echo "Python version: \$(python --version)"
echo "Python path: \$(which python)"
EOF
    
    chmod +x "$env_path/activate-$env_name.sh"
    
    print_confirmation "Virtual environment setup: $env_name"
    print_info "Activate with: source $env_path/$env_name/bin/activate"
    print_info "Or use: $env_path/activate-$env_name.sh"
}

# Function to install data science packages
install_data_science_packages() {
    local packages=("numpy" "pandas" "matplotlib" "scipy" "seaborn" "plotly" "scikit-learn")
    local pip_cmd
    
    if command -v pip3 &> /dev/null; then
        pip_cmd="pip3"
    elif command -v pip &> /dev/null; then
        pip_cmd="pip"
    else
        handle_error "pip not found"
    fi
    
    print_info "Installing data science packages..."
    
    for package in "${packages[@]}"; do
        print_info "Installing $package..."
        $pip_cmd install "$package" || handle_error "Failed to install $package"
    done
    
    print_confirmation "Data science packages installation"
}

# Function to install web development packages
install_web_dev_packages() {
    local packages=("flask" "django" "fastapi" "requests" "beautifulsoup4" "selenium")
    local pip_cmd
    
    if command -v pip3 &> /dev/null; then
        pip_cmd="pip3"
    elif command -v pip &> /dev/null; then
        pip_cmd="pip"
    else
        handle_error "pip not found"
    fi
    
    print_info "Installing web development packages..."
    
    for package in "${packages[@]}"; do
        print_info "Installing $package..."
        $pip_cmd install "$package" || handle_error "Failed to install $package"
    done
    
    print_confirmation "Web development packages installation"
}

# Function to install development tools
install_development_tools() {
    local packages=("black" "flake8" "pytest" "mypy" "jupyterlab" "ipython" "virtualenv")
    local pip_cmd
    
    if command -v pip3 &> /dev/null; then
        pip_cmd="pip3"
    elif command -v pip &> /dev/null; then
        pip_cmd="pip"
    else
        handle_error "pip not found"
    fi
    
    print_info "Installing development tools..."
    
    for package in "${packages[@]}"; do
        print_info "Installing $package..."
        $pip_cmd install "$package" || handle_error "Failed to install $package"
    done
    
    print_confirmation "Development tools installation"
}

# Function to install custom packages
install_custom_packages() {
    local packages_string="$1"
    local pip_cmd
    
    if command -v pip3 &> /dev/null; then
        pip_cmd="pip3"
    elif command -v pip &> /dev/null; then
        pip_cmd="pip"
    else
        handle_error "pip not found"
    fi
    
    # Convert comma-separated string to array
    IFS=',' read -ra packages <<< "$packages_string"
    
    print_info "Installing custom packages: ${packages[*]}"
    
    for package in "${packages[@]}"; do
        # Trim whitespace
        package=$(echo "$package" | xargs)
        print_info "Installing $package..."
        $pip_cmd install "$package" || handle_error "Failed to install $package"
    done
    
    print_confirmation "Custom packages installation"
}

# Function to verify Python installation
verify_installation() {
    print_info "Verifying Python installation..."
    
    # Check Python version
    if command -v python3 &> /dev/null; then
        echo "Python3 version: $(python3 --version)"
        echo "Python3 path: $(which python3)"
    else
        echo "Warning: python3 command not found"
    fi
    
    # Check pip version
    if command -v pip3 &> /dev/null; then
        echo "pip3 version: $(pip3 --version)"
    elif command -v pip &> /dev/null; then
        echo "pip version: $(pip --version)"
    else
        echo "Warning: pip not found"
    fi
    
    # Test basic Python functionality
    python3 -c "import sys; print(f'Python executable: {sys.executable}'); print(f'Python version: {sys.version}')" 2>/dev/null || {
        echo "Warning: Python basic functionality test failed"
    }
    
    print_confirmation "Python installation verification"
}

# Function to display help message
display_help() {
    echo "Python3 Installation Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Installation Methods:"
    echo "  -s, --system            Install via system package manager (default)"
    echo "  -p, --pyenv             Install via pyenv (version manager)"
    echo "  -r, --source            Install from source code"
    echo ""
    echo "Version Options:"
    echo "  -v, --version VERSION   Install specific Python version (e.g., 3.11.5)"
    echo "  -l, --latest            Install latest Python version (default)"
    echo ""
    echo "Package Options:"
    echo "  -d, --data-science      Install data science packages (numpy, pandas, matplotlib, etc.)"
    echo "  -w, --web-dev           Install web development packages (flask, django, requests, etc.)"
    echo "  -t, --dev-tools         Install development tools (black, pytest, jupyter, etc.)"
    echo "  -c, --custom PACKAGES   Install custom packages (comma-separated list)"
    echo ""
    echo "Environment Options:"
    echo "  -e, --venv [NAME]       Create virtual environment (default name: python-env)"
    echo "  --venv-path PATH        Virtual environment path (default: ~/python-environments)"
    echo ""
    echo "Utility Options:"
    echo "  -u, --upgrade-pip       Upgrade pip to latest version"
    echo "  -a, --all               Install everything (system Python + all packages + venv)"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --system --version 3.11.5 --data-science"
    echo "  $0 --pyenv --latest --dev-tools --venv my-project"
    echo "  $0 --all"
    echo "  $0 --custom 'tensorflow,torch,opencv-python'"
}

# Main execution function
main() {
    local install_method="system"
    local python_version=""
    local install_data_science=false
    local install_web_dev=false
    local install_dev_tools=false
    local custom_packages=""
    local create_venv=false
    local venv_name=""
    local venv_path=""
    local upgrade_pip_flag=false
    local install_all=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--system)
                install_method="system"
                shift
                ;;
            -p|--pyenv)
                install_method="pyenv"
                shift
                ;;
            -r|--source)
                install_method="source"
                shift
                ;;
            -v|--version)
                python_version="$2"
                shift 2
                ;;
            -l|--latest)
                python_version="latest"
                shift
                ;;
            -d|--data-science)
                install_data_science=true
                shift
                ;;
            -w|--web-dev)
                install_web_dev=true
                shift
                ;;
            -t|--dev-tools)
                install_dev_tools=true
                shift
                ;;
            -c|--custom)
                custom_packages="$2"
                shift 2
                ;;
            -e|--venv)
                create_venv=true
                if [[ -n "$2" && "$2" != -* ]]; then
                    venv_name="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --venv-path)
                venv_path="$2"
                shift 2
                ;;
            -u|--upgrade-pip)
                upgrade_pip_flag=true
                shift
                ;;
            -a|--all)
                install_all=true
                shift
                ;;
            -h|--help)
                display_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                display_help
                exit 1
                ;;
        esac
    done
    
    # Set defaults for --all flag
    if $install_all; then
        install_data_science=true
        install_web_dev=true
        install_dev_tools=true
        create_venv=true
        upgrade_pip_flag=true
    fi
    
    # Detect OS and initialize
    detect_os
    update_package_manager
    
    # Install Python
    install_python3 "$python_version" "$install_method"
    
    # Upgrade pip if requested
    if $upgrade_pip_flag; then
        upgrade_pip
    fi
    
    # Install package collections
    if $install_data_science; then
        install_data_science_packages
    fi
    
    if $install_web_dev; then
        install_web_dev_packages
    fi
    
    if $install_dev_tools; then
        install_development_tools
    fi
    
    # Install custom packages
    if [[ -n "$custom_packages" ]]; then
        install_custom_packages "$custom_packages"
    fi
    
    # Create virtual environment
    if $create_venv; then
        setup_virtual_environment "$venv_name" "$venv_path"
    fi
    
    # Verify installation
    verify_installation
    
    print_confirmation "Python3 installation script completed"
}

# Error handling
set -e
trap 'handle_error "An unexpected error occurred on line $LINENO"' ERR

# Display help if no arguments provided
if [[ $# -eq 0 ]]; then
    display_help
    exit 0
fi

# Run main function with all arguments
main "$@"
