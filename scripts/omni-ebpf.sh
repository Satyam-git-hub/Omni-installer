#!/bin/bash

# eBPF Development Environment Installer
# Comprehensive setup for eBPF development and debugging

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/lib/common.sh"

# eBPF installer functions
install_kernel_headers() {
    print_info "Installing kernel headers and build dependencies..."
    
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt update
            sudo apt install -y linux-headers-$(uname -r) linux-tools-$(uname -r) linux-tools-common
            sudo apt install -y build-essential clang llvm libelf-dev libcap-dev libssl-dev
            ;;
        centos|fedora)
            local pkg_manager="yum"
            [[ "$os_type" == "fedora" ]] && pkg_manager="dnf"
            
            sudo $pkg_manager install -y kernel-headers kernel-devel
            sudo $pkg_manager groupinstall -y "Development Tools"
            sudo $pkg_manager install -y clang llvm elfutils-libelf-devel libcap-devel openssl-devel
            ;;
        *)
            handle_error "Unsupported OS for automatic kernel headers installation"
            ;;
    esac
    
    print_success "Kernel headers and build dependencies installed"
}

install_libbpf() {
    print_info "Installing libbpf development library..."
    
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt install -y libbpf-dev
            ;;
        centos|fedora)
            # Build from source for CentOS/RHEL
            install_libbpf_from_source
            ;;
        *)
            install_libbpf_from_source
            ;;
    esac
    
    print_success "libbpf installed"
}

install_libbpf_from_source() {
    print_info "Building libbpf from source..."
    
    cd /tmp
    git clone https://github.com/libbpf/libbpf.git || handle_error "Failed to clone libbpf"
    cd libbpf/src
    
    make || handle_error "Failed to build libbpf"
    sudo make install || handle_error "Failed to install libbpf"
    
    # Update library cache
    sudo ldconfig
    
    cd /
    rm -rf /tmp/libbpf
    
    print_success "libbpf built and installed from source"
}

install_bpftool() {
    print_info "Installing bpftool..."
    
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            # Try to install from package first
            local kernel_version=$(uname -r)
            sudo apt install -y linux-tools-$kernel_version || {
                print_warning "Package installation failed, building from source"
                install_bpftool_from_source
            }
            ;;
        *)
            install_bpftool_from_source
            ;;
    esac
    
    print_success "bpftool installed"
}

install_bpftool_from_source() {
    print_info "Building bpftool from source..."
    
    cd /tmp
    git clone --recurse-submodules https://github.com/libbpf/bpftool.git || handle_error "Failed to clone bpftool"
    cd bpftool/src
    
    make || handle_error "Failed to build bpftool"
    sudo make install || handle_error "Failed to install bpftool"
    
    cd /
    rm -rf /tmp/bpftool
    
    print_success "bpftool built and installed from source"
}

install_bcc() {
    print_info "Installing BCC (BPF Compiler Collection)..."
    
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt install -y bpfcc-tools linux-headers-$(uname -r)
            # Install Python bindings
            sudo apt install -y python3-bpfcc
            ;;
        centos|fedora)
            local pkg_manager="yum"
            [[ "$os_type" == "fedora" ]] && pkg_manager="dnf"
            
            sudo $pkg_manager install -y bcc-tools python3-bcc
            ;;
        *)
            install_bcc_from_source
            ;;
    esac
    
    print_success "BCC installed"
}

install_bcc_from_source() {
    print_info "Building BCC from source..."
    
    # Install dependencies
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt install -y cmake python3-dev python3-pip
            ;;
        centos|fedora)
            local pkg_manager="yum"
            [[ "$os_type" == "fedora" ]] && pkg_manager="dnf"
            sudo $pkg_manager install -y cmake python3-devel python3-pip
            ;;
    esac
    
    cd /tmp
    git clone https://github.com/iovisor/bcc.git || handle_error "Failed to clone BCC"
    cd bcc
    
    mkdir build && cd build
    cmake .. || handle_error "Failed to configure BCC build"
    make || handle_error "Failed to build BCC"
    sudo make install || handle_error "Failed to install BCC"
    
    cd /
    rm -rf /tmp/bcc
    
    print_success "BCC built and installed from source"
}

