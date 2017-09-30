=== How To Rescue your CentOS 6.5 import and install the Linux Guest Environment===

    1.	The first thing we will need to do is create a new instance from the Google-provided public CentOS 6 image. We will call this the ‘life-raft’ instance, and we will use it to rescue your CentOS 6.7 disk to install the Linux Guest environment and make a new image from that disk which you can use for creating future CentOS 6.7 instances. 

2.) Once you have created the life-raft instance, go ahead and stop your CentOS 6.7 instance for now (we will refer to your CentOS 6.7 instance as the ‘problematic instance’).

3.)The next thing we’ll want to do is to download the current Guest Environment packages. The code for the script is pasted here for you:

——Begin Pasted Code———

# Determine Linux dist and version:
if [ -f "/etc/os-release" ]; then
  # Debian 8+, Ubuntu 14+, CentOS 7+, RHEL 7+
  dist_name="$(cat /etc/os-release | grep ^ID\= | sed "s|\"||g" | awk -F\= '{print tolower($2)}')"
  dist_vers="$(cat /etc/os-release | grep ^VERSION_ID\= | sed "s|\"||g" | awk -F\= '{print tolower($2)}' | awk -F. '{print $1}')"
elif [ -f "/etc/system-release-cpe" ]; then
# CentOS 6, RHEL 6
  dist_name="$(cat /etc/system-release-cpe | awk -F':' '{print tolower($3)}')"
  if [ "$dist_name" == "redhat" ]; then
     dist_name="rhel" # Correction for RHEL 6
  fi
  dist_vers="$(cat /etc/system-release-cpe | awk -F':' '{print tolower($5)}' | sed "s|server||g" | awk -F. '{print $1}')"
fi
dist_name_and_vers="$dist_name-$dist_vers"

# Determine packaging tools:
which apt
if [ "$?" == "0" ]; then
   pkg_tools="apt"
else
   which yum
   if [ "$?" == "0" ]; then
       pkg_tools="yum"
   fi
fi

# Define packages based on dist/version:
if [ "$dist_name" == "ubuntu" ]; then
   if [ "$dist_vers" == "14.04" ]; then
        declare -a PKG_LIST=(python-google-compute-engine google-compute-engine-oslogin)
   else
        declare -a PKG_LIST=(python-google-compute-engine python3-google-compute-engine google-compute-engine-oslogin)
   fi
elif [ "$dist_name" == "debian" ]; then
   declare -a PKG_LIST=(google-cloud-packages-archive-keyring python-google-compute-engine python3-google-compute-engine google-compute-engine)
elif ( [ "$dist_name" == "centos" ] || [ "$dist_name" == "rhel" ] ); then
   declare -a PKG_LIST=(python-google-compute-engine.noarch google-compute-engine.noarch)
fi

# Download tools and packages:
pkg_output_dir="/tmp/lge_pkgs_$dist_name_and_vers"
mkdir -p "$pkg_output_dir"
cd "$pkg_output_dir"

if [ "$pkg_tools" == "apt" ]; then
   # Debian flavors...
   # See https://linux.die.net/man/8/aptitude.
   apt-get -y update
   apt-get -y upgrade
   apt install -y aptitude
   for pkg in "${PKG_LIST[@]}"; do
       aptitude download "$pkg"
   done
   # Rename files for installation order:
   for file_name in $(ls .); do
       new_name="$(echo $file_name | sed "s|python|00-python|")"
       if [ "$file_name" != "new_name" ]; then
          mv $file_name $new_name
       fi
   done

elif [ "$pkg_tools" == "yum" ]; then
   # RHEL flavors...
   # See https://access.redhat.com/solutions/10154.
   # See https://linux.die.net/man/1/yumdownloader.
   yum -y update
   yum -y upgrade
   yum -y install yum-utils
   for pkg in "${PKG_LIST[@]}"; do
       yumdownloader "$pkg"
   done
   # Rename files for installation order:
   for file_name in $(ls .); do
       IFS="-" eval 'file_name_array=($file_name)'
       new_name="$(echo ${file_name_array[@]:1} | sed "s| |-|g" | sed "s|python|00-python|")"
       if [ "$file_name" != "new_name" ]; then
          mv $file_name $new_name
       fi
   done

——End Pasted Code——
 
I recommend transferring this file to your life-raft instance either via a file transfer tool such as rsync, or by copying/pasting it over a terminal-based SSH session, as there may be problems pasting the file into a Browser-based SSH terminal.

4.) Once the file is transferred, go ahead and run it. This will download the appropriate packages and leave them on your life-raft instance for later use.

