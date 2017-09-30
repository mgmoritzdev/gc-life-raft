# Instructions to generate a new gc instance out of a non-supported Cent OS Version (6.7)

## How To Rescue your CentOS 6.5 import and install the Linux Guest Environment===

1. [x] The first thing we will need to do is create a new instance from the Google-provided public CentOS 6 image. We will call this the ‘life-raft’ instance, and we will use it to rescue your CentOS 6.7 disk to install the Linux Guest environment and make a new image from that disk which you can use for creating future CentOS 6.7 instances. 

2. [x] Once you have created the life-raft instance, go ahead and stop your CentOS 6.7 instance for now (we will refer to your CentOS 6.7 instance as the ‘problematic instance’).

3. [x] The next thing we’ll want to do is to download the current Guest Environment packages. The code for the script is pasted here for you:

## Execute [script 1](./script1.sh).

I recommend transferring this file to your life-raft instance either via a file transfer tool such as rsync, or by copying/pasting it over a terminal-based SSH session, as there may be problems pasting the file into a Browser-based SSH terminal. 

```
The first transfer option of choice were scp, everything went fine 
but then the script execution raised a few errors outputs so I 
figured it would be better if we split the file instructions 
from the executing bits. So git pulls and pushes became the 
transfer option. This repo can be purged if needed in case 
of non-disclosure breaking. 
``` 

4.  [x] Once the file is transferred, go ahead and run it. This will download the appropriate packages and leave them on your life-raft instance for later use.

5. [x] Now that the life-raft is mostly prepared, stop the problematic instance and determine the name of its boot disk: you can do this by going in the Google Cloud Console, select Compute Engine > VM Instances, and select the problematic instance. Click Stop. Note the name of the boot disk in the Boot disk and local disks section.

```
gcloud compute disks list

NAME                ZONE                  SIZE_GB  TYPE         STATUS
**clirea-67**           southamerica-east1-a  10       pd-standard  READY
clirea-prod         southamerica-east1-a  150      pd-ssd       READY
db-prod             southamerica-east1-a  30       pd-ssd       READY
dsk-db-prod-arch    southamerica-east1-a  200      pd-ssd       READY
dsk-db-prod-backup  southamerica-east1-a  1000     pd-ssd       READY
dsk-db-prod-orcl    southamerica-east1-a  100      pd-ssd       READY
dsk-db-prod-redo01  southamerica-east1-a  10       pd-ssd       READY
dsk-db-prod-redo02  southamerica-east1-a  10       pd-ssd       READY
dsk-db-prod-tmp     southamerica-east1-a  10       pd-ssd       READY
dsk-db-prod-u01     southamerica-east1-a  1000     pd-ssd       READY
instance-1          southamerica-east1-a  10       pd-standard  READY
life-raft           southamerica-east1-a  10       pd-standard  READY
vmmin               southamerica-east1-a  10       pd-ssd       READY
``` 


6. [ ] Next, create a snapshot of the problematic instance’s boot disk:
In the Google Cloud Console, select Compute Engine > Snapshots, and click Create Snapshot. Name the snapshot something descriptive. For an example, we'll name the snapshot [INSTANCE-NAME]-disk-snapshot. For the Source disk, choose the problematic instance's boot disk determined in the previous step. Click Create.

7. [ ] Then create a new disk from the snapshot:
In the Google Cloud Console, select Compute Engine > Disks, and click Create Disk. Name the new disk something descriptive. For an example, we'll use [INSTANCE-NAME]-new-disk, using the instance name of the problematic instance. Change Source type to Snapshot, then select the Source snapshot created in the previous step. Click Create.

8. [ ] Now, attach the newly created disk to the life-raft instance:
In the Google Cloud Console, select Compute Engine > VM Instances, and select the life raft instance. Click Edit, scroll down to Additional disks, and click Add item. Add the disk you created in the previous step; for example, [INSTANCE-NAME]-new-disk. Ensure the Modeis Read/write, and that When deleting instance is set to Keep disk. Scroll down and click Save.

9. Connect to the life-raft instance via SSH in the Browser, mount the disk you just attached, install the Guest Environment packages onto it, then unmount the disk
    •	    List storage devices. Note the device identifier for the unmounted disk. If sda is the life raft instance's boot device, then the additional disk is likely sdb. The primary volume on it is likely sdb1 if the disk only has one volume. Otherwise, lsblk can provide you with a list of volumes on the device. (Run: `lsblk` to get this info) 

    •	    Create a new mount point and mount the additional disk as follows. The following code block will mount ext4 and xfs filesystems: 
