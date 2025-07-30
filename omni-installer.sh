#!/bin/bash

# Omni-Installer CLI - Unified Installation Tool
# Version: 1.0.0
# Description: Comprehensive developer environment installer

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
CONFIG_DIR="$SCRIPT_DIR/config"

# Source common functions
source "$LIB_DIR/common.sh"
source "$LIB_DIR/ui.sh"

# Global variables
VERSION="1.0.0"
INTERACTIVE_MODE=true
LOG_FILE="$HOME/.omni-installer.log"

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Omni-Installer Session Started: $(date) ===" >> "$LOG_FILE"
}

# Display main menu
show_main_menu() {
    clear
    print_header "Omni-Installer v$VERSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 INSTALLATION CATEGORIES"
    echo ""
    echo "  1️⃣  System Tools        - Docker, Kubernetes, Development Tools"
    echo "  2️⃣  Python Environment  - Python versions, packages, virtual environments"
    echo "  3️⃣  eBPF Development    - eBPF toolkit, libraries, and development environment"
    echo "  4️⃣  Custom Installation - Install from custom script or configuration"
    echo ""
    echo "🔧 UTILITIES"
    echo ""
    echo "  5️⃣  Installation Status - Check installed tools and versions"
    echo "  6️⃣  Configuration       - Manage installer preferences"
    echo "  7️⃣  Update Installer    - Update omni-installer to latest version"
    echo "  8️⃣  Help & Documentation"
    echo ""
    echo "  0️⃣  Exit"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Handle menu selection
handle_menu_selection() {
    local choice="$1"
    
    case $choice in
        1)
            show_system_tools_menu
            ;;
        2)
            show_python_menu
            ;;
        3)
            show_ebpf_menu
            ;;
        4)
            show_custom_installation_menu
            ;;
        5)
            show_installation_status
            ;;
        6)
            show_configuration_menu
            ;;
        7)
            update_installer
            ;;
        8)
            show_help
            ;;
        0)
            print_info "Thank you for using Omni-Installer!"
            exit 0
            ;;
        *)
            print_error "Invalid selection. Please choose a number from 0-8."
            ;;
    esac
}

# System Tools submenu
show_system_tools_menu() {
    clear
    print_header "System Tools Installation"
    echo ""
    echo "Available System Tools:"
    echo ""
    echo "  1️⃣  Docker & Docker Compose"
    echo "  2️⃣  Kubernetes Tools (kubectl, minikube)"
    echo "  3️⃣  Development Tools (Git, Make, CMake)"
    echo "  4️⃣  Network Tools (net-tools, curl, wget)"
    echo "  5️⃣  Build Tools (GCC, Clang, LLVM)"
    echo "  6️⃣  Shell Environment (Zsh, Oh-My-Zsh)"
    echo "  7️⃣  All System Tools"
    echo "  8️⃣  Custom Selection"
    echo ""
    echo "  9️⃣  Back to Main Menu"
    echo "  0️⃣  Exit"
    echo ""
    
    read -p "Select option [0-9]: " choice
    
    case $choice in
        1) run_system_installer "-d -c" ;;
        2) run_system_installer "-k -p" ;;
        3) run_system_installer "--dev-tools" ;;
        4) run_system_installer "-n" ;;
        5) run_system_installer "--build-tools" ;;
        6) run_system_installer "-z" ;;
        7) run_system_installer "-a" ;;
        8) custom_system_selection ;;
        9) return ;;
        0) exit 0 ;;
        *) print_error "Invalid selection"; sleep 2; show_system_tools_menu ;;
    esac
}

# Python Environment submenu
show_python_menu() {
    clear
    print_header "Python Environment Setup"
    echo ""
    echo "Python Installation Options:"
    echo ""
    echo "  1️⃣  System Python (via package manager)"
    echo "  2️⃣  PyEnv (version manager)"
    echo "  3️⃣  Python from Source"
    echo "  4️⃣  Anaconda/Miniconda"
    echo ""
    echo "Package Collections:"
    echo ""
    echo "  5️⃣  Data Science Stack (NumPy, Pandas, Matplotlib)"
    echo "  6️⃣  Web Development (Flask, Django, FastAPI)"
    echo "  7️⃣  Machine Learning (TensorFlow, PyTorch, Scikit-learn)"
    echo "  8️⃣  Development Tools (Black, Pytest, Jupyter)"
    echo "  9️⃣  Custom Package Selection"
    echo ""
    echo "Environment Management:"
    echo ""
    echo "  🔟  Create Virtual Environment"
    echo "  1️⃣1️⃣  Complete Python Setup (All packages + Venv)"
    echo ""
    echo "  🔙  Back to Main Menu"
    echo "  0️⃣  Exit"
    echo ""
    
    read -p "Select option: " choice
    
    case $choice in
        1) run_python_installer "--system --latest" ;;
        2) run_python_installer "--pyenv --latest" ;;
        3) run_python_installer "--source --latest" ;;
        4) install_anaconda ;;
        5) run_python_installer "--system --data-science --venv ds-env" ;;
        6) run_python_installer "--system --web-dev --venv web-env" ;;
        7) install_ml_stack ;;
        8) run_python_installer "--system --dev-tools --venv dev-env" ;;
        9) custom_python_packages ;;
        10) create_virtual_environment ;;
        11) run_python_installer "--all" ;;
        "back"|"b") return ;;
        0) exit 0 ;;
        *) print_error "Invalid selection"; sleep 2; show_python_menu ;;
    esac
}

