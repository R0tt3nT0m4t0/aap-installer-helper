terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. The Base Cloud Image, this block can be changed to any other linux cloud image, as long as it is in the same specified directory
# Decided to go with almalinux instead of RHEL (original code) due to login requirement to download RHEL images, this can be changed to RHEL with minimum changes to code
resource "libvirt_volume" "rhel_base" {
  name   = "almalinux-9-base.qcow2"
  pool   = "default"
  source = "/var/lib/libvirt/images/almalinux-9-cloud-base.qcow2" 
  format = "qcow2"
}

# 2. The VM Specific Disk
# Clones the base image and expands it to the requested 40 GiB. (can adjust later with another terraform apply)
resource "libvirt_volume" "os_disk" {
  name           = "aap26_disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.rhel_base.id
  size           = 42949672960 # 40 GiB in bytes
}

# 3. The Cloud-Init Data Source
# This reads your YAML file and creates the initialization ISO.
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit-aap26.iso"
  pool      = "default"
  user_data = file("${path.module}/cloud_init.cfg")
}

# 4. The Virtual Machine Definition
# NOTE: Both the memory and the vpcu can be changed with a terraform apply
resource "libvirt_domain" "aap_vm" {
  name   = "aap26"
  memory = 8192
  vcpu   = 4 

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true # Tells Terraform to wait until the VM gets an IP
  }

  # Attach the OS disk
  disk {
    volume_id = libvirt_volume.os_disk.id
  }

  # Attach the Cloud-Init configuration
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # Console setup for debugging and serial access
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    # Changed spice to vnc due to cockpit struguling with spice
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

# 5. Output the IP Address
# This makes it easy to grab the IP for Ansible immediately after deployment.
output "vm_ip" {
  value       = libvirt_domain.aap_vm.network_interface[0].addresses[0]
  description = "The IP address of the newly provisioned AAP node."
}