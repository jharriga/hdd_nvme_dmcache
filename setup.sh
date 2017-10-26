#----------------------------------------------------------------
# setup.sh - create/setup lvm device configuration
# Calls Utils/partitionDEVICES.shinc and Utils/setupCACHES.shinc
#
# Configures the devices, creates the XFS filesystems and mounts the
# filesystems at the mount points, for each of the two device modes,
# listed below.
#
# DEVICE CONFIGURATION:
#   Prepares the devices used for 'mixed I/O' tests.
#   The tests run in one of these three 'device-modes': 
#   XFSHDD:
#     Block devices: /dev/sdk1 (100GB partitions)
#     Mount points:  /mnt/hdd0 (XFS filesystems)
#   XFSNVME:
#     Block devices: /dev/nvme0n1p1 (100GB partitions)
#     Mount points:  /mnt/nvme0 (XFS filesystems)
#   XFSWRITETHROUGH:
#     slowDEV (100GB): /dev/sde
#     fastDEV (10GB): /dev/nvme0n1p2
#     Block device: /dev/mapper/vg_cache0-lv_writethrough0
#     Mount points: /mnt/writethrough1 (XFS filesystems)
#   XFSWRITEBACK:
#     slowDEV (100GB): /dev/sdh
#     fastDEV (10GB): /dev/nvme0n1p3
#     Block device: /dev/mapper/vg_cache0-lv_writeback0
#     Mount points: /mnt/writeback1 (XFS filesystems)
#
#----------------------------------------

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# MANDATORY: set the deviceMODE and runMODE vars
runMODE="setup"
deviceMODE="setup"

# Variables
source "$myPath/vars.shinc"

# Functions
source "$myPath/Utils/functions.shinc"

# Assign LOGFILE
LOGFILE="./LOGFILEsetup"

#--------------------------------------

# check mountpts 
devarr=( "${hddDEV_arr[@]}" "${slowDEV_arr[@]}" "${fastDEV_arr[@]}" )

for dev in "${devarr[@]}"; do
  echo "Checking if ${dev} is in use, if yes abort"
  mount | grep ${dev}
  if [ $? == 0 ]; then
    echo "Device ${dev} is mounted - ABORTING!" 
    echo "User must manually unmount ${dev}"
    exit 1
  fi
done

# Create new log file
if [ -e $LOGFILE ]; then
  rm -f $LOGFILE
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "$PROGNAME - Created logfile: $LOGFILE"

# PARTITION devices
updatelog "Starting: PARTITION Devices"
source "$myPath/Utils/partitionDEVICES.shinc"
updatelog "Completed: PARTITION Devices"

# SETUP CACHE configuration
updatelog "Starting: DEVICES Setup"
source "$myPath/Utils/setupDEVICES.shinc"
updatelog "Completed: DEVICES Setup"

# Display mount points
echo "HDD mount points"
df -T | grep "${hddMNT}"
echo "NVME mount points"
df -T | grep "${nvmeMNT}"
echo "LVMcached WRITETHROUGH mount points"
df -T | grep "${writethroughMNT}"
echo "LVMcached WRITEBACK mount points"
df -T | grep "${writeback}"

updatelog "$PROGNAME - END"
echo "END ${PROGNAME}**********************"
exit 0
