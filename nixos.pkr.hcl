### Variables

variable "version" {
  type        = string
  default     = "22.05"
  description = "NixOS Version"
}

variable "arch" {
  type        = string
  default     = "x86_64"
  description = "Host Architecture"
}

variable "iso_checksum" {
  type        = string
  #default     = "file:https://channels.nixos.org/nixos-21.05/latest-nixos-minimal-x86_64-linux.iso.sha256"
  default     = "none"
  description = "ISO Checksum"
}

variable "linode_upload" {
  type        = bool
  default     = false
  description = "Enables image upload to Linode via preconfigured linode-cli"
}

### Locals

locals {
  name       = "nixos-${var.version}-${var.arch}-{{ isotime \"20060102\" }}"
  filename   = "${local.name}.raw"
  output_dir = "build"
}

### Builders

source "qemu" "nixos" {
  accelerator       = "kvm"

  boot_command = [
    "<wait40>",
    "export HTTP_BASE=http://{{.HTTPIP}}:{{.HTTPPort}}<enter>",
    "curl -L $HTTP_BASE/install.sh | sudo --preserve-env=HTTP_BASE bash<enter>",
  ]

  boot_wait         = "10s"
  disk_cache        = "unsafe"
  disk_interface    = "virtio-scsi"
  disk_size         = "2048M"
  format            = "raw"

  iso_checksum      = "${var.iso_checksum}"
  iso_urls = [
    "latest-nixos-minimal-${var.arch}-linux.iso",
    "https://channels.nixos.org/nixos-${var.version}/latest-nixos-minimal-${var.arch}-linux.iso"
  ]

  memory           = "1024"
  http_directory   = "src"
  output_directory = local.output_dir

  communicator     = "none"
  ssh_timeout      = "30m"
  #ssh_username     = "nixos"
  #ssh_password     = "nixos"

  vm_name          = local.filename
}

build {
  sources = [
    "source.qemu.nixos"
  ]

  # Linode requires gzip compressed raw image
  post-processor "compress" {
    output            = "${local.output_dir}/${local.filename}.gz"
    compression_level = "9"
    # keep_input_artifact = false
  }

  # OPTIONAL: Upload to Linode via linode-cli
  post-processor "shell-local" {
    command = "if [ '${var.linode_upload}' = 'true' ]; then linode-cli image-upload --label ${local.name} ${local.output_dir}/${local.filename}.gz; fi"
  }
}