# eBPF Development submenu
show_ebpf_menu() {
    clear
    print_header "eBPF Development Environment"
    echo ""
    echo "eBPF Installation Options:"
    echo ""
    echo "  1️⃣  eBPF Core Tools (bpftool, libbpf)"
    echo "  2️⃣  BCC (BPF Compiler Collection)"
    echo "  3️⃣  bpftrace (High-level tracing language)"
    echo "  4️⃣  libbpf Development Environment"
    echo "  5️⃣  Kernel Headers & Build Tools"
    echo "  6️⃣  eBPF Examples & Tutorials"
    echo "  7️⃣  Complete eBPF Development Stack"
    echo "  8️⃣  Custom eBPF Selection"
    echo ""
    echo "Verification & Testing:"
    echo ""
    echo "  9️⃣  Verify eBPF Environment"
    echo "  🔟  Run eBPF Hello World"
    echo ""
    echo "  🔙  Back to Main Menu"
    echo "  0️⃣  Exit"
    echo ""
    
    read -p "Select option: " choice
    
    case $choice in
        1) run_ebpf_installer "--core-tools" ;;
        2) run_ebpf_installer "--bcc" ;;
        3) run_ebpf_installer "--bpftrace" ;;
        4) run_ebpf_installer "--libbpf-dev" ;;
        5) run_ebpf_installer "--kernel-headers" ;;
        6) run_ebpf_installer "--examples" ;;
        7) run_ebpf_installer "--all" ;;
        8) custom_ebpf_selection ;;
        9) verify_ebpf_environment ;;
        10) run_ebpf_hello_world ;;
        "back"|"b") return ;;
        0) exit 0 ;;
        *) print_error "Invalid selection"; sleep 2; show_ebpf_menu ;;
    esac
}

# Run system tools installer
run_system_installer() {
    local flags="$1"
    print_info "Running system tools installer with flags: $flags"
    
    if [[ -f "$SCRIPTS_DIR/omni-general.sh" ]]; then
        log_action "System Tools Installation" "$flags"
        bash "$SCRIPTS_DIR/omni-general.sh" $flags
        press_enter_to_continue
    else
        print_error "System tools installer not found at $SCRIPTS_DIR/omni-general.sh"
        press_enter_to_continue
    fi
}

# Run Python installer
run_python_installer() {
    local flags="$1"
    print_info "Running Python installer with flags: $flags"
    
    if [[ -f "$SCRIPTS_DIR/omni-python.sh" ]]; then
        log_action "Python Installation" "$flags"
        bash "$SCRIPTS_DIR/omni-python.sh" $flags
        press_enter_to_continue
    else
        print_error "Python installer not found at $SCRIPTS_DIR/omni-python.sh"
        press_enter_to_continue
    fi
}

# Run eBPF installer
run_ebpf_installer() {
    local flags="$1"
    print_info "Running eBPF installer with flags: $flags"
    
    if [[ -f "$SCRIPTS_DIR/omni-ebpf.sh" ]]; then
        log_action "eBPF Installation" "$flags"
        bash "$SCRIPTS_DIR/omni-ebpf.sh" $flags
        press_enter_to_continue
    else
        print_error "eBPF installer not found at $SCRIPTS_DIR/omni-ebpf.sh"
        press_enter_to_continue
    fi
}

# Custom system tool selection
custom_system_selection() {
    clear
    print_header "Custom System Tools Selection"
    echo ""
    echo "Available flags for system-tools.sh:"
    echo ""
    echo "  -d    Docker"
    echo "  -c    Docker Compose"
    echo "  -k    Minikube"
    echo "  -p    kubectl"
    echo "  -n    net-tools"
    echo "  -b    bpftool"
    echo "  -z    Zsh"
    echo "  -g    Go"
    echo "  -a    All tools"
    echo ""
    
    read -p "Enter flags (e.g., -d -c -k): " custom_flags
    
    if [[ -n "$custom_flags" ]]; then
        run_system_installer "$custom_flags"
    else
        print_error "No flags provided"
        press_enter_to_continue
    fi
}

