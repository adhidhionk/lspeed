#!/system/bin/sh

# L Speed tweak
# Codename : lspeed
version="v1.1";
build_date=29-11-2019;
# Developer : Paget96
# Paypal : https://paypal.me/Paget96

# To select current profile go to /data/lspeed/setup
# and edit file "profile"
# 0 - default
# 1 - power saving
# 2 - balanced
# 3 - performance
# Save the file and reboot phone
#
# To check if mod working go to /data/lspeed/logs/main_log.log
# that's main output after executing service.sh
#


# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');
brand=$(getprop ro.product.brand) 2>/dev/null
model=$(getprop ro.product.model) 2>/dev/null
arch="Soon!" 2>/dev/null
busyboxVersion=$(busybox | awk 'NR==1{print $2}') 2>/dev/null
if [ -z "${busyboxVersion}" ]; then
	busyboxVersion="Busybox not found"
fi
rom=$(getprop ro.build.display.id) 2>/dev/null
androidRelease=$(getprop ro.build.version.release)
api=$(getprop ro.build.version.sdk) 2>/dev/null
kernel=$(uname -r) 2>/dev/null
root=$(magisk -c) 2>/dev/null
divider="==============================================="

#PATHS
LSPEED=/data/lspeed

LOG_DIR=$LSPEED/logs
LOG=$LOG_DIR/main_log.log
OPTIMIZATION_LOG=$LOG_DIR/optimization_log.log

SETUP_DIR=$LSPEED/setup
PROFILE=$SETUP_DIR/profile
USER_PROFILE=$SETUP_DIR/user_profile

# Detecting modules path
if [ -d /data/adb/modules ]; then
	MODULES=/data/adb/modules
elif [ -d /sbin/.core/img ]; then
	MODULES=/sbin/.core/img
elif [ -d /sbin/.magisk/img ]; then
	MODULES=/sbin/.magisk/img
fi;

# Functions
createFile() {
    touch "$1"
	chmod 0644 "$1" 2> /dev/null
}

sendToLog() {
    echo "[$(date +"%H:%M:%S %d-%m-%Y")] $1" | tee -a $LOG
}

write() {
	#chmod 0644 "$1" 2> /dev/null
    echo "$2" > "$1" 2> /dev/null
}

lockFile() {
	chmod 0644 "$1" 2> /dev/null
    echo "$2" > "$1" 2> /dev/null
	chmod 0444 "$1" 2> /dev/null
}

# Setting up default L Speed dirs and files
# If for any reason any of them are missing, add them manually
if [ ! -d $LSPEED ]; then
	mkdir -p $LSPEED
fi;

