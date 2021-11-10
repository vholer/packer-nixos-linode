#!/bin/bash

# NixOS Linode image installation. Follows recommended steps from
# https://gist.github.com/nocoolnametom/a359624afce4278f16e2760fe65468cc

set -xe -o pipefail

HTTP_BASE=${HTTP_BASE:-$1}

if [ -z "${HTTP_BASE}" ]; then
    echo "ERROR: Missing HTTP_BASE argument" >&2
    exit 1
fi

### Prepare ###

# Create and mount root volume
mkfs.ext4 -L nixos /dev/sda
mount /dev/sda /mnt

# Generate initial configuration
nixos-generate-config --root /mnt

### Fix configuration ###

NIX_HWC=/mnt/etc/nixos/hardware-configuration.nix
NIX_CFG=/mnt/etc/nixos/configuration.nix
NIX_LIN=/mnt/etc/nixos/linode.nix

# Filesystem reference to use labels
UUID=$(blkid --list-one --match-token LABEL=nixos -s UUID -o value)
sed -i -e "s,by-uuid/${UUID},by-label/nixos," "${NIX_HWC}"

# Delete entries
sed -i -e '/^\s*boot\.loader/d' "${NIX_CFG}"
sed -i -e '/^\s*boot\.kernelParams/d' "${NIX_CFG}"
sed -i -e '/^\s*networking\.interfaces\./d' "${NIX_CFG}"
sed -i -e '/^}$/d' "${NIX_CFG}"

# Use Linode profile
curl "${HTTP_BASE}/linode.nix" -o "${NIX_LIN}"
sed -i -e 's,^\(\s*\)\(\./hardware-configuration.nix\)$,\1\2\n\1\./linode.nix,' "${NIX_CFG}"
#sed -i -e 's,^\(\s*\)\(\./hardware-configuration.nix\)$,\1\2\n\1<nixpkgs/nixos/modules/profiles/minimal.nix>,' "${NIX_CFG}"

# Enable OpenSSH
cat - >>"${NIX_CFG}" <<EOF
  # Added by packer-nixos-linode
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
EOF

# Append back trailing }
echo '}' >> "${NIX_CFG}"

# Install system and poweroff machine
nixos-install --no-root-passwd

poweroff
