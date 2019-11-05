#!/bin/bash

openstack image create --disk-format qcow2 --container-format bare --property hw_vif_model=e1000 --min-disk 40 --min-ram 10000 --file vCenterServerAppliance.qcow2 vCenterServerAppliance
