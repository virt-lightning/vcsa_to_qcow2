#!/bin/bash

vl up
vl ansible_inventory>inventory
ansible-playbook install_vcsa.yml -i inventory

echo 'vcenter ansible_host=192.168.123.90 ansible_user=root ansible_password="!234AaAa56" ansible_python_interpreter=/usr/bin/python ansible_ssh_common_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"' > inventory

ansible-playbook prepare_vm.yml -i inventory

# If we don't reboot the ESXi, the download fails with an err 500
ansible-playbook shutdown_esxi.yml
ssh root@192.168.123.5 sh -c 'reboot&'
sleep 300
curl -v -k --user 'root:!234AaAa56' -o vCenterServerAppliance.raw 'https://192.168.123.5/folder/vCenter-Server-Appliance/vCenter-Server-Appliance-flat.vmdk?dcPath=ha%252ddatacenter&dsName=local'
qemu-img convert -f raw -O qcow2 -c vCenterServerAppliance.raw vCenterServerAppliance.qcow2
vl down