install_bpftrace() {
    print_info "Installing bpftrace..."
    
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt install -y bpftrace
            ;;
        centos|fedora)
            local pkg_manager="yum"
            [[ "$os_type" == "fedora" ]] && pkg_manager="dnf"
            sudo $pkg_manager install -y bpftrace
            ;;
        *)
            install_bpftrace_from_source
            ;;
    esac
    
    print_success "bpftrace installed"
}

install_bpftrace_from_source() {
    print_info "Building bpftrace from source..."
    
    # Install dependencies
    local os_type=$(detect_os_type)
    case "$os_type" in
        ubuntu)
            sudo apt install -y cmake libelf-dev zlib1g-dev libfl-dev systemtap-sdt-dev binutils-dev
            sudo apt install -y llvm-dev libclang-dev clang libpcap-dev
            ;;
        centos|fedora)
            local pkg_manager="yum"
            [[ "$os_type" == "fedora" ]] && pkg_manager="dnf"
            sudo $pkg_manager install -y cmake elfutils-libelf-devel zlib-devel flex systemtap-sdt-devel binutils-devel
            sudo $pkg_manager install -y llvm-devel clang-devel libpcap-devel
            ;;
    esac
    
    cd /tmp
    git clone https://github.com/iovisor/bpftrace || handle_error "Failed to clone bpftrace"
    cd bpftrace
    
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release .. || handle_error "Failed to configure bpftrace build"
    make || handle_error "Failed to build bpftrace"
    sudo make install || handle_error "Failed to install bpftrace"
    
    cd /
    rm -rf /tmp/bpftrace
    
    print_success "bpftrace built and installed from source"
}

install_ebpf_examples() {
    print_info "Installing eBPF examples and tutorials..."
    
    local examples_dir="$HOME/ebpf-examples"
    mkdir -p "$examples_dir"
    
    # Clone various eBPF example repositories
    cd "$examples_dir"
    
    # Linux kernel samples
    git clone https://github.com/torvalds/linux.git --depth 1 || print_warning "Failed to clone kernel repo"
    if [[ -d linux ]]; then
        mv linux/samples/bpf ./kernel-samples
        rm -rf linux
    fi
    
    # libbpf-bootstrap
    git clone https://github.com/libbpf/libbpf-bootstrap.git || print_warning "Failed to clone libbpf-bootstrap"
    
    # BCC examples
    git clone https://github.com/iovisor/bcc.git --depth 1 || print_warning "Failed to clone BCC examples"
    if [[ -d bcc ]]; then
        mv bcc/examples ./bcc-examples
        mv bcc/tools ./bcc-tools
        rm -rf bcc
    fi
    
    # Create simple hello world example
    create_hello_world_example "$examples_dir"
    
    print_success "eBPF examples installed in $examples_dir"
}

