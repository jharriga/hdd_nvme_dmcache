#---------------------------------------
# START GLOBAL VARIABLES
#
# List of dependencies - verfied by 'chk_dependencies' function
DEPENDENCIES_arr=(
  "fio"                  # I/O workload generator
  "parted" "fdisk"       # partition tools
  "pvs" "lvs" "pvcreate" "vgcreate" "lvcreate"  # LVM utils
  "dmsetup" "bc"         # function cacheStats
)

# DEVICE-MODE for testing: xfsnvme OR xfscached
# MUST BE DEFINED PRIOR TO INCLUDING THIS FILE!
if [ ! "$deviceMODE" ]; then
    echo "Fatal error: deviceMODE must be set before vars.shinc file"
    exit 1
fi

########################################################### 
# DEVICE vars
#
# Number of LVMcached devices to create/teardown
numdevs=1

# SLOW device vars
#   WRITETHROUGH
WTslowDEV_arr=( "/dev/sde" )
WTslowVG="vg_WTslow"
WTslowLV_arr="lv_WTslow"
#   WRITEBACK
WBslowDEV_arr=( "/dev/sdh" )
WBslowVG="vg_WBslow"
WBslowLV_arr="lv_WBslow"

# FAST device vars
#   WRITETHROUGH
WTfastDEV="nvme0n1"
WTfastTARGET="/dev/${WTfastDEV}"
WTfastDEV_arr=( "${WTfastTARGET}p2" )
WTfastVG="vg_WTfast"
WTfastLV="lv_WTfast"
#   WRITEBACK
WBfastDEV="nvme0n1"
WBfastTARGET="/dev/${WBfastDEV}"
WBfastDEV_arr=( "${WBfastTARGET}p3")
WBfastVG="vg_WBfast"
WBfastLV="lv_WBfast"

# LVMcached device vars
#   WRITETHROUGH
WTcacheVG="vg_WTcache" 
WTcachedataLV="lv_WTcache_data"
WTcachemetaLV="lv_WTcache_meta"
WTcachedLV="lv_WTcached"
WToriginLV="${WTcachedLV}"
WTcachedMNT="/mnt/writethrough"
#cachedLVPATH="/dev/${cacheVG}/${cachedLV}"
WTcachePOLICY="smq"
WTcacheMODE="writethrough"
#   WRITEBACK
WBcacheVG="vg_WBcache" 
WBcachedataLV="lv_WBcache_data"
WBcachemetaLV="lv_WBcache_meta"
WBcachedLV="lv_WBcached"
WBoriginLV="${WBcachedLV}"
WBcachedMNT="/mnt/writeback"
#cachedLVPATH="/dev/${cacheVG}/${cachedLV}"
WBcachePOLICY="smq"
WBcacheMODE="writeback"

# More DEVICE vars
hddDEV_arr=( "/dev/sdk" )
hddPARTNUM=1
hddMNT="/mnt/hdd"
nvmeDEV="nvme0n1"
nvmeTARGET="/dev/${nvmeDEV}"
nvmeDEV_arr=( "${nvmeTARGET}p1" )
nvmeMNT="/mnt/nvme"

########################################################### 
# FIO vars
fioJOBS=( \
   "primary95G" 
   "primary9G"
   )
#operations_list=( "write" "randwrite" "read" "randread" )
operations_list=( "write" "randwrite" )
#operations_list=( "randwrite" )
bs_list=( "4k" "64k" "1024k" )

# runtime and ramptime are used in runMULTI.sh
# runTIME and rampTIME are used for fio jobs
xfshdd_RUNT="100"
xfshdd_RAMPT="30"
xfscached_RUNT="600"
xfscached_RAMPT="600"
xfsnvme_RUNT="100"
xfsnvme_RAMPT="30"

########################################################### 
# Calculate the SIZEs, all based on unitSZ and cache_size values
# cache_size sets the LVMcache_data size
unitSZ="G"
let cache_size=10

