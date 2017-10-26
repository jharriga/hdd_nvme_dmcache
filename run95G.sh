#!/bin/bash
#----------------------------------------------------------------
# run95G.sh - run the various fio jobs on DEVICES using the device-mode
#               passed as $1
# EXPECTS TWO PARAMETERs:
#     device-mode
#                 Valid values are: xfshdd; xfsnvme; xfswritethrough
#                                   xfswriteback
#
# DEPENDENCIES: (must be in search path)
#   I/O workload generator: fio
# 
# ASSUMES the device-mode devices are already mounted.
#    /mnt/xfshdd; /mnt/xfsnvme; /mnt/xfswritethrough; /mnt/xfswriteback
#    See the 'setup.sh' and 'teardown.sh' scripts.
#    Device name vars used for FIO filename param:
#     - fnamePRIMARY
#
# NOTE caches are dropped prior to each testrun as described here:
#   https://linux-mm.org/Drop_Caches
#----------------------------------------

# Verify valid DEVICEMODE parameter passed
case $1 in
  xfshdd|xfsnvme|xfswritethrough|xfswriteback)
      deviceMODE=$1
      ;;
  *)
      echo "USAGE: $0 deviceMODE"
      echo "$LINENO: unrecognized value for deviceMODE on cmdline"
      echo "Valid values are: xfshdd, xfsnvme, xfswritethrough, xfswriteback"
      exit 1
      ;;
esac

# Bring in other script files
myPath="${BASH_SOURCE%/*}"
if [[ ! -d "$myPath" ]]; then
    myPath="$PWD" 
fi

# Note DEVICE-MODE
# MUST BE SET BEFORE INCLUDING vars.shinc FILE!
# Variables
source "$myPath/vars.shinc"

# Functions
source "$myPath/Utils/functions.shinc"

#--------------------------------------
# Housekeeping
#
# Check dependencies are met
chk_dependencies

# Create log file - named in vars.shinc
if [ ! -d $RESULTSDIR ]; then
  mkdir -p $RESULTSDIR || \
    error_exit "$LINENO: Unable to create RESULTSDIR."
fi
touch $LOGFILE || error_exit "$LINENO: Unable to create LOGFILE."
updatelog "${PROGNAME} - Created logfile: $LOGFILE"

updatelog "${PROGNAME} - deviceMODE is $deviceMODE"

#
# END: Housekeeping
#--------------------------------------

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Pre-TEST SECTION 
############################

#
# Call teardown and then setup.sh ??
#

# Set the fname and runtime/ramptime vars based on deviceMODE
# filename settings for fio runs
if [ "$deviceMODE" = "setup" ] || [ "$deviceMODE" = "teardown" ]; then
  # do nothing
  :
elif [ "$deviceMODE" = "xfshdd" ]; then
  fnamePRIMARY="${hddMNT}0"
  runtime=$xfshdd_RUNT
  ramptime=$xfshdd_RAMPT
elif [ "$deviceMODE" = "xfsnvme" ]; then
  fnamePRIMARY="${nvmeMNT}0"
  runtime=$xfsnvme_RUNT
  ramptime=$xfsnvme_RAMPT
elif [ "$deviceMODE" = "xfswritethrough" ]; then
  fnamePRIMARY="${WTcachedMNT}0"
  runtime=$xfscached_RUNT
  ramptime=$xfscached_RAMPT
elif [ "$deviceMODE" = "xfswriteback" ]; then
  fnamePRIMARY="${WBcachedMNT}0"
  runtime=$xfscached_RUNT
  ramptime=$xfscached_RAMPT
else
  error_exit "$LINENO: invalid value for deviceMODE"
fi

# set the SCRATCH location used by the FIO jobs
scratchPRIMARY="${fnamePRIMARY}/scratch_primary"

# Write runtime environment and key variable values to LOGFILE
print_Runtime

updatelog "${PROGNAME} - preparing to run $numjobs fio jobs"
updatelog "${PROGNAME} > each for $runtime seconds"

