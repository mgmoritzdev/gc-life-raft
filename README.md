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


6. [x] Next, create a snapshot of the problematic instance’s boot disk:
In the Google Cloud Console, select Compute Engine > Snapshots, and click Create Snapshot. Name the snapshot something descriptive. For an example, we'll name the snapshot [INSTANCE-NAME]-disk-snapshot. For the Source disk, choose the problematic instance's boot disk determined in the previous step. Click Create.

```
gcloud compute --project=clirea-prod disks snapshot clirea-67 --zone=southamerica-east1-a --snapshot-names=clirea-67-snapshot

gcc snapshots list
NAME                DISK_SIZE_GB  SRC_DISK                              STATUS
clirea-67-snapshot  10            southamerica-east1-a/disks/clirea-67  READY
```

7. [x] Then create a new disk from the snapshot:
In the Google Cloud Console, select Compute Engine > Disks, and click Create Disk. Name the new disk something descriptive. For an example, we'll use [INSTANCE-NAME]-new-disk, using the instance name of the problematic instance. Change Source type to Snapshot, then select the Source snapshot created in the previous step. Click Create.

```
gcc disks create new-disk-clirea-67 --source-snapshot clirea-67-snapshot
Created [https://www.googleapis.com/compute/v1/projects/clirea-prod/zones/southamerica-east1-a/disks/new-disk-clirea-67].
NAME                ZONE                  SIZE_GB  TYPE         STATUS
new-disk-clirea-67  southamerica-east1-a  10       pd-standard  READY
```

8. [x] Now, attach the newly created disk to the life-raft instance:
In the Google Cloud Console, select Compute Engine > VM Instances, and select the life raft instance. Click Edit, scroll down to Additional disks, and click Add item. Add the disk you created in the previous step; for example, [INSTANCE-NAME]-new-disk. Ensure the Modeis Read/write, and that When deleting instance is set to Keep disk. Scroll down and click Save.

```
gcci attach-disk life-raft --disk new-disk-clirea-67
Updated [https://www.googleapis.com/compute/v1/projects/clirea-prod/zones/southamerica-east1-a/instances/life-raft].
```


9. [x] Connect to the life-raft instance via SSH in the Browser, mount the disk you just attached, install the Guest Environment packages onto it, then unmount the disk
    •	  [x]  List storage devices. Note the device identifier for the unmounted disk. If sda is the life raft instance's boot device, then the additional disk is likely sdb. The primary volume on it is likely sdb1 if the disk only has one volume. Otherwise, lsblk can provide you with a list of volumes on the device. (Run: `lsblk` to get this info)

    • Create a new mount point and mount the additional disk as follows. The following code block will mount ext4 and xfs filesystems:
    • [x] The [second script](./script2.sh) will do that for you


     • [X] Copy the Linux Guest Environment packages to the mounted problematic instance disk. Install the Linux Guest Environment packages in a chroot environment: by executing [script 3](./script3.sh)

    ```
    Not all commands went through smoothly, so I rpm'd -i the /tmp/lge_pkgs individually
    ```


    • [ ] Then, unmount the additional disk:
        `sudo umount /tmp/problematic-instance-new-disk`
      ```
      cannot seem possible to umount the disk due to the following error :

      umount: /tmp/problematic-instance-new-disk: device is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))

      I will try a different approach by first stopping the life-raft and then going to the next step
      ```



10. [x] Now go ahead and detach the [INSTANCE-NAME]-new-disk from life raft instance:
     ◦	 In the Google Cloud Console, select Compute Engine > VM Instances, and select the life raft instance. Click Edit, scroll down to Additional disks, and click the X icon next to the disk you attached in step 5. Scroll down and click Save.

      ```
      After

      gcci stop life-raft

      I tried to detach using gcloud, but unfortunately got this error :

      gcci detach-disk life-raft --disk=new-disk-clrea-67 --zone=southamerica-east1-a

      ERROR: (gcloud.compute.instances.detach-disk) Disk [new-disk-clrea-67] is not attached to instance [life-raft] in zone [southamerica-east1-a].
      ```
      ```
      I will go ahead and try the same using the console

      (ok) <== worked with the console
      ```

