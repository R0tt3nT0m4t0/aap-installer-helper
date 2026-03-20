terraform {
  required_providers {
    libvirt = {
        source = "dmacvicar/libvirt"
        version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Storage for OS Disk

resource "libvirt_volume" "aap_virt_disk" {
  name = "aap_virt_disk.qcow2"
  pool = "default"
  size = 322122547200 # 300GB in bytes
  format = "qcow2"
}

# Machine definition

resource "libvirt_domain" "aap_virt_vm" {
  name = "aap_virt_vm"
  memory = 24576   # 24G
  vcpu = 12
  firmware = "/usr/share/edk2/ovmf/OVMF_CODE.fd"

  cpu {
    mode = "host-passthrough"
  }

  # Installation media (CDROM)
  disk {
    file = "/var/lib/libvirt/images/rhel-10.0-x86_64-dvd.iso"
  }

  # Main storage (HDD)
  disk {
    volume_id = libvirt_volume.aap_virt_disk.id
  }

  boot_device {
    dev = ["cdrom","hd"]
  }

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

#  network_interface {
#    bridge = "br0"
#  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type = "spice"
    autoport = true
    listen_type = "address"
  }
}

output "vm_ip_address" {
  value = length(libvirt_domain.aap_virt_vm.network_interface[0].addresses) > 0 ? libvirt_domain.aap_virt_vm.network_interface[0].addresses[0] : "Waiting for IP..."
}