# Print summary
echo "deviceMODE is ${deviceMODE}"
echo "> scratchPRIMARY is ${scratchPRIMARY}"
#echo "> scratchPRIMARY is ${scratchPRIMARY} : size ${scratchPRIMARY_SZ}"

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TEST SECTION 
############################
for fiojob in "${fioJOBS[@]}"; do
  for op in "${operations_list[@]}"; do
    for bs in "${bs_list[@]}"; do
      # set vars needed for this fiojob
      case $fiojob in
        primary*)
          bs="${bs}"
          rw="${op}"
          ioeng="libaio"
          direct=1
          filename="${scratchPRIMARY}"
          xtraFlags="--iodepth=16"
          case $fiojob in
            primary9G) offset="0G"; fs="9G" ;;
            primary95G) offset="0G" ; fs="95G" ;;
            *) error_exit "$LINENO: unrecognized value for fiojob = $fiojob."
          esac
          ;;
      *)
          error_exit "$LINENO: unrecognized value for fiojob = $fiojob."
          ;;
      esac

      res_file_path="${RESULTSDIR}/${fiojob}"
      mkdir -p $res_file_path || error_exit "unable to mkdir $res_file_path"
      res_file="${res_file_path}/${op}_${bs}.fio"
      if [ -e $res_file ]; then
          rm -f $res_file
      fi

      updatelog "*************************"
      updatelog "STARTING: fio job - $fiojob"
      updatelog "FIO params: OFFSET=$offset; FILESZ=$fs RW=$rw; BS=$bs; \
        filename=$filename runtime=$runtime ramptime=$ramptime $xtraFlags"

      # ONLY NEEDED FOR deviceMODE=xfscached OR xfswriteback
      # Output lvmcache statistics prior to this run
      if [ "$deviceMODE" = "xfswritethrough" ]
      then
        devmapper=$(df $filename | awk '{if ($1 != "Filesystem") print $1}')
        cacheStats $devmapper start
      elif [ "$deviceMODE" = "xfswriteback" ]
      then
        devmapper=$(df $filename | awk '{if ($1 != "Filesystem") print $1}')
        cacheStats $devmapper start
      fi

      # clear the cache prior to fio job
      sync; echo 3 > /proc/sys/vm/drop_caches

      # issue the fio job and wait for it to complete
      fio --offset=${offset} --filesize=${fs} --blocksize=${bs} --rw=${rw} \
        --ioengine=${ioeng} --direct=${direct} --filename=${filename} \
        --time_based --runtime=${runtime} --ramp_time=${ramptime} \
        --fsync_on_close=1 --group_reporting ${xtraFlags} \
        --name=${fiojob} --output=${res_file} >> $LOGFILE

      if [ ! -e $res_file ]; then
         error_exit "fio job $fiojob failed to: ${filename}"
      fi

      updatelog "COMPLETED: fio job - $fiojob"
      fio_print $res_file

      # ONLY NEEDED FOR deviceMODE=xfscached OR xfswriteback
      # Output lvmcache statistics after each run
      # these calls should emit delta values
      if [ "$deviceMODE" = "xfswritethrough" ]
      then
        devmapper=$(df $filename | awk '{if ($1 != "Filesystem") print $1}')
        cacheStats $devmapper stop
      elif [ "$deviceMODE" = "xfswriteback" ]
      then
        devmapper=$(df $filename | awk '{if ($1 != "Filesystem") print $1}')
        cacheStats $devmapper stop
      fi

      echo "FIO output:" >> $LOGFILE
      cat ${res_file} >> $LOGFILE
      updatelog "+++++++++++++++++++++++++++++++++++++++++++++++"
    done     # end FOR bs
  done       # end FOR oper
done         # end FOR fiojob

###################################################

# Really Done
updatelog "END ${PROGNAME}**********************"
updatelog "${PROGNAME} - Closed logfile: $LOGFILE"
exit 0
