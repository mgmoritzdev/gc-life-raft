## [Importing Boot Disk Images to Compute Engine on Google Cloud](https://cloud.google.com/compute/docs/images/import-existing-image)
Overview

To import a boot disk image to Compute Engine, use the following process:

1. Plan your import path. You must identify where you are going to prepare your boot disk image before you upload it, and how you are going to connect to that image after it boots in the Compute Engine environment.

  The process described in here is going to be made using a Cent OS 6.7 Version. We are going to use Oracle Virtual Box. Terminal and command line usage on both virtualization platforms will be prioritezed. 

2. Install new operational system, target is one of the choices presented in [here](http://vault.centos.org/6.7/isos/x86_64/). Option of choice for this work will be the [minimal version](http://vault.centos.org/6.7/isos/x86_64/CentOS-6.7-x86_64-minimal.iso). Sometimes the iso link may be a little troublesome of being downloaded, specially because it triggers a page instead of the actual iso file. To fix this, install [aria2c](https://aria2.github.io/) and then torrent it down: 

```
aria2c http://vault.centos.org/6.7/isos/x86_64/CentOS-6.7-x86_64-minimal.torrent
```

The followin VBoxManage list of commands are going to create new vm with all the requirements demanded for this work to succeed. The commands were all put inside the underlying function inside [tset](https://github.com/marcosantana77/tset/blob/master/bashrc/.bash_alias)/.bash_alias file, line #103.

Usage is: 

```
vbcreatel64 vmname 2 10 OS_Setup_iso_path.iso
``` 

This will create a vm Linux 64 at the current directory with 2gb RAM and 10gb Fixed Disk Size (**??? hd fixed size wasn't created, a test will take place to see if gcloud upload image actually accept dinamically sized images**)


3. After installation, execute the following commands in order to make it better: 

``` 
yum update -y && yum upgrade -y
```

**at this point it was observed that the machine lost its ability to shutdown with `sudo shutdown 0` or `sudo shutdown -r 0`. A new installation attempt was made in order to be certain that neither `yum update` or `yum upgrade` were responsable for this defect. The problem was quite simpler, documented at this [link](https://lists.centos.org/pipermail/centos/2007-April/037690.html). `shutdown -h 0` resolved the issue** 


shutdown vm and clone it or snapshot it with

```
 vboxmanage snapshot $VM take $snapshotName
```

. Let's assume from now on that the first version


2. Prepare your boot disk so it can boot within the Compute Engine environment and so you can access it after it boots.

3. Create and compress the boot disk image file.

5. Upload the image file to Google Cloud Storage and import the image to Compute Engine as a new custom image.

6. Use the imported image to create a virtual machine instance and make sure it boots properly.

7. Optimize the image and install the Linux Guest Environment so that your imported operating system image can communicate with the metadata server and use additional Compute Engine features.

8. If the image does not successfully boot, you can troubleshoot the issue by attaching the boot disk image to another instance and reconfiguring it.

```
Suggestion is that throughout the process that the source vm is froken as much as it can. That can be accomplished by cloning the source image as many time as needed at any major step taken.
``` 