5.) Now that the life-raft is mostly prepared, stop the problematic instance and determine the name of its boot disk: you can do this by going in the Google Cloud Console, select Compute Engine > VM Instances, and select the problematic instance. Click Stop. Note the name of the boot disk in the Boot disk and local disks section.

6.) Next, create a snapshot of the problematic instance’s boot disk:
In the Google Cloud Console, select Compute Engine > Snapshots, and click Create Snapshot. Name the snapshot something descriptive. For an example, we'll name the snapshot [INSTANCE-NAME]-disk-snapshot. For the Source disk, choose the problematic instance's boot disk determined in the previous step. Click Create.

7.) Then create a new disk from the snapshot:
In the Google Cloud Console, select Compute Engine > Disks, and click Create Disk. Name the new disk something descriptive. For an example, we'll use [INSTANCE-NAME]-new-disk, using the instance name of the problematic instance. Change Source type to Snapshot, then select the Source snapshot created in the previous step. Click Create.

8.) Now, attach the newly created disk to the life-raft instance:
In the Google Cloud Console, select Compute Engine > VM Instances, and select the life raft instance. Click Edit, scroll down to Additional disks, and click Add item. Add the disk you created in the previous step; for example, [INSTANCE-NAME]-new-disk. Ensure the Modeis Read/write, and that When deleting instance is set to Keep disk. Scroll down and click Save.

9.) Connect to the life-raft instance via SSH in the Browser, mount the disk you just attached, install the Guest Environment packages onto it, then unmount the disk
    •	    List storage devices. Note the device identifier for the unmounted disk. If sda is the life raft instance's boot device, then the additional disk is likely sdb. The primary volume on it is likely sdb1 if the disk only has one volume. Otherwise, lsblk can provide you with a list of volumes on the device. (Run: `lsblk` to get this info) 

    •	    Create a new mount point and mount the additional disk as follows. The following code block will mount ext4 and xfs filesystems: 

dev_id="sdb1" # for most cases
mount_point="/tmp/problematic-instance-new-disk"
# Get the filesystem for the device:
vol_filesystem="$(lsblk -fi | grep "$dev_id" | awk '{print tolower($2)}')"
# Adjust mount options for certain filesystems:
mount_opts="defaults"
if [ "$vol_filesystem" == "xfs" ]; then
   mount_opts="nouuid"
   # See https://linux-tips.com/t/xfs-filesystem-has-duplicate-uuid-problem/181
fi
sudo mkdir -p "$mount_point"
sudo mount -o "$mount_opts" /dev/"$dev_id" "$mount_point"

     •	   Copy the Linux Guest Environment packages to the mounted problematic instance disk. Install the Linux Guest Environment packages in a chroot environment:  
sudo cp -R /tmp/lge_pkgs_* \
/tmp/problematic-instance-new-disk/tmp/lge_pkgs

sudo chroot /tmp/problematic-instance-new-disk
cd /tmp/lge_pkgs

# Determine installer tool:
which dpkg
if [ "$?" == "0" ]; then
   installer_tool="dpkg"
else
   which rpm
   if [ "$?" == "0" ]; then
       installer_tool="rpm"
   fi
fi

for pkg in $(ls .); do
   "$installer_tool" -i "$pkg"
done

exit #Required so you leave the chroot!

Then, unmount the additional disk: sudo umount /tmp/problematic-instance-new-disk

10.) Now go ahead and detach the [INSTANCE-NAME]-new-disk from life raft instance:
     ◦	 In the Google Cloud Console, select Compute Engine > VM Instances, and select the life raft instance. Click Edit, scroll down to Additional disks, and click the X icon next to the disk you attached in step 5. Scroll down and click Save. 
11.) Next, clone the problematic instance, selecting the [INSTANCE-NAME]-new-disk as its boot disk. This creates the ‘repaired instance.’
     ◦	   In the Google Cloud Console, select Compute Engine > VM Instances, and select the stopped problematic instance. Click Clone. Provide a new name for the instance; for example,[INSTANCE-NAME]-repaired. In the Boot disk section, click Change, the click Existing Disks. Select the disk you just detached from the life raft instance (for example,[INSTANCE-NAME]-new-disk), click Select then click Create. 
12.) Now that the repaired instance is created, verify that you can connect successfully to the repaired instance via SSH in the Browser.
     •	 If you were able to successfully connect to the repaired instance, you can now clean up. You may delete the problematic instance, its problematic boot disk, and the snapshot you created. 

