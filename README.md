# hdd_nvme_dmcache
Performance comparative across: HDD; NVME; dm-cache (writethrough and writeback)

Creates four local XFS filesystems on different device types and uses FIO to
run performance tests across them.
* HDD
* NVME
* dm-cache : cachemode=writethrough (default)
* dm-cache : cachemode=writeback

Includes utility scripts to setup and teardown the local storage devices.
Mounted filesystems are named:
* /mnt/xfshdd
* /mnt/xfsnvme
* /mnt/xfswritethrough
* /mnt/xfswriteback

Edit 'vars.sh' to match your systems disk configuration:
* WTslowDEV_arr  <-- HDD to use as dm-cache writethrough origin device
* WBslowDEV_arr  <-- HDD to use as dm-cache writeback origin device
* WTfastDEV_arr  <-- NVMe partition to use as dm-cache writethrough fast device
* WBfastDEV_arr  <-- NVMe partition to use as dm-cache writeback fast device
* hdd_DEV_arr    <-- device to use for HDD device tests
* nvmeDEV_arr    <-- NVMe partition to use for NVME device tests

Workflow
1) # ./setup.sh
2) # ./run95G.sh
3) # ./teardown.sh

Leaves FIO output files (timestamped) in 'RESULTS' directory.