11. [x] Next, clone the problematic instance, selecting the [INSTANCE-NAME]-new-disk as its boot disk. This creates the ‘repaired instance.’
     ◦	   In the Google Cloud Console, select Compute Engine > VM Instances, and select the stopped problematic instance. Click Clone. Provide a new name for the instance; for example,[INSTANCE-NAME]-repaired. In the Boot disk section, click Change, the click Existing Disks. Select the disk you just detached from the life raft instance (for example,[INSTANCE-NAME]-new-disk), click Select then click Create.

```
'some info have been changed in order to not expose sensitive information'

gcloud beta compute --project "clirea-prod" instances create "clirea-67-r" --zone "southamerica-east1-a" --machine-type "custom-1-1792" --subnet "default" --metadata "port-enabled=1,serial-port-enable=1,serial-port-enabled=1,ssh-keys=ptmroot:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDl1ukLCkDFEIEEsGajlNtjQpgPNtjanPiGQK5QicWRsiSdfBPtuBvC4gKSzFgAioEKwFCPCNSYbcBlDZbPviMjIx8KIL2azMWYTwnakOcefKmEUq3r2GulxERq+t5IT9awzKxq5uul4QhH3IzmXMTV68k1kMIUgjdgIQTww5KuE6/7t+PWMr/OKOV2AqxicYN951fBtPnreV9R+49jQMeK7DwDcQsez2q6FHgyc2STEcr9C9WYUlkQSZcNHgiJ0guMYwbqNnuTDYHRG87JmsgUBmB+fwawAzjz3QhB36hWK/INg5W/NULociD3bShdnfqISvfioWkN130zCTSMSrFB ptmroot" --maintenance-policy "MIGRATE" --service-account "461101376066-compute@developer.gserviceaccount.com" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --min-cpu-platform "Automatic" --tags "http-server" --disk "name=new-disk-clirea-67,device-name=new-disk-clirea-67,mode=rw,boot=yes"


Created [https://www.googleapis.com/compute/beta/projects/clirea-prod/zones/southamerica-east1-a/instances/clirea-67-r].
NAME         ZONE                  MACHINE_TYPE               PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
clirea-67-r  southamerica-east1-a  custom (1 vCPU, 1.75 GiB)               10.158.0.6   192.198.0.2  RUNNING
```

12. [ ] Now that the repaired instance is created, verify that you can connect successfully to the repaired instance via SSH in the Browser.
     •	 If you were able to successfully connect to the repaired instance, you can now clean up. You may delete the problematic instance, its problematic boot disk, and the snapshot you created.

```
Unfortunately the same error remains

gcssh clirea-67-r
ssh: connect to host 192.198.0.1 port 22: Operation timed out
ERROR: (gcloud.compute.ssh) [/usr/bin/ssh] exited with return code [255].
```