# Size of the Cache
#  sets fastDEV size for lvcreate in Utils/setupLVM.shinc
#  sets LVMcache_data size for lvconvert in Utils/setupCACHE.shinc
cacheSZ="$cache_size$unitSZ"

# Calculate percentages used to roundup/down sizes
ten_percent=$(($cache_size / 10))
twenty_percent=$(($ten_percent * 2))
# Remember - bash only supports integer arithmetic
# exit if the roundups are not integers
if [ $ten_percent -lt 1 ]; then
  echo "Math error in vars.shinc - var 'ten_percent' must be integer >= 1"
  exit 1
fi

## Continue defining the 'SZ' vars used by the scripts
#
# Size of the fastDEV used by lvcreate in Utils/setupLVM.shinc
#   roundup by 20%
fast_calc=$(($cache_size + $twenty_percent))
fastSZ="$fast_calc$unitSZ"
#
# Size of the slowDEV used by lvcreate in Utils/setupLVM.shinc
#   ten times size of cache
slow_calc=$(($cache_size * 10))
slowSZ="$slow_calc$unitSZ"
#
# Array of sizes used by fio in runLVM.sh
#   one tenth of cache size
#   cache size
lvm1_calc=$(($cache_size / 10))
lvm2_calc=$cache_size
lvmSize1="$lvm1_calc$unitSZ"; lvmSize2="$lvm2_calc$unitSZ"
LVMsize_arr=("${lvmSize1}" "${lvmSize2}")
#LVMsize_arr=("${lvmSize2}" "${lvmSize2}")
#
# Size of scratch file created by fio in runLVM.sh
#   equal to cache size plus 10%
# NOTE: must be less than 'fast_calc'
scratchLVM_calc=$(($cache_size + $ten_percent))
scratchLVM_SZ="$scratchLVM_calc$unitSZ"

# runCACHE.sh SIZE Variables ---------------------
#
# LVMcache_metadata size is one tenth size of LVMcache_data
#   used by lvconvert in Utils/setupCACHE.shinc
metadata_calc=$(($cache_size / 10))
metadataSZ="$metadata_calc$unitSZ"
#
# Size of the origin lvm device used by lvcreate in Utils/setupCACHES.shinc
originSZ="${slowSZ}"
#
# Array of sizes used by fio in runCACHE.sh
# Three size scenarios:
#   cacheSize1=Cache size less 20%
#   cacheSize2=ten times cacheSize1
#   cacheSize1=Cache size less 20%
cache1_calc=$(($cache_size - $twenty_percent))
cache2_calc=$(($cache_size * 3))
#cache2_calc=$(($cache1_calc * 10))
cache3_calc=$(($cache2_calc + $ten_percent))
cacheSize1="$cache3_calc$unitSZ"
#
# Size of scratch files created by fio in runMULTI.sh
# pad it a bit so we don't overrun the end
#scratchCACHE_calc=$(($cache2_calc + $cache1_calc))
scratchCACHE_calc=$(($cache2_calc + $twenty_percent))
scratchCACHE_SZ="$scratchCACHE_calc$unitSZ"

scratchCACHE_SZ="98G"
# Size of scratch file for the fio jobs 
# at some point we may want these to be uniquely sized
scratchPRIMARY_SZ=$scratchCACHE_SZ

# Array used in cacheStats function
# Stores cache stats from last call - used to calculate deltas
# for 'Demotions, Promotions, Dirty'
# initialize as empty integer array, used in runCACHE.sh
declare -ia lastCS_arr=()

########################################################### 
# HOUSEKEEPING vars
#
# Timestamp logfile
ts="$(date +%Y%m%d-%H%M%S)"
# Name of the program being run
PROGNAME=$(basename $0)
# LOGFILE - records steps
RESULTSDIR="./RESULTS/${deviceMODE}_${ts}"
LOGFILE="${RESULTSDIR}/LOGFILE.log"
# Logfile date format, customize it to your wishes
#   - see man date for help
DATE='date +%Y/%m/%d:%H:%M:%S'

# END GLOBAL VARIABLES
#--------------------------------------