# Custom Python package selection
custom_python_packages() {
    clear
    print_header "Custom Python Package Installation"
    echo ""
    echo "Enter packages separated by commas:"
    echo "Examples:"
    echo "  tensorflow,torch,opencv-python"
    echo "  requests,beautifulsoup4,selenium"
    echo "  fastapi,uvicorn,pydantic"
    echo ""
    
    read -p "Packages: " packages
    
    if [[ -n "$packages" ]]; then
        run_python_installer "--custom '$packages'"
    else
        print_error "No packages provided"
        press_enter_to_continue
    fi
}

# Install machine learning stack
install_ml_stack() {
    clear
    print_header "Machine Learning Stack Installation"
    echo ""
    echo "Installing comprehensive ML environment..."
    echo "This includes: TensorFlow, PyTorch, Scikit-learn, Jupyter, and more"
    echo ""
    
    read -p "Continue? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local ml_packages="tensorflow,torch,torchvision,scikit-learn,xgboost,lightgbm,opencv-python,jupyterlab,notebook,matplotlib,seaborn,plotly"
        run_python_installer "--custom '$ml_packages' --venv ml-env"
    fi
}

# Show installation status
show_installation_status() {
    clear
    print_header "Installation Status"
    echo ""
    
    check_tool_status "Docker" "docker --version"
    check_tool_status "Docker Compose" "docker compose version"
    check_tool_status "Kubernetes (kubectl)" "kubectl version --client"
    check_tool_status "Minikube" "minikube version"
    check_tool_status "Python3" "python3 --version"
    check_tool_status "pip" "pip --version"
    check_tool_status "Go" "go version"
    check_tool_status "Git" "git --version"
    check_tool_status "Make" "make --version | head -1"
    check_tool_status "CMake" "cmake --version | head -1"
    check_tool_status "bpftool" "bpftool version"
    check_tool_status "bpftrace" "bpftrace --version"
    
    echo ""
    press_enter_to_continue
}

# Check individual tool status
check_tool_status() {
    local tool_name="$1"
    local check_command="$2"
    
    printf "%-20s: " "$tool_name"
    
    if eval "$check_command" &>/dev/null; then
        local version=$(eval "$check_command" 2>/dev/null | head -1)
        print_success "✓ Installed ($version)"
    else
        print_error "✗ Not installed"
    fi
}

# Main execution loop
main() {
    # Initialize
    init_logging
    check_dependencies
    
    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        INTERACTIVE_MODE=false
        handle_cli_args "$@"
        exit 0
    fi
    
    # Interactive mode
    while true; do
        show_main_menu
        echo ""
        read -p "Select option [0-8]: " choice
        handle_menu_selection "$choice"
        
        if [[ $choice != "0" ]]; then
            echo ""
            press_enter_to_continue
        fi
    done
}

# Handle CLI arguments for non-interactive mode
handle_cli_args() {
    case "$1" in
        --system-tools)
            shift
            run_system_installer "$*"
            ;;
        --python)
            shift
            run_python_installer "$*"
            ;;
        --ebpf)
            shift
            run_ebpf_installer "$*"
            ;;
        --status)
            show_installation_status
            ;;
        --help|-h)
            show_cli_help
            ;;
        --version|-v)
            echo "Omni-Installer v$VERSION"
            ;;
        *)
            print_error "Unknown option: $1"
            show_cli_help
            exit 1
            ;;
    esac
}

# Show CLI help
show_cli_help() {
    echo "Omni-Installer v$VERSION - Unified Installation Tool"
    echo ""
    echo "Usage: $0 [CATEGORY] [OPTIONS]"
    echo ""
    echo "Categories:"
    echo "  --system-tools [FLAGS]    Run system tools installer"
    echo "  --python [FLAGS]          Run Python installer"
    echo "  --ebpf [FLAGS]            Run eBPF installer"
    echo ""
    echo "Utilities:"
    echo "  --status                  Show installation status"
    echo "  --help, -h               Show this help message"
    echo "  --version, -v            Show version information"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 --system-tools -d -c              # Install Docker and Docker Compose"
    echo "  $0 --python --system --data-science  # Install Python with data science packages"
    echo "  $0 --ebpf --all                      # Install complete eBPF environment"
    echo "  $0 --status                          # Check installation status"
}

# Run main function
main "$@"
