#!/bin/bash

### Define the msr addresses of CBox PMON registers
Cx_MSR_PMON_BOX_CTL=0x0E00
Cx_MSR_PMON_BOX_FTL0=0x0E05
Cx_MSR_PMON_CTL0=0x0E01
Cx_MSR_PMON_CTR0=0x0E08

### Step size for going from one CBox to the next one
Cx_MSR_PMON_STP=0x10

### Define bit field offsets 
# for CBox box-wide control register
frz_offset=8
rst_ctr_offset=1
rst_ctl_offset=0

# for CBox box-wide filter register
state_offset=17

# for counter control register
en_offset=22
umask_offset=8

### Define values to be programmed
# for CBox box-wide filter register
state_any=0x3F

# for counter control register
event_val=0x34					## LLC Lookup event
umask_val=0x11					## Any Lookup Transaction

### Program the counters
program_counters()
{
	### Define number of system cores i.e. the cache slices or number of cboxes
	local core_count=6

	until [ $core_count -lt 1 ]; do
		let core_count-=1
	
		# Step-1 : Reset all the counters and the controls via box-wide control registers
		wrmsr -p0 $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)))|(0x3)))
	
		# Step-2 : Freeze all the counters via box-wide control registers
		wrmsr -p0 $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)))|(1<<$frz_offset)))
	
		# Step-3 : Program the box-wide filter registers to track any llc transactions for the lookup event
		wrmsr -p0 $(($Cx_MSR_PMON_BOX_FTL0+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_BOX_FTL0+$Cx_MSR_PMON_STP*$core_count)))|($state_any<<$state_offset)))
	
		# Step-4 : Program the event field and unit-mask value in the counter control registers
		wrmsr -p0 $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)))|($umask_val<<$umask_offset)|($event_val)))
	
		# Step-x : Print the counter values at this point
		# echo "Initial Value of LLC-Slice Utilization Counter for Core-$core_count : `rdmsr -p0 $(($Cx_MSR_PMON_CTR0+$Cx_MSR_PMON_STP*$core_count))`"
	done
}

# Enable the counters
enable_counters()
{
	### Define number of system cores i.e. the cache slices or number of cboxes
	local core_count=6

	### Enable and unfreeze the counters
	until [ $core_count -lt 1 ]; do
		let core_count-=1
	
		# Step-5 : Enable the counters via the control registers
		wrmsr -p0 $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)))|(1<<$en_offset)))
	
		# Step-6 : Unfreeze the counters via the box-wide control registers
		wrmsr -p0 $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)))&(~(1<<$frz_offset))))
	done
}

### Freeze and disable the counters
freeze_counters()
{
	### Define number of system cores i.e. the cache slices or number of cboxes
	local core_count=6

	until [ $core_count -lt 1 ]; do
		let core_count-=1
	
		# Step-7 : Freeze the counters
		wrmsr -p0 $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_BOX_CTL+$Cx_MSR_PMON_STP*$core_count)))|(1<<$frz_offset)))
	
		# Step-8 : Disable the counters
		wrmsr -p0 $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)) $(($(rdmsr -p0 -c $(($Cx_MSR_PMON_CTL0+$Cx_MSR_PMON_STP*$core_count)))&(~(1<<$en_offset))))
	done
}

### Print counter values to terminal	
print_counters()
{
	### Define number of system cores i.e. the cache slices or number of cboxes
	local core_count=6

	until [ $core_count -lt 1 ]; do
		let core_count-=1

		# Step-x : Print the final value of counters
		echo "slice-$core_count : `rdmsr -p0 $(($Cx_MSR_PMON_CTR0+$Cx_MSR_PMON_STP*$core_count))`"
	done
}
