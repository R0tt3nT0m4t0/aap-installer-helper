#!/usr/bin/env bash
# Script: create-vm.sh
# Author: Juan Medina
# Purpose: Create a new VM for AAP and register it

# Configuration
IMAGE_DIR="/var/lib/libvirt/images"
export PS3="Please enter your choice (number): "

echo "------------------------------------------------"
echo "  RHEL/Fedora VM Creator for AAP 26/Dev         "
echo "------------------------------------------------"

# Select ISO
echo "Scanning for ISOs in $IMAGE_DIR..."
ISO_LIST=$(sudo find "$IMAGE_DIR" -maxdepth 1 -type f -name "*.iso")

if [ -z "$ISO_LIST" ]; then
    echo "Error: No .iso files found in $IMAGE_DIR"
    echo "Make sure your ISO is in $IMAGE_DIR and ends in .iso"
    exit 1
fi

# Convert string list to array
mapfile -t ISOS <<< "$ISO_LIST"
echo "Select an ISO to boot from:"
select ISO_PATH in "${ISOS[@]}"; do
    if [ -n "$ISO_PATH" ]; then
        echo "Selected: $(basename $ISO_PATH)"
        break
    else
        echo "Invalid selection."
    fi
done

# Kickstart Selection
read -p "Would you like to use a Kickstart file? (y/n): " USE_KS
S_ARG=""
if [[ "$USE_KS" == "y" ]]; then
    echo "Scanning current directory for .ks files..."
    KS_LIST=$(ls *.ks 2>/dev/null)
    
    if [ -z "$KS_LIST" ]; then
        echo "No .ks files found in $(pwd). Proceeding without Kickstart."
    else
        mapfile -t KSS <<< "$KS_LIST"
        echo "Select a Kickstart file:"
        select KS_FILE in "${KSS[@]}"; do
            if [ -n "$KS_FILE" ]; then
                # We use absolute path for the initrd injection
                KS_PATH="$(pwd)/$KS_FILE"
                echo "Selected Kickstart: $KS_FILE"
                # This flag injects the KS into the boot process
                KS_ARG="--initrd-inject=$KS_PATH --extra-args=inst.ks=file:/$KS_FILE"
                break
            else
                echo "Invalid selection."
            fi
        done
    fi
fi

# Name the VM
read -p "Enter VM Name (default: aap26): " VM_NAME
VM_NAME=${VM_NAME:-aap26}

if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    echo "Error: A VM named '$VM_NAME' already exists."
    read -p "Would you like to DELETE it and start over? (y/n): " DELETE_EXISTING
    if [[ "$DELETE_EXISTING" == "y" ]]; then
        sudo virsh destroy "$VM_NAME" 2>/dev/null
        sudo virsh undefine "$VM_NAME" --nvram
    else
        exit 1
    fi
fi

# Choose CPU
echo "Select CPU Cores:"
select CPU in "4" "8" "12" "16" "20" "24" "32"; do
    if [ -n "$CPU" ]; then break; fi
done

# Choose Memory
echo "Select Memory (GiB):"
select MEM in "8" "16" "24" "32"; do
    if [ -n "$MEM" ]; then 
        MEM_MB=$((MEM * 1024))
        break 
    fi
done

# Choose Disk Size
echo "Select OS Disk Size (GiB):"
select DISK_SIZE in "40" "100" "200" "300"; do
    if [ -n "$DISK_SIZE" ]; then break; fi
done

DISK_PATH="$IMAGE_DIR/${VM_NAME}_disk.qcow2"

# 6. Summary and Execution
echo "------------------------------------------------"
echo "NAME:   $VM_NAME"
echo "ISO:    $(basename $ISO_PATH)"
echo "KICKSTART: ${KS_FILE:-None}"
echo "CPU:    $CPU cores"
echo "MEM:    $MEM GiB"
echo "DISK:   $DISK_PATH ($DISK_SIZE GiB)"
echo "------------------------------------------------"
read -p "Proceed with creation? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" ]]; then
    # Create the QCOW2 disk in the default pool location
    echo "Creating disk..."
    sudo qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE}G"
    sudo chown qemu:qemu "$DISK_PATH"
    sudo restorecon -v "$DISK_PATH"

		COMMON_ARGS=(
				--name "$VM_NAME"
				--memory "$((MEM * 1024))"
				--vcpus "$CPU"
				--cpu host-passthrough
				--os-variant rhel10.0
				--disk path="$DISK_PATH",bus=virtio,format=qcow2
				--network network=default,model=virtio
				--graphics spice,listen=127.0.0.1
				--video virtio
				--console pty,target.type=serial
				--noautoconsole
		)

		if [[ "$USE_KS" == "y" ]]; then
        echo "Starting Automated Kickstart Installation..."
				virt-install "${COMMON_ARGS[@]}" \
        --location "$ISO_PATH" \
        --initrd-inject="$KS_PATH" \
        --extra-args="inst.ks=file:/$(basename "$KS_PATH") console=ttyS0"
    else
        echo "Starting Manual ISO Installation..."
				virt-install "${COMMON_ARGS[@]}" \
        --boot loader=/usr/share/edk2/ovmf/OVMF_CODE.fd,loader.readonly=yes,loader.type=pflash \
        --disk path="$ISO_PATH",device=cdrom
		fi

    echo "VM $VM_NAME defined. Opening console..."
    virt-viewer --connect qemu:///system --wait "$VM_NAME" &

else
    echo "Aborted."
fi

