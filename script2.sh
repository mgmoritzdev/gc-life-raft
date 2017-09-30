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
