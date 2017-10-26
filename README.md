# hdd_nvme_dmcache
Performance comparative across: HDD; NVME; dm-cache (writethrough and writeback)

Creates four local XFS filesystems on different device types and uses FIO to
run performance tests across them.
* HDD
* NVME
* dm-cache : cachemode=writethrough (default)
* dm-cache : cachemode=writeback

Includes utility scripts to configure the local storage devices:
* setup.sh
* teardown.sh

After running 'setup.sh', the mounted filesystems are named:
* /mnt/xfshdd
* /mnt/xfsnvme
* /mnt/xfswritethrough
* /mnt/xfswriteback

'teardown.sh' unmounts the filesystems and removes the LVM configurations.

Edit 'vars.sh' to match your systems disk configuration. Key variables:
* WTslowDEV_arr  <-- HDD to use as dm-cache writethrough origin device
* WBslowDEV_arr  <-- HDD to use as dm-cache writeback origin device
* WTfastDEV_arr  <-- NVMe partition to use as dm-cache writethrough fast device
* WBfastDEV_arr  <-- NVMe partition to use as dm-cache writeback fast device
* hdd_DEV_arr    <-- device to use for HDD device tests
* nvmeDEV_arr    <-- NVMe partition to use for NVME device tests

# Workflow
1) ./setup.sh
2) ./run95G.sh
3) ./teardown.sh

The 'run95G.sh' script requires that a device-mode be specified, one of: xfshdd; xfsnvme; xfswritethrough or xfswriteback. The script executes FIO runs which leave their output files (timestamped) in the 'RESULTS' directory.