# Downgrade CentOS from 6.9 to 6.7 (Alternative)
Follow the steps in this [link](https://serverfault.com/a/697578) to downgrade CentOS
  - [ ] Update yum packages editing /etc/yum.repos.d/CentOS-Base.repo accordind to [this link](https://www.centos.org/forums/viewtopic.php?t=36628). Use [these files](http://vault.centos.org/6.7/).
  - [ ] Install kernel 2.6.32-573.26.1
  - [ ] Downgrade the kernel

## Check current version
```bash
uname -r
cat /etc/centos-release
```
output:
```
2.6.32-696.10.2.el6.x86_64
CentOS release 6.9 (Final)
```

## Change repos to release version
```bash
sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/base.repo.bkp
sudo sed -i -e 's/mirrorlist=/#mirrolist=/g' /etc/yum.repos.d/CentOS-Base.repo
sudo sed -i -e 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/CentOS-Base.repo
sudo sed -i -e 's/mirror.centos/vault.centos/g' /etc/yum.repos.d/CentOS-Base.repo
sudo sed -i -e 's/$releasever/6.7/g' /etc/yum.repos.d/CentOS-Base.repo

sudo yum clean all
```
output:
```
Loaded plugins: fastestmirror, security
Cleaning repos: base centos-sclo-rh centos-sclo-sclo epel extras google-cloud-compute updates
Cleaning up Everything
```

## Check the results after find & replace
```bash
  cat /etc/yum.repos.d/CentOS-Base.repo
```

output:
```
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the #mirrolist= does not work for you, as a fall back you can try the
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-6.7 - Base
#mirrolist=http://mirrorlist.centos.org/?release=6.7&arch=$basearch&repo=os&infra=$infra
baseurl=http://vault.centos.org/centos/6.7/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#released updates
[updates]
name=CentOS-6.7 - Updates
#mirrolist=http://mirrorlist.centos.org/?release=6.7&arch=$basearch&repo=updates&infra=$infra
baseurl=http://vault.centos.org/centos/6.7/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that may be useful
[extras]
name=CentOS-6.7 - Extras
#mirrolist=http://mirrorlist.centos.org/?release=6.7&arch=$basearch&repo=extras&infra=$infra
baseurl=http://vault.centos.org/centos/6.7/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-6.7 - Plus
#mirrolist=http://mirrorlist.centos.org/?release=6.7&arch=$basearch&repo=centosplus&infra=$infra
baseurl=http://vault.centos.org/centos/6.7/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

#contrib - packages by Centos Users
[contrib]
name=CentOS-6.7 - Contrib
#mirrolist=http://mirrorlist.centos.org/?release=6.7&arch=$basearch&repo=contrib&infra=$infra
baseurl=http://vault.centos.org/centos/6.7/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
```

## Downgrade Kernel
```bash
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
sudo yum install kernel-2.6.32 -y
```

output:
```
Retrieving http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
Preparing...                ########################################### [100%]
   1:elrepo-release         ########################################### [100%]
Loaded plugins: fastestmirror, security
Setting up Install Process
Determining fastest mirrors

epel/metalink                                            |  11 kB     00:00
    * elrepo: repos.ord.lax-noc.com
    * epel: mirror.steadfast.net

base                                                     | 3.7 kB     00:00
   base/primary_db           18% [==-            ]  0.0 B/s | 849 kB     --:-- ETA

base/primary_db                                          | 4.6 MB     00:00

centos-sclo-rh                                           | 2.9 kB     00:00
   centos-sclo-rh/primary_db 70% [==========-    ]  0.0 B/s | 1.8 MB     --:-- ETA

centos-sclo-rh/primary_db                                | 2.6 MB     00:00

centos-sclo-sclo                                         | 2.9 kB     00:00

centos-sclo-sclo/primary_db                              | 171 kB     00:00

elrepo                                                   | 2.9 kB     00:00

elrepo/primary_db                                        | 731 kB     00:00

epel                                                     | 4.3 kB     00:00

epel/primary_db                                          | 5.9 MB     00:00

extras                                                   | 3.4 kB     00:00

extras/primary_db                                        |  37 kB     00:00

google-cloud-compute/signature                           |  454 B     00:00

google-cloud-compute/signature                           | 1.4 kB     00:00 ...

google-cloud-compute/primary                             | 3.3 kB     00:00

google-cloud-compute: [#######                                            ] 1/7
google-cloud-compute: [##############                                     ] 2/7
google-cloud-compute: [#####################                              ] 3/7
google-cloud-compute: [#############################                      ] 4/7
google-cloud-compute: [####################################               ] 5/7
google-cloud-compute: [###########################################        ] 6/7
google-cloud-compute                                                        7/7

updates                                                  | 3.4 kB     00:00
   updates/primary_db        15% [==             ]  0.0 B/s | 804 kB     --:-- ETA

updates/primary_db                                       | 5.2 MB     00:00
   Resolving Dependencies
   --> Running transaction check
   ---> Package kernel.x86_64 0:2.6.32-573.26.1.el6 will be installed
   --> Finished Dependency Resolution

   Dependencies Resolved

   ================================================================================
    Package       Arch          Version                       Repository      Size
   ================================================================================
   Installing:
    kernel        x86_64        2.6.32-573.26.1.el6           updates         30 M

   Transaction Summary
   ================================================================================
   Install       1 Package(s)

   Total download size: 30 M
   Installed size: 126 M
   Downloading Packages:
   kernel-2.6.32-573.26.1.el  3% [               ]  0.0 B/s | 1.0 MB     --:-- ETA
kernel-2.6.32-573.26.1.el 36% [=====-         ]  17 MB/s |  11 MB     00:01 ETA
kernel-2.6.32-573.26.1.el 64% [=========-     ]  18 MB/s |  20 MB     00:00 ETA
kernel-2.6.32-573.26.1.el 88% [=============  ]  18 MB/s |  27 MB     00:00 ETA

kernel-2.6.32-573.26.1.el6.x86_64.rpm                    |  30 MB     00:01
   Running rpm_check_debug
   Running Transaction Test
   Transaction Test Succeeded
   Running Transaction

  Installing : kernel-2.6.32-573.26.1.el6.x [                             ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#                            ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [##                           ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [###                          ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [####                         ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#####                        ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [######                       ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#######                      ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [########                     ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#########                    ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [##########                   ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [###########                  ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [############                 ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#############                ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [##############               ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [###############              ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [################             ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#################            ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [##################           ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [###################          ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [####################         ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#####################        ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [######################       ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#######################      ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [########################     ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [#########################    ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [##########################   ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [###########################  ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x [############################ ] 1/1
  Installing : kernel-2.6.32-573.26.1.el6.x86_64                            1/1

  Verifying  : kernel-2.6.32-573.26.1.el6.x86_64                            1/1

   Installed:
     kernel.x86_64 0:2.6.32-573.26.1.el6

   Complete!
```

## Restart VM
```bash
sudo reboot
```
output:
```
   Broadcast message from marcosmoritz@centos67-test4

     (unknown) at 2:29 ...




The system is going down for reboot NOW!
```

## Downgrade OS
```bash
sudo yum downgrade centos-release -y
```

output:
```
Loaded plugins: fastestmirror, security
Setting up Downgrade Process
Loading mirror speeds from cached hostfile
 * elrepo: repos.ord.lax-noc.com
 * epel: mirror.steadfast.net
Resolving Dependencies
--> Running transaction check
---> Package centos-release.x86_64 0:6-7.el6.centos.12.3 will be a downgrade
---> Package centos-release.x86_64 0:6-9.el6.12.3 will be erased
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================
 Package              Arch         Version                     Repository  Size
================================================================================
Downgrading:
 centos-release       x86_64       6-7.el6.centos.12.3         base        21 k

Transaction Summary
================================================================================
Downgrade     1 Package(s)

Total download size: 21 k
Downloading Packages:

centos-release-6-7.el6.centos.12.3.x86_64.rpm            |  21 kB     00:00
    Running rpm_check_debug
    Running Transaction Test
    Transaction Test Succeeded
    Running Transaction

Installing : centos-release-6-7.el6.cento [                             ] 1/2
Installing : centos-release-6-7.el6.cento [#                            ] 1/2
Installing : centos-release-6-7.el6.cento [###                          ] 1/2
Installing : centos-release-6-7.el6.cento [####                         ] 1/2
Installing : centos-release-6-7.el6.cento [#####                        ] 1/2
Installing : centos-release-6-7.el6.cento [######                       ] 1/2
Installing : centos-release-6-7.el6.cento [########                     ] 1/2
Installing : centos-release-6-7.el6.cento [#########                    ] 1/2
Installing : centos-release-6-7.el6.cento [#############                ] 1/2
Installing : centos-release-6-7.el6.cento [##############               ] 1/2
Installing : centos-release-6-7.el6.cento [############################ ] 1/2
Installing : centos-release-6-7.el6.centos.12.3.x86_64                    1/2

Cleanup    : centos-release-6-9.el6.12.3.x86_64                           2/2

Verifying  : centos-release-6-7.el6.centos.12.3.x86_64                    1/2

Verifying  : centos-release-6-9.el6.12.3.x86_64                           2/2

  Removed:
    centos-release.x86_64 0:6-9.el6.12.3

  Installed:
    centos-release.x86_64 0:6-7.el6.centos.12.3

  Complete!
```

## Downgrade OS

```bash
cat /etc/centos-release
uname -r
```
output:

```
CentOS release 6.7 (Final)
2.6.32-573.26.1.el6.x86_64
```
