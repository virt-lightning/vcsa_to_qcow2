# Prepare a VCSA (a.k.a vcenter) Qcow2 image

This script will prepare a Qcow2 image from the VCSA ISO image.

You can use it with OpenStack or Libvirt (e.g: VirtLightning).

- cloud-init is enabled, default user is `root`, the SSH key is injected
- Password based SSH auth is disabled

## Requirements

- a functional Virt-Lightning installation ( https://virt-lightning.org/ )
- an ESXi image ( https://github.com/virt-lightning/esxi-cloud-images )
- an ISO image

## Usage

```
./run.sh
```

## Notes

- the administrator password is `!234AaAa56`