create_hello_world_example() {
    local examples_dir="$1"
    local hello_dir="$examples_dir/hello-world"
    
    mkdir -p "$hello_dir"
    
    # Create hello.bpf.c
    cat > "$hello_dir/hello.bpf.c" << 'EOF'
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

SEC("tp/syscalls/sys_enter_openat")
int handle_tp(void *ctx)
{
    int pid = bpf_get_current_pid_tgid() >> 32;
    bpf_printk("BPF triggered from PID %d.\n", pid);
    return 0;
}
EOF

    # Create hello.c
    cat > "$hello_dir/hello.c" << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <sys/resource.h>
#include <bpf/libbpf.h>
#include "hello.skel.h"

static int libbpf_print_fn(enum libbpf_print_level level, const char *format, va_list args)
{
    return vfprintf(stderr, format, args);
}

static volatile sig_atomic_t stop;

static void int_exit(int sig)
{
    stop = 1;
}

int main(int argc, char **argv)
{
    struct hello_bpf *skel;
    int err;

    libbpf_set_print(libbpf_print_fn);

    /* Open load and verify BPF application */
    skel = hello_bpf__open_and_load();
    if (!skel) {
        fprintf(stderr, "Failed to open BPF skeleton\n");
        return 1;
    }

    /* Attach tracepoint handler */
    err = hello_bpf__attach(skel);
    if (err) {
        fprintf(stderr, "Failed to attach BPF skeleton\n");
        goto cleanup;
    }

    if (signal(SIGINT, int_exit) == SIG_ERR) {
        fprintf(stderr, "can't set signal handler: %s\n", strerror(errno));
        goto cleanup;
    }

    printf("Successfully started! Please run `sudo cat /sys/kernel/debug/tracing/trace_pipe` "
           "to see output of the BPF programs.\n");

    while (!stop) {
        fprintf(stderr, ".");
        sleep(1);
    }

cleanup:
    hello_bpf__destroy(skel);
    return -err;
}
EOF

    # Create Makefile
    cat > "$hello_dir/Makefile" << 'EOF'
OUTPUT := .output
CLANG ?= clang
LLVM_STRIP ?= llvm-strip
BPFTOOL ?= bpftool
LIBBPF_SRC := $(abspath ../libbpf/src)
LIBBPF_OBJ := $(abspath $(OUTPUT)/libbpf.a)
INCLUDES := -I$(OUTPUT)
CFLAGS := -g -Wall
ARCH := $(shell uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm64/' | sed 's/ppc64le/powerpc/' | sed 's/mips.*/mips/')

APPS = hello

.PHONY: all
all: $(APPS)

ifeq ($(wildcard $(LIBBPF_OBJ)),)
$(error Please run 'git submodule update --init --recursive' to initialize libbpf)
endif

$(OUTPUT):
	mkdir -p $(OUTPUT)

# Build BPF code
$(OUTPUT)/%.bpf.o: %.bpf.c $(LIBBPF_OBJ) | $(OUTPUT)
	$(CLANG) -g -O2 -target bpf -D__TARGET_ARCH_$(ARCH) $(INCLUDES) -c $(filter %.c,$^) -o $@
	$(LLVM_STRIP) -g $@

# Generate BPF skeletons
$(OUTPUT)/%.skel.h: $(OUTPUT)/%.bpf.o | $(OUTPUT)
	$(BPFTOOL) gen skeleton $< > $@

# Build user-space code
$(APPS): %: %.c $(OUTPUT)/%.skel.h $(LIBBPF_OBJ) | $(OUTPUT)
	$(CC) $(CFLAGS) $(INCLUDES) $< -L$(LIBBPF_SRC) -l:libbpf.a -lelf -lz -o $(OUTPUT)/$@

# delete failed targets
.DELETE_ON_ERROR:

# keep intermediate (.skel.h, .bpf.o, etc) targets
.SECONDARY:

clean:
	rm -rf $(OUTPUT)
EOF

    # Create build script
    cat > "$hello_dir/build.sh" << 'EOF'
#!/bin/bash
set -e

echo "Building eBPF Hello World example..."

# Create output directory
mkdir -p .output

# Build BPF object
clang -g -O2 -target bpf -D__TARGET_ARCH_x86 -c hello.bpf.c -o .output/hello.bpf.o
llvm-strip -g .output/hello.bpf.o

# Generate skeleton
bpftool gen skeleton .output/hello.bpf.o > .output/hello.skel.h

# Build user-space program
gcc -g -Wall -I.output hello.c -lbpf -lelf -lz -o .output/hello

echo "Build complete! Run with: sudo ./.output/hello"
EOF

    chmod +x "$hello_dir/build.sh"
    
    # Create README
    cat > "$hello_dir/README.md" << 'EOF'
# eBPF Hello World Example

This is a simple eBPF program that demonstrates basic tracepoint usage.

## Building