# Remove old logs when running the script again
# and create dir if not exists
# This will be only executed if there are no arguments while executing
if [ $# -eq 0 ]; then
	if [ -d $LOG_DIR ]; then
		rm -rf $LOG_DIR
		mkdir -p $LOG_DIR
	else
		mkdir -p $LOG_DIR
	fi;
fi;

# Create setup dir and child files and dirs
# Needed for module working at all
# /data/lsepeed/setup/profile
# /data/lsepeed/setup/user_profile/*
if [ ! -d $SETUP_DIR ]; then
	mkdir -p $SETUP_DIR
fi;

if [ -f $PROFILE ]; then
	createFile $PROFILE
fi;

# Remove user_profile if it's already mounted as a file
# This is needed to prevent crashes while running the script
if [ -f $USER_PROFILE ]; then
	rm -rf $USER_PROFILE
fi;

# Directory dedicated for storing current profile
if [ ! -d $USER_PROFILE ]; then
	mkdir -p $USER_PROFILE
fi;

if [ -d $USER_PROFILE ]; then
	createFile $USER_PROFILE/battery_improvements

	# CPU section
	createFile $USER_PROFILE/cpu_optimization
	createFile $USER_PROFILE/gov_tuner

	createFile $USER_PROFILE/entropy

	# GPU section
	createFile $USER_PROFILE/gpu_optimizer
	createFile $USER_PROFILE/optimize_buffers
	createFile $USER_PROFILE/render_opengles_using_gpu
	createFile $USER_PROFILE/use_opengl_skia

	# I/O tweaks section
	createFile $USER_PROFILE/disable_io_stats
	createFile $USER_PROFILE/io_blocks_optimization
	createFile $USER_PROFILE/io_extended_queue
	createFile $USER_PROFILE/scheduler_tuner
	createFile $USER_PROFILE/sd_tweak

	# LNET tweaks section
	createFile $USER_PROFILE/dns
	createFile $USER_PROFILE/net_buffers
	createFile $USER_PROFILE/net_speed_plus
	createFile $USER_PROFILE/net_tcp
	createFile $USER_PROFILE/optimize_ril

	# Other
	createFile $USER_PROFILE/disable_debugging
	createFile $USER_PROFILE/disable_kernel_panic

	# RAM manager section
	createFile $USER_PROFILE/ram_manager
	createFile $USER_PROFILE/disable_multitasking_limitations
	createFile $USER_PROFILE/low_ram_flag
	createFile $USER_PROFILE/oom_killer
	createFile $USER_PROFILE/swappiness
	createFile $USER_PROFILE/virtual_memory
	createFile $USER_PROFILE/heap_optimization

fi;

if [ $# -eq 0 ]; then
	sendToLog "L Speed finished with base setup";

	sendToLog "Starting with logging...";
	sendToLog $divider;
	sendToLog "Getting module info"
	sendToLog "Version: $version ($build_date)";
	sendToLog $divider;
	sendToLog "Getting device info"
	sendToLog "Brand: $brand"
	sendToLog "Model: $model"
	sendToLog "Arch: $arch"
	sendToLog "Busybox: $busyboxVersion"
	sendToLog "ROM: $rom (Android: $androidRelease|API: $api)"
	sendToLog "Kernel: $kernel"
	sendToLog "Root: $root"
	sendToLog "RAM: $((memTotal))mb"
	sendToLog $divider;
fi

#
# Battery improvements
#
batteryImprovements() {
sendToLog "Activating battery improvements...";

	# Disabling ksm
	if [ -e "/sys/kernel/mm/ksm/run" ]; then
		write /sys/kernel/mm/ksm/run "0";
		sendToLog "KSM is disabled, saving battery cycles and improving battery life...";
	fi;

	# Disabling uksm
	if [ -e "/sys/kernel/mm/uksm/run" ]; then
		write /sys/kernel/mm/uksm/run "0"
		sendToLog "UKSM is disabled, saving battery cycles and improving battery life...";
	fi;

	# Kernel sleepers
	if [ -e "/sys/kernel/sched/gentle_fair_sleepers" ]; then
		write /sys/kernel/sched/gentle_fair_sleepers "0"
		sendToLog "Gentle fair sleepers disabled...";
	fi;

	if [ -e "/sys/kernel/sched/arch_power" ]; then
		write /sys/kernel/sched/arch_power "1"
		sendToLog "Arch power enabled...";
	fi;

	if [ -e "/sys/kernel/debug/sched_features" ]; then
		# Only give sleepers 50% of their service deficit. This allows
		# them to run sooner, but does not allow tons of sleepers to
		# rip the spread apart.
		write /sys/kernel/debug/sched_features "NO_GENTLE_FAIR_SLEEPERS"
		sendToLog "GENTLE_FAIR_SLEEPERS disabled...";

		write /sys/kernel/debug/sched_features "ARCH_POWER"
		sendToLog "ARCH_POWER enabled...";
	fi;

	# Enable fast charging
	if [ -e "/sys/kernel/fast_charge/force_fast_charge" ];  then
		write /sys/kernel/fast_charge/force_fast_charge "1"
		sendToLog "Fast charge enabled";
	fi;

	resetprop ro.audio.flinger_standbytime_ms 300
	sendToLog "Set low audio flinger standby delay to 300ms for reducing power consumption";

	scsi_disk=$(ls -d /sys/class/scsi_disk/*) 2>/dev/null
	for i in $scsi_disk; do
 		write "$i"/cache_type "temporary none"
 		sendToLog "Set cache type to temporary none in $i";
 	done

	if [ -e /sys/module/wakeup/parameters/enable_bluetooth_timer ]; then
		write /sys/module/wakeup/parameters/enable_bluetooth_timer "Y"
		write /sys/module/wakeup/parameters/enable_ipa_ws "N"
		write /sys/module/wakeup/parameters/enable_netlink_ws "Y"
		write /sys/module/wakeup/parameters/enable_netmgr_wl_ws "Y"
		write /sys/module/wakeup/parameters/enable_qcom_rx_wakelock_ws "N"
		write /sys/module/wakeup/parameters/enable_timerfd_ws "Y"
		write /sys/module/wakeup/parameters/enable_wlan_extscan_wl_ws "N"
		write /sys/module/wakeup/parameters/enable_wlan_wow_wl_ws "N"
		write /sys/module/wakeup/parameters/enable_wlan_ws "N"
		write /sys/module/wakeup/parameters/enable_netmgr_wl_ws "N"
		write /sys/module/wakeup/parameters/enable_wlan_wow_wl_ws "N"
		write /sys/module/wakeup/parameters/enable_wlan_ipa_ws "N"
		write /sys/module/wakeup/parameters/enable_wlan_pno_wl_ws "N"
		write /sys/module/wakeup/parameters/enable_wcnss_filter_lock_ws "N"
		sendToLog "Blocked various wakelocks";
	fi;

	if [ -e /sys/module/bcmdhd/parameters/wlrx_divide ]; then
		write /sys/module/bcmdhd/parameters/wlrx_divide "4"
		write /sys/module/bcmdhd/parameters/wlctrl_divide "4"
		sendToLog "wlan wakelocks blocked";
	fi;

	if [ -e /sys/devices/virtual/misc/boeffla_wakelock_blocker/wakelock_blocker ]; then
		write /sys/devices/virtual/misc/boeffla_wakelock_blocker/wakelock_blocker "wlan_pno_wl;wlan_ipa;wcnss_filter_lock;hal_bluetooth_lock;IPA_WS;sensor_ind;wlan;netmgr_wl;qcom_rx_wakelock;wlan_wow_wl;wlan_extscan_wl;NETLINK;bam_dmux_wakelock;IPA_RM12"
		sendToLog "Updated Boeffla wakelock blocker";

	elif [ -e /sys/class/misc/boeffla_wakelock_blocker/wakelock_blocker ]; then
		write /sys/class/misc/boeffla_wakelock_blocker/wakelock_blocker "wlan_pno_wl;wlan_ipa;wcnss_filter_lock;hal_bluetooth_lock;IPA_WS;sensor_ind;wlan;netmgr_wl;qcom_rx_wakelock;wlan_wow_wl;wlan_extscan_wl;NETLINK;bam_dmux_wakelock;IPA_RM12"
		sendToLog "Updated Boeffla wakelock blocker";
	fi;

	# lpm Levels
	lpm=/sys/module/lpm_levels
	if [ -d $lpm/parameters ]; then
		write $lpm/enable_low_power/l2 "4"
		write $lpm/parameters/lpm_prediction "Y"
		write $lpm/parameters/menu_select "N"
		write $lpm/parameters/print_parsed_dt "N"
		write $lpm/parameters/sleep_disabled "N"
		write $lpm/parameters/sleep_time_override "0"
		sendToLog "Low power mode sleep enabled";
	fi;

	if [ -e "/sys/class/lcd/panel/power_reduce" ]; then
		write /sys/class/lcd/panel/power_reduce "1"
		sendToLog "LCD power reduce enabled";
	fi;

	if [ -e "/sys/module/pm2/parameters/idle_sleep_mode" ]; then
		write /sys/module/pm2/parameters/idle_sleep_mode "Y"
		sendToLog "PM2 module idle sleep mode enabled";
	fi;

	sendToLog "Battery improvements are enabled";
	sendToLog "$divider";
}

#
# CPU Optimization battery profile
#
cpuOptimizationBattery() {
	real_cpu_cores=$(ls /sys/devices/system/cpu | grep -c ^cpu[0-9]);
	cpu_cores=$((real_cpu_cores-1));

	sendToLog "Optimizing CPU...";

	if [ -e "/sys/devices/system/cpu/cpuidle/use_deepest_state" ]; then
		write /sys/devices/system/cpu/cpuidle/use_deepest_state "1"
		sendToLog "Enable deepest CPU idle state";
	fi;

	# Disable krait voltage boost
	if [ -e "/sys/module/acpuclock_krait/parameters/boost" ];  then
		write /sys/module/acpuclock_krait/parameters/boost "N"
		sendToLog "Disable Krait voltage boost";
	fi;

	if [ -e "/sys/module/workqueue/parameters/power_efficient" ]; then
		lockFile /sys/module/workqueue/parameters/power_efficient "Y"
		sendToLog "Power-save workqueues enabled, scheduling workqueues on awake CPUs to save power."
	fi;

	if [ -e /sys/module/cpu_input_boost/parameters/input_boost_duration ]; then
		write /sys/module/cpu_input_boost/parameters/input_boost_duration "0"
		sendToLog "CPU Boost Input Duration=0"
	fi;

	if [ -e /sys/module/cpu_boost/parameters/input_boost_ms ]; then
		write /sys/module/cpu_boost/parameters/input_boost_ms "0"
		sendToLog "CPU Boost Input Ms=0"
	fi;

	if [ -e /sys/module/cpu_boost/parameters/input_boost_ms_s2 ]; then
		write /sys/module/cpu_boost/parameters/input_boost_ms_s2 "0"
		sendToLog "CPU Boost Input Ms_S2=0"
	fi;

	if [ -e /sys/module/cpu_boost/parameters/dynamic_stune_boost ]; then
		write /sys/module/cpu_boost/parameters/dynamic_stune_boost "0"
		sendToLog "CPU Boost Dyn_Stune_Boost=0"
	fi;

	if [ -e /sys/module/cpu_input_boost/parameters/dynamic_stune_boost ]; then
		write /sys/module/cpu_input_boost/parameters/dynamic_stune_boost "0"
		sendToLog "CPU input boost Dyn_Stune_Boost=0"
	fi;

	if [ -e /sys/module/cpu_input_boost/parameters/general_stune_boost ]; then
		write /sys/module/cpu_input_boost/parameters/general_stune_boost "10"
		sendToLog "CPU input boost General_Stune_Boost=10"
	fi;

	if [ -e /sys/module/dsboost/parameters/input_boost_duration ]; then
		write /sys/module/dsboost/parameters/input_boost_duration "0"
		sendToLog "Dsboost Input Boost Duration=0"
	fi;

	if [ -e /sys/module/dsboost/parameters/input_stune_boost ]; then
		write /sys/module/dsboost/parameters/input_stune_boost "0"
		sendToLog "Dsboost Input Stune Boost Duration=0"
	fi;

	if [ -e /sys/module/dsboost/parameters/sched_stune_boost ]; then
		write /sys/module/dsboost/parameters/sched_stune_boost "0"
		sendToLog "Dsboost Sched_Stune_Boost=0"
	fi;

	if [ -e /sys/module/dsboost/parameters/cooldown_boost_duration ]; then
		write /sys/module/dsboost/parameters/cooldown_boost_duration "0"
		sendToLog "Dsboost Cooldown_Boost_Duration=0"
	fi;

	if [ -e /sys/module/dsboost/parameters/cooldown_stune_boost ]; then
		write /sys/module/dsboost/parameters/cooldown_stune_boost "0"
		sendToLog "Dsboost Cooldown_Stune_Boost=0"
	fi;

	# CPU CTL
	if [ -e /dev/cpuctl/cpu.rt_period_us ]; then
		write /dev/cpuctl/cpu.rt_period_us "1000000"
		sendToLog "cpu.rt_period_us=1000000"
	fi;

	if [ -e /dev/cpuctl/cpu.rt_runtime_us ]; then
		write /dev/cpuctl/cpu.rt_period_us "950000"
		sendToLog "cpu.rt_runtime_us=950000"
	fi;

	sched_rt_period_us=/proc/sys/kernel/sched_rt_period_us
	if [ -e $sched_rt_period_us ]; then
		write $sched_rt_period_us "1000000"
		sendToLog "$sched_rt_period_us=1000000"
	fi;

	sched_rt_runtime_us=/proc/sys/kernel/sched_rt_runtime_us
	if [ -e $sched_rt_runtime_us ]; then
		write $sched_rt_runtime_us "950000"
		sendToLog "$sched_rt_runtime_us=950000"
	fi;

	sched_wake_to_idle=/proc/sys/kernel/sched_wake_to_idle
	if [ -e $sched_wake_to_idle ]; then
		write $sched_wake_to_idle "0"
		sendToLog "$sched_wake_to_idle=0"
	fi;

	# Disable touch boost
	touchboost=/sys/module/msm_performance/parameters/touchboost
	if [ -e $touchboost ]; then
		write $touchboost "0"
		sendToLog "$touchboost=0"
	fi;

	touch_boost=/sys/power/pnpmgr/touch_boost
	if [ -e $touch_boost ]; then
		write $touch_boost "N"
		sendToLog "$touch_boost=N"
	fi;

	#Disable CPU Boost
	boost_ms=/sys/module/cpu_boost/parameters/boost_ms
	if [ -e $boost_ms ]; then
		write $boost_ms "N"
		sendToLog "$boost_ms=N"
	fi;

	sched_boost_on_input=/sys/module/cpu_boost/parameters/sched_boost_on_input
	if [ -e $sched_boost_on_input ]; then
		write $sched_boost_on_input "N"
		sendToLog "$sched_boost_on_input=N"
	fi;

	sendToLog "CPU is optimized..."
	sendToLog "$divider";
}

#
# CPU Optimization balanced profile
#
cpuOptimizationBalanced() {
real_cpu_cores=$(ls /sys/devices/system/cpu | grep -c ^cpu[0-9]);
cpu_cores=$((real_cpu_cores-1));

sendToLog "Optimizing CPU...";

if [ -e "/sys/devices/system/cpu/cpuidle/use_deepest_state" ]; then
	write /sys/devices/system/cpu/cpuidle/use_deepest_state "1"
	sendToLog "Enable deepest CPU idle state";
fi;

# Disable krait voltage boost
if [ -e "/sys/module/acpuclock_krait/parameters/boost" ];  then
	write /sys/module/acpuclock_krait/parameters/boost "N"
	sendToLog "Disable Krait voltage boost";
fi;

if [ -e "/sys/module/workqueue/parameters/power_efficient" ]; then
	lockFile /sys/module/workqueue/parameters/power_efficient "N"
	sendToLog "Power-save workqueues disabled, scheduling workqueues on awake CPUs to save power."
fi;

if [ -e /sys/module/cpu_input_boost/parameters/input_boost_duration ]; then
	write /sys/module/cpu_input_boost/parameters/input_boost_duration "60"
	sendToLog "CPU Boost Input Duration=60"
fi;

if [ -e /sys/module/cpu_boost/parameters/input_boost_ms ]; then
	write /sys/module/cpu_boost/parameters/input_boost_ms "60"
	sendToLog "CPU Boost Input Ms=60"
fi;

if [ -e /sys/module/cpu_boost/parameters/input_boost_ms_s2 ]; then
	write /sys/module/cpu_boost/parameters/input_boost_ms_s2 "30"
	sendToLog "CPU Boost Input Ms_S2=30"
fi;

if [ -e /sys/module/cpu_boost/parameters/dynamic_stune_boost ]; then
	write /sys/module/cpu_boost/parameters/dynamic_stune_boost "20"
	sendToLog "CPU Boost Dyn_Stune_Boost=20"
fi;

if [ -e /sys/module/cpu_input_boost/parameters/dynamic_stune_boost ]; then
	write /sys/module/cpu_input_boost/parameters/dynamic_stune_boost "20"
	sendToLog "CPU input boost Dyn_Stune_Boost=20"
fi;

if [ -e /sys/module/cpu_input_boost/parameters/general_stune_boost ]; then
	write /sys/module/cpu_input_boost/parameters/general_stune_boost "60"
	sendToLog "CPU input boost General_Stune_Boost=60"
fi;

if [ -e /sys/module/dsboost/parameters/input_boost_duration ]; then
	write /sys/module/dsboost/parameters/input_boost_duration "60"
	sendToLog "Dsboost Input Boost Duration=60"
fi;

if [ -e /sys/module/dsboost/parameters/input_stune_boost ]; then
	write /sys/module/dsboost/parameters/input_stune_boost "60"
	sendToLog "Dsboost Input Stune Boost Duration=60"
fi;

if [ -e /sys/module/dsboost/parameters/sched_stune_boost ]; then
	write /sys/module/dsboost/parameters/sched_stune_boost "10"
	sendToLog "Dsboost Sched_Stune_Boost=10"
fi;

if [ -e /sys/module/dsboost/parameters/cooldown_boost_duration ]; then
	write /sys/module/dsboost/parameters/cooldown_boost_duration "60"
	sendToLog "Dsboost Cooldown_Boost_Duration=60"
fi;

if [ -e /sys/module/dsboost/parameters/cooldown_stune_boost ]; then
	write /sys/module/dsboost/parameters/cooldown_stune_boost "10"
	sendToLog "Dsboost Cooldown_Stune_Boost=10"
fi;

# CPU CTL
if [ -e /dev/cpuctl/cpu.rt_period_us ]; then
	write /dev/cpuctl/cpu.rt_period_us "1000000"
	sendToLog "cpu.rt_period_us=1000000"
fi;

if [ -e /dev/cpuctl/cpu.rt_runtime_us ]; then
	write /dev/cpuctl/cpu.rt_period_us "950000"
	sendToLog "cpu.rt_runtime_us=950000"
fi;

sched_rt_period_us=/proc/sys/kernel/sched_rt_period_us
if [ -e $sched_rt_period_us ]; then
	write $sched_rt_period_us "1000000"
	sendToLog "$sched_rt_period_us=1000000"
fi;

sched_rt_runtime_us=/proc/sys/kernel/sched_rt_runtime_us
if [ -e $sched_rt_runtime_us ]; then
	write $sched_rt_runtime_us "950000"
	sendToLog "$sched_rt_runtime_us=950000"
fi;

sched_wake_to_idle=/proc/sys/kernel/sched_wake_to_idle
if [ -e $sched_wake_to_idle ]; then
	write $sched_wake_to_idle "0"
	sendToLog "$sched_wake_to_idle=0"
fi;

# Disable touch boost
touchboost=/sys/module/msm_performance/parameters/touchboost
if [ -e $touchboost ]; then
	write $touchboost "0"
	sendToLog "$touchboost=0"
fi;

touch_boost=/sys/power/pnpmgr/touch_boost
if [ -e $touch_boost ]; then
	write $touch_boost "N"
	sendToLog "$touch_boost=N"
fi;

#Disable CPU Boost
boost_ms=/sys/module/cpu_boost/parameters/boost_ms
if [ -e $boost_ms ]; then
	write $boost_ms "N"
	sendToLog "$boost_ms=N"
fi;

sched_boost_on_input=/sys/module/cpu_boost/parameters/sched_boost_on_input
if [ -e $sched_boost_on_input ]; then
	write $sched_boost_on_input "N"
	sendToLog "$sched_boost_on_input=N"
fi;

sendToLog "CPU is optimized..."
sendToLog "$divider";
}

#
# CPU Optimization performance profile
#
cpuOptimizationPerformance() {
real_cpu_cores=$(ls /sys/devices/system/cpu | grep -c ^cpu[0-9]);
cpu_cores=$((real_cpu_cores-1));

sendToLog "Optimizing CPU...";

if [ -e "/sys/devices/system/cpu/cpuidle/use_deepest_state" ]; then
	write /sys/devices/system/cpu/cpuidle/use_deepest_state "1"
	sendToLog "Enable deepest CPU idle state";
fi;

# Disable krait voltage boost
if [ -e "/sys/module/acpuclock_krait/parameters/boost" ];  then
	write /sys/module/acpuclock_krait/parameters/boost "Y"
	sendToLog "Enable Krait voltage boost";
fi;

if [ -e "/sys/module/workqueue/parameters/power_efficient" ]; then
	lockFile /sys/module/workqueue/parameters/power_efficient "N"
	sendToLog "Power-save workqueues disabled, scheduling workqueues on awake CPUs to save power."
fi;

if [ -e /sys/module/cpu_input_boost/parameters/input_boost_duration ]; then
	write /sys/module/cpu_input_boost/parameters/input_boost_duration "120"
	sendToLog "CPU Boost Input Duration=120"
fi;

if [ -e /sys/module/cpu_boost/parameters/input_boost_ms ]; then
	write /sys/module/cpu_boost/parameters/input_boost_ms "120"
	sendToLog "CPU Boost Input Ms=120"
fi;

if [ -e /sys/module/cpu_boost/parameters/input_boost_ms_s2 ]; then
	write /sys/module/cpu_boost/parameters/input_boost_ms_s2 "50"
	sendToLog "CPU Boost Input Ms_S2=50"
fi;

if [ -e /sys/module/cpu_boost/parameters/dynamic_stune_boost ]; then
	write /sys/module/cpu_boost/parameters/dynamic_stune_boost "30"
	sendToLog "CPU Boost Dyn_Stune_Boost=30"
fi;

if [ -e /sys/module/cpu_input_boost/parameters/dynamic_stune_boost ]; then
	write /sys/module/cpu_input_boost/parameters/dynamic_stune_boost "30"
	sendToLog "CPU input boost Dyn_Stune_Boost=30"
fi;

if [ -e /sys/module/cpu_input_boost/parameters/general_stune_boost ]; then
	write /sys/module/cpu_input_boost/parameters/general_stune_boost "10"
	sendToLog "CPU input boost General_Stune_Boost=10"
fi;

if [ -e /sys/module/dsboost/parameters/input_boost_duration ]; then
	write /sys/module/dsboost/parameters/input_boost_duration "120"
	sendToLog "Dsboost Input Boost Duration=120"
fi;

if [ -e /sys/module/dsboost/parameters/input_stune_boost ]; then
	write /sys/module/dsboost/parameters/input_stune_boost "120"
	sendToLog "Dsboost Input Stune Boost Duration=120"
fi;

if [ -e /sys/module/dsboost/parameters/sched_stune_boost ]; then
	write /sys/module/dsboost/parameters/sched_stune_boost "10"
	sendToLog "Dsboost Sched_Stune_Boost=10"
fi;

if [ -e /sys/module/dsboost/parameters/cooldown_boost_duration ]; then
	write /sys/module/dsboost/parameters/cooldown_boost_duration "120"
	sendToLog "Dsboost Cooldown_Boost_Duration=120"
fi;

if [ -e /sys/module/dsboost/parameters/cooldown_stune_boost ]; then
	write /sys/module/dsboost/parameters/cooldown_stune_boost "10"
	sendToLog "Dsboost Cooldown_Stune_Boost=10"
fi;


# CPU CTL
if [ -e /dev/cpuctl/cpu.rt_period_us ]; then
	write /dev/cpuctl/cpu.rt_period_us "1000000"
	sendToLog "cpu.rt_period_us=1000000"
fi;

if [ -e /dev/cpuctl/cpu.rt_runtime_us ]; then
	write /dev/cpuctl/cpu.rt_period_us "950000"
	sendToLog "cpu.rt_runtime_us=950000"
fi;

sched_rt_period_us=/proc/sys/kernel/sched_rt_period_us
if [ -e $sched_rt_period_us ]; then
	write $sched_rt_period_us "1000000"
	sendToLog "$sched_rt_period_us=1000000"
fi;

sched_rt_runtime_us=/proc/sys/kernel/sched_rt_runtime_us
if [ -e $sched_rt_runtime_us ]; then
	write $sched_rt_runtime_us "950000"
	sendToLog "$sched_rt_runtime_us=950000"
fi;


sched_wake_to_idle=/proc/sys/kernel/sched_wake_to_idle
if [ -e $sched_wake_to_idle ]; then
	write $sched_wake_to_idle "0"
	sendToLog "$sched_wake_to_idle=0"
fi;

# Disable touch boost
touchboost=/sys/module/msm_performance/parameters/touchboost
if [ -e $touchboost ]; then
	write $touchboost "0"
	sendToLog "$touchboost=0"
fi;

touch_boost=/sys/power/pnpmgr/touch_boost
if [ -e $touch_boost ]; then
	write $touch_boost "N"
	sendToLog "$touch_boost=N"
fi;

#Disable CPU Boost
boost_ms=/sys/module/cpu_boost/parameters/boost_ms
if [ -e $boost_ms ]; then
	write $boost_ms "N"
	sendToLog "$boost_ms=N"
fi;

sched_boost_on_input=/sys/module/cpu_boost/parameters/sched_boost_on_input
if [ -e $sched_boost_on_input ]; then
	write $sched_boost_on_input "N"
	sendToLog "$sched_boost_on_input=N"
fi;

sendToLog "CPU is optimized..."
sendToLog "$divider";
}

entropyAggressive() {
sendToLog "Activating aggressive entropy profile..."

sysctl -e -w kernel.random.read_wakeup_threshold=512
sysctl -e -w kernel.random.write_wakeup_threshold=1024
sysctl -e -w kernel.random.urandom_min_reseed_secs=90

sendToLog "Aggressive entropy profile activated"
sendToLog "$divider";
}

entropyEnlarger() {
sendToLog "Activating enlarger entropy profile..."

sysctl -e -w kernel.random.read_wakeup_threshold=128
sysctl -e -w kernel.random.write_wakeup_threshold=896
sysctl -e -w kernel.random.urandom_min_reseed_secs=90

sendToLog "Enlarger entropy profile activated"
sendToLog "$divider";
}

entropyLight() {
sendToLog "Activating light entropy profile..."

sysctl -e -w kernel.random.read_wakeup_threshold=64
sysctl -e -w kernel.random.write_wakeup_threshold=128
sysctl -e -w kernel.random.urandom_min_reseed_secs=90

sendToLog "Light entropy profile activated"
sendToLog "$divider";
}

entropyModerate() {
sendToLog "Activating moderate entropy profile..."

sysctl -e -w kernel.random.read_wakeup_threshold=128
sysctl -e -w kernel.random.write_wakeup_threshold=256
sysctl -e -w kernel.random.urandom_min_reseed_secs=90

sendToLog "Moderate entropy profile activated"
sendToLog "$divider";
}

gpuOptimizerBalanced() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

sendToLog "Optimizing GPU..."

# GPU related tweaks
if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
	gpu="/sys/class/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/*.gpu/devfreq/*.gpu" ]; then
	gpu="/sys/devices/platform/*.gpu/devfreq/*.gpu"
elif [ -d "/sys/devices/platform/gpusysfs" ]; then
	gpu="/sys/devices/platform/gpusysfs"
elif [ -d "/sys/devices/*.mali" ]; then
	gpu="/sys/devices/*.mali"
elif [ -d "/sys/devices/*.gpu" ]; then
	gpu="/sys/devices/*.gpu"
elif [ -d "/sys/devices/platform/mali.0" ]; then
	gpu="/sys/devices/platform/mali.0"
elif [ -d "/sys/devices/platform/mali-*.0" ]; then
	gpu="/sys/devices/platform/mali-*.0"
elif [ -d "/sys/module/mali/parameters" ]; then
	gpu="/sys/module/mali/parameters"
elif [ -d "/sys/class/misc/mali0" ]; then
	gpu="/sys/class/misc/mali0"
elif [ -d "/sys/kernel/gpu" ]; then
	gpu="/sys/kernel/gpu"
fi

if [ "$memTotal" -lt 3072 ]; then
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100/2));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100/2));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100/2));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100/2));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100/2));
	resetprop ro.hwui.texture_cache_flushrate 0.3
else 
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100));
	resetprop ro.hwui.texture_cache_flushrate 0.3
fi
sendToLog "Optimized GPU caches";

if [ -e /proc/gpufreq/gpufreq_limited_thermal_ignore ]; then
	write /proc/gpufreq/gpufreq_limited_thermal_ignore "1"		
	sendToLog "Disabled gpufreq thermal"
fi;

if [ -e /proc/mali/dvfs_enable ]; then
	write /proc/mali/dvfs_enable "1"		
	sendToLog "dvfs enabled"
fi;

if [ -e /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate ]; then
	write /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate "1"		
	sendToLog "Simple GPU algorithm enabled"
fi;

# Adreno idler
if [ -e /sys/module/adreno_idler/parameters/adreno_idler_active ]; then
	write /sys/module/adreno_idler/parameters/adreno_idler_active "N"
	write /sys/module/adreno_idler/parameters/adreno_idler_idleworkload "6000"
	write /sys/module/adreno_idler/parameters/adreno_idler_downdifferential "15"
	write /sys/module/adreno_idler/parameters/adreno_idler_idlewait "15"
	sendToLog "Disabled and tweaked adreno idler"
fi;

if [ -e $gpu/devfreq/adrenoboost ]; then
	write $gpu/devfreq/adrenoboost "1"
	sendToLog "Adreno boost is set to 1"
fi;

if [ -e $gpu/throttling ]; then
	write $gpu/throttling "0"
	sendToLog "GPU throttling disabled"
fi;

if [ -e $gpu/max_pwrlevel ]; then
	write $gpu/max_pwrlevel "0"
	sendToLog "GPU max power level disabled"
fi;

if [ -e $gpu/force_no_nap ]; then
	write $gpu/force_no_nap "1"
	sendToLog "force_no_nap enabled"
fi;

if [ -e $gpu/bus_split ]; then
	write $gpu/bus_split "1"
	sendToLog "bus_split enabled"
fi;

if [ -e $gpu/force_bus_on ]; then
	write $gpu/force_bus_on "1"		
	sendToLog "force_bus_on enabled"
fi;

if [ -e $gpu/force_clk_on ]; then
	write $gpu/force_clk_on "1"		
	sendToLog "force_clk_on enabled"
fi;
	
if [ -e $gpu/force_rail_on ]; then
	write $gpu/force_rail_on "1"		
	sendToLog "force_rail_on enabled"
fi;

sendToLog "GPU is optimized..."
sendToLog "$divider";
}

gpuOptimizerPerformance() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

sendToLog "Optimizing GPU..."

# GPU related tweaks
if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
	gpu="/sys/class/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/*.gpu/devfreq/*.gpu" ]; then
	gpu="/sys/devices/platform/*.gpu/devfreq/*.gpu"
elif [ -d "/sys/devices/platform/gpusysfs" ]; then
	gpu="/sys/devices/platform/gpusysfs"
elif [ -d "/sys/devices/*.mali" ]; then
	gpu="/sys/devices/*.mali"
elif [ -d "/sys/devices/*.gpu" ]; then
	gpu="/sys/devices/*.gpu"
elif [ -d "/sys/devices/platform/mali.0" ]; then
	gpu="/sys/devices/platform/mali.0"
elif [ -d "/sys/devices/platform/mali-*.0" ]; then
	gpu="/sys/devices/platform/mali-*.0"
elif [ -d "/sys/module/mali/parameters" ]; then
	gpu="/sys/module/mali/parameters"
elif [ -d "/sys/class/misc/mali0" ]; then
	gpu="/sys/class/misc/mali0"
elif [ -d "/sys/kernel/gpu" ]; then
	gpu="/sys/kernel/gpu"
fi

if [ "$memTotal" -lt 3072 ]; then
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100/2));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100/2));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100/2));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100/2));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100/2));
	resetprop ro.hwui.texture_cache_flushrate 0.3
else 
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100));
	resetprop ro.hwui.texture_cache_flushrate 0.3
fi
sendToLog "Optimized GPU caches";

if [ -e /proc/gpufreq/gpufreq_limited_thermal_ignore ]; then
	write /proc/gpufreq/gpufreq_limited_thermal_ignore "1"		
	sendToLog "Disabled gpufreq thermal"
fi;

if [ -e /proc/mali/dvfs_enable ]; then
	write /proc/mali/dvfs_enable "1"		
	sendToLog "dvfs enabled"
fi;

if [ -e /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate ]; then
	write /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate "1"		
	sendToLog "Simple GPU algorithm enabled"
fi;

# Adreno idler
if [ -e /sys/module/adreno_idler/parameters/adreno_idler_active ]; then
	write /sys/module/adreno_idler/parameters/adreno_idler_active "N"
	write /sys/module/adreno_idler/parameters/adreno_idler_idleworkload "6000"
	write /sys/module/adreno_idler/parameters/adreno_idler_downdifferential "15"
	write /sys/module/adreno_idler/parameters/adreno_idler_idlewait "15"
	sendToLog "Disabled and tweaked adreno idler"
fi;

if [ -e $gpu/devfreq/adrenoboost ]; then
	write $gpu/devfreq/adrenoboost "2"
	sendToLog "Adreno boost is set to 2"
fi;

if [ -e $gpu/throttling ]; then
	write $gpu/throttling "0"
	sendToLog "GPU throttling disabled"
fi;

if [ -e $gpu/max_pwrlevel ]; then
	write $gpu/max_pwrlevel "0"
	sendToLog "GPU max power level disabled"
fi;

if [ -e $gpu/force_no_nap ]; then
	write $gpu/force_no_nap "1"
	sendToLog "force_no_nap enabled"
fi;

if [ -e $gpu/bus_split ]; then
	write $gpu/bus_split "0"
	sendToLog "bus_split disabled"
fi;

if [ -e $gpu/force_bus_on ]; then
	write $gpu/force_bus_on "1"		
	sendToLog "force_bus_on enabled"
fi;

if [ -e $gpu/force_clk_on ]; then
	write $gpu/force_clk_on "1"		
	sendToLog "force_clk_on enabled"
fi;
	
if [ -e $gpu/force_rail_on ]; then
	write $gpu/force_rail_on "1"		
	sendToLog "force_rail_on enabled"
fi;

sendToLog "GPU is optimized..."
sendToLog "$divider";
}

gpuOptimizerPowerSaving() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

sendToLog "Optimizing GPU..."

# GPU related tweaks
if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
	gpu="/sys/class/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0" ]; then
	gpu="/sys/devices/soc.0/*.qcom,kgsl-3d0/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/*.gpu/devfreq/*.gpu" ]; then
	gpu="/sys/devices/platform/*.gpu/devfreq/*.gpu"
elif [ -d "/sys/devices/platform/gpusysfs" ]; then
	gpu="/sys/devices/platform/gpusysfs"
elif [ -d "/sys/devices/*.mali" ]; then
	gpu="/sys/devices/*.mali"
elif [ -d "/sys/devices/*.gpu" ]; then
	gpu="/sys/devices/*.gpu"
elif [ -d "/sys/devices/platform/mali.0" ]; then
	gpu="/sys/devices/platform/mali.0"
elif [ -d "/sys/devices/platform/mali-*.0" ]; then
	gpu="/sys/devices/platform/mali-*.0"
elif [ -d "/sys/module/mali/parameters" ]; then
	gpu="/sys/module/mali/parameters"
elif [ -d "/sys/class/misc/mali0" ]; then
	gpu="/sys/class/misc/mali0"
elif [ -d "/sys/kernel/gpu" ]; then
	gpu="/sys/kernel/gpu"
fi

if [ "$memTotal" -lt 3072 ]; then
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100/2));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100/2));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100/2));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100/2));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100/2));
	resetprop ro.hwui.texture_cache_flushrate 0.3
else 
	resetprop ro.hwui.texture_cache_size $((memTotal*10/100));
	resetprop ro.hwui.layer_cache_size $((memTotal*5/100));
	resetprop ro.hwui.path_cache_size $((memTotal*2/100));
	resetprop ro.hwui.r_buffer_cache_size $((memTotal/100));
	resetprop ro.hwui.drop_shadow_cache_size $((memTotal/100));
	resetprop ro.hwui.texture_cache_flushrate 0.3
fi
sendToLog "Optimized GPU caches";


if [ -e /proc/gpufreq/gpufreq_limited_thermal_ignore ]; then
	write /proc/gpufreq/gpufreq_limited_thermal_ignore "1"
	sendToLog "Disabled gpufreq thermal"
fi;

if [ -e /proc/mali/dvfs_enable ]; then
	write /proc/mali/dvfs_enable "1"
	sendToLog "dvfs enabled"
fi;

if [ -e /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate ]; then
	write /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate "1"
	sendToLog "Simple GPU algorithm enabled"
fi;

# Adreno idler
if [ -e /sys/module/adreno_idler/parameters/adreno_idler_active ]; then
	write /sys/module/adreno_idler/parameters/adreno_idler_active "Y"
	write /sys/module/adreno_idler/parameters/adreno_idler_idleworkload "10000"
	write /sys/module/adreno_idler/parameters/adreno_idler_downdifferential "35"
	write /sys/module/adreno_idler/parameters/adreno_idler_idlewait "25"
	sendToLog "Enabled and tweaked adreno idler"
fi;

if [ -e $gpu/devfreq/adrenoboost ]; then
	write $gpu/devfreq/adrenoboost "0"
	sendToLog "Adreno boost is set to 0"
fi;

if [ -e $gpu/throttling ]; then
	write $gpu/throttling "0"
	sendToLog "GPU throttling disabled"
fi;

if [ -e $gpu/max_pwrlevel ]; then
	write $gpu/max_pwrlevel "0"
	sendToLog "GPU max power level disabled"
fi;

if [ -e $gpu/force_no_nap ]; then
	write $gpu/force_no_nap "0"
	sendToLog "force_no_nap disabled"
fi;

if [ -e $gpu/bus_split ]; then
	write $gpu/bus_split "1"
	sendToLog "bus_split enabled"
fi;

if [ -e $gpu/force_bus_on ]; then
	write $gpu/force_bus_on "0"
	sendToLog "force_bus_on disabled"
fi;

if [ -e $gpu/force_clk_on ]; then
	write $gpu/force_clk_on "0"
	sendToLog "force_clk_on disabled"
fi;

if [ -e $gpu/force_rail_on ]; then
	write $gpu/force_rail_on "0"
	sendToLog "force_rail_on disabled"
fi;

sendToLog "GPU is optimized..."
sendToLog "$divider";
}

optimizeBuffers() {
sendToLog "Changing GPU buffer count"

setprop debug.egl.buffcount 4

sendToLog "GPU buffer count set to 4"
sendToLog "$divider";
}

renderOpenglesUsingGpu() {
sendToLog "Setting GPU to render OpenGLES..."

setprop debug.egl.hw 1

sendToLog "GPU successfully set up to render OpenGLES"
sendToLog "$divider";
}

useOpenglSkia() {
sendToLog "Changing app rendering to skiagl..."

setprop debug.hwui.renderer skiagl

sendToLog "Rendering chaned to skiagl"
sendToLog "$divider";
}

enableIoStats() {
sendToLog "Enabling I/O Stats..."

blocks=$(ls -d /sys/block/*)

for i in $blocks;
	do
		write "$i/queue/iostats" "1"
		sendToLog "iostats=1 in $i"
done

sendToLog "I/O Stats enabled"
sendToLog "$divider";
}

disableIoStats() {
sendToLog "Disabling I/O Stats..."

blocks=$(ls -d /sys/block/*)

for i in $blocks;
	do
		write "$i/queue/iostats" "0"
		sendToLog "iostats=0 in $i"
done

sendToLog "I/O Stats disabled"
sendToLog "$divider";
}

sdTweak() {

# Storage blocks eMMC
DEV_MMCBLK0="/dev/block/mmcblk0";
MMCBLK0="/sys/block/mmcblk0";
MMCBLK0_READ_AHEAD_KB="$MMCBLK0/queue/read_ahead_kb";
DEV_MMCBLK1="/dev/block/mmcblk1";
MMCBLK1="/sys/block/mmcblk1";
MMCBLK1_READ_AHEAD_KB="$MMCBLK1/queue/read_ahead_kb";

# Storage blocks UFS
SDA="/sys/block/sda";

sendToLog "Activating SD speed tweak";

if [ -e $SDA ] && [ -e $MMCBLK0 ]; then

	external_totalSize=$(blockdev --getsize64 $DEV_MMCBLK0);

	if [ "$external_totalSize" -lt 8589934592 ]; then
		extReadAhead="256";
	elif [ "$external_totalSize" -ge 8589934592 ] && [ "$external_totalSize" -lt 17179869184 ]; then
		extReadAhead="512";
	elif [ "$external_totalSize" -ge 17179869184 ] && [ "$external_totalSize" -lt 34359738368 ]; then
		extReadAhead="1024";
	elif [ "$external_totalSize" -ge 34359738368 ]; then
		extReadAhead="2048";
	else
		extReadAhead="256";
	fi

	sendToLog "Your SD Card size is: $((external_totalSize/1024/1024/1024))kb";
	sendToLog "Read Ahead based on SD Card size: $((extReadAhead))kb";
	write $MMCBLK0_READ_AHEAD_KB $extReadAhead;
	sendToLog "SD speed tweak is activated";

elif [ -e $SDA ] && [ -e $MMCBLK1 ]; then

	external_totalSize=$(blockdev --getsize64 $DEV_MMCBLK1);

	if [ "$external_totalSize" -lt 8589934592 ]; then
		extReadAhead="256";
	elif [ "$external_totalSize" -ge 8589934592 ] && [ "$external_totalSize" -lt 17179869184 ]; then
		extReadAhead="512";
	elif [ "$external_totalSize" -ge 17179869184 ] && [ "$external_totalSize" -lt 34359738368 ]; then
		extReadAhead="1024";
	elif [ "$external_totalSize" -ge 34359738368 ]; then
		extReadAhead="2048";
	else
		extReadAhead="256";
	fi

	sendToLog "Your SD Card size is: $((external_totalSize/1024/1024/1024))kb";
	sendToLog "Read Ahead based on SD Card size: $((extReadAhead))kb";
	write $MMCBLK1_READ_AHEAD_KB $extReadAhead;
	sendToLog "SD speed tweak is activated";

else
	sendToLog "SD card not available or not supported...";

fi
sendToLog "$divider";
}
 
ioBlocksOptimizationBalanced() {
sendToLog "Activating balanced I/O blocks optimization..."

blocks=$(ls -d /sys/block/*)

for i in $blocks;
	do
	if [ -e "$i/queue/add_random" ]; then
		write "$i/queue/add_random" "0"
		sendToLog "add_random=0 in $i"
	fi
	
	if [ -e "$i/queue/nomerges" ]; then
		write "$i/queue/nomerges" "0"
		sendToLog "nomerges=0 in $i"
	fi
		
	if [ -e "$i/queue/rq_affinity" ]; then
		write "$i/queue/rq_affinity" "1"
		sendToLog "rq_affinity=1 in $i"
	fi
	
	if [ -e "$i/queue/nr_requests" ]; then
		write "$i/queue/nr_requests" "128"
		sendToLog "nr_requests=128 in $i"
	fi
	
	if [ -e "$i/queue/read_ahead_kb" ]; then
		write "$i/queue/read_ahead_kb" "1024"
		sendToLog "read_ahead_kb=1024 in $i"
	fi
	
	if [ -e "$i/queue/write_cache" ]; then
		write "$i/queue/write_cache" "write through"
		sendToLog "write_cache=write through in $i"
	fi
done

# MMC CRC disabled
removable=/sys/module/mmc_core/parameters/removable
if [ -e $removable ]; then
	write $removable "N"
	sendToLog "CRC Checks disabled $removable"
fi;

crc=/sys/module/mmc_core/parameters/crc
if [ -e $crc ]; then
	write $crc "N"
	sendToLog "CRC Checks disabled $crc"
fi;

use_spi_crc=/sys/module/mmc_core/parameters/use_spi_crc
if [ -e $use_spi_crc ]; then
	write $use_spi_crc "N"
	sendToLog "CRC Checks disabled $use_spi_crc"
fi;

sendToLog "Balanced I/O blocks optimization activated"
sendToLog "$divider";
}

ioBlocksOptimizationPerformance() {
sendToLog "Activating performance I/O blocks optimization..."

blocks=$(ls -d /sys/block/*)

for i in $blocks;
	do
	if [ -e "$i/queue/add_random" ]; then
		write "$i/queue/add_random" "0"
		sendToLog "add_random=0 in $i"
	fi
	
	if [ -e "$i/queue/nomerges" ]; then
		write "$i/queue/nomerges" "0"
		sendToLog "nomerges=0 in $i"
	fi
		
	if [ -e "$i/queue/rq_affinity" ]; then
		write "$i/queue/rq_affinity" "2"
		sendToLog "rq_affinity=2 in $i"
	fi
	
	if [ -e "$i/queue/nr_requests" ]; then
		write "$i/queue/nr_requests" "256"
		sendToLog "nr_requests=256 in $i"
	fi
	
	if [ -e "$i/queue/read_ahead_kb" ]; then
		write "$i/queue/read_ahead_kb" "2048"
		sendToLog "read_ahead_kb=2048 in $i"
	fi
	
	if [ -e "$i/queue/write_cache" ]; then
		write "$i/queue/write_cache" "write through"
		sendToLog "write_cache=write through in $i"
	fi
done

# MMC CRC disabled
removable=/sys/module/mmc_core/parameters/removable
if [ -e $removable ]; then
	write $removable "N"
	sendToLog "CRC Checks disabled $removable"
fi;

crc=/sys/module/mmc_core/parameters/crc
if [ -e $crc ]; then
	write $crc "N"
	sendToLog "CRC Checks disabled $crc"
fi;

use_spi_crc=/sys/module/mmc_core/parameters/use_spi_crc
if [ -e $use_spi_crc ]; then
	write $use_spi_crc "N"
	sendToLog "CRC Checks disabled $use_spi_crc"
fi;

sendToLog "Performance I/O blocks optimization activated"
sendToLog "$divider";
}

ioBlocksOptimizationPowerSaving() {
sendToLog "Activating power saving I/O blocks optimization..."

blocks=$(ls -d /sys/block/*)

for i in $blocks;
	do
	if [ -e "$i/queue/add_random" ]; then
		write "$i/queue/add_random" "0"
		sendToLog "add_random=0 in $i"
	fi
	
	if [ -e "$i/queue/nomerges" ]; then
		write "$i/queue/nomerges" "0"
		sendToLog "nomerges=0 in $i"
	fi
		
	if [ -e "$i/queue/rq_affinity" ]; then
		write "$i/queue/rq_affinity" "0"
		sendToLog "rq_affinity=0 in $i"
	fi
	
	if [ -e "$i/queue/nr_requests" ]; then
		write "$i/queue/nr_requests" "64"
		sendToLog "nr_requests=64 in $i"
	fi
	
	if [ -e "$i/queue/read_ahead_kb" ]; then
		write "$i/queue/read_ahead_kb" "256"
		sendToLog "read_ahead_kb=256 in $i"
	fi
	
	if [ -e "$i/queue/write_cache" ]; then
		write "$i/queue/write_cache" "write through"
		sendToLog "write_cache=write through in $i"
	fi
done

# MMC CRC disabled
removable=/sys/module/mmc_core/parameters/removable
if [ -e $removable ]; then
	write $removable "N"
	sendToLog "CRC Checks disabled $removable"
fi;

crc=/sys/module/mmc_core/parameters/crc
if [ -e $crc ]; then
	write $crc "N"
	sendToLog "CRC Checks disabled $crc"
fi;

use_spi_crc=/sys/module/mmc_core/parameters/use_spi_crc
if [ -e $use_spi_crc ]; then
	write $use_spi_crc "N"
	sendToLog "CRC Checks disabled $use_spi_crc"
fi;

sendToLog "Power saving I/O blocks optimization activated"
sendToLog "$divider";
}

ioExtendedQueue() {
sendToLog "Activating I/O extend queue..."

mmc=$(ls -d /sys/block/mmc*);
sd=$(ls -d /sys/block/sd*);

for i in $mmc $sd
	do
	if [ -e "$i" ]; then
		write "$i/queue/nr_requests" "512"
		sendToLog "nr_requests=512 in $i"
	fi
done

sendToLog "I/O extend queue is activated"
sendToLog "$divider";
}

dnsOptimizationCloudFlare() {
sendToLog "Activating DNS optimization..."

iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to 1.0.0.1:53
iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 1.0.0.1:53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to 1.1.1.1:53
iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to 1.1.1.1:53
ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to  2606:4700:4700::1111
ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to  2606:4700:4700::1001
ip6tables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to  2606:4700:4700::1111
ip6tables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to  2606:4700:4700::1001

setprop net.eth0.dns1 1.1.1.1
setprop net.eth0.dns2 1.0.0.1
setprop net.dns1 1.1.1.1
setprop net.dns2 1.0.0.1
setprop net.ppp0.dns1 1.1.1.1
setprop net.ppp0.dns2 1.0.0.1
setprop net.rmnet0.dns1 1.1.1.1
setprop net.rmnet0.dns2 1.0.0.1
setprop net.rmnet1.dns1 1.1.1.1
setprop net.rmnet1.dns2 1.0.0.1
setprop net.rmnet2.dns1 1.1.1.1
setprop net.rmnet2.dns2 1.0.0.1
setprop net.pdpbr1.dns1 1.1.1.1
setprop net.pdpbr1.dns2 1.0.0.1
setprop net.wlan0.dns1 1.1.1.1
setprop net.wlan0.dns2 1.0.0.1
setprop 2606:4700:4700::1111
setprop 2606:4700:4700::1001

sendToLog "Changing DNS to CloudFlare"

sendToLog "DNS optimization is activated"
sendToLog "$divider";
}

dnsOptimizationGooglePublic() {
sendToLog "Activating DNS optimization..."

iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to 8.8.8.8:53
iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 8.8.4.4:53
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to 8.8.8.8:53
iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to 8.8.4.4:53
ip6tables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to 2001:4860:4860:8888
ip6tables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to 2001:4860:4860:8888
ip6tables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to 2001:4860:4860:8844
ip6tables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 2001:4860:4860:8844

setprop net.eth0.dns1 8.8.8.8
setprop net.eth0.dns2 8.8.4.4
setprop net.dns1 8.8.8.8
setprop net.dns2 8.8.4.4
setprop net.ppp0.dns1 8.8.8.8
setprop net.ppp0.dns2 8.8.4.4
setprop net.rmnet0.dns1 8.8.8.8
setprop net.rmnet0.dns2 8.8.4.4
setprop net.rmnet1.dns1 8.8.8.8
setprop net.rmnet1.dns2 8.8.4.4
setprop net.rmnet2.dns1 8.8.8.8
setprop net.rmnet2.dns2 8.8.4.4
setprop net.pdpbr1.dns1 8.8.8.8
setprop net.pdpbr1.dns2 8.8.4.4
setprop net.wlan0.dns1 8.8.8.8
setprop net.wlan0.dns2 8.8.4.4
setprop 2001:4860:4860::8888
setprop 2001:4860:4860::8844

sendToLog "Changing DNS to Google Public"

sendToLog "DNS optimization is activated"
sendToLog "$divider";
}

netBuffersBig() {
sendToLog "Activating big net buffers..."

# Define TCP buffer sizes for various networks
# ReadMin, ReadInitial, ReadMax, WriteMin, WriteInitial, WriteMax
setprop net.tcp.buffersize.default 6144,87380,1048576,6144,87380,524288
setprop net.tcp.buffersize.wifi 524288,1048576,2097152,524288,1048576,2097152
setprop net.tcp.buffersize.umts 6144,87380,1048576,6144,87380,524288
setprop net.tcp.buffersize.gprs 6144,87380,1048576,6144,87380,524288
setprop net.tcp.buffersize.edge 6144,87380,524288,6144,16384,262144
setprop net.tcp.buffersize.hspa 6144,87380,524288,6144,16384,262144
setprop net.tcp.buffersize.lte 524288,1048576,2097152,524288,1048576,2097152
setprop net.tcp.buffersize.hsdpa 6144,87380,1048576,6144,87380,1048576
setprop net.tcp.buffersize.evdo_b 6144,87380,1048576,6144,87380,1048576

sendToLog "Big net buffers activated"
sendToLog "$divider";
}

netBuffersSmall() {
sendToLog "Activating small net buffers..."

# Define TCP buffer sizes for various networks
# ReadMin, ReadInitial, ReadMax, WriteMin, WriteInitial, WriteMax
setprop net.tcp.buffersize.hspa 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.umts 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.edge 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.gprs 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.hsdpa 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.wifi 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.evdo_b 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.lte 4096,32768,65536,4096,32768,65536
setprop net.tcp.buffersize.default 4096,32768,12582912,4096,32768,12582912

sendToLog "Small net buffers activated"
sendToLog "$divider";
}

netSpeedPlus() {
sendToLog "Activating Net Speed+..."


net=$(ls /sys/class/net);
for i in $net; do
	if [ -e /sys/class/net/"$i"/tx_queue_len ]; then
		write /sys/class/net/"$i"/tx_queue_len "128"
		sendToLog "tx_queue_len=128 in $i";
	fi
done

#for i in $(ls /sys/class/net); do
#echo "1500" > /sys/class/net/"$i"/mtu
#echo "mtu=1500 in $i" >> $LOG;
#done

sendToLog "Net Speed+ activated"
sendToLog "$divider";
}

netTcpTweaks() {
sendToLog "Activating TCP tweak..."

#echo "128" > /proc/sys/net/core/netdev_max_backlog
#echo "0" > /proc/sys/net/core/netdev_tstamp_prequeue
#echo "0" > /proc/sys/net/ipv4/cipso_cache_bucket_size
#echo "0" > /proc/sys/net/ipv4/cipso_cache_enable
#echo "0" > /proc/sys/net/ipv4/cipso_rbm_strictvalid
#echo "0" > /proc/sys/net/ipv4/igmp_link_local_mcast_reports
#echo "24" > /proc/sys/net/ipv4/ipfrag_time
#echo "1" > /proc/sys/net/ipv4/tcp_ecn
#echo "0" > /proc/sys/net/ipv4/tcp_fwmark_accept
#echo "320" > /proc/sys/net/ipv4/tcp_keepalive_intvl
#echo "21600" > /proc/sys/net/ipv4/tcp_keepalive_time
#echo "1" > /proc/sys/net/ipv4/tcp_no_metrics_save
#echo "1800" > /proc/sys/net/ipv4/tcp_probe_interval
#echo "0" > /proc/sys/net/ipv4/tcp_slow_start_after_idle
#echo "48" > /proc/sys/net/ipv6/ip6frag_time

echo "0" > /proc/sys/net/ipv4/conf/default/secure_redirects
echo "0" > /proc/sys/net/ipv4/conf/default/accept_redirects
echo "0" > /proc/sys/net/ipv4/conf/default/accept_source_route
echo "0" > /proc/sys/net/ipv4/conf/all/secure_redirects
echo "0" > /proc/sys/net/ipv4/conf/all/accept_redirects
echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route
echo "0" > /proc/sys/net/ipv4/ip_forward
echo "0" > /proc/sys/net/ipv4/ip_dynaddr
echo "0" > /proc/sys/net/ipv4/ip_no_pmtu_disc
echo "0" > /proc/sys/net/ipv4/tcp_ecn
echo "0" > /proc/sys/net/ipv4/tcp_timestamps
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse
echo "1" > /proc/sys/net/ipv4/tcp_fack
echo "1" > /proc/sys/net/ipv4/tcp_sack
echo "1" > /proc/sys/net/ipv4/tcp_dsack
echo "1" > /proc/sys/net/ipv4/tcp_rfc1337
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling
echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf
echo "1" > /proc/sys/net/ipv4/tcp_no_metrics_save
echo "2" > /proc/sys/net/ipv4/tcp_synack_retries
echo "2" > /proc/sys/net/ipv4/tcp_syn_retries
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes
echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout
echo "1800" > /proc/sys/net/ipv4/tcp_keepalive_time
echo "261120" > /proc/sys/net/core/rmem_max
echo "261120" > /proc/sys/net/core/wmem_max
echo "261120" > /proc/sys/net/core/rmem_default
echo "261120" > /proc/sys/net/core/wmem_default

sendToLog "TCP tweak activated"
sendToLog "$divider";
}

rilTweaks() {
sendToLog "Activating ril tweaks..."

resetprop ro.ril.gprsclass 12
sendToLog "GPRS Class changed to 12"

resetprop ro.ril.hsdpa.category 28
sendToLog "hsdpa category changed to 28"

resetprop ro.ril.hsupa.category 7
sendToLog "hsupa category changed to 7"

resetprop ro.telephony.call_ring.delay 1500
sendToLog "RING/CRING event delay reduced to 1.5sec"

resetprop ro.telephony.call_ring.multiple false
sendToLog "Ril sends only one RIL_UNSOL_CALL_RING, so set call_ring.multiple to false"

sendToLog "Ril tweaks are activated"
sendToLog "$divider";
}

disableDebugging() {
sendToLog "Powerful logging disable started..."

find /sys -name debug_mask |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name debug |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name debug_enabled |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name debug_level |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name edac_mc_log_ce |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name edac_mc_log_ue |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name enable_event_log |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name log_ecn_error |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

find /sys -name snapshot_crashdumper |
while read -r fileName
	do
		write "$fileName" "0"
		sendToLog "Disabled debugging for $fileName"  
done

console_suspend=/sys/module/printk/parameters/console_suspend
if [ -e $console_suspend ]; then
	write $console_suspend "Y"
	sendToLog "Console suspended"
fi;

log_mode=/sys/module/logger/parameters/log_mode
if [ -e $log_mode ]; then
	write $log_mode "2"
	sendToLog "Logger disabled"
fi;

debug_enabled=/sys/kernel/debug/debug_enabled
if [ -e $debug_enabled ]; then
	write $debug_enabled "N"
	sendToLog "Disabled kernel debugging"
fi;

exception_trace=/proc/sys/debug/exception-trace
if [ -e "$exception_trace" ]; then
	write $exception_trace "0"
	sendToLog "Disabled exception-trace debugger"
fi;

mali_debug_level=/sys/module/mali/parameters/mali_debug_level
if [ -e $mali_debug_level ]; then
	write $mali_debug_level "0"
	sendToLog "Disabled mali GPU debugging"
fi;

block_dump=/proc/sys/vm/block_dump
if [ -e $block_dump ]; then
	write $block_dump "0"
	sendToLog "Disabled I/O block debugging"
fi;

mballoc_debug=/sys/module/ext4/parameters/mballoc_debug
if [ -e $mballoc_debug ]; then
	write $mballoc_debug "0"
	sendToLog "Disabled ext4 runtime debugging"
fi;

logger_mode=/sys/kernel/logger_mode/logger_mode
if [ -e $logger_mode ]; then
	write $logger_mode "0"
	sendToLog "Disabled $logger_mode"
fi;

log_enabled=/sys/module/logger/parameters/log_enabled
if [ -e $log_enabled ]; then
	write $log_enabled "0"
	sendToLog "Disabled $log_enabled"
fi;

logger_enabled=/sys/module/logger/parameters/enabled
if [ -e $logger_enabled ]; then
	write $logger_enabled "0"
	sendToLog "Disabled $logger_enabled"
fi;

compat_log=/proc/sys/kernel/compat-log
if [ -e $compat_log ]; then
	write $compat_log "0"
	sendToLog "Compat logging disabled"
fi;

disable_ertm=/sys/module/bluetooth/parameters/disable_ertm
if [ -e $disable_ertm ]; then
	write $disable_ertm "0"
	sendToLog "Bluetooth ertm disabled"
fi;

disable_esco=/sys/module/bluetooth/parameters/disable_esco
if [ -e $disable_esco ]; then
	write $disable_esco "0"
	sendToLog "Bluetooth esco is disabled"
fi;

sendToLog "Logging disabled..."
sendToLog "$divider";
}

disableKernelPanic() {
sendToLog "Disabling kernel panic..."

	sysctl -e -w vm.panic_on_oom=0
	sysctl -e -w kernel.panic_on_oops=0
	sysctl -e -w kernel.panic=0
	sysctl -e -w kernel.panic_on_warn=0

sendToLog "Kernel panic disabled"
sendToLog "$divider";
}

disableMultitaskingLimitations() {
sendToLog "Disabling multitasking limitations..."

setprop MIN_HIDDEN_APPS false
sendToLog "MIN_HIDDEN_APPS=false"

setprop ACTIVITY_INACTIVE_RESET_TIME false
sendToLog "ACTIVITY_INACTIVE_RESET_TIME=false"

setprop MIN_RECENT_TASKS false
sendToLog "MIN_RECENT_TASKS=false"

setprop PROC_START_TIMEOUT false
sendToLog "PROC_START_TIMEOUT=false"

setprop CPU_MIN_CHECK_DURATION false
sendToLog "CPU_MIN_CHECK_DURATION=false"

setprop GC_TIMEOUT false
sendToLog "GC_TIMEOUT=false"

setprop SERVICE_TIMEOUT false
sendToLog "SERVICE_TIMEOUT=false"

setprop MIN_CRASH_INTERVAL false
sendToLog "MIN_CRASH_INTERVAL=false"

setprop ENFORCE_PROCESS_LIMIT false
sendToLog "ENFORCE_PROCESS_LIMIT=false"

sendToLog "Multitasking limitations disabled"
sendToLog "$divider";
}

lowRamFlagDisabled() {
sendToLog "Disabling low RAM flag..."

resetprop ro.config.low_ram false

sendToLog "Low RAM flag disabled"
sendToLog "$divider";
}

lowRamFlagEnabled() {
sendToLog "Enabling low RAM flag..."

resetprop ro.config.low_ram true

sendToLog "Low RAM flag enabled"
sendToLog "$divider";
}

oomKillerDisabled() {
sendToLog "Disabled OOM killer..."

oom_kill_allocating_task=/proc/sys/vm/oom_kill_allocating_task
if [ -e $oom_kill_allocating_task ]; then
	write $oom_kill_allocating_task "0"
fi;

sendToLog "OOM killer disabled"
sendToLog "$divider";
}

oomKillerEnabled() {
sendToLog "Enabling OOM killer..."

oom_kill_allocating_task=/proc/sys/vm/oom_kill_allocating_task
if [ -e $oom_kill_allocating_task ]; then
	write $oom_kill_allocating_task "1"
fi;

sendToLog "OOM killer enabled"
sendToLog "$divider";
}

ramManagerBalanced() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

fa=$(((memTotal*2/100)*1024/4));
va=$(((memTotal*3/100)*1024/4));
ss=$(((memTotal*5/100)*1024/4));
ha=$(((memTotal*7/100)*1024/4));
cp=$(((memTotal*9/100)*1024/4));
ea=$(((memTotal*11/100)*1024/4));
minFree="$fa,$va,$ss,$ha,$cp,$ea";

# Higher values of oom_adj are more likely
# to be killed by the kernel's oom killer.
# The current foreground app has a oom_adj of 0
adj="0,112,224,408,824,1000";

# If you set this to lower than 1024KB, your system will
# become subtly broken, and prone to deadlock under high loads, we don't allow it below 2048kb
mfk=$((memTotal*4));

if [ "$mfk" -le "4096" ]; then
	mfk=4096;
fi;

# Extra free kbytes should not be bigger than min free kbytes
efk=$((mfk/2));

if [ "$efk" -le "2048" ]; then
	efk=2048;
fi;

# Background app limit per ram size
if [ "$memTotal" -le "1024" ]; then
	backgroundAppLimit="24";
elif [ "$memTotal" -le "2048" ]; then
	backgroundAppLimit="28";
elif [ "$memTotal" -le "3072" ]; then
	backgroundAppLimit="30";
elif [ "$memTotal" -le "4096" ]; then
	backgroundAppLimit="36";
else
	backgroundAppLimit="42";
fi;

# Set 1 to reclaim resources quickly when needed.
fastRun="0";

oomReaper="1";
adaptiveLmk="0";

# How much memory of swap will be counted as free
fudgeSwap="1024";


sendToLog "Enabling balanced RAM manager profile"

sync
sysctl -w vm.drop_caches=3;

resetprop ro.sys.fw.bg_apps_limit $backgroundAppLimit;
resetprop ro.vendor.qti.sys.fw.bg_apps_limit $backgroundAppLimit;
sendToLog "Background app limit=$backgroundAppLimit"

parameter_adj=/sys/module/lowmemorykiller/parameters/adj;
if [ -e $parameter_adj ]; then
	write $parameter_adj "$adj"
	sendToLog "adj=$adj"
fi;

parameter_oom_reaper=/sys/module/lowmemorykiller/parameters/oom_reaper;
if [ -e $parameter_oom_reaper ]; then
	write $parameter_oom_reaper "$oomReaper"
	sendToLog "oom_reaper=$oomReaper"
fi;

parameter_lmk_fast_run=/sys/module/lowmemorykiller/parameters/lmk_fast_run;
if [ -e $parameter_lmk_fast_run ]; then
	write $parameter_lmk_fast_run "$fastRun"
	sendToLog "lmk_fast_run=$fastRun"
fi;

parameter_adaptive_lmk=/sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
if [ -e $parameter_adaptive_lmk ]; then
	write $parameter_adaptive_lmk "$adaptiveLmk"
	setprop lmk.autocalc false;
	sendToLog "adaptive_lmk=$adaptiveLmk"
fi;

parameter_fudge_swap=/sys/module/lowmemorykiller/parameters/fudgeswap;
if [ -e $parameter_fudge_swap ]; then
	write $parameter_fudge_swap "$fudgeSwap"
	sendToLog "fudge_swap=$fudgeSwap"
fi;

parameter_minfree=/sys/module/lowmemorykiller/parameters/minfree;
if [ -e $parameter_minfree ]; then
	write $parameter_minfree "$minFree"
	sendToLog "minfree=$minFree"
fi;

parameter_min_free_kbytes=/proc/sys/vm/min_free_kbytes;
if [ -e $parameter_min_free_kbytes ]; then
	write $parameter_min_free_kbytes "$mfk"
	sendToLog "min_free_kbytes=$mfk"
fi;

parameter_extra_free_kbytes=/proc/sys/vm/extra_free_kbytes;
if [ -e $parameter_extra_free_kbytes ]; then
	write $parameter_extra_free_kbytes "$efk"
	sendToLog "extra_free_kbytes=$efk"
fi;

sendToLog "Balanced RAM manager profile for $((memTotal))mb devices successfully applied"
sendToLog "$divider";
}

ramManagerGaming() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

fa=$(((memTotal*3/100)*1024/4));
va=$(((memTotal*4/100)*1024/4));
ss=$(((memTotal*6/100)*1024/4));
ha=$(((memTotal*7/100)*1024/4));
cp=$(((memTotal*11/100)*1024/4));
ea=$(((memTotal*15/100)*1024/4));
minFree="$fa,$va,$ss,$ha,$cp,$ea";

# Higher values of oom_adj are more likely
# to be killed by the kernel's oom killer.
# The current foreground app has a oom_adj of 0
adj="0,112,224,408,824,1000";

# If you set this to lower than 1024KB, your system will
# become subtly broken, and prone to deadlock under high loads, we don't allow it below 2048kb
mfk=$((memTotal*4));

if [ "$mfk" -le "4096" ]; then
mfk=4096;
fi;

# Extra free kbytes should not be bigger than min free kbytes
efk=$((mfk/2));

if [ "$efk" -le "2048" ]; then
	efk=2048;
fi;

# Background app limit per ram size
if [ "$memTotal" -le "1024" ]; then
	backgroundAppLimit="18";
elif [ "$memTotal" -le "2048" ]; then
	backgroundAppLimit="22";
elif [ "$memTotal" -le "3072" ]; then
	backgroundAppLimit="26";
elif [ "$memTotal" -le "4096" ]; then
	backgroundAppLimit="30";
else
	backgroundAppLimit="42";
fi;

# Set 1 to reclaim resources quickly when needed.
fastRun="1";

oomReaper="1";
adaptiveLmk="0";

# How much memory of swap will be counted as free
fudgeSwap="1024";


sendToLog "Enabling gaming RAM manager profile"

sync
sysctl -w vm.drop_caches=3;

resetprop ro.sys.fw.bg_apps_limit $backgroundAppLimit;
resetprop ro.vendor.qti.sys.fw.bg_apps_limit $backgroundAppLimit;
sendToLog "Background app limit=$backgroundAppLimit"

parameter_adj=/sys/module/lowmemorykiller/parameters/adj;
if [ -e $parameter_adj ]; then
	write $parameter_adj "$adj"
	sendToLog "adj=$adj"
fi;

parameter_oom_reaper=/sys/module/lowmemorykiller/parameters/oom_reaper;
if [ -e $parameter_oom_reaper ]; then
	write $parameter_oom_reaper "$oomReaper"
	sendToLog "oom_reaper=$oomReaper"
fi;

parameter_lmk_fast_run=/sys/module/lowmemorykiller/parameters/lmk_fast_run;
if [ -e $parameter_lmk_fast_run ]; then
	write $parameter_lmk_fast_run "$fastRun"
	sendToLog "lmk_fast_run=$fastRun"
fi;

parameter_adaptive_lmk=/sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
if [ -e $parameter_adaptive_lmk ]; then
	write $parameter_adaptive_lmk "$adaptiveLmk"
	setprop lmk.autocalc false;
	sendToLog "adaptive_lmk=$adaptiveLmk"
fi;

parameter_fudge_swap=/sys/module/lowmemorykiller/parameters/fudgeswap;
if [ -e $parameter_fudge_swap ]; then
	write $parameter_fudge_swap "$fudgeSwap"
	sendToLog "fudge_swap=$fudgeSwap"
fi;

parameter_minfree=/sys/module/lowmemorykiller/parameters/minfree;
if [ -e $parameter_minfree ]; then
	write $parameter_minfree "$minFree"
	sendToLog "minfree=$minFree"
fi;

parameter_min_free_kbytes=/proc/sys/vm/min_free_kbytes;
if [ -e $parameter_min_free_kbytes ]; then
	write $parameter_min_free_kbytes "$mfk"
	sendToLog "min_free_kbytes=$mfk"
fi;

parameter_extra_free_kbytes=/proc/sys/vm/extra_free_kbytes;
if [ -e $parameter_extra_free_kbytes ]; then
	write $parameter_extra_free_kbytes "$efk"
	sendToLog "extra_free_kbytes=$efk"
fi;

sendToLog "Gaming RAM manager profile for $((memTotal))mb devices successfully applied"
sendToLog "$divider";
}

ramManagerMultitasking() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

fa=$(((memTotal*2/100)*1024/4));
va=$(((memTotal*3/100)*1024/4));
ss=$(((memTotal*5/100)*1024/4));
ha=$(((memTotal*6/100)*1024/4));
cp=$(((memTotal*9/100)*1024/4));
ea=$(((memTotal*11/100)*1024/4));
minFree="$fa,$va,$ss,$ha,$cp,$ea";

# Higher values of oom_adj are more likely
# to be killed by the kernel's oom killer.
# The current foreground app has a oom_adj of 0
adj="0,112,224,408,824,1000";

# If you set this to lower than 1024KB, your system will
# become subtly broken, and prone to deadlock under high loads, we don't allow it below 2048kb
mfk=$((memTotal*4));

if [ "$mfk" -le "4096" ]; then
mfk=4096;
fi;

# Extra free kbytes should not be bigger than min free kbytes
efk=$((mfk/2));

if [ "$efk" -le "2048" ]; then
	efk=2048;
fi;

# Background app limit per ram size
if [ "$memTotal" -le "1024" ]; then
	backgroundAppLimit="25";
elif [ "$memTotal" -le "2048" ]; then
	backgroundAppLimit="30";
elif [ "$memTotal" -le "3072" ]; then
	backgroundAppLimit="36";
elif [ "$memTotal" -le "4096" ]; then
	backgroundAppLimit="42";
else
	backgroundAppLimit="44";
fi;

# Set 1 to reclaim resources quickly when needed.
fastRun="0";

oomReaper="1";
adaptiveLmk="0";

# How much memory of swap will be counted as free
fudgeSwap="1024";


sendToLog "Enabling multitasking RAM manager profile"

sync
sysctl -w vm.drop_caches=3;

resetprop ro.sys.fw.bg_apps_limit $backgroundAppLimit;
resetprop ro.vendor.qti.sys.fw.bg_apps_limit $backgroundAppLimit;
sendToLog "Background app limit=$backgroundAppLimit"

parameter_adj=/sys/module/lowmemorykiller/parameters/adj;
if [ -e $parameter_adj ]; then
	write $parameter_adj "$adj"
	sendToLog "adj=$adj"
fi;

parameter_oom_reaper=/sys/module/lowmemorykiller/parameters/oom_reaper;
if [ -e $parameter_oom_reaper ]; then
	write $parameter_oom_reaper "$oomReaper"
	sendToLog "oom_reaper=$oomReaper"
fi;

parameter_lmk_fast_run=/sys/module/lowmemorykiller/parameters/lmk_fast_run;
if [ -e $parameter_lmk_fast_run ]; then
	write $parameter_lmk_fast_run "$fastRun"
	sendToLog "lmk_fast_run=$fastRun"
fi;

parameter_adaptive_lmk=/sys/module/lowmemorykiller/parameters/enable_adaptive_lmk;
if [ -e $parameter_adaptive_lmk ]; then
	write $parameter_adaptive_lmk "$adaptiveLmk"
	setprop lmk.autocalc false;
	sendToLog "adaptive_lmk=$adaptiveLmk"
fi;

parameter_fudge_swap=/sys/module/lowmemorykiller/parameters/fudgeswap;
if [ -e $parameter_fudge_swap ]; then
	write $parameter_fudge_swap "$fudgeSwap"
	sendToLog "fudge_swap=$fudgeSwap"
fi;

parameter_minfree=/sys/module/lowmemorykiller/parameters/minfree;
if [ -e $parameter_minfree ]; then
	write $parameter_minfree "$minFree"
	sendToLog "minfree=$minFree"
fi;

parameter_min_free_kbytes=/proc/sys/vm/min_free_kbytes;
if [ -e $parameter_min_free_kbytes ]; then
	write $parameter_min_free_kbytes "$mfk"
	sendToLog "min_free_kbytes=$mfk"
fi;

parameter_extra_free_kbytes=/proc/sys/vm/extra_free_kbytes;
if [ -e $parameter_extra_free_kbytes ]; then
	write $parameter_extra_free_kbytes "$efk"
	sendToLog "extra_free_kbytes=$efk"
fi;

sendToLog "Multitasking RAM manager profile for $((memTotal))mb devices successfully applied"
sendToLog "$divider";
}

swappinessTendency() {
	sendToLog "Setting swappiness tendency...";

	swappiness=/proc/sys/vm/swappiness
	if [ -e $swappiness ]; then
		if [ "$1" = "1" ]; then
			write $swappiness "1"
			
			sendToLog "swappiness=1";
			sendToLog "Swappiness tendency set to 1";
		elif [ "$1" = "2" ]; then
			write $swappiness "10"
			
			sendToLog "swappiness=10";
			sendToLog "Swappiness tendency set to 10";
			
		elif [ "$1" = "3" ]; then
			write $swappiness "25"
			
			sendToLog "swappiness=25";
			sendToLog "Swappiness tendency set to 25";
			
		elif [ "$1" = "4" ]; then
			write $swappiness "50"
			
			sendToLog "swappiness=50";
			sendToLog "Swappiness tendency set to 50";

		elif [ "$1" = "5" ]; then
			write $swappiness "75"
			
			sendToLog "swappiness=75";
			sendToLog "Swappiness tendency set to 75";

		elif [ "$1" = "6" ]; then
			write $swappiness "100"
			
			sendToLog "swappiness=100";
			sendToLog "Swappiness tendency set to 100";			
		fi
	fi;
	sendToLog "$divider";
}

virtualMemoryTweaksBalanced() {
sendToLog "Activating balanced virtual memory tweaks..."

sync

leases_enable=/proc/sys/fs/leases-enable
if [ -e $leases_enable ]; then
	write $leases_enable "1"		
	sendToLog "leases_enable=1"
fi;

# This file specifies the grace period (in seconds) that the kernel grants
# to a process holding a file lease after it has sent a signal to that process
# notifying it that another process is waiting to open the file.
# If the lease holder does not remove or downgrade the lease within this grace period,
# the kernel forcibly breaks the lease.

lease_break_time=/proc/sys/fs/lease-break-time
if [ -e $lease_break_time ]; then
	write $lease_break_time "10"		
	sendToLog "lease_break_time=10"
fi;

# dnotify is a signal used to notify a process about file/directory changes.
dir_notify_enable=/proc/sys/fs/dir-notify-enable
if [ -e $dir_notify_enable ]; then
	write $dir_notify_enable "0"		
	sendToLog "dir_notify_enable=0"
fi;

sendToLog "File system parameters are updated"

enable_process_reclaim=/sys/module/process_reclaim/parameters/enable_process_reclaim
if [ -e $enable_process_reclaim ]; then
	write $enable_process_reclaim "0"		
	sendToLog "Reclaiming pages of inactive tasks disabled"
fi;

# This parameter tells how much of physical RAM to take when swap is full
overcommit_ratio=/proc/sys/vm/overcommit_ratio
if [ -e overcommit_ratio ]; then
	write $overcommit_ratio "0"		
	sendToLog "overcommit_ratio=0"
fi;

oom_dump_tasks=/proc/sys/vm/oom_dump_tasks
if [ -e $oom_dump_tasks ]; then
	write $oom_dump_tasks "0"		
	sendToLog "OOM dump tasks are disabled"
fi;

vfs_cache_pressure=/proc/sys/vm/vfs_cache_pressure
if [ -e $vfs_cache_pressure ]; then
	write $vfs_cache_pressure "60"		
	sendToLog "vfs_cache_pressure=60"
fi;

laptop_mode=/proc/sys/vm/laptop_mode
if [ -e $laptop_mode ]; then
	write $laptop_mode "0"		
	sendToLog "laptop_mode=0"
fi;

#Available only when CONFIG_COMPACTION is set. When 1 is written to the file,
#all zones are compacted such that free memory is available in contiguous
#blocks where possible. This can be important for example in the allocation of
#huge pages although processes will also directly compact memory as required.
compact_memory=/proc/sys/vm/compact_memory
if [ -e $compact_memory ]; then
	write $compact_memory "1"		
	sendToLog "compact_memory=1"
fi;

#Available only when CONFIG_COMPACTION is set. When set to 1, compaction is
#allowed to examine the unevictable lru (mlocked pages) for pages to compact.
#This should be used on systems where stalls for minor page faults are an
#acceptable trade for large contiguous free memory.  Set to 0 to prevent
#compaction from moving pages that are unevictable.  Default value is 1.
compact_unevictable_allowed=/proc/sys/vm/compact_unevictable_allowed
if [ -e $compact_unevictable_allowed ]; then
	write $compact_unevictable_allowed "1"
	sendToLog "compact_unevictable_allowed=1"
fi;

# page-cluster controls the number of pages up to which consecutive pages
# are read in from swap in a single attempt. This is the swap counterpart
# to page cache readahead.
# The mentioned consecutivity is not in terms of virtual/physical addresses,
# but consecutive on swap space - that means they were swapped out together.
# It is a logarithmic value - setting it to zero means "1 page", setting
# it to 1 means "2 pages", setting it to 2 means "4 pages", etc.
# Zero disables swap readahead completely.
# The default value is three (eight pages at a time).  There may be some
# small benefits in tuning this to a different value if your workload is
# swap-intensive.
# Lower values mean lower latencies for initial faults, but at the same time
# extra faults and I/O delays for following faults if they would have been part of
# that consecutive pages readahead would have brought in.
page_cluster=/proc/sys/vm/page-cluster
if [ -e $page_cluster ]; then
	write $page_cluster "0"		
	sendToLog "page_cluster=0"
fi;

# vm.dirty_expire_centisecs is how long something can be in cache
# before it needs to be written.
# When the pdflush/flush/kdmflush processes kick in they will
# check to see how old a dirty page is, and if it’s older than this value it’ll
# be written asynchronously to disk. Since holding a dirty page in memory is
# unsafe this is also a safeguard against data loss.
dirty_expire_centisecs=/proc/sys/vm/dirty_expire_centisecs
if [ -e $dirty_expire_centisecs ]; then
	write $dirty_expire_centisecs "500"		
	sendToLog "dirty_expire_centisecs=500"
fi;

# vm.dirty_writeback_centisecs is how often the pdflush/flush/kdmflush processes wake up
# and check to see if work needs to be done.
dirty_writeback_centisecs=/proc/sys/vm/dirty_writeback_centisecs
if [ -e $dirty_writeback_centisecs ]; then
	write $dirty_writeback_centisecs "1000"		
	sendToLog "dirty_writeback_centisecs=1000"
fi;

# vm.dirty_background_ratio is the percentage of system memory(RAM)
# that can be filled with “dirty” pages — memory pages that
# still need to be written to disk — before the pdflush/flush/kdmflush
# background processes kick in to write it to disk.
# It can be 50% or less of dirtyRatio
# If ( dirty_background_ratio >= dirty_ratio ) {
# dirty_background_ratio = dirty_ratio / 2
dirty_background_ratio=/proc/sys/vm/dirty_background_ratio
if [ -e $dirty_background_ratio ]; then
	write $dirty_background_ratio "10"		
	sendToLog "dirty_background_ratio=10"
fi;

# vm.dirty_ratio is the absolute maximum amount of system memory
# that can be filled with dirty pages before everything must get committed to disk.
# When the system gets to this point all new I/O blocks until dirty pages
# have been written to disk. This is often the source of long I/O pauses,
# but is a safeguard against too much data being cached unsafely in memory.
dirty_ratio=/proc/sys/vm/dirty_ratio
if [ -e $dirty_ratio ]; then
	write $dirty_ratio "35"		
	sendToLog "dirty_ratio=35"
fi;

sendToLog "Balanced virtual memory tweaks activated"
sendToLog "$divider";
}

virtualMemoryTweaksBattery() {
sendToLog "Activating battery virtual memory tweaks..."

sync

leases_enable=/proc/sys/fs/leases-enable
if [ -e $leases_enable ]; then
	write $leases_enable "1"		
	sendToLog "leases_enable=1"
fi;

# This file specifies the grace period (in seconds) that the kernel grants
# to a process holding a file lease after it has sent a signal to that process
# notifying it that another process is waiting to open the file.
# If the lease holder does not remove or downgrade the lease within this grace period,
# the kernel forcibly breaks the lease.

lease_break_time=/proc/sys/fs/lease-break-time
if [ -e $lease_break_time ]; then
	write $lease_break_time "10"		
	sendToLog "lease_break_time=10"
fi;

# dnotify is a signal used to notify a process about file/directory changes.
dir_notify_enable=/proc/sys/fs/dir-notify-enable
if [ -e $dir_notify_enable ]; then
	write $dir_notify_enable "0"		
	sendToLog "dir_notify_enable=0"
fi;

sendToLog "File system parameters are updated"

enable_process_reclaim=/sys/module/process_reclaim/parameters/enable_process_reclaim
if [ -e $enable_process_reclaim ]; then
	write $enable_process_reclaim "0"		
	sendToLog "Reclaiming pages of inactive tasks disabled"
fi;

# This parameter tells how much of physical RAM to take when swap is full
overcommit_ratio=/proc/sys/vm/overcommit_ratio
if [ -e overcommit_ratio ]; then
	write $overcommit_ratio "0"		
	sendToLog "overcommit_ratio=0"
fi;

oom_dump_tasks=/proc/sys/vm/oom_dump_tasks
if [ -e $oom_dump_tasks ]; then
	write $oom_dump_tasks "0"		
	sendToLog "OOM dump tasks are disabled"
fi;

vfs_cache_pressure=/proc/sys/vm/vfs_cache_pressure
if [ -e $vfs_cache_pressure ]; then
	write $vfs_cache_pressure "40"		
	sendToLog "vfs_cache_pressure=40"
fi;

laptop_mode=/proc/sys/vm/laptop_mode
if [ -e $laptop_mode ]; then
	write $laptop_mode "0"		
	sendToLog "laptop_mode=0"
fi;

#Available only when CONFIG_COMPACTION is set. When 1 is written to the file,
#all zones are compacted such that free memory is available in contiguous
#blocks where possible. This can be important for example in the allocation of
#huge pages although processes will also directly compact memory as required.
compact_memory=/proc/sys/vm/compact_memory
if [ -e $compact_memory ]; then
	write $compact_memory "1"		
	sendToLog "compact_memory=1"
fi;

#Available only when CONFIG_COMPACTION is set. When set to 1, compaction is
#allowed to examine the unevictable lru (mlocked pages) for pages to compact.
#This should be used on systems where stalls for minor page faults are an
#acceptable trade for large contiguous free memory.  Set to 0 to prevent
#compaction from moving pages that are unevictable.  Default value is 1.
compact_unevictable_allowed=/proc/sys/vm/compact_unevictable_allowed
if [ -e $compact_unevictable_allowed ]; then
	write $compact_unevictable_allowed "1"
	sendToLog "compact_unevictable_allowed=1"
fi;

# page-cluster controls the number of pages up to which consecutive pages
# are read in from swap in a single attempt. This is the swap counterpart
# to page cache readahead.
# The mentioned consecutivity is not in terms of virtual/physical addresses,
# but consecutive on swap space - that means they were swapped out together.
# It is a logarithmic value - setting it to zero means "1 page", setting
# it to 1 means "2 pages", setting it to 2 means "4 pages", etc.
# Zero disables swap readahead completely.
# The default value is three (eight pages at a time).  There may be some
# small benefits in tuning this to a different value if your workload is
# swap-intensive.
# Lower values mean lower latencies for initial faults, but at the same time
# extra faults and I/O delays for following faults if they would have been part of
# that consecutive pages readahead would have brought in.
page_cluster=/proc/sys/vm/page-cluster
if [ -e $page_cluster ]; then
	write $page_cluster "0"		
	sendToLog "page_cluster=0"
fi;

# vm.dirty_expire_centisecs is how long something can be in cache
# before it needs to be written.
# When the pdflush/flush/kdmflush processes kick in they will
# check to see how old a dirty page is, and if it’s older than this value it’ll
# be written asynchronously to disk. Since holding a dirty page in memory is
# unsafe this is also a safeguard against data loss.
dirty_expire_centisecs=/proc/sys/vm/dirty_expire_centisecs
if [ -e $dirty_expire_centisecs ]; then
	write $dirty_expire_centisecs "500"		
	sendToLog "dirty_expire_centisecs=500"
fi;

# vm.dirty_writeback_centisecs is how often the pdflush/flush/kdmflush processes wake up
# and check to see if work needs to be done.
dirty_writeback_centisecs=/proc/sys/vm/dirty_writeback_centisecs
if [ -e $dirty_writeback_centisecs ]; then
	write $dirty_writeback_centisecs "1000"		
	sendToLog "dirty_writeback_centisecs=1000"
fi;

# vm.dirty_background_ratio is the percentage of system memory(RAM)
# that can be filled with “dirty” pages — memory pages that
# still need to be written to disk — before the pdflush/flush/kdmflush
# background processes kick in to write it to disk.
# It can be 50% or less of dirtyRatio
# If ( dirty_background_ratio >= dirty_ratio ) {
# dirty_background_ratio = dirty_ratio / 2
dirty_background_ratio=/proc/sys/vm/dirty_background_ratio
if [ -e $dirty_background_ratio ]; then
	write $dirty_background_ratio "5"		
	sendToLog "dirty_background_ratio=5"
fi;

# vm.dirty_ratio is the absolute maximum amount of system memory
# that can be filled with dirty pages before everything must get committed to disk.
# When the system gets to this point all new I/O blocks until dirty pages
# have been written to disk. This is often the source of long I/O pauses,
# but is a safeguard against too much data being cached unsafely in memory.
dirty_ratio=/proc/sys/vm/dirty_ratio
if [ -e $dirty_ratio ]; then
	write $dirty_ratio "20"		
	sendToLog "dirty_ratio=20"
fi;

sendToLog "Battery virtual memory tweaks activated"
sendToLog "$divider";
}

virtualMemoryTweaksPerformance() {
sendToLog "Activating performance virtual memory tweaks..."

sync

leases_enable=/proc/sys/fs/leases-enable
if [ -e $leases_enable ]; then
	write $leases_enable "1"
	sendToLog "leases_enable=1"
fi;

# This file specifies the grace period (in seconds) that the kernel grants
# to a process holding a file lease after it has sent a signal to that process
# notifying it that another process is waiting to open the file.
# If the lease holder does not remove or downgrade the lease within this grace period,
# the kernel forcibly breaks the lease.

lease_break_time=/proc/sys/fs/lease-break-time
if [ -e $lease_break_time ]; then
	write $lease_break_time "10"
	sendToLog "lease_break_time=10"
fi;

# dnotify is a signal used to notify a process about file/directory changes.
dir_notify_enable=/proc/sys/fs/dir-notify-enable
if [ -e $dir_notify_enable ]; then
	write $dir_notify_enable "0"
	sendToLog "dir_notify_enable=0"
fi;

sendToLog "File system parameters are updated"

enable_process_reclaim=/sys/module/process_reclaim/parameters/enable_process_reclaim
if [ -e $enable_process_reclaim ]; then
	write $enable_process_reclaim "0"
	sendToLog "Reclaiming pages of inactive tasks disabled"
fi;

# This parameter tells how much of physical RAM to take when swap is full
overcommit_ratio=/proc/sys/vm/overcommit_ratio
if [ -e $overcommit_ratio ]; then
	write $overcommit_ratio "0"
	sendToLog "overcommit_ratio=0"
fi;

oom_dump_tasks=/proc/sys/vm/oom_dump_tasks
if [ -e $oom_dump_tasks ]; then
	write $oom_dump_tasks "0"
	sendToLog "oom_dump_tasks=0"
fi;

vfs_cache_pressure=/proc/sys/vm/vfs_cache_pressure
if [ -e $vfs_cache_pressure ]; then
	write $vfs_cache_pressure "100"
	sendToLog "vfs_cache_pressure=100"
fi;

laptop_mode=/proc/sys/vm/laptop_mode
if [ -e $laptop_mode ]; then
	write $laptop_mode "0"
	sendToLog "laptop_mode=0"
fi;

#Available only when CONFIG_COMPACTION is set. When 1 is written to the file,
#all zones are compacted such that free memory is available in contiguous
#blocks where possible. This can be important for example in the allocation of
#huge pages although processes will also directly compact memory as required.
compact_memory=/proc/sys/vm/compact_memory
if [ -e $compact_memory ]; then
	write $compact_memory "1"		
	sendToLog "compact_memory=1"
fi;

#Available only when CONFIG_COMPACTION is set. When set to 1, compaction is
#allowed to examine the unevictable lru (mlocked pages) for pages to compact.
#This should be used on systems where stalls for minor page faults are an
#acceptable trade for large contiguous free memory.  Set to 0 to prevent
#compaction from moving pages that are unevictable.  Default value is 1.
compact_unevictable_allowed=/proc/sys/vm/compact_unevictable_allowed
if [ -e $compact_unevictable_allowed ]; then
	write $compact_unevictable_allowed "1"
	sendToLog "compact_unevictable_allowed=1"
fi;

# page-cluster controls the number of pages up to which consecutive pages
# are read in from swap in a single attempt. This is the swap counterpart
# to page cache readahead.
# The mentioned consecutivity is not in terms of virtual/physical addresses,
# but consecutive on swap space - that means they were swapped out together.
# It is a logarithmic value - setting it to zero means "1 page", setting
# it to 1 means "2 pages", setting it to 2 means "4 pages", etc.
# Zero disables swap readahead completely.
# The default value is three (eight pages at a time).  There may be some
# small benefits in tuning this to a different value if your workload is
# swap-intensive.
# Lower values mean lower latencies for initial faults, but at the same time
# extra faults and I/O delays for following faults if they would have been part of
# that consecutive pages readahead would have brought in.
page_cluster=/proc/sys/vm/page-cluster
if [ -e $page_cluster ]; then
	write $page_cluster "0"
	sendToLog "page_cluster=0"
fi;

# vm.dirty_expire_centisecs is how long something can be in cache
# before it needs to be written.
# When the pdflush/flush/kdmflush processes kick in they will
# check to see how old a dirty page is, and if it’s older than this value it’ll
# be written asynchronously to disk. Since holding a dirty page in memory is
# unsafe this is also a safeguard against data loss.
dirty_expire_centisecs=/proc/sys/vm/dirty_expire_centisecs
if [ -e $dirty_expire_centisecs ]; then
	write $dirty_expire_centisecs "500"
	sendToLog "dirty_expire_centisecs=500"
fi;

# vm.dirty_writeback_centisecs is how often the pdflush/flush/kdmflush processes wake up
# and check to see if work needs to be done.
dirty_writeback_centisecs=/proc/sys/vm/dirty_writeback_centisecs
if [ -e $dirty_writeback_centisecs ]; then
	write $dirty_writeback_centisecs "1200"
	sendToLog "dirty_writeback_centisecs=1200"
fi;

# vm.dirty_background_ratio is the percentage of system memory(RAM)
# that can be filled with “dirty” pages — memory pages that
# still need to be written to disk — before the pdflush/flush/kdmflush
# background processes kick in to write it to disk.
# It can be 50% or less of dirtyRatio
# If ( dirty_background_ratio >= dirty_ratio ) {
# dirty_background_ratio = dirty_ratio / 2
dirty_background_ratio=/proc/sys/vm/dirty_background_ratio
if [ -e $dirty_background_ratio ]; then
	write $dirty_background_ratio "15"
	sendToLog "dirty_background_ratio=15"
fi;

# vm.dirty_ratio is the absolute maximum amount of system memory
# that can be filled with dirty pages before everything must get committed to disk.
# When the system gets to this point all new I/O blocks until dirty pages
# have been written to disk. This is often the source of long I/O pauses,
# but is a safeguard against too much data being cached unsafely in memory.
dirty_ratio=/proc/sys/vm/dirty_ratio
if [ -e $dirty_ratio ]; then
	write $dirty_ratio "60"
	sendToLog "dirty_ratio=60"
fi;

sendToLog "Performance virtual memory tweaks activated"
sendToLog "$divider";
}

heapOptimization() {

# Variables
memTotal=$(free -m | awk '/^Mem:/{print $2}');

heapSize=$((memTotal*3/16));

#if [ "$heapSize" -gt "512" ]; then
#	heapSize=512;
#fi

heapGrowthLimit=$((heapSize*5/11));

sendToLog "Activating heap optimization";

# The ideal ratio of live to free memory. Is clamped to have a value between 0.2 and 0.9.
# This limit the managed hepSize to heapsize*heaptargetutilization
setprop dalvik.vm.heaptargetutilization 0.85
sendToLog "heapTargetUtilization=0.85";

# This is the heap size that Dalvik/ART assigns to every new ‘large’ App.
# Large Apps are the ones that include the ‘android:largeHeap’ option in their manifest.
# Note that many apps abuse this option, in an effort to increase their performance.
setprop dalvik.vm.heapsize "$((heapSize))m"
sendToLog "heapSize=$((heapSize))m";

# This is the heap size that is assigned to standard Apps.
# This should typically be no more than half the dalvik.vm.heapsize value.
setprop dalvik.vm.heapgrowthlimit "$((heapGrowthLimit))m"
sendToLog "heapgrowthlimit=$((heapGrowthLimit))m";

# Forces the free memory to never be larger than the given value.
setprop dalvik.vm.heapmaxfree 8m
sendToLog "heapmaxfree=8m";

# Forces the free memory to never be smaller than the given value.
setprop dalvik.vm.heapminfree 2m
sendToLog "heapminfree=2m";

sendToLog "Heap optimization activated";
sendToLog "$divider";
}

#
# Profile presets
#
setDefaultProfile() {
	write "$USER_PROFILE"/battery_improvements "1"

	# CPU section
	write "$USER_PROFILE"/cpu_optimization "2"
	write "$USER_PROFILE"/gov_tuner "2"

	# Entropy section
	write "$USER_PROFILE"/entropy "0"

	# GPU section
	write "$USER_PROFILE"/gpu_optimizer "2"
	write "$USER_PROFILE"/optimize_buffers "0"
	write "$USER_PROFILE"/render_opengles_using_gpu "0"
	write "$USER_PROFILE"/use_opengl_skia "0"

	# I/O tweaks section
	write "$USER_PROFILE"/disable_io_stats "1"
	write "$USER_PROFILE"/io_blocks_optimization "2"
	write "$USER_PROFILE"/io_extended_queue "0"
	write "$USER_PROFILE"/scheduler_tuner "1"
	write "$USER_PROFILE"/sd_tweak "0"

	# LNET tweaks section
	write "$USER_PROFILE"/dns "0"
	write "$USER_PROFILE"/net_buffers "0"
	write "$USER_PROFILE"/net_speed_plus "0"
	write "$USER_PROFILE"/net_tcp "1"
	write "$USER_PROFILE"/optimize_ril "0"

	# Other
	write "$USER_PROFILE"/disable_debugging "0"
	write "$USER_PROFILE"/disable_kernel_panic "0"

	# RAM manager section
	write "$USER_PROFILE"/ram_manager "2"
	write "$USER_PROFILE"/disable_multitasking_limitations "1"
	write "$USER_PROFILE"/low_ram_flag "0"
	write "$USER_PROFILE"/oom_killer "0"
	write "$USER_PROFILE"/swappiness "3"
	write "$USER_PROFILE"/virtual_memory "2"
	write "$USER_PROFILE"/heap_optimization "0"
}

setPowerSavingProfile() {
	write "$USER_PROFILE"/battery_improvements "1"

	# CPU section
	write "$USER_PROFILE"/cpu_optimization "1"
	write "$USER_PROFILE"/gov_tuner "1"

	# Entropy section
	write "$USER_PROFILE"/entropy "0"

	# GPU section
	write "$USER_PROFILE"/gpu_optimizer "1"
	write "$USER_PROFILE"/optimize_buffers "0"
	write "$USER_PROFILE"/render_opengles_using_gpu "0"
	write "$USER_PROFILE"/use_opengl_skia "0"

	# I/O tweaks section
	write "$USER_PROFILE"/disable_io_stats "1"
	write "$USER_PROFILE"/io_blocks_optimization "1"
	write "$USER_PROFILE"/io_extended_queue "0"
	write "$USER_PROFILE"/scheduler_tuner "1"
	write "$USER_PROFILE"/sd_tweak "0"

	# LNET tweaks section
	write "$USER_PROFILE"/dns "0"
	write "$USER_PROFILE"/net_buffers "0"
	write "$USER_PROFILE"/net_speed_plus "0"
	write "$USER_PROFILE"/net_tcp "1"
	write "$USER_PROFILE"/optimize_ril "1"

	# Other
	write "$USER_PROFILE"/disable_debugging "0"
	write "$USER_PROFILE"/disable_kernel_panic "0"

	# RAM manager section
	write "$USER_PROFILE"/ram_manager "2"
	write "$USER_PROFILE"/disable_multitasking_limitations "0"
	write "$USER_PROFILE"/low_ram_flag "0"
	write "$USER_PROFILE"/oom_killer "0"
	write "$USER_PROFILE"/swappiness "1"
	write "$USER_PROFILE"/virtual_memory "1"
	write "$USER_PROFILE"/heap_optimization "0"
}

setBalancedProfile() {
	write "$USER_PROFILE"/battery_improvements "1"

	# CPU section
	write "$USER_PROFILE"/cpu_optimization "2"
	write "$USER_PROFILE"/gov_tuner "2"

	# Entropy section
	write "$USER_PROFILE"/entropy "0"

	# GPU section
	write "$USER_PROFILE"/gpu_optimizer "2"
	write "$USER_PROFILE"/optimize_buffers "0"
	write "$USER_PROFILE"/render_opengles_using_gpu "0"
	write "$USER_PROFILE"/use_opengl_skia "0"

	# I/O tweaks section
	write "$USER_PROFILE"/disable_io_stats "1"
	write "$USER_PROFILE"/io_blocks_optimization "2"
	write "$USER_PROFILE"/io_extended_queue "0"
	write "$USER_PROFILE"/scheduler_tuner "1"
	write "$USER_PROFILE"/sd_tweak "0"

	# LNET tweaks section
	write "$USER_PROFILE"/dns "0"
	write "$USER_PROFILE"/net_buffers "0"
	write "$USER_PROFILE"/net_speed_plus "0"
	write "$USER_PROFILE"/net_tcp "1"
	write "$USER_PROFILE"/optimize_ril "1"

	# Other
	write "$USER_PROFILE"/disable_debugging "0"
	write "$USER_PROFILE"/disable_kernel_panic "0"

	# RAM manager section
	write "$USER_PROFILE"/ram_manager "2"
	write "$USER_PROFILE"/disable_multitasking_limitations "1"
	write "$USER_PROFILE"/low_ram_flag "0"
	write "$USER_PROFILE"/oom_killer "0"
	write "$USER_PROFILE"/swappiness "3"
	write "$USER_PROFILE"/virtual_memory "2"
	write "$USER_PROFILE"/heap_optimization "0"
}

setPerformanceProfile() {
	write "$USER_PROFILE"/battery_improvements "1"

	# CPU section
	write "$USER_PROFILE"/cpu_optimization "3"
	write "$USER_PROFILE"/gov_tuner "3"

	# Entropy section
	write "$USER_PROFILE"/entropy "2"

	# GPU section
	write "$USER_PROFILE"/gpu_optimizer "3"
	write "$USER_PROFILE"/optimize_buffers "0"
	write "$USER_PROFILE"/render_opengles_using_gpu "0"
	write "$USER_PROFILE"/use_opengl_skia "0"

	# I/O tweaks section
	write "$USER_PROFILE"/disable_io_stats "1"
	write "$USER_PROFILE"/io_blocks_optimization "3"
	write "$USER_PROFILE"/io_extended_queue "1"
	write "$USER_PROFILE"/scheduler_tuner "1"
	write "$USER_PROFILE"/sd_tweak "0"

	# LNET tweaks section
	write "$USER_PROFILE"/dns "0"
	write "$USER_PROFILE"/net_buffers "0"
	write "$USER_PROFILE"/net_speed_plus "1"
	write "$USER_PROFILE"/net_tcp "1"
	write "$USER_PROFILE"/optimize_ril "1"

	# Other
	write "$USER_PROFILE"/disable_debugging "0"
	write "$USER_PROFILE"/disable_kernel_panic "0"

	# RAM manager section
	write "$USER_PROFILE"/ram_manager "3"
	write "$USER_PROFILE"/disable_multitasking_limitations "1"
	write "$USER_PROFILE"/low_ram_flag "0"
	write "$USER_PROFILE"/oom_killer "0"
	write "$USER_PROFILE"/swappiness "1"
	write "$USER_PROFILE"/virtual_memory "3"
	write "$USER_PROFILE"/heap_optimization "0"
}

# Check number of arguments and perform task based on it.
if [ $# -eq 2 ]; then
	sleep 1;
	$1 "$2";
	
	exit 0;
elif [ $# -eq 1 ]; then
	sleep 1;
	$1
	
	exit 0;
else
sendToLog "Starting L Speed";

# Wait for boot completed and then continue with execution, when getprop sys.boot_completed is
# equal to 1 while loop will be passed
attempts=10
wait=15 # Time in seconds
while [ "$attempts" -gt 0 ] && [ "$(getprop sys.boot_completed)" != "1" ]; do
   attempts=$((attempts-1));
   sendToLog "Waiting for boot_completed";
   sleep $wait
done

# This should prevent freezing on boot
sleep 90

# Read current profile
currentProfile=$(cat "$PROFILE" 2> /dev/null);
sendToLog "Getting profile...";

if [ "$currentProfile" = "-1" ]; then
	profile="user defined";

elif [ "$currentProfile" = "0" ]; then
	profile="default";
	setDefaultProfile;

elif [ "$currentProfile" = "1" ]; then
	profile="power saving";
	setPowerSavingProfile;

elif [ "$currentProfile" = "2" ]; then
	profile="balanced";
	setBalancedProfile;

elif [ "$currentProfile" = "3" ]; then
	profile="performance";
	setPerformanceProfile;
else
	profile="default";
	setDefaultProfile;
fi
sendToLog "Current profile is $profile";

sendToLog "Applying $profile profile";

# Time in seconds when starting with profile applying
# This will be later used for the time difference
start=$(date +%s)

if [ "$(cat "$USER_PROFILE"/battery_improvements)" -eq 1 ]; then
	batteryImprovements;
fi

#
# CPU tuner section
#
if [ "$(cat "$USER_PROFILE"/cpu_optimization)" -eq 1 ]; then
	cpuOptimizationBattery;
elif [ "$(cat "$USER_PROFILE"/cpu_optimization)" -eq 2 ]; then
	cpuOptimizationBalanced;
elif [ "$(cat "$USER_PROFILE"/cpu_optimization)" -eq 3 ]; then
	cpuOptimizationPerformance;
fi

#if [ `cat $USER_PROFILE/gov_tuner` -eq 1 ]; then
	# soon;
#elif [ `cat $USER_PROFILE/gov_tuner` -eq 2 ]; then
#	# soon;
#elif [ `cat $USER_PROFILE/gov_tuner` -eq 3 ]; then
#	# soon;
#fi

#
# Entropy section
#
if [ "$(cat "$USER_PROFILE"/entropy)" -eq 1 ]; then
	entropyLight;
elif [ "$(cat "$USER_PROFILE"/entropy)" -eq 2 ]; then
	entropyEnlarger;
elif [ "$(cat "$USER_PROFILE"/entropy)" -eq 3 ]; then
	entropyModerate;
elif [ "$(cat "$USER_PROFILE"/entropy)" -eq 4 ]; then
	entropyAggressive;
fi

#
# GPU section
#
if [ "$(cat "$USER_PROFILE"/gpu_optimizer)" -eq 1 ]; then
	gpuOptimizerPowerSaving;
elif [ "$(cat "$USER_PROFILE"/gpu_optimizer)" -eq 2 ]; then
	gpuOptimizerBalanced;
elif [ "$(cat "$USER_PROFILE"/gpu_optimizer)" -eq 3 ]; then
	gpuOptimizerPerformance;
fi

if [ "$(cat "$USER_PROFILE"/optimize_buffers)" -eq 1 ]; then
	optimizeBuffers;
fi

if [ "$(cat "$USER_PROFILE"/render_opengles_using_gpu)" -eq 1 ]; then
	renderOpenglesUsingGpu;
fi

if [ "$(cat "$USER_PROFILE"/use_opengl_skia)" -eq 1 ]; then
	useOpenglSkia;
fi

#
# I/O tweaks section
#
if [ "$(cat "$USER_PROFILE"/disable_io_stats)" -eq 0 ]; then
	enableIoStats;
elif [ "$(cat "$USER_PROFILE"/disable_io_stats)" -eq 1 ]; then
	disableIoStats;
fi

if [ "$(cat "$USER_PROFILE"/io_blocks_optimization)" -eq 1 ]; then
	ioBlocksOptimizationPowerSaving;
elif [ "$(cat "$USER_PROFILE"/io_blocks_optimization)" -eq 2 ]; then
	ioBlocksOptimizationBalanced;
elif [ "$(cat "$USER_PROFILE"/io_blocks_optimization)" -eq 3 ]; then
	ioBlocksOptimizationPerformance;
fi

if [ "$(cat "$USER_PROFILE"/io_extended_queue)" -eq 1 ]; then
	ioExtendedQueue;
fi

#if [ `cat $USER_PROFILE/scheduler_tuner` -eq 1 ]; then
#	schedulerTuner;
#fi

if [ "$(cat "$USER_PROFILE"/sd_tweak)" -eq 1 ]; then
	sdTweak;
fi

#
# LNET tweaks section
#
if [ "$(cat "$USER_PROFILE"/dns)" -eq 1 ]; then
	dnsOptimizationGooglePublic;
elif [ "$(cat "$USER_PROFILE"/dns)" -eq 2 ]; then
	dnsOptimizationCloudFlare;
fi

if [ "$(cat "$USER_PROFILE"/net_buffers)" -eq 1 ]; then
	netBuffersSmall;
elif [ "$(cat "$USER_PROFILE"/net_buffers)" -eq 2 ]; then
	netBuffersBig;
fi

if [ "$(cat "$USER_PROFILE"/net_speed_plus)" -eq 1 ]; then
	netSpeedPlus;
fi

if [ "$(cat "$USER_PROFILE"/net_tcp)" -eq 1 ]; then
	netTcpTweaks;
fi

if [ "$(cat "$USER_PROFILE"/optimize_ril)" -eq 1 ]; then
	rilTweaks;
fi

#
# Other
#
if [ "$(cat "$USER_PROFILE"/disable_debugging)" -eq 1 ]; then
	disableDebugging;
fi

if [ "$(cat "$USER_PROFILE"/disable_kernel_panic)" -eq 1 ]; then
	disableKernelPanic;
fi

#
# RAM manager section
#
if [ "$(cat "$USER_PROFILE"/ram_manager)" -eq 1 ]; then
	ramManagerMultitasking;
elif [ "$(cat "$USER_PROFILE"/ram_manager)" -eq 2 ]; then
	ramManagerBalanced;
elif [ "$(cat "$USER_PROFILE"/ram_manager)" -eq 3 ]; then
	ramManagerGaming;
fi

if [ "$(cat "$USER_PROFILE"/disable_multitasking_limitations)" -eq 1 ]; then
	disableMultitaskingLimitations;
fi

if [ "$(cat "$USER_PROFILE"/low_ram_flag)" -eq 0 ]; then
	lowRamFlagDisabled;
elif [ "$(cat "$USER_PROFILE"/low_ram_flag)" -eq 1 ]; then
	lowRamFlagEnabled;
fi

if [ "$(cat "$USER_PROFILE"/oom_killer)" -eq 0 ]; then
	oomKillerDisabled;
elif [ "$(cat "$USER_PROFILE"/oom_killer)" -eq 1 ]; then
	oomKillerEnabled;
fi

if [ "$(cat "$USER_PROFILE"/swappiness)" -eq 1 ]; then
	swappinessTendency 1;
elif [ "$(cat "$USER_PROFILE"/swappiness)" -eq 2 ]; then
	swappinessTendency 2;
elif [ "$(cat "$USER_PROFILE"/swappiness)" -eq 3 ]; then
	swappinessTendency 3;
elif [ "$(cat "$USER_PROFILE"/swappiness)" -eq 4 ]; then
	swappinessTendency 4;
elif [ "$(cat "$USER_PROFILE"/swappiness)" -eq 5 ]; then
	swappinessTendency 5;
elif [ "$(cat "$USER_PROFILE"/swappiness)" -eq 6 ]; then
	swappinessTendency 6;
fi

if [ "$(cat "$USER_PROFILE"/virtual_memory)" -eq 1 ]; then
	virtualMemoryTweaksBattery;
elif [ "$(cat "$USER_PROFILE"/virtual_memory)" -eq 2 ]; then
	virtualMemoryTweaksBalanced;
elif [ "$(cat "$USER_PROFILE"/virtual_memory)" -eq 3 ]; then
	virtualMemoryTweaksPerformance;
fi

#if [ `cat $USER_PROFILE/heap_optimization` -eq 1 ]; then
#	heapOptimization;
#fi

# End time of the script
end=$(date +%s)

# Calculate how much took to set up L Speed parameters,
# everything is calculated in seconds
runtime=$((end-start))

sendToLog "Applying took $runtime seconds";
sendToLog "Successfully applied $profile profile";

exit 0
fi

exit 0
