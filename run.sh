#!/bin/bash
set -eux

iso_path=$1
if ! test -f ${iso_path}; then
    echo usage ./run.sh /somewhere/VMware-VCSA-all-6.7.0-14367737.iso
    exit 1
fi

VERSION=$(basename -s .iso ${iso_path})
vl up
vl ansible_inventory>inventory

extra_args="vcenter_instance_installation_iso_path=${iso_path}"
ansible-playbook install_vcsa.yml -i inventory -e "${extra_args}" -vvv

echo 'vcenter ansible_host=192.168.123.90 ansible_user=root ansible_password="!234AaAa56" ansible_python_interpreter=/usr/bin/python ansible_ssh_common_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"' > inventory

ansible-playbook prepare_vm.yml -i inventory -vvv
ansible-playbook zuul_user.yml -i inventory
ansible-playbook add_local_ssh_pubkey.yml -i inventory

# If we don't reboot the ESXi, the download fails with an err 500, probably because the VM disks are still used
ansible-playbook shutdown_esxi.yml -i inventory

sleep 300

ssh root@192.168.123.5 sh -c 'reboot&'
sleep 300
curl -v -k --user 'root:!234AaAa56' -o vCenterServerAppliance.raw 'https://192.168.123.5/folder/vCenter-Server-Appliance/vCenter-Server-Appliance-flat.vmdk?dcPath=ha%252ddatacenter&dsName=local'

mkdir -p tmp

vl down
virt-df vCenterServerAppliance.raw
## since 7.0.1
if [ ${VERSION} = "VMware-VCSA-all-7.0.1-16860138" ]; then
    guestfish <<_EOF_
add vCenterServerAppliance.raw
run
list-filesystems
e2fsck-f /dev/sda3
resize2fs-size /dev/sda3 10G
e2fsck-f /dev/sda3
q
_EOF_
    virt-df vCenterServerAppliance.raw
    truncate -s 12G shrinked.raw
    virt-resize --no-sparse --shrink /dev/sda3 vCenterServerAppliance.raw shrinked.raw
    virt-df shrinked.raw
    virt-sparsify --tmp tmp --compress --convert qcow2 shrinked.raw ${VERSION}.qcow2

elif [ ${VERSION} = "VMware-VCSA-all-7.0.2-17694817" ]; then
    guestfish <<_EOF_
add vCenterServerAppliance.raw
run
list-filesystems
resize2fs-size /dev/vg_root_0/lv_root_0 10G
lvresize /dev/vg_root_0/lv_root_0 11000
e2fsck /dev/vg_root_0/lv_root_0 correct:true
pvresize-size /dev/sda4 11634335744


pvcreate /dev/sda2
vgcreate swap_vg /dev/sda2
lvcreate-free swap1 swap_vg 100
mkswap /dev/mapper/swap_vg-swap1
lvm-clear-filter
lvm-scan true
q
_EOF_
    virt-df vCenterServerAppliance.raw
    truncate -s 12G shrinked.raw
    virt-resize --no-sparse --shrink /dev/sda4 vCenterServerAppliance.raw shrinked.raw
    virt-df shrinked.raw
    virt-sparsify --tmp tmp --compress --convert qcow2 shrinked.raw ${VERSION}.qcow2
else :
    virt-sparsify --tmp tmp --compress --convert qcow2 vCenterServerAppliance.raw ${VERSION}.qcow2
fi

echo "You image is ready! Do use it:
    Virt-Lightning:
        sudo cp -v ${VERSION}.qcow2 /var/lib/virt-lightning/pool/upstream/
        sudo cp -v default_config.yaml /var/lib/virt-lightning/pool/upstream/${VERSION}.yaml

    OpenStack:
        source ~/openrc.sh
        openstack image create --disk-format qcow2 --container-format bare --file ${VERSION}.qcow2 --property hw_qemu_guest_agent=no --min-disk 12 --min-ram 12000 --property hw_vif_model=e1000 ${VERSION}"
