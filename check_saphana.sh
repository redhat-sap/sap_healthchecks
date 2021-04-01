#!/bin/bash

echo "#### SAP Hana on RHEL 7 system validation"

echo

echo "## Verify kernel is at or above required release"
echo "#  RHEL 7.7 specific package release, or newer"
echo "#  - kernel-3.10.0-1062.21.1.el7.x86_64"
rpm -q kernel

echo

echo "## Check SAP HANA tuned profile is in use"
echo "#  This should report 'Current active profile: sap-hana'"
tuned-adm active

echo

echo "## Verify tuned is enabled"
systemctl status tuned

echo

cat << EOF
## The following configurations are set when using tuned sap-hana
#  Configure C-States for lower latency in Linux
#  CPU Frequency/Voltage scaling
#  Disable transparent_hugepages
EOF

echo

echo "## tuned applied: Verify transparent_hugepages is disabled"
echo "#  This should report 'always madvise [never]'"
cat /sys/kernel/mm/transparent_hugepage/enabled

echo

cat << EOF
## tuned applied: Set hardware to “Maximum Performance”
#                 Energy Performance Bias
#  This can be tested with “cpupower info” command
#  If the command reports 'perf-bias: 0' EPB has been set to the correct value
#  This requires “kernel-tools” RPM to be installed
EOF
cpupower frequency-info

echo

cpupower info

echo

cat << EOF
## Default grub cmdline may include:
#    transparent_hugepage=never
#    processor.max_cstate=1
#    intel_idle.max_cstate=1
Example:
GRUB_CMDLINE_LINUX=".. transparent_hugepage=never processor.max_cstate=1 intel_idle.max_cstate=1"
EOF
grep GRUB_CMDLINE_LINUX /etc/default/grub

echo

echo "## Verify kernel shared memory (KSM) is disabled"
echo "#  This should report '0' if KSM is disabled"
cat /sys/kernel/mm/ksm/run

echo

echo "## Verify SELINUX is disabled on SAP HANA systems"
echo "#  This should report 'Disabled'"
getenforce

echo

echo "## Verify systemd is updated past systemd-219-19.el7"
echo "#  Example: systemd-219-67.el7.x86_64"
rpm -q systemd

echo

echo "## Verify compat-sap-c++-5 RPM is installed"
echo "#  This should report the following RPM (version may vary)"
echo "#  Example: compat-sap-c++-5-5.3.1-10.el7_3.x86_64"
rpm -q compat-sap-c++-5

echo

# optional - Validate SAP HANA installation
cat << EOF
## Optional, check SAP HANA installation"

The folder <sapmnt> defaults to /hana/shared

Sample:
<sapmnt>/<SID>/hdblcm/hdblcm --action=check_installation

Checks are based on:
<sapmnt>/<SID>/global/hdb/install/support/hdbcheck.xml

Output log file:
/var/tmp/hdb_<SID>_hdblcm_check_installation_<time stamp>/hdblcm.log
EOF

echo "#### Pacemaker validation"

echo

echo "## Create backup:"
pcs config backup /dev/shm/$(hostname)-pcs-backup`

echo

echo "## Verify files in backup:"
tar tvf /dev/shm/$(hostname)-pcs-backup.tar.bz2

echo

cat << EOF
## Verify pacemaker status:
#  All resources should be started
#  All daemons should be active/enabled
EOF
pcs status --full

echo

echo "## Verify pcs constraints:"
pcs constraint list --full

echo

echo "## Verify pcs resources:"
pcs resource show

echo "## Verify stonith_admin has fence_agent_arm installed (database servers):"
echo "#    fence_azure_arm"
stonith_admin --list-installed | grep azure

echo

echo "#  If not installed, install fence-agents-azure-arm and nmap-ncat:"
echo "yum install -y fence-agents-azure-arm nmap-ncat

echo
