packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "version" {
  type    = string
  default = ""
}

source "vmware-iso" "debian13" {
  boot_command = [
    "<wait>",
    "<esc>",
    "<wait>",
    "auto preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg netcfg/get_hostname={{ .Name }}",
    "<enter>"
  ]

  boot_wait             = "10s"

  disk_type_id          = "0"
  disk_size             = 10240
  cpus                  = 4
  memory                = 4096
  guest_os_type         = "debian12_64Guest"

  headless              = true

  http_directory        = "http"

  iso_urls              = ["https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.2.0-amd64-netinst.iso"]
  iso_checksum          = "sha256:677c4d57aa034dc192b5191870141057574c1b05df2b9569c0ee08aa4e32125d"

  ssh_username          = "debian13"
  ssh_password          = "ilovecoconutwater"
  ssh_port              = 22
  ssh_wait_timeout      = "10000s"

  shutdown_command      = "echo 'ilovecoconutwater' | sudo -S shutdown -P now"

  vmdk_name             = "debian13"
  vm_name               = "debian13"

  output_directory      = "dist"
}

build {
  sources = ["source.vmware-iso.debian13"]

  provisioner "shell" {
    script = "install.sh"
  }
}
