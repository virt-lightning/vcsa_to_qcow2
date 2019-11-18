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

## OpenStack

You can upload the image with the following command:

```shell
openstack image create --disk-format qcow2 --container-format bare --file VMware-VCSA-all-6.7.0-14836122.qcow2 --property hw_qemu_guest_agent=no --min-disk 20 --min-ram 9000 --property hw_vif_model=e1000 VMware-VCSA-all-6.7.0-14836122
```

## Notes

- the administrator password is `!234AaAa56`
